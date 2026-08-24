class EventModel {
  final String id;
  final String? clubId;
  final String? hostId;
  final String title;
  final String? description;
  final String? location;
  final String? coverUrl;
  final String startsAt;
  final String? endsAt;
  final String createdAt;
  final int rsvpCount;
  final bool isGoing;

  EventModel({
    required this.id,
    this.clubId,
    this.hostId,
    required this.title,
    this.description,
    this.location,
    this.coverUrl,
    required this.startsAt,
    this.endsAt,
    required this.createdAt,
    this.rsvpCount = 0,
    this.isGoing = false,
  });

  factory EventModel.fromJson(Map<String, dynamic> json, {int rsvpCount = 0, bool isGoing = false}) {
    return EventModel(
      id: json['id'] as String? ?? '',
      clubId: json['club_id'] as String?,
      hostId: json['host_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      coverUrl: json['cover_url'] as String?,
      startsAt: json['starts_at'] as String? ?? '',
      endsAt: json['ends_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      rsvpCount: rsvpCount,
      isGoing: isGoing,
    );
  }

  EventModel copyWith({int? rsvpCount, bool? isGoing}) {
    return EventModel(
      id: id,
      clubId: clubId,
      hostId: hostId,
      title: title,
      description: description,
      location: location,
      coverUrl: coverUrl,
      startsAt: startsAt,
      endsAt: endsAt,
      createdAt: createdAt,
      rsvpCount: rsvpCount ?? this.rsvpCount,
      isGoing: isGoing ?? this.isGoing,
    );
  }
}
