class UserPhoto {
  final String photoId;
  final String userId;
  final String userRole; // 'patient', 'caretaker', or 'admin'
  final String imagePath;
  final String? caption;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPhoto({
    required this.photoId,
    required this.userId,
    required this.userRole,
    required this.imagePath,
    this.caption,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserPhoto copyWith({
    String? photoId,
    String? userId,
    String? userRole,
    String? imagePath,
    String? caption,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPhoto(
      photoId: photoId ?? this.photoId,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      imagePath: imagePath ?? this.imagePath,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'photoId': photoId,
      'userId': userId,
      'userRole': userRole,
      'imagePath': imagePath,
      'caption': caption,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserPhoto.fromMap(Map<String, dynamic> map) {
    return UserPhoto(
      photoId: map['photoId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userRole: map['userRole'] as String? ?? 'patient',
      imagePath: map['imagePath'] as String? ?? '',
      caption: map['caption'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
