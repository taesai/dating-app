class PhotoModel {
  final String id; // Document ID
  final String userId; // ID de l'utilisateur propriétaire
  final String fileId; // ID du fichier dans le storage
  final DateTime createdAt;
  final bool isApproved; // Statut d'approbation
  final bool isProfilePhoto; // Est-ce la photo de profil principale?
  final int displayOrder; // Ordre d'affichage

  PhotoModel({
    required this.id,
    required this.userId,
    required this.fileId,
    required this.createdAt,
    this.isApproved = false,
    this.isProfilePhoto = false,
    this.displayOrder = 0,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userID'] ?? json['userId'] ?? '', // CORRIGÉ: userID avec I majuscule (fallback sur userId pour compatibilité)
      fileId: json['fileId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isApproved: json['isApproved'] ?? false,
      isProfilePhoto: json['isPhotoProfile'] ?? json['isProfilePhoto'] ?? false, // CORRIGÉ: isPhotoProfile
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userId, // CORRIGÉ: userID avec I majuscule
      'fileId': fileId,
      'createdAt': createdAt.toIso8601String(),
      'isApproved': isApproved,
      'isPhotoProfile': isProfilePhoto, // CORRIGÉ: isPhotoProfile
      'displayOrder': displayOrder,
    };
  }

  PhotoModel copyWith({
    String? id,
    String? userId,
    String? fileId,
    DateTime? createdAt,
    bool? isApproved,
    bool? isProfilePhoto,
    int? displayOrder,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileId: fileId ?? this.fileId,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
      isProfilePhoto: isProfilePhoto ?? this.isProfilePhoto,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
