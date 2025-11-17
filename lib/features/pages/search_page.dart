import 'package:flutter/material.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/search_preferences.dart';
import '../../core/services/backend_service.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final BackendService _backend = BackendService();

  // Filtres de recherche basiques
  RangeValues _ageRange = const RangeValues(18, 50);
  double _maxDistance = 10000.0; // 10000km pour recherche mondiale
  String? _selectedGender;
  String? _selectedEducation;
  String? _selectedOccupation;
  List<String> _selectedInterests = [];
  List<String> _selectedLookingFor = [];

  // Nouveaux filtres avancés
  String? _selectedMaritalStatus;
  List<String> _selectedSports = [];
  List<String> _selectedHobbies = [];
  String? _selectedReligion;
  List<String> _selectedBodyTypes = [];
  RangeValues _heightRange = const RangeValues(150, 200);
  RangeValues _weightRange = const RangeValues(45, 120);
  bool _useGeolocation = false;

  // Filtres géographiques
  final Set<String> _selectedContinents = {};
  final Set<String> _selectedCountries = {};
  final Set<String> _selectedCities = {};

  List<DatingUser> _searchResults = [];
  DatingUser? _currentUser;
  bool _isLoading = false;
  bool _showFilters = true;
  Position? _currentPosition;

  // Options géographiques
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
    _loadSavedPreferences();
  }

  void _loadSavedPreferences() {
    try {
      final prefsJson = html.window.localStorage['search_preferences'];
      if (prefsJson != null && prefsJson.isNotEmpty) {
        // Parser le JSON
        final Map<String, dynamic> prefsMap = jsonDecode(prefsJson);
        final prefs = SearchPreferences.fromJson(prefsMap);

        // Charger toutes les valeurs
        setState(() {
          _ageRange = prefs.ageRange;
          _maxDistance = prefs.maxDistance;
          _selectedGender = prefs.gender;
          _selectedInterests = prefs.interests;
          _selectedLookingFor = prefs.lookingFor;
          _selectedContinents.clear();
          _selectedContinents.addAll(prefs.continents);
          _selectedCountries.clear();
          _selectedCountries.addAll(prefs.countries);
          _selectedCities.clear();
          _selectedCities.addAll(prefs.cities);
        });

        print('✅ Préférences de recherche chargées: Age ${_ageRange.start}-${_ageRange.end}, Distance ${_maxDistance}km, Continents: ${prefs.continents.length}, Pays: ${prefs.countries.length}, Villes: ${prefs.cities.length}');
      }
    } catch (e) {
      print('⚠️ Erreur chargement préférences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = SearchPreferences(
        ageRange: _ageRange,
        maxDistance: _maxDistance,
        gender: _selectedGender,
        interests: _selectedInterests,
        lookingFor: _selectedLookingFor,
        continents: _selectedContinents.toList(),
        countries: _selectedCountries.toList(),
        cities: _selectedCities.toList(),
      );

      html.window.localStorage['search_preferences'] = jsonEncode(prefs.toJson());

      // Sauvegarder le rayon de recherche dans le profil utilisateur
      if (_currentUser != null) {
        try {
          await _backend.updateUserProfile(
            userId: _currentUser!.id,
            data: {'searchRadius': _maxDistance},
          );
          print('✅ Rayon de recherche sauvegardé dans le profil');
        } catch (profileError) {
          print('⚠️ Erreur sauvegarde rayon dans profil: $profileError');
          // Continuer même si ça échoue, le localStorage est sauvegardé
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Préférences sauvegardées !'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('✅ Préférences sauvegardées: ${jsonEncode(prefs.toJson())}');
    } catch (e) {
      print('❌ Erreur sauvegarde préférences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur de sauvegarde: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _useGeolocation = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localisation activée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de localisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final currentUserDoc = await _backend.getCurrentUser();
      // Gérer les différents types de retour (Document avec .data ou Map direct)
      final profileData = (currentUserDoc is Map)
          ? currentUserDoc
          : (currentUserDoc.data is Map ? currentUserDoc.data : {});
      final user = DatingUser.fromJson(profileData);

      setState(() {
        _currentUser = user;
        // Charger le rayon de recherche sauvegardé
        if (user.searchRadius != null) {
          _maxDistance = user.searchRadius!;
        }
      });
    } catch (e) {
      print('Erreur chargement utilisateur: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      // Utiliser la géolocalisation si activée
      final searchLat = _useGeolocation && _currentPosition != null
          ? _currentPosition!.latitude
          : _currentUser!.latitude;
      final searchLng = _useGeolocation && _currentPosition != null
          ? _currentPosition!.longitude
          : _currentUser!.longitude;

      final response = await _backend.getNearbyUsers(
        latitude: searchLat,
        longitude: searchLng,
        radiusKm: _maxDistance,
      );

      var users = (response.documents as List)
          .map((doc) {
            final data = doc is Map ? doc : doc.data;
            return DatingUser.fromJson(data);
          })
          .where((user) => user.id != _currentUser!.id)
          .toList();

      // Appliquer tous les filtres
      users = users.where((user) {
        // Filtre par âge
        if (user.age < _ageRange.start || user.age > _ageRange.end) return false;

        // Filtre par genre
        if (_selectedGender != null && user.gender != _selectedGender) return false;

        // Filtre par distance
        if (user.distanceTo(_currentUser!) > _maxDistance) return false;

        // Filtre par situation maritale
        if (_selectedMaritalStatus != null && user.maritalStatus != _selectedMaritalStatus) return false;

        // Filtre par religion
        if (_selectedReligion != null && user.religion != _selectedReligion) return false;

        // Filtre par type de corps
        if (_selectedBodyTypes.isNotEmpty && user.bodyType != null) {
          if (!_selectedBodyTypes.contains(user.bodyType)) return false;
        }

        // Filtre par taille
        if (user.height != null) {
          final heightCm = int.tryParse(user.height!);
          if (heightCm != null) {
            if (heightCm < _heightRange.start || heightCm > _heightRange.end) return false;
          }
        }

        // Filtre par poids
        if (user.weight != null) {
          if (user.weight! < _weightRange.start || user.weight! > _weightRange.end) return false;
        }

        // Filtre par sports (au moins un en commun)
        if (_selectedSports.isNotEmpty) {
          final hasCommonSport = user.sports.any((sport) => _selectedSports.contains(sport));
          if (!hasCommonSport) return false;
        }

        // Filtre par hobbies (au moins un en commun)
        if (_selectedHobbies.isNotEmpty) {
          final hasCommonHobby = user.hobbies.any((hobby) => _selectedHobbies.contains(hobby));
          if (!hasCommonHobby) return false;
        }

        // Filtre par centres d'intérêt
        if (_selectedInterests.isNotEmpty) {
          final hasCommonInterest = user.interests.any((interest) => _selectedInterests.contains(interest));
          if (!hasCommonInterest) return false;
        }

        // Filtre par type de relation recherchée
        if (_selectedLookingFor.isNotEmpty) {
          final hasCommonLookingFor = user.lookingFor.any((lookingFor) => _selectedLookingFor.contains(lookingFor));
          if (!hasCommonLookingFor) return false;
        }

        // Filtres géographiques
        if (_selectedContinents.isNotEmpty) {
          if (user.continent == null || !_selectedContinents.contains(user.continent)) {
            return false;
          }
        }

        if (_selectedCountries.isNotEmpty) {
          if (user.country == null || !_selectedCountries.contains(user.country)) {
            return false;
          }
        }

        if (_selectedCities.isNotEmpty) {
          if (user.city == null || !_selectedCities.contains(user.city)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Trier par compatibilité
      users.sort((a, b) {
        final scoreA = _calculateCompatibilityScore(a);
        final scoreB = _calculateCompatibilityScore(b);
        return scoreB.compareTo(scoreA);
      });

      setState(() {
        _searchResults = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recherche: $e')),
        );
      }
    }
  }

  int _calculateCompatibilityScore(DatingUser user) {
    int score = 0;

    // Intérêts communs
    final commonInterests = user.interests.where((i) => _currentUser!.interests.contains(i)).length;
    score += commonInterests * 10;

    // Sports communs
    final commonSports = user.sports.where((s) => _currentUser!.sports.contains(s)).length;
    score += commonSports * 8;

    // Hobbies communs
    final commonHobbies = user.hobbies.where((h) => _currentUser!.hobbies.contains(h)).length;
    score += commonHobbies * 8;

    // Proximité
    final distance = user.distanceTo(_currentUser!);
    score += (100 - distance.clamp(0, 100)).toInt();

    // Objectifs communs
    final commonLookingFor = user.lookingFor.where((g) => _currentUser!.lookingFor.contains(g)).length;
    score += commonLookingFor * 15;

    // Même religion
    if (user.religion != null && user.religion == _currentUser!.religion) {
      score += 5;
    }

    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Recherche avancée', style: TextStyle(color: Colors.white)),
        actions: [
          // Bouton géolocalisation
          IconButton(
            icon: Icon(
              _useGeolocation ? Icons.location_on : Icons.location_off,
              color: _useGeolocation ? Colors.green : Colors.grey,
            ),
            onPressed: _getCurrentLocation,
            tooltip: 'Utiliser ma position actuelle',
          ),
          // Bouton filtres
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          if (_showFilters) _buildFiltersSection(),

          // Boutons de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _performSearch,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isLoading ? 'Recherche...' : 'Rechercher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _savePreferences,
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text('Sauver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Résultats
          Expanded(child: _buildResultsSection()),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.grey[900],
      height: 400,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Critères de base
            _buildSectionTitle('Critères de base'),
            _buildAgeFilter(),
            const SizedBox(height: 16),
            _buildDistanceFilter(),
            const SizedBox(height: 16),
            _buildGenderFilter(),
            const SizedBox(height: 24),

            // Section: Apparence physique
            _buildSectionTitle('Apparence physique'),
            _buildBodyTypeFilter(),
            const SizedBox(height: 16),
            _buildHeightFilter(),
            const SizedBox(height: 16),
            _buildWeightFilter(),
            const SizedBox(height: 24),

            // Section: Style de vie
            _buildSectionTitle('Style de vie'),
            _buildMaritalStatusFilter(),
            const SizedBox(height: 16),
            _buildReligionFilter(),
            const SizedBox(height: 24),

            // Section: Activités & Intérêts
            _buildSectionTitle('Activités & Intérêts'),
            _buildSportsFilter(),
            const SizedBox(height: 16),
            _buildHobbiesFilter(),
            const SizedBox(height: 16),
            _buildInterestsFilter(),
            const SizedBox(height: 24),

            // Section: Relation
            _buildSectionTitle('Type de relation'),
            _buildLookingForFilter(),
            const SizedBox(height: 24),

            // Section: Localisation géographique
            _buildSectionTitle('Localisation géographique'),
            _buildContinentFilter(),
            const SizedBox(height: 16),
            if (_selectedContinents.isNotEmpty) ...[
              _buildCountryFilter(),
              const SizedBox(height: 16),
            ],
            if (_selectedCountries.isNotEmpty) ...[
              _buildCityFilter(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.pink,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFilterTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.pink, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Âge', Icons.cake),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 80,
          divisions: 62,
          labels: RangeLabels('${_ageRange.start.toInt()}', '${_ageRange.end.toInt()}'),
          activeColor: Colors.pink,
          onChanged: (values) => setState(() => _ageRange = values),
        ),
        Text('${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} ans', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Distance maximale', Icons.location_on),
        Slider(
          value: _maxDistance,
          min: 5,
          max: 2000,
          divisions: 39,
          label: '${_maxDistance.toInt()} km',
          activeColor: Colors.pink,
          onChanged: (value) => setState(() => _maxDistance = value),
        ),
        Text('${_maxDistance.toInt()} km', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildGenderFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Genre', Icons.wc),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
          decoration: _filterInputDecoration(),
          items: ['Tous', 'Homme', 'Femme', 'Autre'].map((value) {
            return DropdownMenuItem<String>(
              value: value == 'Tous' ? null : value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
      ],
    );
  }

  Widget _buildBodyTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Allure physique', Icons.accessibility_new),
        _buildMultiSelectChips(
          options: ['Athlétique', 'Mince', 'Moyenne', 'Ronde', 'Musclé(e)'],
          selected: _selectedBodyTypes,
          onChanged: (values) => setState(() => _selectedBodyTypes = values),
        ),
      ],
    );
  }

  Widget _buildHeightFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Taille (cm)', Icons.height),
        RangeSlider(
          values: _heightRange,
          min: 140,
          max: 220,
          divisions: 80,
          labels: RangeLabels('${_heightRange.start.toInt()} cm', '${_heightRange.end.toInt()} cm'),
          activeColor: Colors.pink,
          onChanged: (values) => setState(() => _heightRange = values),
        ),
        Text('${_heightRange.start.toInt()} - ${_heightRange.end.toInt()} cm', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildWeightFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Poids (kg)', Icons.monitor_weight),
        RangeSlider(
          values: _weightRange,
          min: 40,
          max: 150,
          divisions: 110,
          labels: RangeLabels('${_weightRange.start.toInt()} kg', '${_weightRange.end.toInt()} kg'),
          activeColor: Colors.pink,
          onChanged: (values) => setState(() => _weightRange = values),
        ),
        Text('${_weightRange.start.toInt()} - ${_weightRange.end.toInt()} kg', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildMaritalStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Situation maritale', Icons.favorite),
        DropdownButtonFormField<String>(
          value: _selectedMaritalStatus,
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
          decoration: _filterInputDecoration(),
          items: ['Tous', 'Célibataire', 'Divorcé(e)', 'Veuf(ve)', 'En couple', 'Compliqué'].map((value) {
            return DropdownMenuItem<String>(
              value: value == 'Tous' ? null : value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedMaritalStatus = value),
        ),
      ],
    );
  }

  Widget _buildReligionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Religion', Icons.church),
        DropdownButtonFormField<String>(
          value: _selectedReligion,
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
          decoration: _filterInputDecoration(),
          items: ['Tous', 'Catholique', 'Protestant', 'Musulman', 'Juif', 'Bouddhiste', 'Hindou', 'Athée', 'Autre'].map((value) {
            return DropdownMenuItem<String>(
              value: value == 'Tous' ? null : value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedReligion = value),
        ),
      ],
    );
  }

  Widget _buildSportsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Sports', Icons.sports_soccer),
        _buildMultiSelectChips(
          options: ['Football', 'Basketball', 'Tennis', 'Natation', 'Course', 'Yoga', 'Fitness', 'Cyclisme', 'Danse', 'Arts martiaux'],
          selected: _selectedSports,
          onChanged: (values) => setState(() => _selectedSports = values),
        ),
      ],
    );
  }

  Widget _buildHobbiesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Hobbies', Icons.palette),
        _buildMultiSelectChips(
          options: ['Musique', 'Lecture', 'Cuisine', 'Photographie', 'Jardinage', 'Bricolage', 'Jeux vidéo', 'Cinéma', 'Théâtre', 'Voyages'],
          selected: _selectedHobbies,
          onChanged: (values) => setState(() => _selectedHobbies = values),
        ),
      ],
    );
  }

  Widget _buildInterestsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Centres d\'intérêt', Icons.star),
        _buildMultiSelectChips(
          options: ['Sport', 'Musique', 'Voyage', 'Cuisine', 'Cinéma', 'Lecture', 'Art', 'Technologie', 'Nature', 'Gaming'],
          selected: _selectedInterests,
          onChanged: (values) => setState(() => _selectedInterests = values),
        ),
      ],
    );
  }

  Widget _buildLookingForFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Type de relation', Icons.search_outlined),
        _buildMultiSelectChips(
          options: ['Relation sérieuse', 'Rencontre amicale', 'Aventure'],
          selected: _selectedLookingFor,
          onChanged: (values) => setState(() => _selectedLookingFor = values),
        ),
      ],
    );
  }

  Widget _buildContinentFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Continent', Icons.public),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _continentOptions.map((continent) {
            final isSelected = _selectedContinents.contains(continent);
            return FilterChip(
              label: Text(continent),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedContinents.add(continent);
                  } else {
                    _selectedContinents.remove(continent);
                    // Retirer aussi les pays de ce continent
                    if (_countriesByContinent[continent] != null) {
                      _selectedCountries.removeAll(_countriesByContinent[continent]!);
                      // Retirer aussi les villes de ces pays
                      for (var country in _countriesByContinent[continent]!) {
                        if (_citiesByCountry[country] != null) {
                          _selectedCities.removeAll(_citiesByCountry[country]!);
                        }
                      }
                    }
                  }
                });
              },
              selectedColor: Colors.pink.withOpacity(0.3),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
              backgroundColor: Colors.grey[800],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCountryFilter() {
    final availableCountries = _selectedContinents
        .expand((continent) => _countriesByContinent[continent] ?? [])
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Pays', Icons.flag),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableCountries.map((country) {
            final isSelected = _selectedCountries.contains(country);
            return FilterChip(
              label: Text(country),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
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
              selectedColor: Colors.pink.withOpacity(0.3),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
              backgroundColor: Colors.grey[800],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCityFilter() {
    final availableCities = _selectedCountries
        .expand((country) => _citiesByCountry[country] ?? [])
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('Ville', Icons.location_city),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableCities.map((city) {
            final isSelected = _selectedCities.contains(city);
            return FilterChip(
              label: Text(city),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedCities.add(city);
                  } else {
                    _selectedCities.remove(city);
                  }
                });
              },
              selectedColor: Colors.pink.withOpacity(0.3),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12),
              backgroundColor: Colors.grey[800],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> options,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (bool value) {
            final newSelected = List<String>.from(selected);
            if (value) {
              newSelected.add(option);
            } else {
              newSelected.remove(option);
            }
            onChanged(newSelected);
          },
          selectedColor: Colors.pink.withOpacity(0.3),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
          backgroundColor: Colors.grey[800],
        );
      }).toList(),
    );
  }

  InputDecoration _filterInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildResultsSection() {
    if (_searchResults.isEmpty && !_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun résultat', style: TextStyle(color: Colors.grey, fontSize: 18)),
            SizedBox(height: 8),
            Text('Essayez d\'ajuster vos filtres', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final distance = _currentUser?.distanceTo(user).toStringAsFixed(1) ?? '?';
        final compatibilityScore = _calculateCompatibilityScore(user);

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: user.photoUrlsFull.isNotEmpty ? NetworkImage(user.photoUrlsFull.first) : null,
              child: user.photoUrlsFull.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Row(
              children: [
                Text(
                  '${user.name}, ${user.age}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (user.verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$distance km', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 16),
                    const Icon(Icons.favorite, size: 14, color: Colors.pink),
                    const SizedBox(width: 4),
                    Text('$compatibilityScore% compatible', style: const TextStyle(color: Colors.pink)),
                  ],
                ),
                if (user.bodyType != null) ...[
                  const SizedBox(height: 4),
                  Text(user.bodyType!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
                if (user.occupation != null) ...[
                  const SizedBox(height: 4),
                  Text(user.occupation!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.pink),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} liké !'), backgroundColor: Colors.pink),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
