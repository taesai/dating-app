class VideoModel {
  final String id;
  final String userId;
  final String fileId;
  final String? videoUrl;
  final String title;
  final String description;
  final int views;
  final int likes;
  final DateTime createdAt;
  final bool isApproved;

  VideoModel({
    required this.id,
    required this.userId,
    required this.fileId,
    this.videoUrl,
    required this.title,
    required this.description,
    required this.views,
    required this.likes,
    required this.createdAt,
    this.isApproved = false,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      fileId: json['fileId'] ?? '',
      videoUrl: json['videoUrl'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isApproved: json['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fileId': fileId,
      'title': title,
      'description': description,
      'views': views,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
      'isApproved': isApproved,
    };
  }

  VideoModel copyWith({
    String? id,
    String? userId,
    String? fileId,
    String? videoUrl,
    String? title,
    String? description,
    int? views,
    int? likes,
    DateTime? createdAt,
    bool? isApproved,
  }) {
    return VideoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileId: fileId ?? this.fileId,
      videoUrl: videoUrl ?? this.videoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}