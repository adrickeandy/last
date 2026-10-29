class ProfileModel {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? campus;
  final String? course;
  final int? yearOfStudy;
  final bool isAdmin;
  final bool isVerified;
  final bool isBanned;
  final String createdAt;
  final String updatedAt;

  ProfileModel({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.campus,
    this.course,
    this.yearOfStudy,
    this.isAdmin = false,
    this.isVerified = false,
    this.isBanned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      bio: json['bio'] as String?,
      campus: json['campus'] as String?,
      course: json['course'] as String?,
      yearOfStudy: json['year_of_study'] as int?,
      isAdmin: json['is_admin'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'campus': campus,
      'course': course,
      'year_of_study': yearOfStudy,
      'is_admin': isAdmin,
      'is_verified': isVerified,
      'is_banned': isBanned,
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? campus,
    String? course,
    int? yearOfStudy,
    bool? isVerified,
    bool? isBanned,
  }) {
    return ProfileModel(
      id: id,
      username: username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      campus: campus ?? this.campus,
      course: course ?? this.course,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      isAdmin: isAdmin,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
