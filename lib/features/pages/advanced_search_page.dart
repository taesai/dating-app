import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../../core/models/search_filters.dart';

/// Page de recherche avancée avec tous les filtres
class AdvancedSearchPage extends StatefulWidget {
  final String userId;
  final SearchFilters? initialFilters;

  const AdvancedSearchPage({
    super.key,
    required this.userId,
    this.initialFilters,
  });

  @override
  State<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends State<AdvancedSearchPage> {
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? _loadSavedFilters() ?? SearchFilters.defaultFilters();
  }

  SearchFilters? _loadSavedFilters() {
    try {
      final stored = html.window.localStorage['search_filters_${widget.userId}'];
      if (stored != null) {
        return SearchFilters.fromJson(jsonDecode(stored));
      }
    } catch (e) {
      print('Erreur chargement filtres: $e');
    }
    return null;
  }

  void _saveFilters() {
    try {
      html.window.localStorage['search_filters_${widget.userId}'] = jsonEncode(_filters.toJson());
    } catch (e) {
      print('Erreur sauvegarde filtres: $e');
    }
  }

  void _applyFilters() {
    _saveFilters();
    Navigator.of(context).pop(_filters);
  }

  void _resetFilters() {
    setState(() {
      _filters = SearchFilters.defaultFilters();
    });
    _saveFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres de recherche'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Compteur de filtres actifs
          if (_filters.activeFiltersCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${_filters.activeFiltersCount} filtre(s) actif(s)',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Section: Informations de base
          _buildSection(
            'Informations de base',
            Icons.person_outline,
            [
              _buildAgeRangeFilter(isDark),
              const SizedBox(height: 16),
              _buildGenderFilter(isDark),
              const SizedBox(height: 16),
              _buildDistanceFilter(isDark),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Apparence
          _buildSection(
            'Apparence',
            Icons.accessibility_new,
            [
              _buildHeightRangeFilter(isDark),
              const SizedBox(height: 16),
              _buildBodyTypeFilter(isDark),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Intérêts & Activités
          _buildSection(
            'Intérêts & Activités',
            Icons.favorite_outline,
            [
              _buildInterestsFilter(isDark),
              const SizedBox(height: 16),
              _buildSportsFilter(isDark),
              const SizedBox(height: 16),
              _buildHobbiesFilter(isDark),
              const SizedBox(height: 16),
              _buildLookingForFilter(isDark),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Valeurs & Mode de vie
          _buildSection(
            'Valeurs & Mode de vie',
            Icons.church,
            [
              _buildReligionFilter(isDark),
              const SizedBox(height: 16),
              _buildMaritalStatusFilter(isDark),
              const SizedBox(height: 16),
              _buildChildrenPreferenceFilter(isDark),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Filtres avancés
          _buildSection(
            'Filtres avancés',
            Icons.tune,
            [
              _buildBooleanFilter(
                'Utilisateurs actifs uniquement',
                'Connectés dans les 7 derniers jours',
                _filters.isActive,
                (value) => setState(() => _filters = _filters.copyWith(isActive: value)),
                isDark,
              ),
              const SizedBox(height: 12),
              _buildBooleanFilter(
                'Avec photos uniquement',
                'Profils ayant au moins une photo',
                _filters.hasPhotos,
                (value) => setState(() => _filters = _filters.copyWith(hasPhotos: value)),
                isDark,
              ),
              const SizedBox(height: 12),
              _buildBooleanFilter(
                'Photos vérifiées',
                'Profils avec badge de vérification photo',
                _filters.hasVerifiedPhotos,
                (value) => setState(() => _filters = _filters.copyWith(hasVerifiedPhotos: value)),
                isDark,
              ),
              const SizedBox(height: 12),
              _buildBooleanFilter(
                'Membres Premium uniquement',
                'Afficher seulement les comptes premium',
                _filters.isPremium,
                (value) => setState(() => _filters = _filters.copyWith(isPremium: value)),
                isDark,
              ),
              const SizedBox(height: 16),
              _buildCompatibilityScoreFilter(isDark),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Appliquer les filtres',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildAgeRangeFilter(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Âge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(
              '${_filters.minAge ?? 18} - ${_filters.maxAge ?? 99} ans',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        RangeSlider(
          min: 18,
          max: 99,
          divisions: 81,
          values: RangeValues(
            (_filters.minAge ?? 18).toDouble(),
            (_filters.maxAge ?? 99).toDouble(),
          ),
          onChanged: (values) {
            setState(() {
              _filters = _filters.copyWith(
                minAge: values.start.toInt(),
                maxAge: values.end.toInt(),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildDistanceFilter(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Distance maximale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(
              '${(_filters.maxDistance ?? 50).toInt()} km',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          min: 1,
          max: 200,
          divisions: 199,
          value: (_filters.maxDistance ?? 50),
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(maxDistance: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildHeightRangeFilter(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Taille', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(
              _filters.minHeight != null || _filters.maxHeight != null
                  ? '${_filters.minHeight ?? 140} - ${_filters.maxHeight ?? 210} cm'
                  : 'Toutes les tailles',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        RangeSlider(
          min: 140,
          max: 210,
          divisions: 70,
          values: RangeValues(
            (_filters.minHeight ?? 140).toDouble(),
            (_filters.maxHeight ?? 210).toDouble(),
          ),
          onChanged: (values) {
            setState(() {
              _filters = _filters.copyWith(
                minHeight: values.start.toInt(),
                maxHeight: values.end.toInt(),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildGenderFilter(bool isDark) {
    return _buildChipFilter(
      'Genre',
      ['Homme', 'Femme', 'Autre'],
      _filters.genders,
      (selected) => setState(() => _filters = _filters.copyWith(genders: selected)),
      isDark,
    );
  }

  Widget _buildBodyTypeFilter(bool isDark) {
    return _buildChipFilter(
      'Allure physique',
      FilterOptions.bodyTypes,
      _filters.bodyTypes,
      (selected) => setState(() => _filters = _filters.copyWith(bodyTypes: selected)),
      isDark,
    );
  }

  Widget _buildInterestsFilter(bool isDark) {
    return _buildChipFilter(
      'Centres d\'intérêt',
      ['Sport', 'Musique', 'Voyage', 'Cuisine', 'Cinéma', 'Lecture', 'Art', 'Technologie', 'Nature', 'Gaming'],
      _filters.interests,
      (selected) => setState(() => _filters = _filters.copyWith(interests: selected)),
      isDark,
    );
  }

  Widget _buildSportsFilter(bool isDark) {
    return _buildChipFilter(
      'Sports',
      ['Football', 'Basketball', 'Tennis', 'Natation', 'Course', 'Yoga', 'Fitness', 'Cyclisme'],
      _filters.sports,
      (selected) => setState(() => _filters = _filters.copyWith(sports: selected)),
      isDark,
    );
  }

  Widget _buildHobbiesFilter(bool isDark) {
    return _buildChipFilter(
      'Hobbies',
      ['Musique', 'Lecture', 'Cuisine', 'Photographie', 'Jardinage', 'Jeux vidéo', 'Cinéma', 'Voyages'],
      _filters.hobbies,
      (selected) => setState(() => _filters = _filters.copyWith(hobbies: selected)),
      isDark,
    );
  }

  Widget _buildLookingForFilter(bool isDark) {
    return _buildChipFilter(
      'Recherche',
      FilterOptions.lookingForOptions,
      _filters.lookingFor,
      (selected) => setState(() => _filters = _filters.copyWith(lookingFor: selected)),
      isDark,
    );
  }

  Widget _buildReligionFilter(bool isDark) {
    return _buildChipFilter(
      'Religion',
      FilterOptions.religions,
      _filters.religions,
      (selected) => setState(() => _filters = _filters.copyWith(religions: selected)),
      isDark,
    );
  }

  Widget _buildMaritalStatusFilter(bool isDark) {
    return _buildChipFilter(
      'Situation maritale',
      FilterOptions.maritalStatuses,
      _filters.maritalStatuses,
      (selected) => setState(() => _filters = _filters.copyWith(maritalStatuses: selected)),
      isDark,
    );
  }

  Widget _buildChildrenPreferenceFilter(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Désir d\'enfants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FilterOptions.childrenPreferences.map((pref) {
            final isSelected = _filters.childrenPreference == pref;
            return ChoiceChip(
              label: Text(FilterOptions.getChildrenPreferenceLabel(pref)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    childrenPreference: selected ? pref : 'any',
                  );
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
              labelStyle: TextStyle(color: isSelected ? Theme.of(context).primaryColor : null),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompatibilityScoreFilter(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Score de compatibilité minimum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(
              _filters.minCompatibilityScore != null ? '${_filters.minCompatibilityScore}%' : 'Aucun',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          min: 0,
          max: 100,
          divisions: 20,
          value: (_filters.minCompatibilityScore ?? 0).toDouble(),
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(
                minCompatibilityScore: value.toInt(),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildChipFilter(
    String label,
    List<String> options,
    List<String> selected,
    Function(List<String>) onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                final newSelected = List<String>.from(selected);
                if (value) {
                  newSelected.add(option);
                } else {
                  newSelected.remove(option);
                }
                onChanged(newSelected);
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(color: isSelected ? Theme.of(context).primaryColor : null),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBooleanFilter(
    String label,
    String description,
    bool? value,
    Function(bool?) onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value ?? false,
            tristate: true,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
