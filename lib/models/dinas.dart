import 'package:cloud_firestore/cloud_firestore.dart';

class Dinas {
  final String id; // e.g. 'kominfo', 'dlh', 'dishub'
  final String name; // Nama lengkap dinas
  final String code; // Kode singkat, e.g. 'KOMINFO'
  final String description;
  final DateTime createdAt;

  const Dinas({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.createdAt,
  });

  // ─── 3 Dinas Awal (seed data) ─────────────────────────────────────────────
  static const List<Map<String, String>> seedDinas = [
    {
      'id': 'kominfo',
      'name': 'Dinas Komunikasi dan Informatika',
      'code': 'KOMINFO',
      'description': 'Mengelola komunikasi, informatika, dan teknologi informasi daerah.',
    },
    {
      'id': 'dlh',
      'name': 'Dinas Lingkungan Hidup',
      'code': 'DLH',
      'description': 'Mengelola lingkungan hidup, kebersihan, dan penghijauan daerah.',
    },
    {
      'id': 'dishub',
      'name': 'Dinas Perhubungan',
      'code': 'DISHUB',
      'description': 'Mengelola transportasi, lalu lintas, dan perhubungan daerah.',
    },
  ];

  // ─── Serialization ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Dinas.fromMap(String id, Map<String, dynamic> data) {
    return Dinas(
      id: id,
      name: data['name'] as String,
      code: data['code'] as String? ?? id.toUpperCase(),
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Dinas.fromDocument(DocumentSnapshot doc) {
    return Dinas.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Dinas copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    DateTime? createdAt,
  }) {
    return Dinas(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
