class MatchModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final bool isActive;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageDate;

  MatchModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.isActive,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageDate,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['\$id'] ?? '',
      user1Id: json['user1Id'] ?? '',
      user2Id: json['user2Id'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      lastMessage: json['lastMessage'],
      lastMessageSenderId: json['lastMessageSenderId'],
      lastMessageDate: json['lastMessageDate'] != null
          ? DateTime.parse(json['lastMessageDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageDate': lastMessageDate?.toIso8601String(),
    };
  }

  // Obtenir l'ID de l'autre utilisateur dans le match
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
}