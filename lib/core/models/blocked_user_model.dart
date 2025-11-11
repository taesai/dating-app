class BlockedUserModel {
  final String id;
  final String blockerId; // User who blocked
  final String blockedUserId; // User who is blocked
  final String? reason; // Optional reason
  final DateTime createdAt;

  BlockedUserModel({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    this.reason,
    required this.createdAt,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: json['\$id'] ?? json['id'] ?? '',
      blockerId: json['blockerId'] ?? '',
      blockedUserId: json['blockedUserId'] ?? '',
      reason: json['reason'],
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
