import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/backend_service.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final BackendService _backend = BackendService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _heightController = TextEditingController();
  final _occupationController = TextEditingController();
  final _educationController = TextEditingController();

  String _selectedGender = 'Homme';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _backend.getCurrentUser();
      setState(() {
        _nameController.text = user.name;
      });
    } catch (e) {
      print('Erreur chargement info utilisateur: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _heightController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🚀 Début création du profil...');

      // Récupérer l'utilisateur actuel
      final currentUser = await _backend.getCurrentUser();
      print('📦 CurrentUser reçu: $currentUser');
      print('📦 Type: ${currentUser.runtimeType}');

      final userId = currentUser is Map ? currentUser['id'] : currentUser.$id;
      final userEmail = currentUser is Map ? currentUser['email'] : currentUser.email;
      print('👤 User ID extrait: $userId');
      print('📧 Email extrait: $userEmail');

      if (userId == null || userId.toString().isEmpty) {
        throw Exception('❌ User ID est null ou vide! Le backend ne retourne pas le champ "id". Redémarrez le serveur backend.');
      }

      // Obtenir la position
      Position? position;
      try {
        print('📍 Demande de géolocalisation...');
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition();
          print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');
        }
      } catch (e) {
        print('⚠️ Erreur géolocalisation: $e');
        // Position par défaut (Paris)
        position = Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        print('📍 Position par défaut utilisée: Paris');
      }

      print('📝 Création du document profil...');
      print('  - Name: ${_nameController.text.trim()}');
      print('  - Email: $userEmail');
      print('  - Age: ${_ageController.text.trim()}');
      print('  - Gender: $_selectedGender');
      print('  - Bio: ${_bioController.text.trim()}');
      print('  - Height: ${_heightController.text.trim()}');
      print('  - Occupation: ${_occupationController.text.trim()}');
      print('  - Education: ${_educationController.text.trim()}');

      print('🔄 Appel createUserProfile...');
      // Créer le profil
      final result = await _backend.createUserProfile(
        userId: userId,
        name: _nameController.text.trim(),
        email: userEmail,
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        bio: _bioController.text.trim(),
        latitude: position?.latitude ?? 48.8566,
        longitude: position?.longitude ?? 2.3522,
        height: _heightController.text.trim().isNotEmpty
            ? _heightController.text.trim()
            : null,
        occupation: _occupationController.text.trim().isNotEmpty
            ? _occupationController.text.trim()
            : null,
        education: _educationController.text.trim().isNotEmpty
            ? _educationController.text.trim()
            : null,
      );

      print('📦 Résultat reçu du backend: $result');
      print('✅ Profil créé avec succès!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil créé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      print('❌ ERREUR création profil: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 64,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Créons votre profil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Veuillez remplir ces informations pour compléter votre profil',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Âge
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Âge *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'âge est requis';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 18 || age > 100) {
                          return 'Âge invalide (18-100)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Genre
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Genre *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Homme', child: Text('Homme')),
                        DropdownMenuItem(value: 'Femme', child: Text('Femme')),
                        DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGender = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Parlez-nous de vous...',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La bio est requise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Champs optionnels
                    const Text(
                      'Informations optionnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Taille
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Taille (ex: 175 cm)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Profession
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Profession',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Éducation
                    TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Niveau d\'éducation',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton de création
                    ElevatedButton(
                      onPressed: _createProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Créer mon profil',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
