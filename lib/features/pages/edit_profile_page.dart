import 'package:flutter/material.dart';
import '../../core/models/dating_user.dart';
import '../../core/services/backend_service.dart';
import 'onboarding_tutorial_page.dart';
import 'theme_settings_page.dart';

class EditProfilePage extends StatefulWidget {
  final DatingUser currentUser;

  const EditProfilePage({super.key, required this.currentUser});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> with SingleTickerProviderStateMixin {
  final BackendService _backend = BackendService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _heightController;
  late TextEditingController _occupationController;
  late TextEditingController _educationController;
  late TextEditingController _weightController;

  late int _age;
  late String _gender;
  late String? _sexualOrientation;
  late String? _maritalStatus;
  late String? _religion;
  late String? _bodyType;
  late List<String> _interests;
  late List<String> _lookingFor;
  late List<String> _sports;
  late List<String> _hobbies;

  bool _isSaving = false;
  late TabController _tabController;

  String _normalizeGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'homme':
        return 'Homme';
      case 'female':
      case 'femme':
        return 'Femme';
      case 'other':
      case 'autre':
        return 'Autre';
      default:
        return 'Autre';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _nameController = TextEditingController(text: widget.currentUser.name);
    _bioController = TextEditingController(text: widget.currentUser.bio);
    _heightController = TextEditingController(text: widget.currentUser.height ?? '');
    _occupationController = TextEditingController(text: widget.currentUser.occupation ?? '');
    _educationController = TextEditingController(text: widget.currentUser.education ?? '');
    _weightController = TextEditingController(text: widget.currentUser.weight?.toString() ?? '');

    _age = widget.currentUser.age;
    _gender = _normalizeGender(widget.currentUser.gender);
    _sexualOrientation = widget.currentUser.sexualOrientation;
    _maritalStatus = widget.currentUser.maritalStatus;
    _religion = widget.currentUser.religion;
    _bodyType = widget.currentUser.bodyType;
    _interests = List.from(widget.currentUser.interests);
    _lookingFor = List.from(widget.currentUser.lookingFor);
    _sports = List.from(widget.currentUser.sports);
    _hobbies = List.from(widget.currentUser.hobbies);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _heightController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      print('💾 Début de la sauvegarde du profil...');

      final data = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'age': _age,
        'gender': _gender,
        'sexualOrientation': _sexualOrientation,
        'height': _heightController.text.trim().isNotEmpty ? _heightController.text.trim() : null,
        'occupation': _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
        'education': _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
        'weight': _weightController.text.trim().isNotEmpty ? int.tryParse(_weightController.text.trim()) : null,
        'interests': _interests,
        'lookingFor': _lookingFor,
        'maritalStatus': _maritalStatus,
        'religion': _religion,
        'bodyType': _bodyType,
        'sports': _sports,
        'hobbies': _hobbies,
      };

      print('📦 Données à sauvegarder: $data');

      await _backend.updateUserProfile(
        userId: widget.currentUser.id,
        data: data,
      );

