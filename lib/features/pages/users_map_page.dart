import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../core/models/dating_user.dart';
import '../../core/services/backend_service.dart';
import '../../core/utils/responsive_helper.dart';

class UsersMapPage extends StatefulWidget {
  const UsersMapPage({super.key});

  @override
  State<UsersMapPage> createState() => _UsersMapPageState();
}

class _UsersMapPageState extends State<UsersMapPage> with SingleTickerProviderStateMixin {
  final BackendService _backend = BackendService();
  final MapController _mapController = MapController();

  List<DatingUser> _nearbyUsers = [];
  DatingUser? _currentUser;
  double _radiusKm = 10000.0; // Rayon initial de 10000 km pour recherche mondiale
  bool _isLoading = true;
  bool _isLoadingUsers = false;
  Timer? _debounceTimer;

  // Animation pour le zoom de la carte
  late AnimationController _zoomAnimationController;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    // Initialiser l'animation de zoom spectaculaire
    _zoomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Animation plus lente pour effet dramatique
      vsync: this,
    );

    // Zoom depuis très haut (vue du monde entier) jusqu'au niveau détaillé
    _zoomAnimation = Tween<double>(begin: 2.0, end: 11.0).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOutCubic, // Courbe douce et élégante
      ),
    );

    _zoomAnimation.addListener(() {
      if (_currentUser != null) {
        _mapController.move(
          LatLng(_currentUser!.latitude, _currentUser!.longitude),
          _zoomAnimation.value,
        );
      }
    });

    _loadCurrentUserAndRadius();
  }

  Future<void> _loadCurrentUserAndRadius() async {
    try {
      print('👤 Chargement de l\'utilisateur actuel...');
      final currentUserDoc = await _backend.getCurrentUser();
      // Gérer les différents types de retour (Document avec .data ou Map direct)
      final profileData = (currentUserDoc is Map)
          ? currentUserDoc
          : (currentUserDoc.data is Map ? currentUserDoc.data : {});
      final user = DatingUser.fromJson(profileData);

      if (mounted) {
        setState(() {
          _currentUser = user;
          // Utiliser le rayon de recherche sauvegardé s'il existe
          if (user.searchRadius != null) {
            _radiusKm = user.searchRadius!;
            print('✅ Rayon de recherche chargé depuis le profil: ${_radiusKm.toInt()} km');
          }
        });

        // Charger les utilisateurs après avoir défini le rayon
        await _loadNearbyUsers();

        // Démarrer l'animation de zoom après le chargement
        _zoomAnimationController.forward();
      }
    } catch (e) {
      print('❌ Erreur chargement utilisateur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _zoomAnimationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNearbyUsers() async {
    if (_isLoadingUsers) {
      print('⏳ Chargement déjà en cours, ignoré');
      return;
    }

    if (_currentUser == null) {
      print('⚠️ Utilisateur non chargé, impossible de charger les utilisateurs');
      return;
    }

    print('🚀 Démarrage _loadNearbyUsers()');

    try {
      // Marquer comme en cours de chargement
      if (mounted) {
        setState(() {
          _isLoadingUsers = true;
        });
        print('📝 État: _isLoadingUsers = true');
      }

      print('🔍 Recherche des utilisateurs dans un rayon de ${_radiusKm.toInt()} km...');
      print('📍 Position: lat=${_currentUser!.latitude}, lng=${_currentUser!.longitude}');

      final response = await _backend.getNearbyUsers(
        latitude: _currentUser!.latitude,
        longitude: _currentUser!.longitude,
        radiusKm: _radiusKm,
      );

      List<DatingUser> users = [];

      try {
        final documents = response.documents as List;
        print('📍 ${documents.length} documents reçus du backend');

        users = documents
            .map((doc) {
              final data = doc is Map ? doc : doc.data;
              return DatingUser.fromJson(data);
            })
            .where((user) => user.id != _currentUser!.id)
            .where((user) {
              final distance = user.distanceTo(_currentUser!);
              return distance <= _radiusKm;
            })
            .toList();

        print('✅ ${users.length} utilisateurs trouvés dans le rayon de ${_radiusKm.toInt()} km');
      } catch (e) {
        print('❌ Erreur parsing documents: $e');
        users = [];
      }

      if (mounted) {
        setState(() {
          _nearbyUsers = users;
          _isLoading = false;
          _isLoadingUsers = false;
        });
        print('📝 État: _isLoadingUsers = false, ${users.length} utilisateurs affichés');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur chargement utilisateurs: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingUsers = false;
        });
        print('📝 État: _isLoadingUsers = false (après erreur)');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mise à jour en temps réel pendant le glissement
  void _onRadiusChanging(double value) {
    if (mounted) {
      setState(() {
        _radiusKm = value;
      });
    }
  }

  // Rechargement seulement quand l'utilisateur relâche le slider
  Future<void> _onRadiusChangeEnd(double value) async {
    print('🎚️ Slider relâché à: ${value.toInt()} km');

    // Annuler tout timer précédent pour être sûr
    _debounceTimer?.cancel();

    setState(() {
      _radiusKm = value;
    });

    // Lancer le rechargement DIRECTEMENT sans timer pour éviter les blocages
    if (mounted && !_isLoadingUsers) {
      print('🔄 Rechargement immédiat avec rayon: ${_radiusKm.toInt()} km');
      await _loadNearbyUsers();
    }
  }

  void _showUserProfile(DatingUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UserProfileSheet(user: user),
    );
  }

  void _centerOnUser() {
    if (_currentUser != null) {
      _mapController.move(
        LatLng(_currentUser!.latitude, _currentUser!.longitude),
        14.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final deviceType = ResponsiveHelper.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return _buildDesktopLayout();
      case DeviceType.tablet:
        return _buildTabletLayout();
      case DeviceType.mobile:
      default:
        return _buildMobileLayout();
    }
  }

  // Layout Mobile - Carte plein écran avec contrôles superposés
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1419),
      body: Stack(
        children: [
          // Fond bleu foncé pour les océans
          Container(
            color: const Color(0xFF1e3a5f), // Bleu marine foncé
          ),
          // Map sombre par dessus
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentUser!.latitude, _currentUser!.longitude),
              initialZoom: 9.0, // Zoom réduit pour voir ~200km de rayon
              minZoom: 2.0,
              maxZoom: 18.0,
            ),
            children: [
              // CARTO Dark Matter - Style noir avec routes blanches
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.dating_app',
                maxNativeZoom: 19,
                maxZoom: 19,
                tileBuilder: (context, tileWidget, tile) {
                  // Appliquer de la transparence pour laisser voir le fond bleu des océans
                  return Opacity(
                    opacity: 0.9,
                    child: tileWidget,
                  );
                },
              ),
              // Marqueur de l'utilisateur actuel (en dehors du cluster)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentUser!.latitude, _currentUser!.longitude),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              // Marqueurs des utilisateurs à proximité avec clustering
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(50, 50),
                  markers: _nearbyUsers.map((user) {
                    // Couleur basée sur le genre
                    final markerColor = user.gender == 'Femme'
                        ? Colors.pinkAccent
                        : user.gender == 'Homme'
                            ? Colors.blueAccent
                            : Colors.purpleAccent;

                    return Marker(
                      point: LatLng(user.latitude, user.longitude),
                      width: 50,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showUserProfile(user),
                        child: Column(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [markerColor, markerColor.withOpacity(0.6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: markerColor.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                image: user.photoUrlsFull.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(user.photoUrlsFull.first),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: user.photoUrlsFull.isEmpty
                                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                                  : null,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                user.name.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  builder: (context, markers) {
                    // Trouver un utilisateur avec photo pour l'afficher dans le cluster
                    DatingUser? randomUserWithPhoto;
                    for (var marker in markers) {
                      final user = _nearbyUsers.firstWhere(
                        (u) => u.latitude == marker.point.latitude && u.longitude == marker.point.longitude,
                        orElse: () => _nearbyUsers.first,
                      );
                      if (user.photoUrlsFull.isNotEmpty) {
                        randomUserWithPhoto = user;
                        break;
                      }
                    }

                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink, Colors.purple.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                        image: randomUserWithPhoto != null && randomUserWithPhoto.photoUrlsFull.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(randomUserWithPhoto.photoUrlsFull.first),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.95),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                markers.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Top bar with search radius slider
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rayon de recherche',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_radiusKm.toInt()} km',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 10.0,
                      max: 2000.0, // Augmenté à 2000km pour voir tous les utilisateurs
                      divisions: 199,
                      label: '${_radiusKm.toInt()} km',
                      activeColor: Colors.pink,
                      onChanged: _onRadiusChanging, // Mise à jour en temps réel
                      onChangeEnd: _onRadiusChangeEnd, // Rechargement à la fin
                    ),
                    if (_isLoadingUsers)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Recherche en cours...', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Users count
          Positioned(
            bottom: 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.pink),
                    const SizedBox(width: 8),
                    Text(
                      '${_nearbyUsers.length} utilisateurs à proximité',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center on user button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerOnUser,
              backgroundColor: Colors.pink,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Layout Tablet - Carte avec panneau latéral
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1419),
      body: Row(
        children: [
          Container(
            width: 320,
            color: Colors.grey[900],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink[700]!, Colors.purple[700]!],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Utilisateurs trouvés',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text('${_nearbyUsers.length}'),
                            backgroundColor: Colors.white,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rayon: ${_radiusKm.toInt()} km',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Slider(
                        value: _radiusKm,
                        min: 10.0,
                        max: 2000.0,
                        divisions: 199,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        onChanged: _onRadiusChanging,
                        onChangeEnd: _onRadiusChangeEnd,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingUsers
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16), // Padding pour voir le dernier élément
                          itemCount: _nearbyUsers.length,
                          itemBuilder: (context, index) {
                            final user = _nearbyUsers[index];
                            return _buildAnimatedUserTile(user, index);
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: _buildMapWidget(),
            ),
          ),
        ],
      ),
    );
  }

  // Layout Desktop - Panneau gauche + carte
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1419),
      body: Row(
        children: [
          Container(
            width: 380,
            color: Colors.grey[900],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink[700]!, Colors.purple[700]!],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recherche avancée',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_nearbyUsers.length} utilisateurs',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.my_location, color: Colors.white),
                            onPressed: _centerOnUser,
                            tooltip: 'Me localiser',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rayon',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_radiusKm.toInt()} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.pink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _radiusKm,
                        min: 10.0,
                        max: 2000.0,
                        divisions: 199,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        onChanged: _onRadiusChanging,
                        onChangeEnd: _onRadiusChangeEnd,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingUsers
                      ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                      : _nearbyUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun utilisateur',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16), // Padding pour voir le dernier élément
                              itemCount: _nearbyUsers.length,
                              itemBuilder: (context, index) {
                                return _buildAnimatedUserTile(_nearbyUsers[index], index);
                              },
                            ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
              child: _buildMapWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    return Stack(
      children: [
        Container(color: const Color(0xFF1e3a5f)),
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(_currentUser!.latitude, _currentUser!.longitude),
            initialZoom: 9.0, // Zoom réduit pour voir ~200km de rayon
            minZoom: 2.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.dating_app',
              maxNativeZoom: 19,
              maxZoom: 19,
              tileBuilder: (context, tileWidget, tile) {
                return Opacity(opacity: 0.9, child: tileWidget);
              },
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(_currentUser!.latitude, _currentUser!.longitude),
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 80,
                size: const Size(50, 50),
                markers: _nearbyUsers.map((user) {
                  final markerColor = user.gender == 'Femme'
                      ? Colors.pinkAccent
                      : user.gender == 'Homme'
                          ? Colors.blueAccent
                          : Colors.purpleAccent;
                  return Marker(
                    point: LatLng(user.latitude, user.longitude),
                    width: 50,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showUserProfile(user),
                      child: Column(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [markerColor, markerColor.withOpacity(0.6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: markerColor.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              image: user.photoUrlsFull.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(user.photoUrlsFull.first),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: user.photoUrlsFull.isEmpty
                                ? const Icon(Icons.person, color: Colors.white, size: 24)
                                : null,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              user.name.split(' ').first,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                builder: (context, markers) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        markers.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Wrapper animé pour les cartes de profils
  Widget _buildAnimatedUserTile(DatingUser user, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)), // Décalage par index
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)), // Slide from bottom
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: _buildUserListTile(user),
    );
  }

  Widget _buildUserListTile(DatingUser user) {
    final distance = _calculateDistance(
      _currentUser!.latitude,
      _currentUser!.longitude,
      user.latitude,
      user.longitude,
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: user.photoUrlsFull.isNotEmpty
              ? NetworkImage(user.photoUrlsFull.first)
              : null,
          child: user.photoUrlsFull.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(
          '${user.name}, ${user.age}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  user.gender == 'Femme' ? Icons.female : Icons.male,
                  size: 16,
                  color: user.gender == 'Femme' ? Colors.pink : Colors.blue,
                ),
                const SizedBox(width: 4),
                Text('${distance.toStringAsFixed(1)} km'),
              ],
            ),
            if (user.bio.isNotEmpty)
              Text(
                user.bio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.location_on, color: Colors.pink),
          onPressed: () {
            _mapController.move(LatLng(user.latitude, user.longitude), 15.0);
          },
          tooltip: 'Voir sur la carte',
        ),
        onTap: () => _showUserProfile(user),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, LatLng(lat1, lon1), LatLng(lat2, lon2));
  }
}

class _UserProfileSheet extends StatelessWidget {
  final DatingUser user;

  const _UserProfileSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // User photo
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: user.photoUrlsFull.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(user.photoUrlsFull.first),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: user.photoUrlsFull.isEmpty ? Colors.grey[300] : null,
              ),
              child: user.photoUrlsFull.isEmpty
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // User info
          Center(
            child: Text(
              '${user.name}, ${user.age}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          if (user.bio.isNotEmpty) ...[
            const Text('Bio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user.bio, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
          ],
          if (user.interests.isNotEmpty) ...[
            const Text('Intérêts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.interests.map((interest) {
                return Chip(
                  label: Text(interest),
                  backgroundColor: Colors.pink[50],
                );
              }).toList(),
            ),
          ],
          const Spacer(),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Passer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.favorite),
                  label: const Text('J\'aime'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}