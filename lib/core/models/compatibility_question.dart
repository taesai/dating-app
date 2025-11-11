/// Modèle pour les questions de compatibilité
class CompatibilityQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String category;
  final int weight; // Importance de la question (1-5)

  CompatibilityQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.category,
    this.weight = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'category': category,
      'weight': weight,
    };
  }

  factory CompatibilityQuestion.fromJson(Map<String, dynamic> json) {
    return CompatibilityQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      category: json['category'],
      weight: json['weight'] ?? 3,
    );
  }
}

/// Réponse d'un utilisateur à une question
class CompatibilityAnswer {
  final String userId;
  final String questionId;
  final String answer;
  final DateTime answeredAt;

  CompatibilityAnswer({
    required this.userId,
    required this.questionId,
    required this.answer,
    required this.answeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'questionId': questionId,
      'answer': answer,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  factory CompatibilityAnswer.fromJson(Map<String, dynamic> json) {
    return CompatibilityAnswer(
      userId: json['userId'],
      questionId: json['questionId'],
      answer: json['answer'],
      answeredAt: DateTime.parse(json['answeredAt']),
    );
  }
}

/// Score de compatibilité entre deux utilisateurs
class CompatibilityScore {
  final String userId1;
  final String userId2;
  final double score; // 0.0 à 100.0
  final Map<String, int> categoryScores; // Scores par catégorie
  final int matchedAnswers;
  final int totalAnswers;

  CompatibilityScore({
    required this.userId1,
    required this.userId2,
    required this.score,
    required this.categoryScores,
    required this.matchedAnswers,
    required this.totalAnswers,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'score': score,
      'categoryScores': categoryScores,
      'matchedAnswers': matchedAnswers,
      'totalAnswers': totalAnswers,
    };
  }

  factory CompatibilityScore.fromJson(Map<String, dynamic> json) {
    return CompatibilityScore(
      userId1: json['userId1'],
      userId2: json['userId2'],
      score: (json['score'] as num).toDouble(),
      categoryScores: Map<String, int>.from(json['categoryScores'] ?? {}),
      matchedAnswers: json['matchedAnswers'],
      totalAnswers: json['totalAnswers'],
    );
  }
}

/// Questions prédéfinies
class CompatibilityQuestions {
  static final List<CompatibilityQuestion> questions = [
    // Catégorie: Style de vie
    CompatibilityQuestion(
      id: 'lifestyle_1',
      question: 'Comment passez-vous votre week-end idéal ?',
      options: [
        'Sortir et faire la fête',
        'Activités en plein air',
        'Rester à la maison et me détendre',
        'Sortir culturellement (musées, cinéma)',
      ],
      category: 'Style de vie',
      weight: 4,
    ),
    CompatibilityQuestion(
      id: 'lifestyle_2',
      question: 'Êtes-vous plutôt du matin ou du soir ?',
      options: ['Lève-tôt', 'Couche-tard', 'Entre les deux'],
      category: 'Style de vie',
      weight: 2,
    ),
    CompatibilityQuestion(
      id: 'lifestyle_3',
      question: 'À quelle fréquence aimez-vous voyager ?',
      options: [
        'Très souvent (plusieurs fois par an)',
        'Quelques fois par an',
        'Rarement',
        'Jamais'
      ],
      category: 'Style de vie',
      weight: 3,
    ),

    // Catégorie: Valeurs
    CompatibilityQuestion(
      id: 'values_1',
      question: 'Quelle importance a la famille pour vous ?',
      options: [
        'Très importante',
        'Importante',
        'Modérément importante',
        'Pas très importante'
      ],
      category: 'Valeurs',
      weight: 5,
    ),
    CompatibilityQuestion(
      id: 'values_2',
      question: 'Voulez-vous avoir des enfants ?',
      options: [
        'Oui, certainement',
        'Peut-être un jour',
        'Pas sûr(e)',
        'Non, jamais'
      ],
      category: 'Valeurs',
      weight: 5,
    ),
    CompatibilityQuestion(
      id: 'values_3',
      question: 'Quelle importance a la religion dans votre vie ?',
      options: [
        'Très importante',
        'Assez importante',
        'Peu importante',
        'Pas importante'
      ],
      category: 'Valeurs',
      weight: 4,
    ),

    // Catégorie: Personnalité
    CompatibilityQuestion(
      id: 'personality_1',
      question: 'Comment gérez-vous les conflits ?',
      options: [
        'J\'en parle immédiatement',
        'Je prends du temps pour réfléchir',
        'J\'évite les confrontations',
        'Je cherche un compromis'
      ],
      category: 'Personnalité',
      weight: 4,
    ),
    CompatibilityQuestion(
      id: 'personality_2',
      question: 'Êtes-vous plutôt introverti(e) ou extraverti(e) ?',
      options: [
        'Très extraverti(e)',
        'Plutôt extraverti(e)',
        'Plutôt introverti(e)',
        'Très introverti(e)'
      ],
      category: 'Personnalité',
      weight: 3,
    ),
    CompatibilityQuestion(
      id: 'personality_3',
      question: 'Comment prenez-vous vos décisions ?',
      options: [
        'Avec la tête (logique)',
        'Avec le cœur (émotions)',
        'Un mélange des deux'
      ],
      category: 'Personnalité',
      weight: 3,
    ),

    // Catégorie: Relations
    CompatibilityQuestion(
      id: 'relationship_1',
      question: 'Quelle est votre vision d\'une soirée parfaite en couple ?',
      options: [
        'Dîner romantique au restaurant',
        'Soirée cocooning à la maison',
        'Sortie entre amis',
        'Activité sportive ou aventure'
      ],
      category: 'Relations',
      weight: 4,
    ),
    CompatibilityQuestion(
      id: 'relationship_2',
      question: 'À quelle fréquence aimez-vous communiquer avec votre partenaire ?',
      options: [
        'Constamment (plusieurs fois par jour)',
        'Régulièrement (une fois par jour)',
        'Occasionnellement',
        'Quand nécessaire'
      ],
      category: 'Relations',
      weight: 4,
    ),
    CompatibilityQuestion(
      id: 'relationship_3',
      question: 'Quelle importance a l\'espace personnel dans une relation ?',
      options: [
        'Très important, j\'ai besoin d\'indépendance',
        'Important, mais j\'aime passer du temps ensemble',
        'Pas très important, je préfère être toujours ensemble'
      ],
      category: 'Relations',
      weight: 5,
    ),

    // Catégorie: Intérêts
    CompatibilityQuestion(
      id: 'interests_1',
      question: 'Quel type de films préférez-vous ?',
      options: [
        'Action/Aventure',
        'Comédie',
        'Drame/Romance',
        'Science-fiction/Fantastique',
        'Horreur/Thriller'
      ],
      category: 'Intérêts',
      weight: 2,
    ),
    CompatibilityQuestion(
      id: 'interests_2',
      question: 'Quelle est votre attitude envers le sport ?',
      options: [
        'Je suis très sportif(ve)',
        'J\'aime faire du sport occasionnellement',
        'Je préfère regarder le sport',
        'Le sport ne m\'intéresse pas'
      ],
      category: 'Intérêts',
      weight: 3,
    ),
    CompatibilityQuestion(
      id: 'interests_3',
      question: 'Comment aimez-vous passer vos vacances ?',
      options: [
        'Plage et détente',
        'Aventure et découverte',
        'Visite culturelle et musées',
        'Staycation à la maison'
      ],
      category: 'Intérêts',
      weight: 3,
    ),
  ];

  static List<String> get categories {
    return questions.map((q) => q.category).toSet().toList();
  }

  static List<CompatibilityQuestion> getQuestionsByCategory(String category) {
    return questions.where((q) => q.category == category).toList();
  }
}
