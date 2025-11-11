import 'package:flutter/material.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/models/dating_user.dart';
import 'content_moderation_page.dart';
import 'statistics_page.dart';
import 'profile_approval_widget.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AppwriteService _appwriteService = AppwriteService();

  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _UsersManagementPage(),
    ProfileApprovalWidget(),
    ContentModerationPage(),
    StatisticsPage(),
    _SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Administration', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Notifications
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            backgroundColor: Colors.grey[900],
            selectedIconTheme: const IconThemeData(color: Colors.deepPurple),
            selectedLabelTextStyle: const TextStyle(color: Colors.deepPurple),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Utilisateurs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_add),
                label: Text('Approbation profils'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.flag),
                label: Text('Modération'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('Statistiques'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Paramètres'),
              ),
            ],
          ),

          // Main content
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// Page de gestion des utilisateurs
class _UsersManagementPage extends StatefulWidget {
  const _UsersManagementPage();

  @override
  State<_UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<_UsersManagementPage> {
  final AppwriteService _appwriteService = AppwriteService();
  List<DatingUser> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _planFilter; // null = tous, 'free', 'silver', 'gold'

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _appwriteService.getAllUsers();
      final users = (response.documents as List)
          .map((doc) => DatingUser.fromJson(doc.data))
          .toList();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  List<DatingUser> get _filteredUsers {
    var filtered = _users;
    
    // Filtre par plan d'abonnement
    if (_planFilter != null) {
      filtered = filtered.where((u) => u.effectivePlan == _planFilter).toList();
    }
    
    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header avec stats et recherche
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatCard(
                    'Total utilisateurs',
                    _users.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Actifs',
                    _users.where((u) => u.isActive).length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Vérifiés',
                    _users.where((u) => u.verified).length.toString(),
                    Icons.verified,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(
                    'FREE',
                    _users.where((u) => u.effectivePlan == 'free').length.toString(),
                    Icons.person,
                    Colors.blue,
                    onTap: () => setState(() => _planFilter = _planFilter == 'free' ? null : 'free'),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'SILVER',
                    _users.where((u) => u.effectivePlan == 'silver').length.toString(),
                    Icons.star,
                    Colors.purple,
                    onTap: () => setState(() => _planFilter = _planFilter == 'silver' ? null : 'silver'),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'GOLD',
                    _users.where((u) => u.effectivePlan == 'gold').length.toString(),
                    Icons.workspace_premium,
                    Colors.amber,
                    onTap: () => setState(() => _planFilter = _planFilter == 'gold' ? null : 'gold'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ],
          ),
        ),

        // Liste des utilisateurs
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrlsFull.isNotEmpty
                        ? NetworkImage(user.photoUrlsFull.first)
                        : null,
                    child: user.photoUrlsFull.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(user.name),
                      if (user.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                      ],
                      if (user.effectivePlan != 'free') ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user.email} • ${user.age} ans'),
                      Text(
                        '${user.videoIds.length} vidéos • ${user.photoUrls.length} photos',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18),
                            SizedBox(width: 8),
                            Text('Voir le profil'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'change_plan',
                        child: Row(
                          children: [
                            Icon(Icons.workspace_premium, size: 18, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('Changer le plan'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'verify',
                        child: Row(
                          children: [
                            Icon(Icons.verified, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Vérifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'ban',
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Bannir'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleUserAction(value.toString(), user),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final isActive = title == 'FREE' && _planFilter == 'free' ||
                     title == 'SILVER' && _planFilter == 'silver' ||
                     title == 'GOLD' && _planFilter == 'gold';

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: color, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: isActive ? color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                blurRadius: isActive ? 15 : 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isActive ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isActive ? color : null,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: isActive ? color : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUserAction(String action, DatingUser user) {
    switch (action) {
      case 'view':
        // TODO: Ouvrir le profil détaillé
        break;
      case 'change_plan':
        _showChangePlanDialog(user);
        break;
      case 'verify':
        // TODO: Vérifier l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} vérifié')),
        );
        break;
      case 'ban':
        // TODO: Bannir l'utilisateur
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bannir l\'utilisateur ?'),
            content: Text('Êtes-vous sûr de vouloir bannir ${user.name} ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Action de bannissement
                },
                child: const Text('Bannir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        break;
    }
  }

  Future<void> _showChangePlanDialog(DatingUser user) async {
    final plans = ['free', 'silver', 'gold'];
    final planColors = {
      'free': Colors.blue,
      'silver': Colors.purple,
      'gold': Colors.amber,
    };
    final planIcons = {
      'free': Icons.person,
      'silver': Icons.star,
      'gold': Icons.workspace_premium,
    };

    String? selectedPlan = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le plan de ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Plan actuel: ${user.effectivePlan.toUpperCase()}'),
            const SizedBox(height: 16),
            ...plans.map((plan) {
              final isCurrentPlan = plan == user.effectivePlan;
              return Card(
                color: isCurrentPlan ? planColors[plan]!.withOpacity(0.1) : null,
                child: ListTile(
                  leading: Icon(planIcons[plan], color: planColors[plan]),
                  title: Text(
                    plan.toUpperCase(),
                    style: TextStyle(
                      fontWeight: isCurrentPlan ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentPlan ? planColors[plan] : null,
                    ),
                  ),
                  trailing: isCurrentPlan ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => Navigator.pop(context, plan),
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedPlan != null && selectedPlan != user.effectivePlan) {
      try {
        await _appwriteService.updateUserProfile(
          userId: user.id,
          data: {'subscriptionPlan': selectedPlan},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plan de ${user.name} changé vers ${selectedPlan.toUpperCase()}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

}


// Page de paramètres
class _SettingsPage extends StatefulWidget {
  const _SettingsPage();

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  final AppwriteService _appwriteService = AppwriteService();
  bool _isMigrating = false;

  Future<void> _migrateProfileApproval() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migration des profils'),
        content: const Text('Mettre isProfileApproved=false pour tous les profils. Continuer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Migrer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isMigrating = true);

    try {
      final response = await _appwriteService.getAllUsers();
      int updated = 0;

      for (var userDoc in response.documents) {
        await _appwriteService.databases.updateDocument(
          databaseId: AppwriteService.databaseId,
          collectionId: AppwriteService.usersCollectionId,
          documentId: userDoc.$id,
          data: {'isProfileApproved': false},
        );
        updated++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$updated profils mis à jour'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isMigrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Paramètres', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.sync, color: Colors.orange),
                      title: Text('Migration isProfileApproved'),
                      subtitle: Text('Mettre false pour tous les profils'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isMigrating ? null : _migrateProfileApproval,
                      icon: _isMigrating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
                      label: Text(_isMigrating ? 'Migration...' : 'Lancer'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
