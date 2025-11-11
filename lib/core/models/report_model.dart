class ReportModel {
  final String id;
  final String reporterId; // ID de l'utilisateur qui signale
  final String reportedUserId; // ID de l'utilisateur signalé
  final String? reportedContentId; // ID de la vidéo/photo signalée (optionnel)
  final String contentType; // 'user', 'video', 'photo'
  final String reason; // Raison du signalement
  final String? additionalInfo; // Informations supplémentaires
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'actioned', 'dismissed'
  final String? adminNotes; // Notes de l'admin

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.reportedContentId,
    required this.contentType,
    required this.reason,
    this.additionalInfo,
    required this.createdAt,
    this.status = 'pending',
    this.adminNotes,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['\$id'] ?? '',
      reporterId: json['reporterId'] ?? '',
      reportedUserId: json['reportedUserId'] ?? '',
      reportedContentId: json['reportedContentId'],
      contentType: json['contentType'] ?? 'user',
      reason: json['reason'] ?? '',
      additionalInfo: json['additionalInfo'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportedContentId': reportedContentId,
      'contentType': contentType,
      'reason': reason,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'adminNotes': adminNotes,
    };
  }

  // Report types constants
  static const String harassment = 'harassment';
  static const String inappropriateContent = 'inappropriate';
  static const String spam = 'spam';
  static const String fakeProfile = 'fake';
  static const String other = 'other';

  static List<String> get reportTypes => [
        harassment,
        inappropriateContent,
        spam,
        fakeProfile,
        other,
      ];

  static String getReportTypeLabel(String type) {
    switch (type) {
      case harassment:
        return 'Harcèlement';
      case inappropriateContent:
        return 'Contenu inapproprié';
      case spam:
        return 'Spam';
      case fakeProfile:
        return 'Faux profil';
      case other:
        return 'Autre';
      default:
        return 'Autre';
    }
  }
}
