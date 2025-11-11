import 'package:flutter/material.dart';
import '../../core/services/sound_service.dart';

/// Page de paramètres des effets sonores
class SoundSettingsPage extends StatefulWidget {
  const SoundSettingsPage({super.key});

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  final SoundService _soundService = SoundService();
  late bool _soundsEnabled;
  late double _volume;

  @override
  void initState() {
    super.initState();
    _soundsEnabled = _soundService.soundsEnabled;
    _volume = _soundService.volume;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Effets sonores'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Activation des sons
          Card(
            child: SwitchListTile(
              value: _soundsEnabled,
              onChanged: (value) async {
                await _soundService.setSoundsEnabled(value);
                setState(() {
                  _soundsEnabled = value;
                });

                if (value) {
                  await _soundService.playSuccess();
                }
              },
              title: const Text('Activer les effets sonores'),
              subtitle: Text(
                _soundsEnabled ? 'Les sons sont activés' : 'Les sons sont désactivés',
              ),
              secondary: Icon(
                _soundsEnabled ? Icons.volume_up : Icons.volume_off,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Volume
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volume_down,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Volume',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: '${(_volume * 100).round()}%',
                          onChanged: _soundsEnabled
                              ? (value) async {
                                  await _soundService.setVolume(value);
                                  setState(() {
                                    _volume = value;
                                  });
                                }
                              : null,
                          onChangeEnd: (value) {
                            if (_soundsEnabled) {
                              _soundService.playTap();
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${(_volume * 100).round()}%',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section: Tester les sons
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Text(
              'Tester les sons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Grille de boutons de test
          _buildSoundTestButton(
            'Swipe Right (Like)',
            Icons.favorite,
            Colors.pink,
            () => _soundService.playSwipeRight(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Swipe Left (Pass)',
            Icons.close,
            Colors.grey,
            () => _soundService.playSwipeLeft(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Match ! 🎉',
            Icons.celebration,
            Colors.purple,
            () => _soundService.playMatch(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Super Like ⭐',
            Icons.star,
            Colors.blue,
            () => _soundService.playSuperLike(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Message envoyé',
            Icons.send,
            Colors.green,
            () => _soundService.playMessageSent(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Message reçu',
            Icons.mark_chat_unread,
            Colors.orange,
            () => _soundService.playMessageReceived(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Notification',
            Icons.notifications_active,
            Colors.red,
            () => _soundService.playNotification(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Tap/Clic',
            Icons.touch_app,
            Colors.teal,
            () => _soundService.playTap(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Succès',
            Icons.check_circle,
            Colors.green,
            () => _soundService.playSuccess(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Erreur',
            Icons.error,
            Colors.red,
            () => _soundService.playError(),
          ),
          const SizedBox(height: 12),
          _buildSoundTestButton(
            'Whoosh (transition)',
            Icons.air,
            Colors.cyan,
            () => _soundService.playWhoosh(),
          ),

          const SizedBox(height: 24),

          // Informations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'À propos des sons',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Les sons ajoutent du feedback à vos actions\n'
                    '• Ils sont discrets et non intrusifs\n'
                    '• Vous pouvez les désactiver à tout moment\n'
                    '• Le volume est réglable selon vos préférences',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundTestButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: _soundsEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                _soundsEnabled ? Icons.play_arrow : Icons.volume_off,
                color: _soundsEnabled ? Theme.of(context).primaryColor : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget compact pour afficher l'état des sons dans les paramètres
class SoundToggleWidget extends StatefulWidget {
  const SoundToggleWidget({super.key});

  @override
  State<SoundToggleWidget> createState() => _SoundToggleWidgetState();
}

class _SoundToggleWidgetState extends State<SoundToggleWidget> {
  final SoundService _soundService = SoundService();
  late bool _soundsEnabled;

  @override
  void initState() {
    super.initState();
    _soundsEnabled = _soundService.soundsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _soundsEnabled ? Icons.volume_up : Icons.volume_off,
        color: Theme.of(context).primaryColor,
      ),
      title: const Text('Effets sonores'),
      subtitle: Text(
        _soundsEnabled ? 'Activés' : 'Désactivés',
      ),
      trailing: Switch(
        value: _soundsEnabled,
        onChanged: (value) async {
          await _soundService.setSoundsEnabled(value);
          setState(() {
            _soundsEnabled = value;
          });

          if (value) {
            await _soundService.playSuccess();
          }
        },
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SoundSettingsPage(),
          ),
        );
      },
    );
  }
}