      setState(() => _isSaving = false);
      print('✅ Profil sauvegardé avec succès');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Erreur sauvegarde profil: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Modifier le profil', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsPage(),
                ),
              );
            },
            tooltip: 'Changer le thème',
          ),
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: _saveProfile,
              tooltip: 'Sauvegarder',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Infos de base'),
            Tab(text: 'Apparence'),
            Tab(text: 'Activités'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildAppearanceTab(),
            _buildActivitiesTab(),
          ],
        ),
      ),
    );
  }

  // Onglet 1: Informations de base
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informations personnelles', Icons.person),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Nom', Icons.person_outline),
            validator: (value) => value?.isEmpty ?? true ? 'Nom requis' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[900],
                  decoration: _inputDecoration('Genre', Icons.wc),
                  items: ['Homme', 'Femme', 'Autre'].map((value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) => setState(() => _gender = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _age.toString(),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Âge', Icons.cake),
                  validator: (value) {
                    final age = int.tryParse(value ?? '');
                    if (age == null || age < 18 || age > 100) return 'Âge invalide';
                    return null;
                  },
                  onChanged: (value) {
                    final age = int.tryParse(value);
                    if (age != null) setState(() => _age = age);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _sexualOrientation,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.grey[900],
            decoration: _inputDecoration('Orientation sexuelle', Icons.favorite),
            items: [
              const DropdownMenuItem(value: null, child: Text('Non spécifié')),
              ...['Hétérosexuel(le)', 'Homosexuel(le)', 'Bisexuel(le)', 'Autre'].map((value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }),
            ],
            onChanged: (value) => setState(() => _sexualOrientation = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _maritalStatus,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.grey[900],
            decoration: _inputDecoration('Situation maritale', Icons.family_restroom),
            items: [
              const DropdownMenuItem(value: null, child: Text('Non spécifié')),
              ...['Célibataire', 'Divorcé(e)', 'Veuf(ve)', 'En couple', 'Compliqué'].map((value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }),
            ],
            onChanged: (value) => setState(() => _maritalStatus = value),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Croyances & Valeurs', Icons.church),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _religion,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.grey[900],
            decoration: _inputDecoration('Religion', Icons.auto_awesome),
            items: [
              const DropdownMenuItem(value: null, child: Text('Non spécifié')),
              ...['Catholique', 'Protestant', 'Musulman', 'Juif', 'Bouddhiste', 'Hindou', 'Athée', 'Autre'].map((value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }),
            ],
            onChanged: (value) => setState(() => _religion = value),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Profession & Éducation', Icons.work),
          const SizedBox(height: 16),
          TextFormField(
            controller: _occupationController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Profession', Icons.business_center),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _educationController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Niveau d\'éducation', Icons.school),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Bio', Icons.description),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            maxLength: 500,
            decoration: _inputDecoration('Parlez de vous...', Icons.edit),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Recherche', Icons.search),
          const SizedBox(height: 16),
          _buildLookingForSection(),
          const SizedBox(height: 24),
          _buildSectionTitle('Personnalisation', Icons.palette),
          const SizedBox(height: 16),
          _buildThemeButton(),
          const SizedBox(height: 24),
          _buildSectionTitle('Tutoriel & Démos', Icons.help_outline),
          const SizedBox(height: 16),
          _buildTutorialButton(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Onglet 2: Apparence
  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Mensuration', Icons.accessibility_new),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Taille (cm)', Icons.height),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final height = int.tryParse(value);
                      if (height == null || height < 100 || height > 250) {
                        return 'Taille invalide';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Poids (kg)', Icons.monitor_weight),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final weight = int.tryParse(value);
                      if (weight == null || weight < 30 || weight > 200) {
                        return 'Poids invalide';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Allure physique', Icons.fitness_center),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Athlétique', 'Mince', 'Moyenne', 'Ronde', 'Musclé(e)'].map((type) {
              final isSelected = _bodyType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) => setState(() => _bodyType = selected ? type : null),
                selectedColor: Colors.pink.withOpacity(0.3),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                backgroundColor: Colors.grey[800],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Onglet 3: Activités
  Widget _buildActivitiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sports pratiqués', Icons.sports_soccer),
          const SizedBox(height: 16),
          _buildMultiSelectChips(
            options: ['Football', 'Basketball', 'Tennis', 'Natation', 'Course', 'Yoga', 'Fitness', 'Cyclisme', 'Danse', 'Arts martiaux'],
            selected: _sports,
            onChanged: (values) => setState(() => _sports = values),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Hobbies & Loisirs', Icons.palette),
          const SizedBox(height: 16),
          _buildMultiSelectChips(
            options: ['Musique', 'Lecture', 'Cuisine', 'Photographie', 'Jardinage', 'Bricolage', 'Jeux vidéo', 'Cinéma', 'Théâtre', 'Voyages'],
            selected: _hobbies,
            onChanged: (values) => setState(() => _hobbies = values),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Centres d\'intérêt', Icons.favorite),
          const SizedBox(height: 16),
          _buildMultiSelectChips(
            options: ['Sport', 'Musique', 'Voyage', 'Cuisine', 'Cinéma', 'Lecture', 'Art', 'Technologie', 'Nature', 'Gaming', 'Mode', 'Photographie', 'Danse', 'Fitness'],
            selected: _interests,
            onChanged: (values) => setState(() => _interests = values),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.pink, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.pink),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.pink),
      ),
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> options,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (bool value) {
            final newSelected = List<String>.from(selected);
            if (value) {
              newSelected.add(option);
            } else {
              newSelected.remove(option);
            }
            onChanged(newSelected);
          },
          selectedColor: Colors.pink.withOpacity(0.3),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
          backgroundColor: Colors.grey[800],
        );
      }).toList(),
    );
  }

  Widget _buildLookingForSection() {
    final options = ['Relation sérieuse', 'Rencontre amicale', 'Aventure', 'Pas sûr(e)'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = _lookingFor.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _lookingFor.add(option);
              } else {
                _lookingFor.remove(option);
              }
            });
          },
          selectedColor: Colors.pink.withOpacity(0.3),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
          backgroundColor: Colors.grey[800],
        );
      }).toList(),
    );
  }

  Widget _buildTutorialButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          TutorialHelper.resetTutorial();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OnboardingTutorialPage(),
            ),
          );
        },
        icon: const Icon(Icons.replay),
        label: const Text('Revoir le tutoriel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ThemeSettingsPage(),
            ),
          );
        },
        icon: const Icon(Icons.palette),
        label: const Text('Changer le thème'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

 
}
