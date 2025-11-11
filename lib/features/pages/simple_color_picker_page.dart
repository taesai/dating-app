import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/providers/theme_provider.dart';

/// Page de personnalisation simple des couleurs par composant
class SimpleColorPickerPage extends ConsumerStatefulWidget {
  const SimpleColorPickerPage({super.key});

  @override
  ConsumerState<SimpleColorPickerPage> createState() => _SimpleColorPickerPageState();
}

class _SimpleColorPickerPageState extends ConsumerState<SimpleColorPickerPage> {
  // Couleurs disponibles (palette simple)
  final List<Color> availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  Color _primaryColor = Colors.pink;      // Couleur principale (navBar, boutons)
  Color _secondaryColor = Colors.purple;  // Couleur secondaire (accents)
  Color _tertiaryColor = Colors.teal;     // Couleur tertiaire (notifications)
  bool _isDarkMode = false;               // Mode sombre ou clair

  @override
  void initState() {
    super.initState();
    _loadCurrentColors();
  }

  void _loadCurrentColors() {
    final themeState = ref.read(themeProvider);
    setState(() {
      _isDarkMode = themeState.isDark;
      if (themeState.isCustomTheme) {
        _primaryColor = themeState.customPrimaryColor ?? Colors.pink;
        _secondaryColor = themeState.customSecondaryColor ?? Colors.purple;
        _tertiaryColor = themeState.customTertiaryColor ?? Colors.teal;
      }
    });
  }

  Future<void> _saveColors() async {
    // Sauvegarder les couleurs via le themeProvider
    await ref.read(themeProvider.notifier).setCustomTheme(
      _primaryColor,
      _secondaryColor,
      _tertiaryColor,
      _isDarkMode, // Utilise le mode sélectionné par l'utilisateur
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Thème personnalisé appliqué'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personnaliser les couleurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveColors,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choisissez les couleurs de chaque élément',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Sélecteur mode clair/sombre
          Card(
            child: SwitchListTile(
              title: const Text('Mode sombre'),
              subtitle: Text(_isDarkMode ? 'Thème sombre activé' : 'Thème clair activé'),
              secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Couleur principale
          _buildColorSelector(
            'Couleur principale',
            'Navigation, boutons principaux',
            Icons.palette,
            _primaryColor,
            (color) => setState(() => _primaryColor = color),
          ),

          const SizedBox(height: 16),

          // Couleur secondaire
          _buildColorSelector(
            'Couleur secondaire',
            'Accents, icônes importantes',
            Icons.star,
            _secondaryColor,
            (color) => setState(() => _secondaryColor = color),
          ),

          const SizedBox(height: 16),

          // Couleur tertiaire
          _buildColorSelector(
            'Couleur tertiaire',
            'Notifications, détails',
            Icons.notifications,
            _tertiaryColor,
            (color) => setState(() => _tertiaryColor = color),
          ),

          const SizedBox(height: 32),

          // Aperçu
          Card(
            color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Aperçu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isDarkMode ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              size: 14,
                              color: _isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isDarkMode ? 'Sombre' : 'Clair',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bouton avec couleur principale
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Bouton principal'),
                  ),

                  const SizedBox(height: 12),

                  // Icône avec couleur secondaire
                  Row(
                    children: [
                      Icon(Icons.star, color: _secondaryColor, size: 32),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Accent / Icône',
                          style: TextStyle(
                            color: _secondaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Badge notification avec couleur tertiaire
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _tertiaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.notifications, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Notification',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(
    String title,
    String subtitle,
    IconData icon,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Palette de couleurs
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableColors.map((color) {
                final isSelected = color == currentColor;
                return GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Bouton pour ouvrir le color picker avancé
            Center(
              child: TextButton.icon(
                onPressed: () => _openAdvancedColorPicker(currentColor, onColorSelected),
                icon: const Icon(Icons.colorize),
                label: const Text('Sélecteur avancé'),
                style: TextButton.styleFrom(
                  foregroundColor: currentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvrir le sélecteur de couleurs avancé avec roue
  void _openAdvancedColorPicker(Color currentColor, Function(Color) onColorSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickerColor = currentColor;
        return AlertDialog(
          title: const Text('Sélecteur de couleurs'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Choisir'),
              onPressed: () {
                onColorSelected(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
