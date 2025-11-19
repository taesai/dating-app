import 'dart:async';
import '../../core/widgets/rive_loader.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:appwrite/appwrite.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/models/search_preferences.dart';
import '../../core/services/backend_service.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/services/usage_tracking_service.dart';
import '../../core/services/swipe_counter_service.dart';
import '../../core/config/feature_flags.dart';
import '../../core/widgets/web_video_player.dart';
import '../../core/utils/page_transitions.dart';
import '../widgets/pending_approval_banner.dart';
import '../widgets/modern_swipe_card.dart';
import '../widgets/swipe_action_buttons.dart';
import '../widgets/heart_particles_animation.dart';
import 'user_detail_profile_page.dart';
import 'dating_home_page.dart';
import 'search_page.dart';
import 'dart:html' as html;
import 'dart:convert';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> with AutomaticKeepAliveClientMixin {
  final BackendService _backendService = BackendService();
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  final UsageTrackingService _usageTracking = UsageTrackingService();
  final SwipeCounterService _swipeCounter = SwipeCounterService();

  @override
  bool get wantKeepAlive => true; // Garder l'état en mémoire

  List<VideoModel> _videos = []; // Liste paginée des vidéos (max 10 à la fois)
  Map<String, DatingUser> _videoOwners = {}; // Map videoId -> propriétaire
  Set<String> _likedVideoIds = {}; // Set des vidéos déjà likées
  Set<String> _likedProfileIds = {}; // Set des profils (userId) déjà likés
  Set<String> _viewedVideoIds = {}; // Set des vidéos déjà vues (pour compteur)
  Set<String> _blockedUserIds = {}; // Set des utilisateurs bloqués
  String? _currentUserId;
  DatingUser? _currentUser;
  bool _isLoading = true;
  bool _isLoadingMore = false; // Flag pour le chargement de nouvelles vidéos
  bool _swipeBlocked = false; // Bloquer le swipe quand limite atteinte
  int _currentCardIndex = 0; // Tracker la carte visible
  int _currentPage = 0; // Page actuelle pour la pagination
  static const int _videosPerPage = 20; // Nombre de vidéos à charger par batch (augmenté pour compenser le filtrage)
  static const int _minVideosToKeep = 5; // Minimum de vidéos valides à garder après filtrage
  bool _hasMoreVideos = true; // Y a-t-il encore des vidéos à charger?
  RealtimeSubscription? _videoSubscription; // Subscription Realtime pour les nouvelles vidéos
  StreamSubscription? _videoStreamSubscription;
  bool _isDisposing = false; // Flag pour bloquer les callbacks pendant dispose
  int _swipesRemaining = 20; // Swipes restants pour les utilisateurs non approuvés
  bool _showHeartParticles = false; // Animation de cœurs lors des likes
  bool _isInitialized = false; // Flag pour éviter de recharger lors des rebuilds

  @override
  void initState() {
    super.initState();
    _loadUsers();

    // Activer Realtime seulement si le feature flag est activé
    if (FeatureFlags.enableRealtime) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _subscribeToNewVideos();
        }
      });
    } else {
      print('ℹ️ Realtime désactivé (FeatureFlags.enableRealtime = false)');
    }
  }

  @override
  void dispose() {
    _isDisposing = true; // Marquer immédiatement comme en dispose

    // IMPORTANT: Fermer la subscription Realtime AVANT d'annuler le stream
    _videoSubscription?.close();
    _videoStreamSubscription?.cancel();

    super.dispose();
  }

  // Écouter les nouvelles vidéos en temps réel avec Appwrite Realtime
  void _subscribeToNewVideos() {
    if (_isDisposing || !mounted) return;

    try {
      final appwriteService = AppwriteService();
      final channel = 'databases.${AppwriteService.databaseId}.collections.${AppwriteService.videosCollectionId}.documents';

      print('🔔 Tentative d\'abonnement Realtime: $channel');

      _videoSubscription = appwriteService.realtime.subscribe([channel]);

      _videoStreamSubscription = _videoSubscription!.stream.listen(
        (response) {
          try {
            if (_isDisposing || !mounted) return;
            print('📡 Event Realtime reçu: ${response.events}');

            if (response.events.contains('databases.*.collections.*.documents.*.create')) {
              print('🎬 Nouvelle vidéo détectée!');
              _handleNewVideo(response.payload);
            }
          } catch (e) {
            if (!_isDisposing && mounted) {
              print('❌ Erreur callback videos: $e');
            }
          }
        },
        onError: (error) {
          if (!_isDisposing && mounted) {
            print('⚠️ Erreur stream Realtime (normal si collections pas créées): $error');
          }
        },
        onDone: () {
          print('✅ Stream Realtime terminé');
        },
        cancelOnError: false,
      );

      print('✅ Abonnement Realtime actif');
    } catch (e) {
      print('⚠️ Impossible de s\'abonner au Realtime (collections peut-être manquantes): $e');
      // L'app continue de fonctionner sans Realtime
    }
  }

  // Gérer l'arrivée d'une nouvelle vidéo
  Future<void> _handleNewVideo(Map<String, dynamic> videoData) async {
    try {
      final newVideo = VideoModel.fromJson(videoData);

      // Ignorer si c'est une vidéo de l'utilisateur actuel
      if (newVideo.userId == _currentUserId) {
        print('⏭️ Vidéo de l\'utilisateur actuel, ignorée');
        return;
      }

      // Ignorer si l'utilisateur est bloqué
      if (_blockedUserIds.contains(newVideo.userId)) {
        print('🚫 Utilisateur bloqué, ignoré');
        return;
      }

      // Charger le propriétaire de la vidéo
      final userDoc = await _backendService.getUserProfile(newVideo.userId);
      final userData = userDoc is Map ? userDoc : userDoc.data;
      final owner = DatingUser.fromJson(userData);

      // Appliquer les filtres de recherche
      final prefs = _loadSearchPreferences();
      if (prefs != null && !_matchesPreferences(owner, prefs)) {
        print('⏭️ Utilisateur ne correspond pas aux préférences');
        return;
      }

      // Ajouter la nouvelle vidéo à la liste
      if (mounted) {
        setState(() {
          _videos.insert(0, newVideo); // Ajouter au début
          _videoOwners[newVideo.id] = owner;
        });
        print('✨ Nouvelle vidéo ajoutée en temps réel: ${owner.name}');
      }
    } catch (e) {
      print('❌ Erreur traitement nouvelle vidéo: $e');
    }
  }

  SearchPreferences? _loadSearchPreferences() {
    try {
      final prefsStr = html.window.localStorage['search_preferences'];
      if (prefsStr != null && prefsStr.isNotEmpty) {
        final prefsMap = jsonDecode(prefsStr);
        return SearchPreferences.fromJson(prefsMap);
      }
    } catch (e) {
      print('⚠️ Erreur chargement préférences: $e');
    }
    return null;
  }

  // Charger les vidéos déjà likées par l'utilisateur et tracker les profils likés
  Future<void> _loadLikedVideos() async {
    try {
      // Récupérer tous les likes de vidéos de l'utilisateur connecté
      final response = await _backendService.getLikedVideos();

      if (response != null) {
        // Gérer les deux types de retour possibles (DocumentList ou Map)
        final likes = response is Map
            ? (response['documents'] as List? ?? [])
            : response.documents;

        // Collecter les videoIds
        final videoIds = <String>[];
        for (var like in likes) {
          final likeData = like is Map ? like : like.data;
          final videoId = likeData['videoId'];
          if (videoId != null) {
            _likedVideoIds.add(videoId);
            videoIds.add(videoId);
          }
        }

        // Charger TOUS les propriétaires de vidéos en PARALLÈLE
        final videoFutures = videoIds.map((videoId) =>
          _backendService.getVideo(videoId).then((videoDoc) {
            final videoData = videoDoc is Map ? videoDoc : videoDoc.data;
            final ownerId = videoData['userId'];
            return ownerId as String?;
          }).catchError((e) {
            // Ignorer silencieusement les vidéos supprimées (404)
            return null;
          })
        ).toList();

        final ownerIds = await Future.wait(videoFutures);

        // Ajouter les ownerIds valides
        for (var ownerId in ownerIds) {
          if (ownerId != null) {
            _likedProfileIds.add(ownerId);
          }
        }

        print('📍 ${_likedVideoIds.length} vidéos déjà likées chargées');
        print('👤 ${_likedProfileIds.length} profils déjà likés');
      }
    } catch (e) {
      print('⚠️ Erreur chargement vidéos likées: $e');
    }
  }

  bool _matchesPreferences(DatingUser user, SearchPreferences prefs) {
    // Filtre par âge
    if (user.age < prefs.ageRange.start || user.age > prefs.ageRange.end) {
      return false;
    }

    // Filtre par genre
    if (prefs.gender != null && user.gender != prefs.gender) {
      return false;
    }

    // Filtre par centres d'intérêt (au moins un en commun)
    if (prefs.interests.isNotEmpty) {
      final hasCommonInterest = user.interests.any(
        (interest) => prefs.interests.contains(interest)
      );
      if (!hasCommonInterest) return false;
    }

    // Filtre par type de relation recherchée
    if (prefs.lookingFor.isNotEmpty) {
      final hasCommonLookingFor = user.lookingFor.any(
        (lookingFor) => prefs.lookingFor.contains(lookingFor)
      );
      if (!hasCommonLookingFor) return false;
    }

    // Filtre par continent
    if (prefs.continents.isNotEmpty) {
      if (user.continent == null || !prefs.continents.contains(user.continent)) {
        return false;
      }
    }

    // Filtre par pays
    if (prefs.countries.isNotEmpty) {
      if (user.country == null || !prefs.countries.contains(user.country)) {
        return false;
      }
    }

    // Filtre par ville
    if (prefs.cities.isNotEmpty) {
      if (user.city == null || !prefs.cities.contains(user.city)) {
        return false;
      }
    }

    return true;
  }

  Future<void> _loadUsers() async {
    // Éviter de recharger si déjà initialisé (lors des rebuilds)
    if (_isInitialized) {
      print('✅ Déjà initialisé, pas de rechargement');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final currentUser = await _backendService.getCurrentUser();
      _currentUserId = currentUser is Map ? currentUser['\$id'] : currentUser.$id;

      // Charger le profil complet de l'utilisateur pour obtenir le plan d'abonnement
      final profileData = (currentUser is Map) ? currentUser : (currentUser.data is Map ? currentUser.data : {});
      _currentUser = DatingUser.fromJson(profileData);

      print('🎬 Chargement des vidéos en PRIORITÉ...');
      // PRIORITÉ 1: Charger les vidéos IMMÉDIATEMENT pour afficher le feed
      await _loadMoreVideos();

      // Attendre que les premières vidéos aient le temps de charger leurs URLs
      print('⏳ Attente du chargement des URLs vidéos...');
      await Future.delayed(const Duration(milliseconds: 1500));
      // Afficher le feed DÈS que les vidéos sont chargées
      setState(() {
        _isLoading = false;
        _isInitialized = true; // Marquer comme initialisé
      });
      print('✅ Feed affiché avec ${_videos.length} vidéos');

      // PRIORITÉ 2: Charger les métadonnées en arrière-plan (non bloquant)
      print('📊 Chargement des métadonnées en arrière-plan...');
      _loadMetadataInBackground();
    } catch (e) {
      print('❌ Erreur _loadUsers: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  // Charger compteur, bloqués, likés en arrière-plan (non bloquant)
  Future<void> _loadMetadataInBackground() async {
    try {
      await Future.wait([
        // Compteur de swipes
        () async {
          if (_currentUser!.isProfileApproved != true) {
            _swipesRemaining = await _swipeCounter.getSwipesRemaining(_currentUserId!);
            print('📊 Utilisateur non approuvé: $_swipesRemaining swipes restants');
          } else if (_currentUser!.effectivePlan == 'free') {
            final currentCount = await _usageTracking.getSwipesCount();
            final limit = _usageTracking.getSwipeLimit('free');
            _swipesRemaining = limit - currentCount;
            print('📊 Utilisateur FREE: $_swipesRemaining swipes restants (sur $limit)');
          }
          if (mounted) setState(() {}); // Rafraîchir le compteur
        }(),
        _loadBlockedUsers(),
        _loadLikedVideos(),
      ]);
      print('✅ Métadonnées chargées');
    } catch (e) {
      print('⚠️ Erreur chargement métadonnées: $e');
      // Ne pas bloquer l'affichage si les métadonnées échouent
    }
  }

  // Charger les utilisateurs bloqués
  Future<void> _loadBlockedUsers() async {
    try {
      final response = await _backendService.getBlockedUsers();
      if (response != null) {
        final blocks = response is Map
            ? (response['documents'] as List? ?? [])
            : response.documents;

        for (var block in blocks) {
          final blockData = block is Map ? block : block.data;
          final blockedUserId = blockData['blockedUserId'];
          if (blockedUserId != null) {
            _blockedUserIds.add(blockedUserId);
          }
        }
        print('🚫 ${_blockedUserIds.length} utilisateurs bloqués chargés');
      }
    } catch (e) {
      print('⚠️ Erreur chargement utilisateurs bloqués: $e');
    }
  }
  /// Algorithme hybride de scoring des vidéos
  double _calculateVideoScore(DatingUser user, VideoModel video) {
    double score = 0;

    // 1. Compatibilité de base (40%)
    score += _calculateCompatibility(user) * 0.4;

    // 2. Engagement de la vidéo (25%)
    double engagementRate = video.views > 0 ? video.likes / video.views : 0;
    score += engagementRate * 0.25;

    // 3. Fraîcheur - vidéos récentes (20%)
    int daysSinceUpload = DateTime.now().difference(video.createdAt ?? DateTime.now()).inDays;
    double freshnessScore = 1 / (1 + daysSinceUpload / 7); // Décroît après 7 jours
    score += freshnessScore * 0.2;

    // 4. Activité utilisateur (15%)
    bool isRecentlyActive = user.isActive;
    score += (isRecentlyActive ? 1.0 : 0.3) * 0.15;

    return score;
  }

  /// Calculer le score de compatibilité entre deux utilisateurs
  double _calculateCompatibility(DatingUser user) {
    if (_currentUser == null) return 0.5;

    double compatScore = 0;
    int factors = 0;

    // 1. Âge compatible (poids: 2)
    int ageDiff = (user.age - _currentUser!.age).abs();
    if (ageDiff <= 5) {
      compatScore += 1.0 * 2;
    } else if (ageDiff <= 10) {
      compatScore += 0.5 * 2;
    }
    factors += 2;

    // 2. Intérêts communs (poids: 3)
    final commonInterests = user.interests.toSet().intersection(_currentUser!.interests.toSet());
    double interestScore = user.interests.isNotEmpty 
        ? commonInterests.length / user.interests.length 
        : 0;
    compatScore += interestScore * 3;
    factors += 3;

    // 3. Distance (poids: 2)
    double distance = user.distanceTo(_currentUser!);
    double distanceScore = 1 - (distance / 10000).clamp(0.0, 1.0); // Normaliser sur 10000km
    compatScore += distanceScore * 2;
    factors += 2;

    // 4. Orientation sexuelle compatible (poids: 1)
    if (user.lookingFor.contains(_currentUser!.gender)) {
      compatScore += 1.0;
    }
    factors += 1;

    return factors > 0 ? compatScore / factors : 0.5;
  }


  /// Charger un nouveau batch de vidéos (pagination)
  /// Continue à charger jusqu'à avoir au moins _minVideosToKeep vidéos valides
  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMoreVideos) {
      print('⏸️ Chargement en cours ou plus de vidéos disponibles');
      return;
    }

    try {
      setState(() => _isLoadingMore = true);

      // Charger les préférences de recherche
      final prefs = _loadSearchPreferences();

      List<VideoModel> newVideos = [];
      int attempts = 0;
      const maxAttempts = 5; // Maximum 5 batches pour éviter une boucle infinie

      // Continuer à charger jusqu'à avoir au moins _minVideosToKeep vidéos valides
      while (newVideos.length < _minVideosToKeep && _hasMoreVideos && attempts < maxAttempts) {
        attempts++;
        print('📥 Chargement batch $_currentPage (tentative $attempts)...');

        // Charger un batch de vidéos avec pagination
        final videosResponse = await _backendService.getVideosPaginated(
          limit: _videosPerPage,
          offset: _currentPage * _videosPerPage,
        );

        print('📦 ${videosResponse.documents.length} vidéos reçues du backend');

        // Pré-filtrer les vidéos avant de charger les profils
        final candidateVideos = <VideoModel>[];
        for (var doc in videosResponse.documents) {
          try {
            final videoData = doc is Map ? doc : doc.data;
            final video = VideoModel.fromJson(videoData);

            // Ignorer les vidéos de l'utilisateur actuel
            if (video.userId == _currentUserId) {
              print('⏭️ Vidéo de l\'utilisateur actuel ignorée');
              continue;
            }

            // Ignorer les vidéos des utilisateurs bloqués
            if (_blockedUserIds.contains(video.userId)) {
              print('🚫 Utilisateur bloqué ignoré');
              continue;
            }

            // FILTRER: Ne garder que les vidéos approuvées
            if (video.isApproved != true) {
              print('❌ ${video.id} - vidéo non approuvée par admin');
              continue;
            }

            candidateVideos.add(video);
          } catch (e) {
            print('❌ Erreur parsing vidéo: $e');
          }
        }

        // Charger TOUS les profils en PARALLÈLE au lieu de séquentiellement
        print('👥 Chargement de ${candidateVideos.length} profils en parallèle...');
        final userFutures = candidateVideos.map((video) =>
          _backendService.getUserProfile(video.userId).catchError((e) {
            print('❌ Erreur profil ${video.userId}: $e');
            return null;
          })
        ).toList();

        final userDocs = await Future.wait(userFutures);

        // Traiter les résultats
        for (int i = 0; i < candidateVideos.length; i++) {
          try {
            final video = candidateVideos[i];
            final userDoc = userDocs[i];

            if (userDoc == null) continue;

            final userData = userDoc is Map ? userDoc : userDoc.data;
            final owner = DatingUser.fromJson(userData);

            // FILTRER: Ne garder que les profils approuvés par l'admin
            if (owner.isProfileApproved != true) {
              print('❌ ${owner.name} - profil non approuvé par admin');
              continue;
            }

            // Vérifier que l'utilisateur a des vidéos
            if (owner.videoIds.isEmpty) {
              print('⏭️ Utilisateur ${owner.name} sans vidéos');
              continue;
            }

            // Appliquer les filtres de recherche
            if (prefs != null && !_matchesPreferences(owner, prefs)) {
              print('⏭️ ${owner.name} ne correspond pas aux préférences');
              continue;
            }

            // Ajouter la vidéo et son propriétaire
            newVideos.add(video);
            _videoOwners[video.id] = owner;
            print('✅ Vidéo chargée: ${owner.name}');

          } catch (e) {
            print('❌ Erreur traitement vidéo: $e');
          }
        }

        // Si on a reçu moins de vidéos que demandé, on a atteint la fin
        if (videosResponse.documents.length < _videosPerPage) {
          _hasMoreVideos = false;
          print('🏁 Plus de vidéos disponibles dans la base');
          break;
        }

        _currentPage++;
        print('📊 ${newVideos.length} vidéos valides trouvées jusqu\'à présent');
      }

      if (mounted) {
        setState(() {
          // Trier les vidéos par score hybride (compatibilité + engagement + fraîcheur + activité)
          newVideos.sort((a, b) {
            final ownerA = _videoOwners[a.id];
            final ownerB = _videoOwners[b.id];
            if (ownerA == null || ownerB == null) return 0;
            final scoreA = _calculateVideoScore(ownerA, a);
            final scoreB = _calculateVideoScore(ownerB, b);
            return scoreB.compareTo(scoreA); // Ordre décroissant (meilleur score first)
          });
          _videos.addAll(newVideos);
          _isLoadingMore = false;
        });
      }

      print('✅ ${newVideos.length} nouvelles vidéos ajoutées (total: ${_videos.length})');

    } catch (e) {
      print('❌ Erreur _loadMoreVideos: $e');
      setState(() => _isLoadingMore = false);
    }
  }


    Future<void> _handleSwipe(int previousIndex, int? targetIndex, SwiperActivity activity) async {
    print('🔍 DEBUG _handleSwipe: previousIndex=$previousIndex, targetIndex=$targetIndex, direction=${activity.direction}');

    // Si utilisateur non approuvé, vérifier la limite de 20 swipes/jour
    if (_currentUser != null && _currentUser!.isProfileApproved != true) {
      final canSwipe = await _swipeCounter.canSwipe(_currentUserId!);
      if (!canSwipe) {
        print('❌ Limite de swipes atteinte pour utilisateur non approuvé');
        setState(() => _swipeBlocked = true); // BLOQUER tous les swipes futurs
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.hourglass_empty, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Limite de swipes atteinte. Revenez demain ou attendez l approbation de votre profil !')),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      // Incrémenter le compteur pour utilisateurs non approuvés
      final success = await _swipeCounter.incrementSwipeCount(_currentUserId!);
      if (success) {
        _swipesRemaining = await _swipeCounter.getSwipesRemaining(_currentUserId!);

        // Vérifier si c'''était le dernier swipe autorisé
        if (_swipesRemaining <= 0) {
          setState(() => _swipeBlocked = true); // BLOQUER les swipes futurs après le dernier
        } else {
          setState(() {}); // Juste mettre à jour le compteur dans le banner
        }
      }
    }
    // Pour utilisateurs approuvés, utiliser le système de plan
    else if (_currentUser != null) {
      final currentCount = await _usageTracking.getSwipesCount();
      final limit = _usageTracking.getSwipeLimit(_currentUser!.effectivePlan);
      print('🔍 DEBUG Swipe - Plan: ${_currentUser!.effectivePlan}, Compteur: $currentCount, Limite: $limit');

      final canSwipe = await _usageTracking.canSwipe(_currentUser!.effectivePlan);
      if (!canSwipe) {
        print('❌ Limite de swipes atteinte!');
        setState(() => _swipeBlocked = true);
        _showLimitReachedDialog('swipes');
        return;
      }
      // Incrémenter le compteur seulement si autorisé
      await _usageTracking.incrementSwipes();
      final newCount = await _usageTracking.getSwipesCount();
      print('✅ Swipe autorisé, compteur incrémenté à $newCount');

      // Mettre à jour le compteur affiché en haut
      setState(() {
        _swipesRemaining = limit - newCount;
      });
    }

    // Mettre à jour l'index de la carte courante
    if (targetIndex != null && targetIndex >= 0 && targetIndex < _videos.length) {
      setState(() {
        _currentCardIndex = targetIndex;
      });
      print('🔄 Changement de carte: $previousIndex → $targetIndex');

      // Charger plus de vidéos si on approche de la fin (2 vidéos restantes)
      if (_videos.length - targetIndex <= 2 && !_isLoadingMore && _hasMoreVideos) {
        print('⏬ Proche de la fin, chargement de nouvelles vidéos...');
        _loadMoreVideos();
      }
    }

    // Vérifier que l'index est valide
    if (previousIndex >= 0 && previousIndex < _videos.length) {
      final video = _videos[previousIndex];
      final owner = _videoOwners[video.id]; // Utiliser video.id au lieu de video.fileId

      print('🔍 DEBUG owner: video.id=${video.id}, owner=${owner?.name}, direction=${activity.direction}');

      if (owner != null) {
        if (activity.direction == AxisDirection.right) {
          print('➡️ Direction RIGHT détectée pour ${owner.name}');
          // Swipe droite = Like (mais bloqué si utilisateur non approuvé)
          
          // BLOQUER LES LIKES POUR UTILISATEURS NON APPROUVÉS
          if (_currentUser != null && _currentUser!.isProfileApproved != true) {
            print('🚫 Like bloqué - utilisateur non approuvé');
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(child: Text('Votre profil doit être approuvé pour pouvoir liker et matcher. Vous pouvez explorer en attendant !')),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
                ),
              );
            }
            return; // Bloquer le like complètement
          }

          print('❤️ Like ${owner.name}');

          // VÉRIFIER LA LIMITE DE LIKES (pour utilisateurs approuvés)
          if (_currentUser != null) {
            final canLike = await _usageTracking.canLike(_currentUser!.effectivePlan);
            if (!canLike) {
              _showLimitReachedDialog('likes');
              return; // Bloquer le like
            }
          }

          // Vérifier si le PROFIL a déjà été liké (peu importe quelle vidéo)
          if (_likedProfileIds.contains(owner.id)) {
            print('⚠️ Profil ${owner.name} (${owner.id}) déjà liké');
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('ℹ️ Vous avez déjà liké le profil de ${owner.name}'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(milliseconds: 1500),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
                ),
              );
            }
            return; // Arrêter ici, ne pas liker à nouveau
          }

          // Incrémenter le compteur de likes
          await _usageTracking.incrementLikes();

          // Activer l'animation de cœurs
          setState(() => _showHeartParticles = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showHeartParticles = false);
          });

          // Like l'utilisateur pour les matches
          _likeUser(owner);

          // Marquer ce profil comme liké
          _likedProfileIds.add(owner.id);

          // IMPORTANT: Liker aussi la vidéo si elle existe
          if (video != null) {
            print('🎥 Like vidéo ${video.id}');
            _likeVideoById(video.id);
          }

          // Afficher un feedback visuel
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('❤️ Vous avez liké ${owner.name}'),
                  ],
                ),
                backgroundColor: Colors.pink,
                duration: const Duration(milliseconds: 1500),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
              ),
            );
          }
        } else if (activity.direction == AxisDirection.left) {
          // Swipe gauche = Dislike
          print('👎 Dislike ${owner.name}');
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('👋 ${owner.name} passé(e)'),
                  ],
                ),
                backgroundColor: Colors.grey[700],
                duration: const Duration(milliseconds: 1200),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
              ),
            );
          }
        } else if (activity.direction == AxisDirection.up) {
          // Swipe haut = Voir profil
          print('👤 Swipe UP - Voir profil de ${owner.name}');
          context.pushModalWithSlideUp(
            UserDetailProfilePage(
              user: owner,
              currentUserId: _currentUserId,
            ),
          );
        }
      }
    }
  }

  void _showLimitReachedDialog(String type) {
    if (!mounted) return;

    final plan = _currentUser?.effectivePlan ?? 'free';
    final limit = type == 'swipes'
        ? _usageTracking.getSwipeLimit(plan)
        : _usageTracking.getLikeLimit(plan);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              type == 'swipes' ? Icons.swipe : Icons.favorite,
              color: Colors.pink,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('Limite atteinte'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'swipes'
                  ? 'Vous avez atteint votre limite de $limit swipes aujourd\'hui.'
                  : 'Vous avez atteint votre limite de $limit likes aujourd\'hui.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (plan == 'free') ...[
              const Text(
                'Passez à SILVER pour avoir 100 swipes et 50 likes par jour, ou GOLD pour un accès illimité !',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ] else if (plan == 'silver') ...[
              const Text(
                'Passez à GOLD pour un accès illimité aux swipes et likes !',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (plan != 'gold')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Naviguer vers la page d'upgrade
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité d\'upgrade à venir !'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  Future<void> _likeUser(DatingUser user) async {
    if (_currentUserId == null) return;

    try {
      print('👍 Envoi du like pour ${user.name}');

      // Appeler le backend pour enregistrer le like
      final result = await _backendService.likeUser(
        fromUserId: _currentUserId!,
        toUserId: user.id,
      );

      print('✅ Like enregistré: $result');

      // Vérifier si c'est un match
      if (result != null && result['isMatch'] == true) {
        print('💕 C\'EST UN MATCH avec ${user.name}!');
        if (mounted) {
          _showMatchDialog(user);
          // Notifier le parent pour rafraîchir les compteurs
          _notifyParentToRefresh();
        }
      } else {
        // Like simple sans match - rafraîchir quand même
        _notifyParentToRefresh();
      }
    } catch (e) {
      final errorMsg = e.toString();
      print('❌ Erreur _likeUser: $errorMsg');

      // Si c'est l'erreur "Déjà liké", ne rien afficher (c'est normal)
      if (!errorMsg.contains('Déjà liké')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      } else {
        print('ℹ️ Utilisateur déjà liké, on ignore');
      }
    }
  }

  // Liker une vidéo par son ID (appelé lors du swipe)
  Future<void> _likeVideoById(String videoId) async {
    if (_currentUserId == null) return;

    try {
      print('🎥 Envoi du like pour vidéo $videoId');

      final result = await _backendService.likeVideo(videoId);

      if (result != null && result['success'] == true) {
        // Marquer comme liké
        _likedVideoIds.add(videoId);

        // Mettre à jour le compteur de likes dans la vidéo locale
        final videoIndex = _videos.indexWhere((v) => v.id == videoId);
        if (videoIndex != -1) {
          setState(() {
            _videos[videoIndex] = _videos[videoIndex].copyWith(
              likes: result['totalLikes'] ?? _videos[videoIndex].likes + 1,
            );
          });
        }

        print('✅ Vidéo likée: ${result['totalLikes']} likes');
      }
    } catch (e) {
      final errorMsg = e.toString();
      print('❌ Erreur _likeVideoById: $errorMsg');

      if (errorMsg.contains('Déjà liké')) {
        _likedVideoIds.add(videoId);
        print('ℹ️ Vidéo déjà likée');
      }
    }
  }

  void _notifyParentToRefresh() {
    // Trouver le DatingHomePage parent et déclencher le refresh
    if (mounted) {
      // On utilise un callback via le contexte
      final homePageState = context.findAncestorStateOfType<DatingHomePageState>();
      homePageState?.refreshCounters();
    }
  }

  void _showMatchDialog(DatingUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink[300]!, Colors.purple[300]!],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 80),
              const SizedBox(height: 16),
              const Text(
                'C\'est un Match !',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous et ${user.name} vous aimez mutuellement !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(149, 255, 255, 255),
                        foregroundColor: const Color.fromARGB(150, 233, 30, 98),
                      ),
                      child: const Text('Continuer'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.pink,
                      ),
                      child: const Text('Message'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Nécessaire pour AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.dotsTriangle(
            color: Colors.pink,
            size: 80,
          ),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Aucune vidéo trouvée', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: HeartParticlesAnimation(
        isActive: _showHeartParticles,
        particleColor: Colors.pink,
        particleCount: 25,
        child: Stack(
          children: [
            // Swiper en plein écran
            AppinioSwiper(
                  controller: _swiperController,
                  cardCount: _videos.length,
                  loop: true, // Permet de revenir au début après la dernière carte
                  swipeOptions: _swipeBlocked ? const SwipeOptions.only() : const SwipeOptions.only(left: true, right: true, up: true), // Activer swipe up pour voir profil
                  cardBuilder: (BuildContext context, int index) {
                    final video = _videos[index];
                    final owner = _videoOwners[video.id]; // Utiliser video.id au lieu de video.fileId
                    if (owner == null) {
                      return const Center(child: Text('Utilisateur introuvable'));
                    }
                    return ModernSwipeCard(
                        key: ValueKey('${video.id}-${video.likes}-${video.views}'), // Key change avec likes/views
                        user: owner,
                        video: video,
                        backendService: _backendService,
                        currentUserId: _currentUserId,
                        isVisible: index == _currentCardIndex, // Seule la carte courante est visible
                        likedVideoIds: _likedVideoIds,
                        viewedVideoIds: _viewedVideoIds,
                        onSwipeUp: () {
                          print('👤 Swipe UP - Voir profil de ${owner.name}');
                          context.pushModalWithSlideUp(
                            UserDetailProfilePage(
                              user: owner,
                              currentUserId: _currentUserId,
                            ),
                          );
                        },
                      );
                  },
                  onSwipeEnd: _handleSwipe,
                  onEnd: () {
                    // Afficher un message quand toutes les cartes ont été swipées
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('🎉 Vous avez vu toutes les vidéos ! Les cartes vont recommencer.'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'Recharger',
                            onPressed: _loadUsers,
                          ),
                        ),
                      );
                    }
                  },
          ),

          // Bouton de recherche moderne en haut à droite
          Positioned(
            top: 50,
            right: 20,
            child: FloatingModernButton(
              icon: Icons.tune,
              color: Colors.pink,
              tooltip: 'Recherche avancée',
              onTap: () async {
                final homeState = context.findAncestorStateOfType<DatingHomePageState>();
                if (homeState != null) {
                  await context.pushModalWithSlideUp(const SearchPage());
                  _loadUsers();
                  homeState.refreshCounters();
                }
              },
            ),
          ),

          // Bannière pour utilisateurs non approuvés OU utilisateurs FREE approuvés
          if (_currentUser != null &&
              (_currentUser!.isProfileApproved != true || _currentUser!.effectivePlan == 'free'))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: PendingApprovalBanner(
                  swipesRemaining: _swipesRemaining,
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _UserCard extends StatefulWidget {
  final DatingUser user;
  final VideoModel? video;
  final BackendService backendService;
  final String? currentUserId;
  final bool isVisible;
  final Set<String> likedVideoIds;
  final Set<String> viewedVideoIds;
  final VoidCallback? onSwipeUp;

  const _UserCard({
    super.key,
    required this.user,
    required this.video,
    required this.backendService,
    this.currentUserId,
    this.isVisible = false,
    required this.likedVideoIds,
    required this.viewedVideoIds,
    this.onSwipeUp,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> with AutomaticKeepAliveClientMixin {
  final GlobalKey _playerKey = GlobalKey();
  bool _isVideoInitialized = false;
  String? _videoUrl;

  @override
  bool get wantKeepAlive => true; // Garder en vie pour éviter de réinitialiser constamment

  // Vérifier si la vidéo est déjà likée
  bool get _hasLikedVideo => widget.video != null && widget.likedVideoIds.contains(widget.video!.id);

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(_UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si la vidéo a changé, réinitialiser
    if (oldWidget.video?.id != widget.video?.id) {
      print('🔄 Changement de vidéo détecté: ${oldWidget.video?.id} -> ${widget.video?.id}');
      setState(() {
        _isVideoInitialized = false;
        _videoUrl = null;
      });
      if (widget.video != null) {
        _initializeVideo();
      }
    }

    // CRITIQUE: Gérer le son selon la visibilité
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        // Carte devient visible → activer le son et jouer
        print('👁️ VISIBLE: ${widget.user.name} - ACTIVER SON');
        if (_isVideoInitialized) {
          WebVideoPlayer.setVolume(_playerKey, 1.0);
          WebVideoPlayer.play(_playerKey);

          // Incrémenter le compteur de vues
          _incrementViewIfNeeded();
        }
      } else {
        // Carte devient invisible → MUTER et pauser
        print('🙈 INVISIBLE: ${widget.user.name} - MUTER');
        if (_isVideoInitialized) {
          WebVideoPlayer.setVolume(_playerKey, 0.0);
          WebVideoPlayer.pause(_playerKey);
        }
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final urlParam = widget.video!.videoUrl ?? widget.video!.fileId;
      final videoUrl = widget.backendService.getVideoUrl(urlParam);
      print('🎬 Init ${widget.user.name} (visible: ${widget.isVisible}): $videoUrl');

      if (mounted) {
        setState(() {
          _videoUrl = videoUrl;
          _isVideoInitialized = true;
        });
        print('✅ Vidéo URL définie pour ${widget.user.name}');
      }

      // Attendre que le widget soit construit et le player initialisé
      await Future.delayed(const Duration(milliseconds: 100));

      // CRITIQUE: Volume selon visibilité
      if (widget.isVisible) {
        print('🔊 Carte VISIBLE - Volume 1.0 + Play pour ${widget.user.name}');
        WebVideoPlayer.setVolume(_playerKey, 1.0);
        WebVideoPlayer.play(_playerKey);

        // Incrémenter le compteur de vues (une seule fois par vidéo)
        _incrementViewIfNeeded();
      } else {
        print('🔇 Carte INVISIBLE - Volume 0.0 + Pause pour ${widget.user.name}');
        WebVideoPlayer.setVolume(_playerKey, 0.0);
        WebVideoPlayer.pause(_playerKey);
      }
    } catch (e) {
      print('❌ Erreur initialisation vidéo pour ${widget.user.name}: $e');
    }
  }

  // Incrémenter le compteur de vues (une seule fois par vidéo)
  Future<void> _incrementViewIfNeeded() async {
    if (widget.video == null) return;

    // Vérifier si cette vidéo a déjà été comptée
    if (widget.viewedVideoIds.contains(widget.video!.id)) {
      print('ℹ️ Vidéo ${widget.video!.id} déjà comptée');
      return;
    }

    try {
      print('👁️ Incrémentation vue pour vidéo ${widget.video!.id}');
      final result = await widget.backendService.incrementVideoView(widget.video!.id);

      if (result != null && result['success'] == true) {
        // Marquer comme vue
        widget.viewedVideoIds.add(widget.video!.id);
        print('✅ Vue incrémentée: ${result['totalViews']} vues');
      }
    } catch (e) {
      print('⚠️ Erreur incrémentation vue: $e');
      // Ne pas bloquer en cas d'erreur
    }
  }

  @override
  void dispose() {
    print('🗑️ Dispose vidéo pour ${widget.user.name}');
    if (_playerKey.currentState != null) {
      print('🛑 Arrêt et libération vidéo pour ${widget.user.name}');
      WebVideoPlayer.pause(_playerKey);
      WebVideoPlayer.setVolume(_playerKey, 0.0);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Nécessaire pour AutomaticKeepAliveClientMixin

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Détecter swipe vertical vers le haut (seuil réduit pour plus de sensibilité)
        if (details.primaryVelocity != null && details.primaryVelocity! < -400) {
          print('👆 Swipe UP détecté dans _UserCard');
          widget.onSwipeUp?.call();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Afficher la vidéo si disponible, sinon photo, sinon placeholder
              _buildBackground(),

            // Gradient overlay sombre simple
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),

            // Informations utilisateur
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${widget.user.name}, ${widget.user.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.video != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.play_circle_filled, color: Colors.white, size: 28),
                      ],
                    ],
                  ),
                  if (widget.user.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.user.bio,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.user.interests.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: widget.user.interests.take(3).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Text(interest, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            ],
          ),
        ),
      ),
    );
  }

  Future<void> _likeVideo() async {
    if (widget.video == null || widget.currentUserId == null) return;

    // Vérifier si déjà liké
    if (_hasLikedVideo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ Vous avez déjà liké cette vidéo'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    try {
      print('❤️ Like vidéo ${widget.video!.id}');

      final result = await widget.backendService.likeVideo(widget.video!.id);

      if (result != null && result['success'] == true) {
        // Marquer comme liké dans le Set global
        widget.likedVideoIds.add(widget.video!.id);

        // Forcer le rebuild
        setState(() {});

        // Feedback visuel
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('❤️ Vous avez liké la vidéo de ${widget.user.name} (${result['totalLikes']} likes)'),
                ],
              ),
              backgroundColor: Colors.pink,
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            ),
          );
        }

        // Notifier le parent pour rafraîchir les compteurs
        _notifyParentToRefresh();
      }
    } catch (e) {
      final errorMsg = e.toString();
      print('❌ Erreur _likeVideo: $errorMsg');

      if (errorMsg.contains('Déjà liké')) {
        // Backend dit déjà liké, marquer localement aussi
        widget.likedVideoIds.add(widget.video!.id);
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ℹ️ Vous avez déjà liké cette vidéo'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _notifyParentToRefresh() {
    // Trouver le DatingHomePage parent et déclencher le refresh
    if (mounted) {
      final homePageState = context.findAncestorStateOfType<DatingHomePageState>();
      homePageState?.refreshCounters();
    }
  }

  Widget _buildBackground() {
    // Priorité : Vidéo > Photo > Placeholder
    if (_isVideoInitialized && _videoUrl != null) {
      return WebVideoPlayer(
        key: _playerKey,
        videoUrl: _videoUrl!,
        autoPlay: widget.isVisible,
        loop: true,
        muted: !widget.isVisible,
        onReady: () {
          print('✅ WebVideoPlayer prêt pour ${widget.user.name}');
          // Gérer le volume initial
          if (widget.isVisible) {
            WebVideoPlayer.setVolume(_playerKey, 1.0);
            WebVideoPlayer.play(_playerKey);
          } else {
            WebVideoPlayer.setVolume(_playerKey, 0.0);
            WebVideoPlayer.pause(_playerKey);
          }
        },
      );
    } else if (widget.video != null && !_isVideoInitialized) {
      // Afficher un loader pendant le chargement de la vidéo
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    } else if (widget.user.photoUrlsFull.isNotEmpty) {
      // Fallback sur la photo si pas de vidéo
      return Image.network(widget.user.photoUrlsFull.first, fit: BoxFit.cover);
    } else {
      // Placeholder si ni vidéo ni photo
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.person, size: 100, color: Colors.grey),
      );
    }
  }
}

