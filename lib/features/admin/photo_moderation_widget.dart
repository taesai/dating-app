import 'package:flutter/material.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/photo_model.dart';

class PhotoModerationWidget extends StatefulWidget {
  const PhotoModerationWidget({super.key});

  @override
  State<PhotoModerationWidget> createState() => _PhotoModerationWidgetState();
}

class _PhotoModerationWidgetState extends State<PhotoModerationWidget> {
  final AppwriteService _appwriteService = AppwriteService();
  List<PhotoModel> _photos = [];
  Map<String, DatingUser> _photoUsers = {};
  bool _isLoading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);

    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
      );

      final allPhotos = (response.documents as List)
          .map((doc) => PhotoModel.fromJson(doc.data))
          .toList();

      List<PhotoModel> filteredPhotos;
      switch (_filter) {
        case 'pending':
          filteredPhotos = allPhotos.where((p) => !p.isApproved).toList();
          break;
        case 'approved':
          filteredPhotos = allPhotos.where((p) => p.isApproved).toList();
          break;
        case 'all':
        default:
          filteredPhotos = allPhotos;
      }

      print('📊 ${filteredPhotos.length} photos filtrées');
      for (var photo in filteredPhotos) {
        print('   Photo ${photo.id}: userID = ${photo.userId}, fileId = ${photo.fileId}');
      }

      final uniqueUserIds = filteredPhotos.map((p) => p.userId).toSet();
      print('👥 ${uniqueUserIds.length} utilisateurs uniques: $uniqueUserIds');

      for (var userId in uniqueUserIds) {
        try {
          final userDoc = await _appwriteService.getUserProfile(userId);
          final userData = userDoc is Map ? userDoc : userDoc.data;
          final user = DatingUser.fromJson(userData);
          _photoUsers[userId] = user;
          print('✅ Utilisateur chargé: ${user.name} (${user.id})');
        } catch (e) {
          print('❌ Erreur chargement utilisateur $userId: $e');
        }
      }

      setState(() {
        _photos = filteredPhotos;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApprove(PhotoModel photo) async {
    try {
      print('🟢 ADMIN: Approbation de la photo ${photo.id}...');

      // 1. Marquer la photo comme approuvée
      final result = await _appwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
        documentId: photo.id,
        data: {'isApproved': true},
      );

      print('✅ ADMIN: Photo approuvée avec succès');

      // 2. Ajouter la photo au profil utilisateur
      try {
        final userProfile = await _appwriteService.getUserProfile(photo.userId);
        final userData = userProfile is Map ? userProfile : userProfile.data;
        final currentPhotoUrls = List<String>.from(userData['photoUrls'] ?? []);

        // Ajouter le fileId si pas déjà présent
        if (!currentPhotoUrls.contains(photo.fileId)) {
          currentPhotoUrls.add(photo.fileId);

          await _appwriteService.updateUserProfile(
            userId: photo.userId,
            data: {'photoUrls': currentPhotoUrls},
          );

          print('✅ Photo ajoutée au profil utilisateur');
        }
      } catch (e) {
        print('⚠️ Erreur ajout photo au profil: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo approuvée et ajoutée au profil'), backgroundColor: Colors.green),
        );
        _loadPhotos();
      }
    } catch (e) {
      print('❌ ADMIN: Erreur lors de l approbation de la photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(PhotoModel photo) async {
    try {
      // 1. Retirer la photo du profil utilisateur si elle y était
      try {
        final userProfile = await _appwriteService.getUserProfile(photo.userId);
        final userData = userProfile is Map ? userProfile : userProfile.data;
        final currentPhotoUrls = List<String>.from(userData['photoUrls'] ?? []);

        if (currentPhotoUrls.contains(photo.fileId)) {
          currentPhotoUrls.remove(photo.fileId);

          await _appwriteService.updateUserProfile(
            userId: photo.userId,
            data: {'photoUrls': currentPhotoUrls},
          );

          print('✅ Photo retirée du profil utilisateur');
        }
      } catch (e) {
        print('⚠️ Erreur retrait photo du profil: $e');
      }

      // 2. Supprimer le fichier du storage
      await _appwriteService.storage.deleteFile(
        bucketId: AppwriteService.mediasBucketId,
        fileId: photo.fileId,
      );

      // 3. Supprimer le document photo
      await _appwriteService.databases.deleteDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
        documentId: photo.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo rejetée et supprimée'), backgroundColor: Colors.red),
        );
        _loadPhotos();
      }
    } catch (e) {
      print('❌ Erreur rejet photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'pending', label: Text('En attente'), icon: Icon(Icons.pending, size: 16)),
                    ButtonSegment(value: 'approved', label: Text('Approuvées'), icon: Icon(Icons.check_circle, size: 16)),
                    ButtonSegment(value: 'all', label: Text('Toutes'), icon: Icon(Icons.list, size: 16)),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() => _filter = selected.first);
                    _loadPhotos();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _photos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                          const SizedBox(height: 16),
                          Text(_filter == 'pending' ? 'Aucune photo en attente' : 'Aucune photo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        final photo = _photos[index];
                        final user = _photoUsers[photo.userId];
                        return PhotoCard(
                          photo: photo,
                          photoUrl: _appwriteService.getPhotoUrl(photo.fileId),
                          user: user,
                          onApprove: () => _handleApprove(photo),
                          onReject: () => _handleReject(photo),
                          showActions: _filter == 'pending',
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class PhotoCard extends StatelessWidget {
  final PhotoModel photo;
  final String photoUrl;
  final DatingUser? user;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool showActions;

  const PhotoCard({
    super.key,
    required this.photo,
    required this.photoUrl,
    required this.user,
    required this.onApprove,
    required this.onReject,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
                if (photo.isApproved)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Approuvée', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user?.name ?? 'Utilisateur',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (showActions)
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rejeter', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                Container(width: 1, height: 25, color: Colors.grey[300]),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approuver', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
