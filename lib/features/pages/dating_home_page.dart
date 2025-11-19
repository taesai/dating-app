import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:animations/animations.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'swipe_page.dart';
import 'users_map_page.dart';
import 'matches_page.dart';
import 'likes_page.dart';
import 'dating_profile_page.dart';
import 'upload_video_page.dart';
import 'search_page.dart';
import 'onboarding_tutorial_page.dart';
import 'simple_color_picker_page.dart';
import '../../core/services/backend_service.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/models/dating_user.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../widgets/likes_matches_panel.dart';
import '../widgets/user_card_panel.dart';
import '../widgets/animated_bottom_nav.dart';
import '../widgets/simple_neumorphic_button.dart';
import '../widgets/offline_indicator_widget.dart';
import '../widgets/layout_transitioner.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/widgets/rive_loader.dart';

class DatingHomePage extends ConsumerStatefulWidget {
  const DatingHomePage({super.key});

  @override
  ConsumerState<DatingHomePage> createState() => DatingHomePageState();
}

class DatingHomePageState extends ConsumerState<DatingHomePage> with WidgetsBindingObserver {
  final BackendService _backend = BackendService();
  int _currentIndex = 0; // Commence sur les cartes swipables (maintenant index 0)
  DatingUser? _currentUser;
  Key _swipePageKey = const ValueKey('swipe_page');
  Key _profilePageKey = const ValueKey('profile_page'); // Forcer le reload du profil
  Key _matchesPageKey = const ValueKey('matches_page'); // Forcer le reload des matches
  int _matchesCount = 0;
  int _likesCount = 0;
  int _messagesCount = 0; // Compteur de messages non lus
  Set<String> _likersUserIds = {}; // Set des userId qui ont déjà liké (dédoublonnage)
  bool _likesViewed = false; // Flag pour savoir si l'utilisateur a vu les likes
  bool _matchesViewed = false; // Flag pour savoir si l'utilisateur a vu les matches
  bool _messagesViewed = false; // Flag pour savoir si l'utilisateur a vu les messages
  RealtimeSubscription? _likesSubscription; // Subscription pour les likes reçus
  RealtimeSubscription? _matchesSubscription; // Subscription pour les matches
  RealtimeSubscription? _messagesSubscription; // Subscription pour les messages
  StreamSubscription? _likesStreamSubscription;
  StreamSubscription? _matchesStreamSubscription;
  StreamSubscription? _messagesStreamSubscription;
  bool _isDisposing = false; // Flag pour bloquer les callbacks pendant dispose
  bool _countersLoaded = false; // Flag pour éviter de charger les compteurs plusieurs fois
  String _previousLayoutType = 'mobile'; // Pour détecter la direction de transition

  late final List<Widget> _pages = [
    SwipePage(key: _swipePageKey), // Cartes swipables = Découvrir
    const LikesPage(), // Likes reçus
    const UsersMapPage(),
    MatchesPage(key: _matchesPageKey), // Avec key pour forcer le reload
    DatingProfilePage(key: _profilePageKey), // Avec key pour forcer le reload
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize(); // Initialiser dans le bon ordre
  }

  // Initialiser dans le bon ordre: flags PUIS compteurs
  Future<void> _initialize() async {
    if (_countersLoaded) return; // Éviter de recharger si déjà chargé

    await _loadViewedFlags(); // D'ABORD charger les flags depuis localStorage
    _loadCurrentUser();
    await Future.wait([
      _loadMatchesCount(), // Charger en parallèle pour plus de rapidité
      _loadLikesCount(),
      _loadMessagesCount(),
    ]);
    if (mounted) {
      setState(() {
        _countersLoaded = true;
      });
    } // Marquer comme chargé
    _subscribeToLikesAndMatches(); // Écouter les likes et matches en temps réel

    // Afficher le tutoriel si première visite
    _checkAndShowTutorial();
  }

