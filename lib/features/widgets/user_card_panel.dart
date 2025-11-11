import 'package:flutter/material.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';

class UserCardPanel extends StatelessWidget {
  final DatingUser? currentUser;
  final VideoModel? currentVideo;

  const UserCardPanel({
    super.key,
    this.currentUser,
    this.currentVideo,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: const Center(
          child: Text('Aucune carte sélectionnée', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final photoUrl = currentUser!.photoUrlsFull.isNotEmpty
        ? currentUser!.photoUrlsFull.first
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo de profil
            if (photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  photoUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 80, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),

            // Nom et âge
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${currentUser!.name}, ${currentUser!.age}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (currentUser!.verified)
                  const Icon(Icons.verified, color: Colors.blue, size: 28),
              ],
            ),
            const SizedBox(height: 8),

            // Bio
            if (currentUser!.bio.isNotEmpty) ...[
              Text(
                currentUser!.bio,
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
            ],

            // Informations détaillées
            _buildInfoSection(
              icon: Icons.work,
              title: 'Profession',
              value: currentUser!.occupation,
            ),
            _buildInfoSection(
              icon: Icons.school,
              title: 'Éducation',
              value: currentUser!.education,
            ),
            _buildInfoSection(
              icon: Icons.height,
              title: 'Taille',
              value: currentUser!.height != null ? '${currentUser!.height} cm' : null,
            ),
            _buildInfoSection(
              icon: Icons.fitness_center,
              title: 'Morphologie',
              value: currentUser!.bodyType,
            ),
            _buildInfoSection(
              icon: Icons.monitor_weight,
              title: 'Poids',
              value: currentUser!.weight != null ? '${currentUser!.weight} kg' : null,
            ),
            _buildInfoSection(
              icon: Icons.favorite_border,
              title: 'Situation',
              value: currentUser!.maritalStatus,
            ),
            _buildInfoSection(
              icon: Icons.explore,
              title: 'Orientation',
              value: currentUser!.sexualOrientation,
            ),

            // Intérêts
            if (currentUser!.interests.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                'Intérêts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentUser!.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Colors.pink[50],
                    labelStyle: const TextStyle(color: Colors.pink),
                  );
                }).toList(),
              ),
            ],

            // Sports
            if (currentUser!.sports.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                'Sports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentUser!.sports.map((sport) {
                  return Chip(
                    label: Text(sport),
                    backgroundColor: Colors.blue[50],
                    labelStyle: const TextStyle(color: Colors.blue),
                  );
                }).toList(),
              ),
            ],

            // Hobbies
            if (currentUser!.hobbies.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                'Loisirs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentUser!.hobbies.map((hobby) {
                  return Chip(
                    label: Text(hobby),
                    backgroundColor: Colors.purple[50],
                    labelStyle: const TextStyle(color: Colors.purple),
                  );
                }).toList(),
              ),
            ],

            // Recherche
            if (currentUser!.lookingFor.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                'Recherche',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...currentUser!.lookingFor.map((looking) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(looking)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    String? value,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
