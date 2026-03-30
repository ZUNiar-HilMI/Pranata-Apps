import 'dart:convert';
import 'package:crypto/crypto.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String password; // hashed (empty when from Firebase)
  final String fullName;
  final String role; // 'superadmin' | 'admin' | 'member'
  final String? dinasId; // null for superadmin; 'kominfo' | 'dlh' | 'dishub' | ...
  final bool isEmailVerified;
  final DateTime createdAt;
  final String? photoUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.dinasId,
    this.isEmailVerified = false,
    required this.createdAt,
    this.photoUrl,
  });

  // ─── Role helpers ─────────────────────────────────────────────────────────
  bool get isSuperAdmin => role == 'superadmin';
  bool get isAdminDinas => role == 'admin';
  bool get isMember => role == 'member';

  /// Apakah user ini admin dari dinas tertentu?
  bool isAdminOf(String targetDinasId) => isAdminDinas && dinasId == targetDinasId;

  // ─── Password ─────────────────────────────────────────────────────────────
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPassword(String password) {
    return this.password == hashPassword(password);
  }

  // ─── Serialization ────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
      'dinasId': dinasId,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String? ?? '',
      fullName: json['fullName'] as String,
      role: json['role'] as String? ?? 'member',
      dinasId: json['dinasId'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  // ─── Copy With ────────────────────────────────────────────────────────────
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? fullName,
    String? role,
    String? dinasId,
    bool? isEmailVerified,
    DateTime? createdAt,
    String? photoUrl,
    bool clearPhoto = false,
    bool clearDinas = false,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      dinasId: clearDinas ? null : (dinasId ?? this.dinasId),
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    );
  }
}
