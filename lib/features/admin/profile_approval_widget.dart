import 'package:flutter/material.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/models/dating_user.dart';

class ProfileApprovalWidget extends StatefulWidget {
  const ProfileApprovalWidget({super.key});

  @override
  State<ProfileApprovalWidget> createState() => _ProfileApprovalWidgetState();
}

class _ProfileApprovalWidgetState extends State<ProfileApprovalWidget> {
  final AppwriteService _appwriteService = AppwriteService();
  List<DatingUser> _users = [];
  bool _isLoading = true;
  String _filter = 'pending'; // pending, approved, all

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final response = await _appwriteService.getAllUsers();
      final allUsers = (response.documents as List)
          .map((doc) => DatingUser.fromJson(doc.data))
          .toList();

      // Filtrer selon le statut
      List<DatingUser> filteredUsers;
      switch (_filter) {
        case 'pending':
          filteredUsers = allUsers.where((u) => !u.isProfileApproved).toList();
          break;
        case 'approved':
          filteredUsers = allUsers.where((u) => u.isProfileApproved).toList();
          break;
        case 'all':
        default:
          filteredUsers = allUsers;
      }

      setState(() {
        _users = filteredUsers;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApprove(DatingUser user) async {
    try {
      print('🟢 ADMIN: Approbation du profil de ${user.name} (${user.id})...');

      final result = await _appwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.usersCollectionId,
        documentId: user.id,
        data: {'isProfileApproved': true},
      );

      print('✅ ADMIN: Profil approuvé avec succès');
      print('📋 Résultat: ${result.data}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil de ${user.name} approuvé'), backgroundColor: Colors.green),
        );
        _loadUsers();
      }
    } catch (e) {
      print('❌ ADMIN: Erreur lors de l approbation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(DatingUser user) async {
    // Confirmer avant de supprimer
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le profil'),
        content: Text('Voulez-vous vraiment rejeter le profil de ${user.name}? Cette action supprimera le compte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Supprimer le compte utilisateur
      await _appwriteService.databases.deleteDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.usersCollectionId,
        documentId: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil de ${user.name} rejeté et supprimé'), backgroundColor: Colors.red),
        );
        _loadUsers();
      }
    } catch (e) {
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
                    ButtonSegment(value: 'approved', label: Text('Approuvés'), icon: Icon(Icons.check_circle, size: 16)),
                    ButtonSegment(value: 'all', label: Text('Tous'), icon: Icon(Icons.list, size: 16)),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() => _filter = selected.first);
                    _loadUsers();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                          const SizedBox(height: 16),
                          Text(_filter == 'pending' ? 'Aucun profil en attente' : 'Aucun profil', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ProfileCard(
                          user: user,
                          onApprove: () => _handleApprove(user),
                          onReject: () => _handleReject(user),
                          showActions: _filter == 'pending',
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class ProfileCard extends StatelessWidget {
  final DatingUser user;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool showActions;

  const ProfileCard({
    super.key,
    required this.user,
    required this.onApprove,
    required this.onReject,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    print('🖼️ ADMIN: Chargement photo pour ${user.name} - photoUrlsFull.length: ${user.photoUrlsFull.length}');
    if (user.photoUrlsFull.isNotEmpty) {
      print('   Photo URL: ${user.photoUrlsFull.first}');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo de profil
            CircleAvatar(
              radius: 40,
              backgroundImage: user.photoUrlsFull.isNotEmpty ? NetworkImage(user.photoUrlsFull.first) : null,
              child: user.photoUrlsFull.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(width: 16),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (user.isProfileApproved) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Approuvé', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (user.bio.isNotEmpty)
                    Text(
                      user.bio,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.photo, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${user.photoUrls.length} photos', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${user.videoIds.length} vidéos', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            // Boutons d'action
            if (showActions)
              Column(
                children: [
                  IconButton(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Approuver',
                  ),
                  IconButton(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Rejeter',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
