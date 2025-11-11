import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../../core/models/compatibility_question.dart';

/// Page du questionnaire de compatibilité
class CompatibilityQuizPage extends StatefulWidget {
  final String userId;

  const CompatibilityQuizPage({super.key, required this.userId});

  @override
  State<CompatibilityQuizPage> createState() => _CompatibilityQuizPageState();
}

class _CompatibilityQuizPageState extends State<CompatibilityQuizPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<String, String> _answers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingAnswers();
  }

  void _loadExistingAnswers() {
    try {
      final stored = html.window.localStorage['compatibility_answers_${widget.userId}'];
      if (stored != null) {
        _answers = Map<String, String>.from(jsonDecode(stored));
      }
    } catch (e) {
      print('Erreur chargement réponses: $e');
    }
    setState(() => _isLoading = false);
  }

  void _saveAnswers() {
    try {
      html.window.localStorage['compatibility_answers_${widget.userId}'] = jsonEncode(_answers);
      html.window.localStorage['compatibility_completed_${widget.userId}'] = 'true';
    } catch (e) {
      print('Erreur sauvegarde réponses: $e');
    }
  }

  void _answerQuestion(String questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });
    _saveAnswers();

    // Passer à la question suivante après un délai
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_currentPage < CompatibilityQuestions.questions.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _completeQuiz();
      }
    });
  }

  void _completeQuiz() {
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Questionnaire complété ! Vos réponses ont été sauvegardées.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final questions = CompatibilityQuestions.questions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions de compatibilité'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          LinearProgressIndicator(
            value: (_currentPage + 1) / questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Question ${_currentPage + 1}/${questions.length}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: questions.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _buildQuestionPage(questions[index], isDark);
              },
            ),
          ),

          // Bouton précédent/suivant
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Précédent'),
                  )
                else
                  const SizedBox(),
                if (_answers.containsKey(questions[_currentPage].id))
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentPage < questions.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeQuiz();
                      }
                    },
                    icon: Icon(_currentPage == questions.length - 1
                        ? Icons.check
                        : Icons.arrow_forward),
                    label: Text(_currentPage == questions.length - 1
                        ? 'Terminer'
                        : 'Suivant'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(CompatibilityQuestion question, bool isDark) {
    final selectedAnswer = _answers[question.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catégorie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              question.category,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Question
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 32),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedAnswer == option;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _answerQuestion(question.id, option),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : (isDark ? Colors.grey[850] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : Center(
                                  child: Text(
                                    String.fromCharCode(65 + index), // A, B, C, D...
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Helper pour calculer le score de compatibilité
class CompatibilityHelper {
  static bool hasCompletedQuiz(String userId) {
    return html.window.localStorage['compatibility_completed_$userId'] == 'true';
  }

  static Map<String, String> getUserAnswers(String userId) {
    try {
      final stored = html.window.localStorage['compatibility_answers_$userId'];
      if (stored != null) {
        return Map<String, String>.from(jsonDecode(stored));
      }
    } catch (e) {
      print('Erreur chargement réponses: $e');
    }
    return {};
  }

  static CompatibilityScore calculateCompatibility(String userId1, String userId2) {
    final answers1 = getUserAnswers(userId1);
    final answers2 = getUserAnswers(userId2);

    int matchedAnswers = 0;
    int totalWeight = 0;
    int earnedWeight = 0;
    Map<String, int> categoryScores = {};

    for (final question in CompatibilityQuestions.questions) {
      final answer1 = answers1[question.id];
      final answer2 = answers2[question.id];

      if (answer1 != null && answer2 != null) {
        totalWeight += question.weight;

        if (answer1 == answer2) {
          matchedAnswers++;
          earnedWeight += question.weight;

          // Incrémenter le score de catégorie
          categoryScores[question.category] = (categoryScores[question.category] ?? 0) + 1;
        }
      }
    }

    final totalAnswers = answers1.length;
    final score = totalWeight > 0 ? (earnedWeight / totalWeight) * 100 : 0.0;

    return CompatibilityScore(
      userId1: userId1,
      userId2: userId2,
      score: score,
      categoryScores: categoryScores,
      matchedAnswers: matchedAnswers,
      totalAnswers: totalAnswers,
    );
  }

  static String getCompatibilityLabel(double score) {
    if (score >= 80) return 'Excellente compatibilité ❤️';
    if (score >= 60) return 'Bonne compatibilité 💕';
    if (score >= 40) return 'Compatibilité moyenne 💛';
    if (score >= 20) return 'Faible compatibilité 💙';
    return 'Très faible compatibilité 💔';
  }

  static Color getCompatibilityColor(double score) {
    if (score >= 80) return Colors.red;
    if (score >= 60) return Colors.pink;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.blue;
    return Colors.grey;
  }
}
