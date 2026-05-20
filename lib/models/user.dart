import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final String? passwordSalt;
  final String fullName;
  final String role;
  final String? dinasId;
  final bool isEmailVerified;
  final DateTime createdAt;
  final String? photoUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.passwordSalt,
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
  static const int _saltLength = 16;

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPassword(String password, {String? salt}) {
    final effectiveSalt = salt ?? _generateSalt();
    final digest = sha256.convert(utf8.encode('$effectiveSalt|$password'));
    return digest.toString();
  }

  static String generateSalt() => _generateSalt();

  bool verifyPassword(String password) {
    if (this.password.isEmpty) return false;
    if (passwordSalt != null && passwordSalt!.isNotEmpty) {
      return this.password == hashPassword(password, salt: passwordSalt);
    }

    final parts = this.password.split(':');
    if (parts.length == 2) {
      final oldSalt = parts[0];
      final storedHash = parts[1];
      return storedHash == hashPassword(password, salt: oldSalt);
    }

    return this.password == hashPassword(password);
  }

  // ─── Serialization ────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'passwordSalt': passwordSalt,
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
      passwordSalt: json['passwordSalt'] as String?,
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
    String? passwordSalt,
    String? fullName,
    String? role,
    String? dinasId,
    bool? isEmailVerified,
    DateTime? createdAt,
    String? photoUrl,
    bool clearPhoto = false,
    bool clearDinas = false,
    bool clearPasswordSalt = false,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      passwordSalt: clearPasswordSalt
          ? null
          : (passwordSalt ?? this.passwordSalt),
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      dinasId: clearDinas ? null : (dinasId ?? this.dinasId),
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    );
  }
}
