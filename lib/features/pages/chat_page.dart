import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:async';
import '../../core/models/chat_message_model.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/match_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/config/feature_flags.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/icebreaker_widget.dart';


class ChatPage extends StatefulWidget {
  final MatchModel match;
  final DatingUser otherUser;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.match,
    required this.otherUser,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final BackendService _backend = BackendService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  dynamic _realtimeSubscription;
  bool _showEmojiPicker = false;
  DatingUser? _currentUser;
  bool _otherUserIsTyping = false;
  Timer? _typingTimer;
  dynamic _typingSubscription;
  Timer? _sendTypingTimer;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _markMessagesAsRead();

    // Activer Realtime seulement si le feature flag est activé
    if (FeatureFlags.enableRealtime) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _subscribeToMessages();
          _subscribeToTypingIndicator();
        }
      });
      // Polling de secours si Realtime échoue (toutes les 5 secondes)
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          _checkNewMessages();
        }
      });
    } else {
      // Mode polling uniquement (toutes les 3 secondes)
      print('ℹ️ Chat en mode polling (${FeatureFlags.pollingInterval}s)');
      _pollingTimer = Timer.periodic(
        Duration(seconds: FeatureFlags.pollingInterval),
        (timer) {
          if (mounted) {
            _checkNewMessages();
          }
        },
      );
    }

    // Écouter les changements du champ de texte pour envoyer typing indicator
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _typingTimer?.cancel();
    _sendTypingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _realtimeSubscription?.cancel();
    _typingSubscription?.cancel();
    _sendTypingIndicator(false); // Arrêter l'indicateur lors de la fermeture
    super.dispose();
  }

  // === TYPING INDICATOR METHODS ===

  void _onTextChanged() {
    final text = _messageController.text;

    // Envoyer l'indicateur de typing si l'utilisateur tape
    if (text.isNotEmpty) {
      _sendTypingIndicator(true);

      // Annuler le timer précédent
      _sendTypingTimer?.cancel();

      // Arrêter automatiquement après 3 secondes d'inactivité
      _sendTypingTimer = Timer(const Duration(seconds: 3), () {
        _sendTypingIndicator(false);
      });
    } else {
      _sendTypingIndicator(false);
    }
  }

  void _sendTypingIndicator(bool isTyping) {
    _backend.sendTypingIndicator(
      matchId: widget.match.id,
      userId: widget.currentUserId,
      isTyping: isTyping,
    );
  }

  void _subscribeToTypingIndicator() {
    _typingSubscription = _backend.subscribeToTypingIndicator(
      matchId: widget.match.id,
      onTypingChange: (String userId, bool isTyping) {
        // Ignorer nos propres events
        if (userId == widget.currentUserId) return;

        if (!mounted) return;

        setState(() {
          _otherUserIsTyping = isTyping;
        });

        if (isTyping) {
          // Annuler le timer précédent
          _typingTimer?.cancel();

          // Arrêter l'indicateur après 5 secondes (sécurité)
          _typingTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _otherUserIsTyping = false;
              });
            }
          });

          // Scroll vers le bas pour montrer l'indicateur
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          _typingTimer?.cancel();
        }
      },
    );

    if (_typingSubscription != null) {
      print('✅ Abonné au typing indicator pour le match ${widget.match.id}');
    }
  }

  /// Simuler que l'autre utilisateur est en train d'écrire
  /// (DEPRECATED - maintenant géré par Realtime)
  void _simulateOtherUserTyping() {
    // Cette fonction n'est plus utilisée
    // Le typing indicator est maintenant géré par _subscribeToTypingIndicator
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userDoc = await _backend.getUserProfile(widget.currentUserId);
      final userData = userDoc is Map ? userDoc : userDoc.data;
      setState(() {
        _currentUser = DatingUser.fromJson(userData);
      });
    } catch (e) {
      print('Erreur chargement utilisateur: $e');
    }
  }

  // Vérifier les nouveaux messages (polling)
  Future<void> _checkNewMessages() async {
    if (_messages.isEmpty) return;

    try {
      final response = await _backend.getMessages(
        matchId: widget.match.id,
        limit: 10,
      );

      final latestMessages = (response.documents as List)
          .map((doc) {
            final data = doc is Map ? doc : doc.data;
            return ChatMessageModel.fromJson(data);
          })
          .toList()
          .reversed
          .toList();

      // Vérifier s'il y a de nouveaux messages
      if (latestMessages.isNotEmpty) {
        final lastKnownId = _messages.last.id;
        final newMessages = latestMessages
            .where((msg) => !_messages.any((m) => m.id == msg.id))
            .toList();

        if (newMessages.isNotEmpty && mounted) {
          setState(() {
            _messages.addAll(newMessages);
          });

          // Scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          // Mark as read
          _markMessagesAsRead();
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _backend.getMessages(
        matchId: widget.match.id,
        limit: 50,
      );

      final messages = (response.documents as List)
          .map((doc) {
            final data = doc is Map ? doc : doc.data;
            return ChatMessageModel.fromJson(data);
          })
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first

      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement messages: $e')),
      );
    }
  }

  void _subscribeToMessages() {
    try {
      _realtimeSubscription = _backend.subscribeToMessages(
        matchId: widget.match.id,
        onMessage: (payload) {
          try {
            final newMessage = ChatMessageModel.fromJson(payload);

            // IMPORTANT: Filtrer les messages envoyés par nous-même pour éviter les doublons
            // (ils sont déjà ajoutés manuellement dans _sendMessage)
            if (newMessage.senderId == widget.currentUserId) {
              print('📤 Message envoyé par nous-même, ignoré (déjà ajouté)');
              return;
            }

            if (mounted) {
              setState(() {
                _messages.add(newMessage);
              });
              // Scroll to bottom
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
              // Mark as read (only messages from other user arrive here now)
              _markMessagesAsRead();
            }
          } catch (e) {
            print('❌ Erreur traitement message: $e');
          }
        },
      );
    } catch (e) {
      print('❌ Erreur subscription messages: $e');
      // Le chat fonctionnera quand même, juste sans temps réel
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _backend.markMessagesAsRead(widget.match.id);
    } catch (e) {
      // Silent fail
    }
  }

  void _handlePhotoButton() {
    // Vérifier l'abonnement
    if (_currentUser == null) return;

    final isPremium = _currentUser!.subscriptionPlan != 'free';

    if (!isPremium) {
      // Afficher un message pour upgrader
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber),
              SizedBox(width: 8),
              Text('Fonctionnalité Premium'),
            ],
          ),
          content: const Text(
            'L\'envoi de photos est réservé aux membres Silver et Gold. Passez à un abonnement premium pour débloquer cette fonctionnalité !',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Naviguer vers la page d'abonnement
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Page d\'abonnement à venir')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Voir les offres'),
            ),
          ],
        ),
      );
    } else {
      // Utilisateur premium - afficher le sélecteur de photos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi de photo - À implémenter')),
      );
    }
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;

    // Si la sélection est invalide, ajouter à la fin
    if (!selection.isValid || selection.start < 0) {
      _messageController.text = text + emoji;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
      return;
    }

    // Insérer l'emoji à la position du curseur
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    final newOffset = selection.start + emoji.length;

    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _showEmojiPicker = false; // Fermer le clavier emoji après envoi
    });
    _messageController.clear();

    try {
      final response = await _backend.sendMessage(
        matchId: widget.match.id,
        receiverId: widget.otherUser.id,
        message: text,
      );

      // Add message to list
      final data = response is Map ? response : response.data;
      final newMessage = ChatMessageModel.fromJson(data);

      if (!mounted) return;
      setState(() {
        _messages.add(newMessage);
        _isSending = false;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _messageController.text = text; // Restore text
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur envoi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUser.photoUrlsFull.isNotEmpty
                  ? NetworkImage(widget.otherUser.photoUrlsFull.first)
                  : null,
              child: widget.otherUser.photoUrlsFull.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.otherUser.isActive ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.otherUser.isActive
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appel vidéo - À implémenter')),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Voir le profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Bloquer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Signaler'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                // Navigate to profile
              } else if (value == 'block') {
                // Show block dialog
              } else if (value == 'report') {
                // Show report dialog
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ?  Center(child: LoadingAnimationWidget.dotsTriangle(color: Colors.pink, size: 60))
                : _messages.isEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Icon(Icons.chat_bubble_outline,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun message',
                              style: TextStyle(
                                  fontSize: 20, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Envoyez le premier message !',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 32),
                            IcebreakerWidget(
                              onIcebreakerSelected: (text) {
                                setState(() {
                                  _messageController.text = text;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_otherUserIsTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Afficher l'indicateur de typing à la fin
                          if (_otherUserIsTyping && index == _messages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TypingIndicator(
                                  userName: widget.otherUser.name,
                                ),
                              ),
                            );
                          }

                          final message = _messages[index];
                          final isMe =
                              message.senderId == widget.currentUserId;
                          final showTime = index == 0 ||
                              _messages[index - 1]
                                      .createdAt
                                      .difference(message.createdAt)
                                      .inMinutes
                                      .abs() >
                                  5;

                          return _MessageBubble(
                            message: message,
                            isMe: isMe,
                            showTime: showTime,
                          );
                        },
                      ),
          ),

          // Input area
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Bouton photo (premium uniquement)
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate),
                      onPressed: () => _handlePhotoButton(),
                    ),
                    // Bouton emoji
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                        color: _showEmojiPicker ? Colors.pink : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.black), // Texte en noir pour fond blanc
                        decoration: const InputDecoration(
                          hintText: 'Écrire un message...',
                          hintStyle: TextStyle(color: Colors.grey), // Hint en gris
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _isSending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Emoji picker
              if (_showEmojiPicker)
                _buildEmojiPicker(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Emojis les plus populaires seulement pour simplifier
    final emojis = [
      // Smileys
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😉', '😊', '😇',
      '🥰', '😍', '🤩', '😘', '😗', '😙', '😋', '😛', '😜', '🤪', '😝',
      '🤗', '🤭', '🤔', '🤐', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
      '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🤧',
      '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐',
      // Coeurs
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️',
      '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟',
      // Gestes
      '👋', '🤚', '✋', '🖖', '👌', '🤏', '✌️', '🤞', '🤟', '🤘', '🤙',
      '👈', '👉', '👆', '👇', '☝️', '👍', '👎', '✊', '👊', '🤛', '🤜',
      '👏', '🙌', '👐', '🤲', '🤝', '🙏',
      // Expressions
      '💋', '💯', '💢', '💥', '💫', '💦', '💨', '💬', '💭', '💤',
      // Quelques animaux
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁',
      '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆', '🦉',
      // Nourriture
      '🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍒', '🍑', '🍍',
      '🍕', '🍔', '🍟', '🌭', '🍿', '🧁', '🍰', '🎂', '🍪', '🍩',
      '☕', '🍵', '🥤', '🍺', '🍻', '🥂', '🍷', '🍾',
    ];

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Entête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
            ),
            child: Row(
              children: [
                Text(
                  'Emojis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() => _showEmojiPicker = false);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Grille d'emojis
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                final emoji = emojis[index];
                return InkWell(
                  onTap: () {
                    _insertEmoji(emoji);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool showTime;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.pink : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
