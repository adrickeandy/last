class ClubModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? coverUrl;
  final String? createdBy;
  final String createdAt;
  final int memberCount;
  final bool isMember;

  ClubModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverUrl,
    this.createdBy,
    required this.createdAt,
    this.memberCount = 0,
    this.isMember = false,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json, {int memberCount = 0, bool isMember = false}) {
    return ClubModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      memberCount: memberCount,
      isMember: isMember,
    );
  }

  ClubModel copyWith({int? memberCount, bool? isMember}) {
    return ClubModel(
      id: id,
      name: name,
      slug: slug,
      description: description,
      coverUrl: coverUrl,
      createdBy: createdBy,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
      isMember: isMember ?? this.isMember,
    );
  }
}
