import 'package:flutter/material.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/models/dating_user.dart';

class SearchPreferencesPage extends StatefulWidget {
  const SearchPreferencesPage({super.key});

  @override
  State<SearchPreferencesPage> createState() => _SearchPreferencesPageState();
}

class _SearchPreferencesPageState extends State<SearchPreferencesPage> {
  final AppwriteService _backend = AppwriteService();

  bool _isLoading = true;
  bool _isSaving = false;

  DatingUser? _currentUser;

  // Préférences de genre
  final Set<String> _selectedGenders = {};

  // Préférences d'âge
  RangeValues _ageRange = const RangeValues(18, 80);

  // Préférences géographiques
  final Set<String> _selectedContinents = {};
  final Set<String> _selectedCountries = {};
  final Set<String> _selectedCities = {};

  // Options disponibles
  final List<String> _genderOptions = ['homme', 'femme', 'autre', 'tous'];
  final List<String> _continentOptions = [
    'Afrique',
    'Amérique du Nord',
    'Amérique du Sud',
    'Asie',
    'Europe',
    'Océanie',
  ];

  final Map<String, List<String>> _countriesByContinent = {
    'Afrique': ['Algérie', 'Bénin', 'Burkina Faso', 'Cameroun', 'Congo', 'Côte d\'Ivoire', 'Égypte', 'Éthiopie', 'Ghana', 'Kenya', 'Madagascar', 'Mali', 'Maroc', 'Niger', 'Nigeria', 'Sénégal', 'Afrique du Sud', 'Tanzanie', 'Tunisie', 'Ouganda'],
    'Amérique du Nord': ['Canada', 'États-Unis', 'Mexique'],
    'Amérique du Sud': ['Argentine', 'Brésil', 'Chili', 'Colombie', 'Pérou', 'Venezuela'],
    'Asie': ['Chine', 'Inde', 'Indonésie', 'Japon', 'Corée du Sud', 'Malaisie', 'Pakistan', 'Philippines', 'Thaïlande', 'Vietnam'],
    'Europe': ['Allemagne', 'Belgique', 'Espagne', 'France', 'Italie', 'Pays-Bas', 'Pologne', 'Portugal', 'Royaume-Uni', 'Suisse'],
    'Océanie': ['Australie', 'Nouvelle-Zélande'],
  };

