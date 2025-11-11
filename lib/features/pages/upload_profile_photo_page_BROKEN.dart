import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/dating_user.dart';
import '../../core/services/backend_service.dart';

class UploadProfilePhotoPage extends StatefulWidget {
  final DatingUser currentUser;

  const UploadProfilePhotoPage({super.key, required this.currentUser});

  @override
  State<UploadProfilePhotoPage> createState() => _UploadProfilePhotoPageState();
}

class _UploadProfilePhotoPageState extends State<UploadProfilePhotoPage> {
  final BackendService _backend = BackendService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isLoading = true;
  List<String> _photoUrls = [];
  String? _mainPhotoId;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      print('📸 Chargement des photos du profil...');
      // Recharger le profil pour avoir les photos à jour
      final profileDoc = await _backend.getUserProfile(widget.currentUser.id);
      final profileData = profileDoc is Map ? profileDoc : profileDoc.data;
      final photoUrls = List<String>.from(profileData['photoUrls'] ?? []);

      print('✅ Photos chargées: $photoUrls');

      setState(() {
        _photoUrls = photoUrls;
        _mainPhotoId = _photoUrls.isNotEmpty ? _photoUrls[0] : null;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement photos: $e');
      setState(() {
        _photoUrls = List.from(widget.currentUser.photoUrls);
        _mainPhotoId = _photoUrls.isNotEmpty ? _photoUrls[0] : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    print('📸 _pickAndUploadPhoto appelé');
    print('   Plan: ${widget.currentUser.subscriptionPlan}');
    print('   Nombre de photos: ${_photoUrls.length}');
    print('   Photos: $_photoUrls');

    // Vérifier la limite de photos pour les utilisateurs gratuits
    if (widget.currentUser.subscriptionPlan == SubscriptionPlan.free && _photoUrls.length >= 2) {
      print('⚠️ Limite de 2 photos atteinte');
      // Proposer de remplacer une photo existante
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limite atteinte'),
          content: const Text(
            'Vous avez atteint la limite de 2 photos en version gratuite.\n\n'
            'Voulez-vous remplacer une photo existante ou passer à Premium pour en ajouter plus ?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remplacer une photo'),
            ),
          ],
        ),
      );

      if (shouldReplace != true) return;

      // Demander quelle photo remplacer
      final photoToReplace = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir la photo à remplacer'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _photoUrls.length,
              itemBuilder: (context, index) {
                final fileId = _photoUrls[index];
                final photoUrl = _backend.getPhotoUrl(fileId);
                return GestureDetector(
                  onTap: () => Navigator.pop(context, fileId),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.pink, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: fileId == _mainPhotoId
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black54,
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star, color: Colors.pink, size: 30),
                                  SizedBox(height: 4),
                                  Text(
                                    'Principale',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      );

      if (photoToReplace == null) return;

      // Supprimer la photo choisie avant d'uploader la nouvelle
      try {
        await _backend.deleteProfilePhoto(
          userId: widget.currentUser.id,
          fileId: photoToReplace,
        );
        setState(() {
          _photoUrls.remove(photoToReplace);
          if (_mainPhotoId == photoToReplace && _photoUrls.isNotEmpty) {
            _mainPhotoId = _photoUrls[0];
          }
        });
      } catch (e) {
        print('❌ Erreur suppression: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    try {
      print('📸 Début sélection photo');
      // Sélectionner une image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        print('❌ Aucune image sélectionnée');
        return;
      }

      print('✅ Image sélectionnée: ${image.name}');
      setState(() => _isUploading = true);

      // Lire les bytes de l'image
      final bytes = await image.readAsBytes();
      final fileName = image.name;
      print('📦 Fichier lu: $fileName, taille: ${bytes.length} bytes');

      // Uploader la photo
      print('🚀 Début upload vers backend...');
      final uploadResult = await _backend.uploadProfilePhoto(
        userId: widget.currentUser.id,
        fileBytes: bytes,
        fileName: fileName,
      );

      print('✅ Upload réussi, résultat: $uploadResult');

      // Extraire le fileId de l'objet retourné
      final fileId = uploadResult is Map ? uploadResult['\$id'] ?? uploadResult['fileId'] : uploadResult.$id;
      print('📎 FileId extrait: $fileId');

      // Recharger le profil utilisateur pour obtenir la liste mise à jour
      print('🔄 Rechargement du profil pour rafraîchir la liste des photos...');
      final profileDoc = await _backend.getUserProfile(widget.currentUser.id);
      final profileData = profileDoc is Map ? profileDoc : profileDoc.data;
      final updatedPhotoUrls = List<String>.from(profileData['photoUrls'] ?? []);

      print('✅ Photos rechargées depuis le profil: $updatedPhotoUrls');

      setState(() {
        _photoUrls = updatedPhotoUrls;
        // Si c'est la première photo, la définir comme principale
        if (_photoUrls.length == 1) {
          _mainPhotoId = _photoUrls[0];
        } else if (_mainPhotoId == null && _photoUrls.isNotEmpty) {
          _mainPhotoId = _photoUrls[0];
        }
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Photo ajoutée avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'upload: $e';

        // Message plus explicite pour l'erreur de type de fichier
        if (e.toString().contains('storage_file_type_unsupported')) {
          errorMessage = 'Format de fichier non supporté. Veuillez utiliser JPG, PNG, GIF ou WEBP.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto(String fileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Voulez-vous vraiment supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      print('🗑️ Suppression de la photo: $fileId');

      // Supprimer le fichier physique
      await _backend.deleteProfilePhoto(
        userId: widget.currentUser.id,
        fileId: fileId,
      );

      print('✅ Fichier supprimé, mise à jour du profil...');

      // Mettre à jour la liste locale
      _photoUrls.remove(fileId);

      // Si on supprime la photo principale, définir la première photo restante comme principale
      if (_mainPhotoId == fileId && _photoUrls.isNotEmpty) {
        _mainPhotoId = _photoUrls[0];
      } else if (_photoUrls.isEmpty) {
        _mainPhotoId = null;
      }

      // Mettre à jour le profil utilisateur avec la nouvelle liste de photos
      await _backend.updateUserProfile(
        userId: widget.currentUser.id,
        data: {'photoUrls': _photoUrls},
      );

      print('✅ Profil mis à jour avec ${_photoUrls.length} photos');

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Photo supprimée avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur suppression photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _setAsMainPhoto(String fileId) async {
    if (fileId == _mainPhotoId) return;

    setState(() {
      // Réorganiser les photos : mettre la photo sélectionnée en première position
      _photoUrls.remove(fileId);
      _photoUrls.insert(0, fileId);
      _mainPhotoId = fileId;
    });

    // Mettre à jour la base de données avec le nouvel ordre
    try {
      await _backend.updateUserProfile(
        userId: widget.currentUser.id,
        data: {'photoUrls': _photoUrls},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Photo principale mise à jour'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Erreur: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Build UploadProfilePhotoPage');
    print('   _isLoading: $_isLoading');
    print('   _isUploading: $_isUploading');
    print('   _photoUrls: $_photoUrls (${_photoUrls.length} photos)');

    // VERSION SIMPLIFIÉE POUR TESTER
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text('MES PHOTOS - VERSION CORRIGÉE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        color: Colors.red, // FOND ROUGE POUR TESTER
        child: _isLoading
            ? Container(
                color: Colors.blue,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des photos...', style: TextStyle(fontSize: 24, color: Colors.white)),
                    ],
                  ),
                ),
              )
            : _isUploading
                ? Container(
                    color: Colors.orange,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Upload en cours...', style: TextStyle(fontSize: 24, color: Colors.white)),
                        ],
                      ),
                    ),
                  )
                : Column(
                  children: [
                    Container(
                      height: 100,
                      color: Colors.red,
                      child: Center(
                        child: Text(
                          'TEST: ${_photoUrls.length} photos chargées',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.grey[200], // Fond gris clair pour voir la grille
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75, // Plus carré
                            mainAxisExtent: 250, // Hauteur fixe pour forcer la visibilité
                          ),
                          itemCount: _photoUrls.length + 1,
                          itemBuilder: (context, index) {
                print('🔨 Building item $index (total: ${_photoUrls.length + 1})');

                if (index == 0) {
                  print('   → Bouton Ajouter');
                  // Bouton pour ajouter une photo (toujours en premier)
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        print('🎯 Bouton Ajouter cliqué');
                        _pickAndUploadPhoto();
                      },
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.pink, width: 4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 60, color: Colors.pink),
                          const SizedBox(height: 12),
                          const Text(
                            'Ajouter une photo',
                            style: TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_photoUrls.length}/2 photos',
                            style: TextStyle(
                              color: Colors.pink.shade400,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                      ),
                  );
                } else {
                  print('   → Photo existante');
                  // Afficher une photo existante (index - 1 car le bouton est en position 0)
                  final photoIndex = index - 1;
                  print('   → photoIndex: $photoIndex');
                  final fileId = _photoUrls[photoIndex];
                  print('   → fileId: $fileId');
                  final photoUrl = _backend.getPhotoUrl(fileId);
                  print('   → photoUrl: $photoUrl');
                  final isMainPhoto = fileId == _mainPhotoId;
                  print('   → isMainPhoto: $isMainPhoto');

                  return Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isMainPhoto ? Colors.pink : Colors.grey[300]!,
                        width: isMainPhoto ? 4 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onLongPress: () {
                        if (!isMainPhoto) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Photo principale'),
                              content: const Text('Définir cette photo comme photo principale ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _setAsMainPhoto(fileId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Définir'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                            ),
                            border: isMainPhoto
                              ? Border.all(color: Colors.pink, width: 3)
                              : null,
                          ),
                        ),
                        // Badge "Principale" pour la photo principale
                        if (isMainPhoto)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Principale',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Bouton supprimer
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => _deletePhoto(fileId),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        // Indicateur de "long press" pour les photos non principales
                        if (!isMainPhoto)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Appui long',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    ),
                  );
                }
              },
                        ),
                      ),
                    ),
                  ],
                ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: _photoUrls.isEmpty
            ? Colors.amber[100]
            : (widget.currentUser.subscriptionPlan == SubscriptionPlan.free && _photoUrls.length >= 2)
                ? Colors.orange[100]
                : null,
        child: _photoUrls.isEmpty
            ? const Row(
                children: [
                  Icon(Icons.info, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ajoutez au moins une photo pour compléter votre profil',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              )
            : (widget.currentUser.subscriptionPlan == SubscriptionPlan.free && _photoUrls.length >= 2)
                ? Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Limite gratuite : ${_photoUrls.length}/2 photos. Passez à Premium pour plus !',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  )
                : null,
      ),
    );
  }
}
