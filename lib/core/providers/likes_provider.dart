import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backend_service.dart';

/// État des likes avec compteurs
class LikesState {
  final Map<String, bool> userLikes; // videoId -> isLiked par l'utilisateur actuel
  final Map<String, int> likeCounts; // videoId -> nombre total de likes

  LikesState({
    required this.userLikes,
    required this.likeCounts,
  });

  LikesState copyWith({
    Map<String, bool>? userLikes,
    Map<String, int>? likeCounts,
  }) {
    return LikesState(
      userLikes: userLikes ?? this.userLikes,
      likeCounts: likeCounts ?? this.likeCounts,
    );
  }
}

/// Provider pour gérer les likes de vidéos
class LikesNotifier extends StateNotifier<LikesState> {
  final BackendService _backend = BackendService();

  LikesNotifier() : super(LikesState(userLikes: {}, likeCounts: {}));

  /// Vérifier si une vidéo est likée par l'utilisateur actuel
  bool isLiked(String videoId) {
    return state.userLikes[videoId] ?? false;
  }

  /// Obtenir le nombre de likes d'une vidéo
  int getLikeCount(String videoId, int initialCount) {
    return state.likeCounts[videoId] ?? initialCount;
  }

  /// Initialiser le compteur de likes d'une vidéo
  void initializeLikeCount(String videoId, int count) {
    if (!state.likeCounts.containsKey(videoId)) {
      state = state.copyWith(
        likeCounts: {...state.likeCounts, videoId: count},
      );
    }
  }

  /// Toggle le like d'une vidéo
  Future<void> toggleLike(String videoId, String currentUserId, int currentCount) async {
    final isCurrentlyLiked = state.userLikes[videoId] ?? false;
    final newLikeStatus = !isCurrentlyLiked;
    final newCount = newLikeStatus ? currentCount + 1 : currentCount - 1;

    // Mettre à jour l'état local immédiatement pour une meilleure UX
    // Créer de nouvelles maps pour forcer la notification Riverpod
    final updatedUserLikes = Map<String, bool>.from(state.userLikes);
    updatedUserLikes[videoId] = newLikeStatus;

    final updatedLikeCounts = Map<String, int>.from(state.likeCounts);
    updatedLikeCounts[videoId] = newCount;

    state = state.copyWith(
      userLikes: updatedUserLikes,
      likeCounts: updatedLikeCounts,
    );

    try {
      if (newLikeStatus) {
        // Liker la vidéo dans Appwrite
        final result = await _backend.likeVideo(videoId);
        final totalLikes = result['totalLikes'] ?? newCount;

        // Mettre à jour avec le vrai compteur du backend
        final finalUserLikes = Map<String, bool>.from(state.userLikes);
        finalUserLikes[videoId] = true;

        final finalLikeCounts = Map<String, int>.from(state.likeCounts);
        finalLikeCounts[videoId] = totalLikes;

        state = state.copyWith(
          userLikes: finalUserLikes,
          likeCounts: finalLikeCounts,
        );

        print('❤️ Like ajouté pour vidéo $videoId (total: $totalLikes)');
      } else {
        // Unlike la vidéo dans Appwrite
        final result = await _backend.unlikeVideo(videoId);
        final totalLikes = result['totalLikes'] ?? newCount;

        // Mettre à jour avec le vrai compteur du backend
        final finalUserLikes = Map<String, bool>.from(state.userLikes);
        finalUserLikes[videoId] = false;

        final finalLikeCounts = Map<String, int>.from(state.likeCounts);
        finalLikeCounts[videoId] = totalLikes;

        state = state.copyWith(
          userLikes: finalUserLikes,
          likeCounts: finalLikeCounts,
        );

        print('💔 Like retiré pour vidéo $videoId (total: $totalLikes)');
      }
    } catch (e) {
      // En cas d'erreur, revenir à l'état précédent
      state = state.copyWith(
        userLikes: {...state.userLikes, videoId: isCurrentlyLiked},
        likeCounts: {...state.likeCounts, videoId: currentCount},
      );
      print('❌ Erreur lors du like: $e');
      rethrow;
    }
  }

  /// Charger les likes de l'utilisateur depuis Appwrite
  Future<void> loadUserLikes(String userId) async {
    try {
      print('📥 Chargement des likes pour $userId');

      // Récupérer les likes de l'utilisateur depuis le backend
      final response = await _backend.getLikedVideos();
      final likedVideos = response['documents'] as List? ?? [];

      // Construire la map videoId -> true
      final Map<String, bool> userLikesMap = {};
      for (var doc in likedVideos) {
        final videoId = doc is Map ? doc['videoId'] : doc.data['videoId'];
        if (videoId != null) {
          userLikesMap[videoId.toString()] = true;
        }
      }

      print('✅ ${userLikesMap.length} vidéos likées chargées');

      // Mettre à jour l'état
      state = state.copyWith(
        userLikes: {...state.userLikes, ...userLikesMap},
      );
    } catch (e) {
      print('❌ Erreur chargement likes: $e');
    }
  }
}

/// Provider global pour les likes
final likesProvider = StateNotifierProvider<LikesNotifier, LikesState>((ref) {
  return LikesNotifier();
});
