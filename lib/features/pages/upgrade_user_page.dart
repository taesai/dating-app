import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../../core/services/backend_service.dart';
import '../../core/services/appwrite_service.dart';

/// Page pour upgrader un utilisateur en premium
class UpgradeUserPage extends StatefulWidget {
  const UpgradeUserPage({super.key});

  @override
  State<UpgradeUserPage> createState() => _UpgradeUserPageState();
}

class _UpgradeUserPageState extends State<UpgradeUserPage> {
  final BackendService _backend = BackendService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _status = '';
  String _selectedPlan = 'gold';
  int _durationDays = 30;

  Future<void> _upgradeToPremium() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _status = '❌ Veuillez entrer un email');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Recherche de l\'utilisateur...';
    });

    try {
      // 1. Trouver l'utilisateur par email
      final appwrite = AppwriteService();
      final usersResponse = await appwrite.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.usersCollectionId,
        queries: [
          Query.equal('email', _emailController.text.trim()),
        ],
      );

      if (usersResponse.documents.isEmpty) {
        setState(() {
          _isLoading = false;
          _status = '❌ Utilisateur non trouvé avec cet email';
        });
        return;
      }

      final userDoc = usersResponse.documents.first;
      final userId = userDoc.$id;
      final userName = userDoc.data['name'];

      setState(() => _status = 'Upgrade de $userName...');

      // 2. Calculer les dates
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: _durationDays));

      // 3. Mettre à jour le profil
      await _backend.updateUserProfile(
        userId: userId,
        data: {
          'subscriptionPlan': _selectedPlan,
          'subscriptionStartedAt': now.toIso8601String(),
          'subscriptionExpiresAt': expiresAt.toIso8601String(),
        },
      );

      setState(() {
        _isLoading = false;
        _status = '✅ $userName a été upgradé en ${_selectedPlan.toUpperCase()} pour $_durationDays jours!\n\nExpire le: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}';
      });

      print('✅ Utilisateur $userName upgradé en ${_selectedPlan.toUpperCase()}');
      print('📅 Expire le: $expiresAt');

    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Erreur: $e';
      });
      print('❌ Erreur upgrade: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Utilisateur'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 80,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Upgrader un utilisateur',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email de l\'utilisateur',
                        hintText: 'exemple@mail.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Plan d\'abonnement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'silver',
                          label: Text('SILVER'),
                          icon: Icon(Icons.star, color: Colors.grey),
                        ),
                        ButtonSegment(
                          value: 'gold',
                          label: Text('GOLD'),
                          icon: Icon(Icons.star, color: Colors.amber),
                        ),
                      ],
                      selected: {_selectedPlan},
                      onSelectionChanged: (Set<String> selected) {
                        setState(() => _selectedPlan = selected.first);
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Durée (jours)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [7, 14, 30, 90, 365].map((days) {
                        final isSelected = _durationDays == days;
                        return ChoiceChip(
                          label: Text('$days jours'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _durationDays = days);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        onPressed: _upgradeToPremium,
                        icon: const Icon(Icons.upgrade),
                        label: Text(
                          'Upgrader en ${_selectedPlan.toUpperCase()}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _selectedPlan == 'gold'
                              ? Colors.amber
                              : Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (_status.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _status.startsWith('✅')
                              ? Colors.green[50]
                              : _status.startsWith('❌')
                                  ? Colors.red[50]
                                  : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _status.startsWith('✅')
                                ? Colors.green
                                : _status.startsWith('❌')
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _status.startsWith('✅')
                                ? Colors.green[900]
                                : _status.startsWith('❌')
                                    ? Colors.red[900]
                                    : Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Avantages des plans :',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPlanFeature('SILVER', '100 swipes/jour, 3 vidéos, filtres avancés'),
                    _buildPlanFeature('GOLD', 'Swipes illimités, 10 vidéos, sans pub'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanFeature(String plan, String features) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: plan == 'GOLD' ? Colors.amber : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$plan: $features',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
