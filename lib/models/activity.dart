class Activity {
  final String id;
  final String name;
  final String description;
  final double budget;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? photoBefore;
  final String? photoAfter;
  final String userId;
  final String dinasId; // dinas pemilik kegiatan ini
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.budget,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    this.photoBefore,
    this.photoAfter,
    required this.userId,
    required this.dinasId,
    this.status = 'pending',
    required this.createdAt,
  });

  // ─── Serialization ────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'budget': budget,
      'date': date.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'photoBefore': photoBefore,
      'photoAfter': photoAfter,
      'userId': userId,
      'dinasId': dinasId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      budget: (json['budget'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      photoBefore: json['photoBefore'] as String?,
      photoAfter: json['photoAfter'] as String?,
      userId: json['userId'] as String,
      dinasId: json['dinasId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // ─── Copy With ────────────────────────────────────────────────────────────
  Activity copyWith({
    String? id,
    String? name,
    String? description,
    double? budget,
    DateTime? date,
    String? location,
    double? latitude,
    double? longitude,
    String? photoBefore,
    String? photoAfter,
    String? userId,
    String? dinasId,
    String? status,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      date: date ?? this.date,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoBefore: photoBefore ?? this.photoBefore,
      photoAfter: photoAfter ?? this.photoAfter,
      userId: userId ?? this.userId,
      dinasId: dinasId ?? this.dinasId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
