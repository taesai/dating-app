import 'package:flutter/material.dart';
import '../../core/models/dating_user.dart';

class PremiumPage extends StatefulWidget {
  final DatingUser currentUser;

  const PremiumPage({super.key, required this.currentUser});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  String _selectedPlan = 'monthly';

  final Map<String, Map<String, dynamic>> _plans = {
    'monthly': {
      'name': 'Mensuel',
      'price': '9.99',
      'period': 'mois',
      'savings': '',
    },
    'quarterly': {
      'name': 'Trimestriel',
      'price': '24.99',
      'period': '3 mois',
      'savings': 'Économisez 17%',
    },
    'yearly': {
      'name': 'Annuel',
      'price': '79.99',
      'period': 'an',
      'savings': 'Économisez 33%',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber,
                      Colors.orange,
                      Colors.deepOrange,
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Passez Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Débloquez toutes les fonctionnalités',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avantages Premium
                  const Text(
                    'Avec Premium, profitez de :',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildFeature(
                    Icons.video_library,
                    'Vidéos de 10 secondes',
                    'Au lieu de 3 secondes pour les utilisateurs gratuits',
                    Colors.amber,
                  ),
                  const SizedBox(height: 16),

                  _buildFeature(
                    Icons.favorite,
                    'Likes illimités',
                    'Likez autant de profils que vous voulez',
                    Colors.pink,
                  ),
                  const SizedBox(height: 16),

                  _buildFeature(
                    Icons.visibility,
                    'Voir qui vous a liké',
                    'Découvrez qui vous a aimé avant de swiper',
                    Colors.purple,
                  ),
                  const SizedBox(height: 16),

                  _buildFeature(
                    Icons.bolt,
                    'Super Likes',
                    '5 super likes par jour pour se démarquer',
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  _buildFeature(
                    Icons.location_searching,
                    'Localisation avancée',
                    'Changez votre position pour rencontrer partout',
                    Colors.green,
                  ),
                  const SizedBox(height: 16),

                  _buildFeature(
                    Icons.verified,
                    'Badge vérifié',
                    'Obtenez le badge vérifié pour plus de confiance',
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  _buildFeature(
                    Icons.ads_click_outlined,
                    'Sans publicité',
                    'Profitez d\'une expérience sans interruption',
                    Colors.grey,
                  ),
                  const SizedBox(height: 16),

                  _buildFeature(
                    Icons.priority_high,
                    'Profil prioritaire',
                    'Soyez montré en premier aux autres utilisateurs',
                    Colors.orange,
                  ),
                  const SizedBox(height: 32),

                  // Sélection du plan
                  const Text(
                    'Choisissez votre abonnement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._plans.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPlanCard(
                        entry.key,
                        entry.value['name'],
                        entry.value['price'],
                        entry.value['period'],
                        entry.value['savings'],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 32),

                  // Bouton de paiement
                  ElevatedButton(
                    onPressed: _handleSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'S\'abonner maintenant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informations légales
                  Text(
                    'En vous abonnant, vous acceptez nos conditions générales. '
                    'L\'abonnement se renouvelle automatiquement. '
                    'Vous pouvez annuler à tout moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Témoignages
                  const Text(
                    'Ce qu\'ils en pensent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTestimonial(
                    'Marie, 28 ans',
                    'Premium m\'a permis de trouver l\'amour en 2 semaines ! '
                    'Le fait de pouvoir envoyer des vidéos plus longues m\'a vraiment aidée.',
                    5,
                  ),
                  const SizedBox(height: 16),

                  _buildTestimonial(
                    'Thomas, 32 ans',
                    'Les super likes et le badge vérifié ont fait toute la différence. '
                    'J\'ai eu 3x plus de matchs qu\'avant !',
                    5,
                  ),
                  const SizedBox(height: 16),

                  _buildTestimonial(
                    'Sophie, 25 ans',
                    'Voir qui m\'a liké m\'a fait gagner un temps fou. '
                    'Je recommande Premium à 100% !',
                    5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String planId, String name, String price, String period, String savings) {
    final isSelected = _selectedPlan == planId;
    final isBestValue = planId == 'yearly';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.1) : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Radio button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.grey[600]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.amber : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (savings.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          savings,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Prix
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            color: isSelected ? Colors.amber : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '€',
                          style: TextStyle(
                            color: isSelected ? Colors.amber : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '/ $period',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Badge "Meilleure valeur"
            if (isBestValue)
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MEILLEURE VALEUR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonial(String name, String review, int stars) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.amber,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        stars,
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscribe() {
    final plan = _plans[_selectedPlan]!;

    // TODO: Intégrer Stripe/PayPal/autre système de paiement
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abonnement Premium'),
        content: Text(
          'Vous avez choisi le plan ${plan['name']} à ${plan['price']}€.\n\n'
          'Cette fonctionnalité nécessite l\'intégration d\'un système de paiement '
          '(Stripe, PayPal, etc.).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simuler l'abonnement réussi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abonnement Premium activé ! (Mode démo)'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Continuer (Démo)'),
          ),
        ],
      ),
    );
  }
}
