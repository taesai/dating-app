class ChatMessageModel {
  final String id;
  final String matchId; // ID of the match this conversation belongs to
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? mediaUrl; // Optional: for images/videos shared in chat

  ChatMessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.mediaUrl,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['\$id'] ?? json['id'] ?? '',
      matchId: json['matchId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      mediaUrl: json['mediaUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'mediaUrl': mediaUrl,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? matchId,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? mediaUrl,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}
