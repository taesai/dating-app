import 'package:flutter/material.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/models/dating_user.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final AppwriteService _appwriteService = AppwriteService();

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _selectedPeriod = 'week'; // day, week, month, year

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Charger tous les utilisateurs
      final usersResponse = await _appwriteService.getAllUsers();
      final users = (usersResponse.documents as List)
          .map((doc) => DatingUser.fromJson(doc.data))
          .toList();

      // Charger toutes les vidéos
      final videosResponse = await _appwriteService.getVideos(limit: 500);
      final totalVideos = videosResponse.total;

      // Calculer les statistiques
      final now = DateTime.now();
      final stats = {
        'totalUsers': users.length,
        'activeUsers': users.where((u) => u.isActive).length,
        'verifiedUsers': users.where((u) => u.verified).length,
        'premiumUsers': users.where((u) => u.effectivePlan != 'free').length,
        'totalVideos': totalVideos,
        'newUsersToday': users.where((u) {
          return u.createdAt.year == now.year &&
              u.createdAt.month == now.month &&
              u.createdAt.day == now.day;
        }).length,
        'newUsersThisWeek': users.where((u) {
          final weekAgo = now.subtract(const Duration(days: 7));
          return u.createdAt.isAfter(weekAgo);
        }).length,
        'newUsersThisMonth': users.where((u) {
          return u.createdAt.year == now.year && u.createdAt.month == now.month;
        }).length,
        // Statistiques par genre
        'maleUsers': users.where((u) => u.gender == 'Homme').length,
        'femaleUsers': users.where((u) => u.gender == 'Femme').length,
        'otherUsers': users.where((u) => u.gender == 'Autre').length,
        // Statistiques d'âge
        'avgAge': users.isEmpty ? 0 : users.map((u) => u.age).reduce((a, b) => a + b) / users.length,
        'users18_25': users.where((u) => u.age >= 18 && u.age <= 25).length,
        'users26_35': users.where((u) => u.age >= 26 && u.age <= 35).length,
        'users36_45': users.where((u) => u.age >= 36 && u.age <= 45).length,
        'users46_plus': users.where((u) => u.age >= 46).length,
      };

      setState(() {
        _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec période
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistiques',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'day', label: Text('Jour')),
                  ButtonSegment(value: 'week', label: Text('Semaine')),
                  ButtonSegment(value: 'month', label: Text('Mois')),
                  ButtonSegment(value: 'year', label: Text('Année')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> selection) {
                  setState(() => _selectedPeriod = selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPIs principaux
          _buildKPISection(),
          const SizedBox(height: 32),

          // Graphiques
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildNewUsersChart(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGenderDistribution(),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAgeDistribution(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSubscriptionStats(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    return Row(
      children: [
        _buildKPI(
          title: 'Utilisateurs totaux',
          value: _stats['totalUsers'].toString(),
          icon: Icons.people,
          color: Colors.blue,
          trend: '+${_stats['newUsersThisWeek']} cette semaine',
        ),
        const SizedBox(width: 16),
        _buildKPI(
          title: 'Utilisateurs actifs',
          value: _stats['activeUsers'].toString(),
          icon: Icons.trending_up,
          color: Colors.green,
          trend: '${((_stats['activeUsers'] / _stats['totalUsers']) * 100).toStringAsFixed(1)}% du total',
        ),
        const SizedBox(width: 16),
        _buildKPI(
          title: 'Vidéos totales',
          value: _stats['totalVideos'].toString(),
          icon: Icons.video_library,
          color: Colors.purple,
          trend: '${(_stats['totalVideos'] / _stats['totalUsers']).toStringAsFixed(1)} par utilisateur',
        ),
        const SizedBox(width: 16),
        _buildKPI(
          title: 'Utilisateurs Premium',
          value: _stats['premiumUsers'].toString(),
          icon: Icons.star,
          color: Colors.amber,
          trend: '${((_stats['premiumUsers'] / _stats['totalUsers']) * 100).toStringAsFixed(1)}% conversion',
        ),
      ],
    );
  }

  Widget _buildKPI({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Icon(Icons.trending_up, color: Colors.green[400], size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trend,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewUsersChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nouvelles inscriptions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Graphique simplifié (barres)
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('Lun', 12, Colors.blue),
                _buildBar('Mar', 18, Colors.blue),
                _buildBar('Mer', 15, Colors.blue),
                _buildBar('Jeu', 22, Colors.blue),
                _buildBar('Ven', 28, Colors.blue),
                _buildBar('Sam', 35, Colors.blue),
                _buildBar('Dim', 20, Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total cette semaine: ${_stats['newUsersThisWeek']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                '+12% vs semaine dernière',
                style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              height: (value / 35) * 150, // Normaliser à 150px max
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDistribution() {
    final total = _stats['totalUsers'];
    final male = _stats['maleUsers'];
    final female = _stats['femaleUsers'];
    final other = _stats['otherUsers'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition par genre',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Donut chart simplifié
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                children: [
                  // Circle de fond
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 20),
                    ),
                  ),
                  // Segments (simplifié - à remplacer par un vrai chart)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          total.toString(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'utilisateurs',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegendItem('Hommes', male, total, Colors.blue),
          const SizedBox(height: 8),
          _buildLegendItem('Femmes', female, total, Colors.pink),
          const SizedBox(height: 8),
          _buildLegendItem('Autre', other, total, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, int total, Color color) {
    final percentage = ((value / total) * 100).toStringAsFixed(1);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label),
        ),
        Text(
          '$value ($percentage%)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAgeDistribution() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition par âge',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildAgeBar('18-25 ans', _stats['users18_25'], Colors.green),
          const SizedBox(height: 12),
          _buildAgeBar('26-35 ans', _stats['users26_35'], Colors.blue),
          const SizedBox(height: 12),
          _buildAgeBar('36-45 ans', _stats['users36_45'], Colors.orange),
          const SizedBox(height: 12),
          _buildAgeBar('46+ ans', _stats['users46_plus'], Colors.red),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Âge moyen', style: TextStyle(color: Colors.grey[600])),
              Text(
                '${_stats['avgAge'].toStringAsFixed(1)} ans',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgeBar(String label, int value, Color color) {
    final maxValue = _stats['totalUsers'];
    final percentage = ((value / maxValue) * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$value ($percentage%)', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value / maxValue,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSubscriptionStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Abonnements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSubscriptionCard(
            'Gratuit',
            _stats['totalUsers'] - _stats['premiumUsers'],
            Icons.person,
            Colors.grey,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(
            'Premium',
            _stats['premiumUsers'],
            Icons.star,
            Colors.amber,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Taux de conversion',
                      style: TextStyle(color: Colors.green[900]),
                    ),
                    Text(
                      '${((_stats['premiumUsers'] / _stats['totalUsers']) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Objectif: 10%',
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(String plan, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
