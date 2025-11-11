/// Modèle pour les suggestions de brise-glace (icebreakers)
class Icebreaker {
  final String id;
  final String text;
  final String category;
  final List<String> tags;

  Icebreaker({
    required this.id,
    required this.text,
    required this.category,
    this.tags = const [],
  });

  factory Icebreaker.fromJson(Map<String, dynamic> json) {
    return Icebreaker(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      category: json['category'] ?? 'general',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'tags': tags,
    };
  }
}

/// Liste prédéfinie de brise-glaces
class IcebreakerList {
  static final List<Icebreaker> defaultIcebreakers = [
    // Questions amusantes
    Icebreaker(
      id: 'fun_1',
      text: 'Si tu pouvais avoir un super-pouvoir, lequel choisirais-tu ? 🦸',
      category: 'fun',
      tags: ['question', 'imagination'],
    ),
    Icebreaker(
      id: 'fun_2',
      text: 'Quelle est la chose la plus folle que tu aies jamais faite ? 🎢',
      category: 'fun',
      tags: ['aventure', 'expérience'],
    ),
    Icebreaker(
      id: 'fun_3',
      text: 'Si tu pouvais dîner avec n\'importe qui (vivant ou non), qui choisirais-tu ? 🍽️',
      category: 'fun',
      tags: ['imagination', 'personnalité'],
    ),

    // Voyages
    Icebreaker(
      id: 'travel_1',
      text: 'Quel est le plus bel endroit que tu aies visité ? ✈️',
      category: 'travel',
      tags: ['voyage', 'découverte'],
    ),
    Icebreaker(
      id: 'travel_2',
      text: 'Si tu pouvais partir en voyage demain, où irais-tu ? 🗺️',
      category: 'travel',
      tags: ['voyage', 'rêve'],
    ),

    // Loisirs
    Icebreaker(
      id: 'hobby_1',
      text: 'Qu\'est-ce que tu aimes faire pendant ton temps libre ? 🎨',
      category: 'hobby',
      tags: ['passion', 'activité'],
    ),
    Icebreaker(
      id: 'hobby_2',
      text: 'Quel est ton film ou ta série préféré en ce moment ? 🎬',
      category: 'hobby',
      tags: ['divertissement', 'culture'],
    ),
    Icebreaker(
      id: 'hobby_3',
      text: 'Tu préfères la montagne ou la plage ? ⛰️🏖️',
      category: 'hobby',
      tags: ['préférence', 'nature'],
    ),

    // Nourriture
    Icebreaker(
      id: 'food_1',
      text: 'Quel est ton plat préféré ? 🍕',
      category: 'food',
      tags: ['gastronomie', 'goût'],
    ),
    Icebreaker(
      id: 'food_2',
      text: 'Tu es plutôt sucré ou salé ? 🍰🧀',
      category: 'food',
      tags: ['préférence', 'nourriture'],
    ),

    // Profond
    Icebreaker(
      id: 'deep_1',
      text: 'Qu\'est-ce qui te rend vraiment heureux/heureuse ? 😊',
      category: 'deep',
      tags: ['bonheur', 'valeurs'],
    ),
    Icebreaker(
      id: 'deep_2',
      text: 'Quel est ton plus grand rêve dans la vie ? ✨',
      category: 'deep',
      tags: ['ambition', 'objectif'],
    ),

    // Compliments
    Icebreaker(
      id: 'compliment_1',
      text: 'Ton sourire est vraiment magnifique ! Comment s\'est passée ta journée ? 😊',
      category: 'compliment',
      tags: ['positif', 'sympathie'],
    ),
    Icebreaker(
      id: 'compliment_2',
      text: 'J\'adore ton profil ! Qu\'est-ce qui te passionne en ce moment ? 💫',
      category: 'compliment',
      tags: ['positif', 'intérêt'],
    ),
  ];

  static List<Icebreaker> getByCategory(String category) {
    return defaultIcebreakers.where((ib) => ib.category == category).toList();
  }

  static List<String> getAllCategories() {
    return defaultIcebreakers.map((ib) => ib.category).toSet().toList();
  }
}