  final Map<String, List<String>> _citiesByCountry = {
    // Afrique
    'Algérie': ['Alger', 'Oran', 'Constantine', 'Annaba'],
    'Bénin': ['Cotonou', 'Porto-Novo', 'Parakou', 'Abomey'],
    'Cameroun': ['Douala', 'Yaoundé', 'Garoua', 'Bafoussam'],
    'Côte d\'Ivoire': ['Abidjan', 'Bouaké', 'Yamoussoukro', 'San-Pédro'],
    'Égypte': ['Le Caire', 'Alexandrie', 'Gizeh', 'Louxor'],
    'Maroc': ['Casablanca', 'Rabat', 'Marrakech', 'Fès', 'Tanger'],
    'Sénégal': ['Dakar', 'Thiès', 'Saint-Louis', 'Ziguinchor'],
    'Afrique du Sud': ['Le Cap', 'Johannesburg', 'Durban', 'Pretoria'],
    'Tunisie': ['Tunis', 'Sfax', 'Sousse', 'Kairouan'],

    // Amérique du Nord
    'Canada': ['Toronto', 'Montréal', 'Vancouver', 'Calgary', 'Ottawa', 'Edmonton'],
    'États-Unis': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Miami', 'Seattle', 'Boston', 'San Francisco', 'Las Vegas'],
    'Mexique': ['Mexico', 'Guadalajara', 'Monterrey', 'Cancún', 'Tijuana'],

    // Amérique du Sud
    'Argentine': ['Buenos Aires', 'Córdoba', 'Rosario', 'Mendoza'],
    'Brésil': ['São Paulo', 'Rio de Janeiro', 'Brasília', 'Salvador', 'Fortaleza'],
    'Chili': ['Santiago', 'Valparaíso', 'Concepción', 'La Serena'],
    'Colombie': ['Bogotá', 'Medellín', 'Cali', 'Cartagena', 'Barranquilla'],

    // Asie
    'Chine': ['Pékin', 'Shanghai', 'Guangzhou', 'Shenzhen', 'Chengdu'],
    'Inde': ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai', 'Kolkata'],
    'Japon': ['Tokyo', 'Osaka', 'Kyoto', 'Yokohama', 'Fukuoka', 'Sapporo'],
    'Thaïlande': ['Bangkok', 'Chiang Mai', 'Phuket', 'Pattaya'],

    // Europe
    'Allemagne': ['Berlin', 'Munich', 'Hambourg', 'Francfort', 'Cologne', 'Stuttgart'],
    'Belgique': ['Bruxelles', 'Anvers', 'Gand', 'Liège', 'Bruges'],
    'Espagne': ['Madrid', 'Barcelone', 'Valence', 'Séville', 'Bilbao', 'Malaga'],
    'France': ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice', 'Nantes', 'Strasbourg', 'Bordeaux', 'Lille', 'Rennes'],
    'Italie': ['Rome', 'Milan', 'Naples', 'Turin', 'Florence', 'Venise', 'Bologne'],
    'Pays-Bas': ['Amsterdam', 'Rotterdam', 'La Haye', 'Utrecht', 'Eindhoven'],
    'Portugal': ['Lisbonne', 'Porto', 'Faro', 'Braga', 'Coimbra'],
    'Royaume-Uni': ['Londres', 'Manchester', 'Birmingham', 'Liverpool', 'Édimbourg', 'Glasgow', 'Bristol'],
    'Suisse': ['Zurich', 'Genève', 'Bâle', 'Lausanne', 'Berne'],

    // Océanie
    'Australie': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adélaïde'],
    'Nouvelle-Zélande': ['Auckland', 'Wellington', 'Christchurch', 'Hamilton'],
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = await _backend.getCurrentUser();
      final profileDoc = await _backend.getUserProfile(currentUser.$id);
      final profileData = profileDoc is Map ? profileDoc : profileDoc.data;
      _currentUser = DatingUser.fromJson(profileData);

      // Charger les préférences existantes
      if (_currentUser!.preferredGenders != null) {
        _selectedGenders.addAll(_currentUser!.preferredGenders!);
      }

      if (_currentUser!.preferredAgeRange != null) {
        _ageRange = _currentUser!.preferredAgeRange!;
      }

      if (_currentUser!.preferredContinents != null) {
        _selectedContinents.addAll(_currentUser!.preferredContinents!);
      }

      if (_currentUser!.preferredCountries != null) {
        _selectedCountries.addAll(_currentUser!.preferredCountries!);
      }

      if (_currentUser!.preferredCities != null) {
        _selectedCities.addAll(_currentUser!.preferredCities!);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Erreur chargement profil: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_currentUser == null) return;

    setState(() => _isSaving = true);

    try {
      await _backend.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.usersCollectionId,
        documentId: _currentUser!.id,
        data: {
          'preferredGenders': _selectedGenders.toList(),
          'preferredAgeRange': [_ageRange.start, _ageRange.end],
          'preferredContinents': _selectedContinents.toList(),
          'preferredCountries': _selectedCountries.toList(),
          'preferredCities': _selectedCities.toList(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences sauvegardées'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erreur sauvegarde préférences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Critères de recherche'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Critères de recherche'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _savePreferences,
              tooltip: 'Sauvegarder',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Genre recherché
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.people, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        'Je recherche',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: _genderOptions.map((gender) {
                      final isSelected = _selectedGenders.contains(gender);
                      return FilterChip(
                        label: Text(gender.capitalize()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenders.add(gender);
                            } else {
                              _selectedGenders.remove(gender);
                            }
                          });
                        },
                        selectedColor: Colors.deepPurple,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Âge recherché
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cake, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        'Âge',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} ans',
                    style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
                  ),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 80,
                    divisions: 62,
                    activeColor: Colors.deepPurple,
                    labels: RangeLabels(
                      _ageRange.start.toInt().toString(),
                      _ageRange.end.toInt().toString(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _ageRange = values;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Continent recherché
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        'Continent',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _continentOptions.map((continent) {
                      final isSelected = _selectedContinents.contains(continent);
                      return FilterChip(
                        label: Text(continent),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedContinents.add(continent);
                            } else {
                              _selectedContinents.remove(continent);
                              if (_countriesByContinent[continent] != null) {
                                _selectedCountries.removeAll(_countriesByContinent[continent]!);
                              }
                            }
                          });
                        },
                        selectedColor: Colors.deepPurple,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pays recherché
          if (_selectedContinents.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flag, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'Pays',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez les pays dans les continents choisis',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ..._selectedContinents.map((continent) {
                      final countries = _countriesByContinent[continent] ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            continent,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: countries.map((country) {
                              final isSelected = _selectedCountries.contains(country);
                              return FilterChip(
                                label: Text(country),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCountries.add(country);
                                    } else {
                                      _selectedCountries.remove(country);
                                      // Retirer aussi les villes de ce pays
                                      if (_citiesByCountry[country] != null) {
                                        _selectedCities.removeAll(_citiesByCountry[country]!);
                                      }
                                    }
                                  });
                                },
                                selectedColor: Colors.deepPurple.shade300,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Villes recherchées
          if (_selectedCountries.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_city, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'Villes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez les villes dans les pays choisis (optionnel)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ..._selectedCountries.map((country) {
                      final cities = _citiesByCountry[country] ?? [];
                      if (cities.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            country,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cities.map((city) {
                              final isSelected = _selectedCities.contains(city);
                              return FilterChip(
                                label: Text(city),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCities.add(city);
                                    } else {
                                      _selectedCities.remove(city);
                                    }
                                  });
                                },
                                selectedColor: Colors.deepPurple.shade200,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Bouton sauvegarder
          ElevatedButton(
            onPressed: _isSaving ? null : _savePreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Sauvegarder les préférences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