  void _checkAndShowTutorial() async {
    // Vérifier si le tutoriel a déjà été complété
    final hasCompleted = await TutorialHelper.hasCompletedTutorial();

    if (!hasCompleted) {
      print('📚 Première visite - affichage du tutoriel');
      // Attendre que l'interface soit chargée
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OnboardingTutorialPage(),
              fullscreenDialog: true,
            ),
          );
        }
      });
    } else {
      print('✅ Tutoriel déjà complété - pas d\'affichage');
    }
  }

  // Charger les flags "viewed" depuis localStorage (spécifique à l'utilisateur)
  Future<void> _loadViewedFlags() async {
    try {
      // Attendre d'avoir l'ID utilisateur
      final user = await _backend.getCurrentUser();
      final userId = user is Map ? user['\$id'] ?? user['id'] : user.$id;

      final likesViewedStr = html.window.localStorage['likes_viewed_$userId'];
      final matchesViewedStr = html.window.localStorage['matches_viewed_$userId'];
      final messagesViewedStr = html.window.localStorage['messages_viewed_$userId'];

      if (mounted) {
        setState(() {
          _likesViewed = likesViewedStr == 'true';
          _matchesViewed = matchesViewedStr == 'true';
          _messagesViewed = messagesViewedStr == 'true';
        });
      }

      print('📂 Flags chargés pour user $userId: likesViewed=$_likesViewed, matchesViewed=$_matchesViewed');
    } catch (e) {
      print('⚠️ Erreur chargement flags viewed: $e');
    }
  }

  // Sauvegarder les flags "viewed" dans localStorage (spécifique à l'utilisateur)
  Future<void> _saveViewedFlags() async {
    try {
      // Attendre d'avoir l'ID utilisateur
      final user = await _backend.getCurrentUser();
      final userId = user is Map ? user['\$id'] ?? user['id'] : user.$id;

      html.window.localStorage['likes_viewed_$userId'] = _likesViewed.toString();
      html.window.localStorage['matches_viewed_$userId'] = _matchesViewed.toString();
      html.window.localStorage['messages_viewed_$userId'] = _messagesViewed.toString();
      print('💾 Flags sauvegardés pour user $userId: likesViewed=$_likesViewed, matchesViewed=$_matchesViewed, messagesViewed=$_messagesViewed');
    } catch (e) {
      print('⚠️ Erreur sauvegarde flags viewed: $e');
    }
  }

  @override
  void dispose() {
    // Marquer immédiatement comme en cours de dispose
    _isDisposing = true;

    // IMPORTANT: Fermer les subscriptions Realtime AVANT d'annuler les streams
    // Cela arrête l'émission de nouveaux événements
    _likesSubscription?.close();
    _matchesSubscription?.close();
    _messagesSubscription?.close();

    // Ensuite annuler les streams
    _likesStreamSubscription?.cancel();
    _matchesStreamSubscription?.cancel();
    _messagesStreamSubscription?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ne rafraîchir que si l'utilisateur n'a pas déjà vu les badges
      if (!_likesViewed && !_matchesViewed) {
        refreshCounters();
      }
    }
  }

  void _subscribeToLikesAndMatches() async {
    try {
      final appwriteService = AppwriteService();
      final user = await _backend.getCurrentUser();
      final userId = user is Map ? user['id'] : user.$id;

      // Subscribe to video_likes collection for new likes received
      final likesChannel = 'databases.${AppwriteService.databaseId}.collections.${AppwriteService.videoLikesCollectionId}.documents';
      _likesSubscription = appwriteService.realtime.subscribe([likesChannel]);

      _likesStreamSubscription = _likesSubscription!.stream.listen(
        (response) {
          try {
            if (_isDisposing || !mounted) return; // Ignorer si dispose en cours
            if (response.events.contains('databases.*.collections.*.documents.*.create')) {
              _handleNewLike(response.payload, userId);
            }
          } catch (e) {
            // Ignorer silencieusement les erreurs pendant dispose
            if (!_isDisposing && mounted) {
              print('❌ Erreur callback likes: $e');
            }
          }
        },
        onError: (error) {
          if (!_isDisposing && mounted) {
            print('❌ Erreur stream likes: $error');
          }
        },
        cancelOnError: false, // Continuer même en cas d'erreur
      );

      // Subscribe to matches collection for new matches
      final matchesChannel = 'databases.${AppwriteService.databaseId}.collections.${AppwriteService.matchesCollectionId}.documents';
      _matchesSubscription = appwriteService.realtime.subscribe([matchesChannel]);

      _matchesStreamSubscription = _matchesSubscription!.stream.listen(
        (response) {
          try {
            if (_isDisposing || !mounted) return; // Ignorer si dispose en cours
            if (response.events.contains('databases.*.collections.*.documents.*.create')) {
              _handleNewMatch(response.payload, userId);
            }
          } catch (e) {
            // Ignorer silencieusement les erreurs pendant dispose
            if (!_isDisposing && mounted) {
              print('❌ Erreur callback matches: $e');
            }
          }
        },
        onError: (error) {
          if (!_isDisposing && mounted) {
            print('❌ Erreur stream matches: $error');
          }
        },
        cancelOnError: false, // Continuer même en cas d'erreur
      );

      // Subscribe to matches collection for new messages (update events)
      _messagesSubscription = appwriteService.realtime.subscribe([matchesChannel]);

      _messagesStreamSubscription = _messagesSubscription!.stream.listen(
        (response) {
          try {
            if (_isDisposing || !mounted) return; // Ignorer si dispose en cours
            if (response.events.contains('databases.*.collections.*.documents.*.update')) {
              _handleNewMessage(response.payload, userId);
            }
          } catch (e) {
            // Ignorer silencieusement les erreurs pendant dispose
            if (!_isDisposing && mounted) {
              print('❌ Erreur callback messages: $e');
            }
          }
        },
        onError: (error) {
          if (!_isDisposing && mounted) {
            print('❌ Erreur stream messages: $error');
          }
        },
        cancelOnError: false, // Continuer même en cas d'erreur
      );

      print('✅ Subscriptions Realtime actives pour likes, matches et messages');
    } catch (e) {
      print('❌ Erreur subscription Realtime likes/matches/messages: $e');
    }
  }

  Future<void> _handleNewLike(Map<String, dynamic> likeData, String currentUserId) async {
    try {
      final videoId = likeData['videoId'];
      final likerId = likeData['userId']; // ID de celui qui a liké

      // Vérifier si la vidéo appartient à l'utilisateur actuel
      final appwriteService = AppwriteService();
      final videoDoc = await appwriteService.databases.getDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.videosCollectionId,
        documentId: videoId,
      );

      final videoData = (videoDoc is Map)
          ? videoDoc
          : (videoDoc.data is Map ? videoDoc.data : {});
      final videoOwnerId = (videoData as Map)['userId'];

      if (videoOwnerId == currentUserId) {
        // Vérifier si ce profil a déjà liké (dédoublonnage)
        if (!_likersUserIds.contains(likerId)) {
          print('🎉 Nouveau like reçu d\'un nouveau profil: $likerId');
          _likersUserIds.add(likerId); // Ajouter au Set
          if (mounted) {
            setState(() {
              _likesCount++;
              _likesViewed = false;
            });
            _saveViewedFlags(); // Persister le changement
          }
        } else {
          print('ℹ️ Like reçu de $likerId (déjà compté, doublon ignoré)');
        }
      }
    } catch (e) {
      print('❌ Erreur traitement nouveau like: $e');
    }
  }

  Future<void> _handleNewMatch(Map<String, dynamic> matchData, String currentUserId) async {
    try {
      final user1Id = matchData['user1Id'];
      final user2Id = matchData['user2Id'];

      // Vérifier si le match concerne l'utilisateur actuel
      if (user1Id == currentUserId || user2Id == currentUserId) {
        print('💖 Nouveau match en temps réel!');
        if (mounted) {
          setState(() {
            _matchesCount++;
            _matchesViewed = false;
          });
          _saveViewedFlags(); // Persister le changement
        }
      }
    } catch (e) {
      print('❌ Erreur traitement nouveau match: $e');
    }
  }

  Future<void> _handleNewMessage(Map<String, dynamic> matchData, String currentUserId) async {
    try {
      final lastMessageSenderId = matchData['lastMessageSenderId'];
      final user1Id = matchData['user1Id'];
      final user2Id = matchData['user2Id'];

      // Vérifier si le message concerne l'utilisateur actuel et qu'il n'est pas l'expéditeur
      if ((user1Id == currentUserId || user2Id == currentUserId) &&
          lastMessageSenderId != null &&
          lastMessageSenderId != currentUserId) {
        print('💬 Nouveau message reçu en temps réel!');
        if (mounted) {
          setState(() {
            _messagesCount++;
            _messagesViewed = false;
          });
          _saveViewedFlags(); // Persister le changement
        }
      }
    } catch (e) {
      print('❌ Erreur traitement nouveau message: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _backend.getCurrentUser();
      final userId = user is Map ? user['id'] : user.$id;
      final profileDoc = await _backend.getUserProfile(userId);
      final profileData = profileDoc is Map ? profileDoc : profileDoc.data;
      setState(() {
        _currentUser = DatingUser.fromJson(profileData);
      });
    } catch (e) {
      // Silently fail, user might not have profile yet
    }
  }

  Future<void> _loadMatchesCount() async {
    try {
      print('📊 Chargement du compteur de matches...');
      final user = await _backend.getCurrentUser();
      final userId = user is Map ? user['id'] : user.$id;
      final matchesDoc = await _backend.getMatches(userId);

      // Dédoublonner et compter uniquement les matches avec profils valides
      final Map<String, bool> uniqueMatches = {};
      for (var matchDoc in matchesDoc.documents) {
        final matchData = matchDoc is Map ? matchDoc : matchDoc.data;
        final user1Id = matchData['user1Id'];
        final user2Id = matchData['user2Id'];
        final otherUserId = (user1Id == userId) ? user2Id : user1Id;

        if (!uniqueMatches.containsKey(otherUserId)) {
          uniqueMatches[otherUserId] = true;
        }
      }

      final count = uniqueMatches.length;
      print('✅ Matches valides: $count (déjà vu: $_matchesViewed)');
      if (mounted) {
        setState(() {
          // Toujours afficher le nombre réel de matches
          _matchesCount = count;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement matches: $e');
    }
  }

  Future<void> _loadMessagesCount() async {
    try {
      print('📊 Chargement du compteur de messages non lus...');
      final user = await _backend.getCurrentUser();
      final userId = user is Map ? user['id'] : user.$id;

      // Compter les conversations avec des messages non lus
      final matchesDoc = await _backend.getMatches(userId);
      int unreadCount = 0;

      for (var matchDoc in matchesDoc.documents) {
        final matchData = matchDoc is Map ? matchDoc : matchDoc.data;
        final lastMessage = matchData['lastMessage'];
        final lastMessageSenderId = matchData['lastMessageSenderId'];

        // Si il y a un dernier message et qu'il n'est pas de moi, c'est un message non lu
        if (lastMessage != null && lastMessageSenderId != null && lastMessageSenderId != userId) {
          unreadCount++;
        }
      }

      print('✅ Messages non lus: $unreadCount (déjà vu: $_messagesViewed)');
      if (mounted) {
        setState(() {
          _messagesCount = _messagesViewed ? 0 : unreadCount;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement messages: $e');
    }
  }

  Future<void> _loadLikesCount() async {
    try {
      print('📊 Chargement du compteur de likes...');
      final likesDoc = await _backend.getLikesReceived();
      // Gérer les deux types de retour possibles (DocumentList ou Map)
      final documents = likesDoc is Map ? (likesDoc['documents'] ?? []) : likesDoc.documents;

      // Extraire les userId des likers (dédoublonnage automatique via Set)
      Set<String> likerIds = {};
      for (var doc in documents) {
        final likeData = doc is Map ? doc : doc.data;
        final userId = likeData['userId'];
        if (userId != null) {
          likerIds.add(userId);
        }
      }

      final count = likerIds.length; // Compter les profils uniques, pas les likes
      print('✅ Likes reçus: $count profils uniques (${documents.length} likes au total, déjà vu: $_likesViewed)');
      if (mounted) {
        setState(() {
          _likersUserIds = likerIds; // Stocker les likers pour dédoublonnage temps réel
          // Si déjà vu, afficher 0. Sinon afficher le nombre réel
          _likesCount = _likesViewed ? 0 : count;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement likes: $e');
    }
  }

  // Méthode publique pour que les enfants puissent rafraîchir les compteurs
  void refreshCounters() {
    if (!mounted) return;
    print('🔄 Rafraîchissement des compteurs likes/matches');
    Future.wait([
      _loadLikesCount(),
      _loadMatchesCount(),
      _loadMessagesCount(),
    ]).then((_) {
      // Force le rebuild pour mettre à jour les badges
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _refreshProfileCounters() {
    // Rafraîchir les compteurs de la page de profil en forçant un rebuild
    setState(() {
      _profilePageKey = UniqueKey(); // Force le rebuild complet du profil
    });
    print('🔄 Page profil rechargée avec nouveaux compteurs');
  }

  Future<void> _navigateToUploadVideo() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement du profil en cours...')),
      );
      return;
    }

    final result = await context.pushModalWithSlideUp(
      UploadVideoPage(currentUser: _currentUser!),
    );

    if (result == true) {
      // Recharger le profil après upload
      await _loadCurrentUser();
      // Aller sur l'onglet profil - les pages se rafraîchiront automatiquement
      setState(() {
        _currentIndex = 4; // Aller sur l'onglet profil pour voir la nouvelle vidéo (index 4 maintenant)
      });
      // Note: Pas besoin de changer les Keys, IndexedStack garde les pages en mémoire
      // et elles se rafraîchiront via leurs propres mécanismes (pull-to-refresh, etc.)
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = !isDesktop && !isTablet;

    return Scaffold(
      // Pas d'AppBar sur la page Découvrir (index 0) pour avoir le plein écran en mobile
      appBar: (isMobile && _currentIndex == 0) ? null : AppBar(
        title: Text(_currentIndex == 1 ? '' :
                    _currentIndex == 2 ? 'Carte' :
                    _currentIndex == 3 ? 'Matchs' : 'Profil'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            tooltip: 'Recherche avancée',
            onPressed: () async {
              await context.pushModalWithSlideUp(const SearchPage());
              refreshCounters();
            },
          ),
          // Bouton pour personnaliser les couleurs
          IconButton(
            icon: const Icon(Icons.palette, color: Colors.white),
            tooltip: 'Personnaliser les couleurs',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SimpleColorPickerPage(),
                ),
              );
            },
          ),
          // Bouton pour basculer le thème
          IconButton(
            icon: Icon(
              ref.watch(themeProvider).isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            tooltip: 'Changer le thème',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Rafraîchir',
            onPressed: refreshCounters,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineIndicatorWidget(),
              Expanded(
                child: LayoutTransitioner(
                  layoutType: isDesktop ? 0 : isTablet ? 1 : 2,
                  desktopChild: _buildDesktopLayout(context),
                  tabletChild: _buildTabletLayout(context),
                  mobileChild: _buildMobileLayout(context),
                ),
              ),
            ],
          ),
          // Loader pendant l'initialisation
          if (!_countersLoaded)
            Container(
              color: Colors.black,
              child: Center(
                child: RiveLoader(size: 80),
              ),
            ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: isMobile
            ? SimpleNeumorphicButton(
                key: const ValueKey('fab'),
                onPressed: _navigateToUploadVideo,
                icon: Icons.videocam,
                size: 60,
              )
            : const SizedBox.shrink(key: ValueKey('no_fab')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      extendBody: isMobile,
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: isMobile
            ? _buildBottomNavBar(context)
            : const SizedBox.shrink(key: ValueKey('no_navbar')),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    // Utiliser IndexedStack au lieu de AnimatedSwitcher pour garder l'état des pages
    return IndexedStack(
      index: _currentIndex,
      children: _pages,
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    // Mode Tablette: Feed + Widget Likes/Matches à côté
    return Row(
      children: [
        // Navigation Rail à gauche
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) {
              setState(() {
                _likesCount = 0;
                _likesViewed = true;
              });
              _saveViewedFlags();
            } else if (index == 3) {
              setState(() {
                _matchesPageKey = UniqueKey();
                _matchesCount = 0;
                _matchesViewed = true;
              });
              _saveViewedFlags();
            } else if (index == 4) {
              // Rafraîchir les compteurs du profil
              _refreshProfileCounters();
            }
          },
          backgroundColor: Colors.black.withOpacity(0.5),
          selectedIconTheme: const IconThemeData(color: Colors.pink, size: 32),
          unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.7), size: 28),
          selectedLabelTextStyle: const TextStyle(color: Colors.pink, fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SimpleNeumorphicButton(
              onPressed: _navigateToUploadVideo,
              icon: Icons.videocam,
              size: 56,
            ),
          ),
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.local_fire_department),
              label: Text('Découvrir'),
            ),
            NavigationRailDestination(
              icon: Badge(
                label: Text('$_likesCount'),
                isLabelVisible: _likesCount > 0,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                child: const Icon(Icons.favorite_border),
              ),
              label: const Text('Likes'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.map),
              label: Text('Carte'),
            ),
            NavigationRailDestination(
              icon: Badge(
                label: Text('$_matchesCount'),
                isLabelVisible: _matchesCount > 0,
                backgroundColor: Colors.pink,
                textColor: Colors.white,
                child: const Icon(Icons.favorite),
              ),
              label: const Text('Matchs'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.person),
              label: Text('Profil'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),

        // Feed principal au centre
        Expanded(
          flex: 2,
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),

        // Widget Likes/Matches à droite (seulement sur page Découvrir)
        if (_currentIndex == 0) ...[
          const VerticalDivider(thickness: 1, width: 1),
          SizedBox(
            width: 300,
            child: LikesMatchesPanel(
              onLikesTap: () {
                setState(() {
                  _currentIndex = 1;
                  _likesCount = 0;
                  _likesViewed = true;
                });
                _saveViewedFlags();
              },
              onMatchesTap: () {
                setState(() {
                  _currentIndex = 3;
                  _matchesPageKey = UniqueKey();
                  _matchesCount = 0;
                  _matchesViewed = true;
                });
                _saveViewedFlags();
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Contenu du feed principal en mode desktop
  Widget _buildDesktopFeed() {
    // Afficher toutes les pages normalement (y compris Likes et Matches avec leur layout responsive)
    return IndexedStack(
      index: _currentIndex,
      children: _pages,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    // Mode Desktop: Navigation Rail complètement à gauche + Widget/Feed/Carte
    return Row(
      children: [
        // Navigation Rail complètement à gauche
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) {
              setState(() {
                _likesCount = 0;
                _likesViewed = true;
              });
              _saveViewedFlags();
            } else if (index == 3) {
              setState(() {
                _matchesPageKey = UniqueKey();
                _matchesCount = 0;
                _matchesViewed = true;
              });
              _saveViewedFlags();
            } else if (index == 4) {
              // Rafraîchir les compteurs du profil
              _refreshProfileCounters();
            }
          },
          backgroundColor: Colors.black.withOpacity(0.5),
          selectedIconTheme: const IconThemeData(color: Colors.pink, size: 32),
          unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.7), size: 28),
          selectedLabelTextStyle: const TextStyle(color: Colors.pink, fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SimpleNeumorphicButton(
              onPressed: _navigateToUploadVideo,
              icon: Icons.videocam,
              size: 56,
            ),
          ),
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.local_fire_department),
              label: Text('Découvrir'),
            ),
            NavigationRailDestination(
              icon: Badge(
                label: Text('$_likesCount'),
                isLabelVisible: _likesCount > 0,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                child: const Icon(Icons.favorite_border),
              ),
              label: const Text('Likes'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.map),
              label: Text('Carte'),
            ),
            NavigationRailDestination(
              icon: Badge(
                label: Text('$_matchesCount'),
                isLabelVisible: _matchesCount > 0,
                backgroundColor: Colors.pink,
                textColor: Colors.white,
                child: const Icon(Icons.favorite),
              ),
              label: const Text('Matchs'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.person),
              label: Text('Profil'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),

        // Panneau gauche : Likes/Matches preview (Découvrir) ou liste complète (Likes/Matches)
        if (_currentIndex == 0) ...[
          // Page Découvrir : Widget résumé Likes/Matches
          SizedBox(
            width: 300,
            child: LikesMatchesPanel(
              onLikesTap: () {
                setState(() {
                  _currentIndex = 1;
                  _likesCount = 0;
                  _likesViewed = true;
                });
                _saveViewedFlags();
              },
              onMatchesTap: () {
                setState(() {
                  _currentIndex = 3;
                  _matchesPageKey = UniqueKey();
                  _matchesCount = 0;
                  _matchesViewed = true;
                });
                _saveViewedFlags();
              },
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
        ] else if (_currentIndex == 1) ...[
          // Page Likes : Liste complète des likes dans le panneau gauche
          const SizedBox(
            width: 350,
            child: LikesPage(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
        ] else if (_currentIndex == 3) ...[
          // Page Matches : Liste complète des matches dans le panneau gauche
          SizedBox(
            width: 350,
            child: MatchesPage(key: _matchesPageKey),
          ),
          const VerticalDivider(thickness: 1, width: 1),
        ],

        // Feed principal au centre (limité pour les vidéos)
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Limiter la largeur à 600px max pour les vidéos (format vertical)
                maxWidth: _currentIndex == 0 ? 600 : double.infinity,
              ),
              child: _buildDesktopFeed(),
            ),
          ),
        ),

        // Carte géographique à droite (seulement sur page Découvrir)
        if (_currentIndex == 0) ...[
          const VerticalDivider(thickness: 1, width: 1),
          SizedBox(
            width: 400,
            child: _MapPanelWidget(), // Widget carte sans scaffold
          ),
        ],
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return AnimatedBottomNav(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        // Rafraîchir les compteurs selon la page
        if (index == 1) {
          // Likes page - mettre badge à 0 après avoir vu et marquer comme vu
          setState(() {
            _likesCount = 0;
            _likesViewed = true;
          });
          _saveViewedFlags(); // Persister dans localStorage
        } else if (index == 3) {
          // Matches page - recharger complètement la page et mettre badges à 0
          setState(() {
            _matchesPageKey = UniqueKey(); // Force le rebuild de MatchesPage
            _matchesCount = 0;
            _messagesCount = 0;
            _matchesViewed = true;
            _messagesViewed = true;
          });
          _saveViewedFlags(); // Persister dans localStorage
        }
      },
      likesCount: _likesCount,
      matchesCount: _matchesCount,
      messagesCount: _messagesCount,
    );
  }
}

/// Widget carte géographique pour le panneau desktop (sans Scaffold)
class _MapPanelWidget extends StatefulWidget {
  const _MapPanelWidget();

  @override
  State<_MapPanelWidget> createState() => _MapPanelWidgetState();
}

class _MapPanelWidgetState extends State<_MapPanelWidget> {
  final BackendService _backend = BackendService();
  final MapController _mapController = MapController();

  List<DatingUser> _nearbyUsers = [];
  DatingUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUserDoc = await _backend.getCurrentUser();
      final profileData = (currentUserDoc is Map) ? currentUserDoc : (currentUserDoc.data is Map ? currentUserDoc.data : {});
      final user = DatingUser.fromJson(profileData);

      final radiusKm = user.searchRadius ?? 50.0;

      final response = await _backend.getNearbyUsers(
        latitude: user.latitude,
        longitude: user.longitude,
        radiusKm: radiusKm,
      );

      final documents = response.documents as List;
      final users = documents
          .map((doc) {
            final data = doc is Map ? doc : doc.data;
            return DatingUser.fromJson(data);
          })
          .where((u) => u.id != user.id)
          .toList();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _nearbyUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement carte: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return Container(
        color: Colors.grey[100],
        child: Center(child: RiveLoader(size: 60)),
      );
    }

    return Container(
      color: const Color(0xFF1e3a5f),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(_currentUser!.latitude, _currentUser!.longitude),
          initialZoom: 11.0,
          minZoom: 2.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.dating_app',
          ),
          MarkerLayer(
            markers: [
              // Marqueur utilisateur actuel
              Marker(
                point: LatLng(_currentUser!.latitude, _currentUser!.longitude),
                width: 40,
                height: 40,
                child: const Icon(Icons.person_pin, color: Colors.blue, size: 40),
              ),
              // Marqueurs autres utilisateurs
              ..._nearbyUsers.map((user) {
                return Marker(
                  point: LatLng(user.latitude, user.longitude),
                  width: 30,
                  height: 30,
                  child: const Icon(Icons.location_on, color: Colors.pink, size: 30),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}