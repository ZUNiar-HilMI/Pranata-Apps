import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import '../models/dinas.dart';

class FirebaseAuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  // ─── Register ────────────────────────────────────────────────────────────
  Future<User?> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String role = 'member',
    String? dinasId,
  }) async {
    // 1. Buat akun di Firebase Auth DULU
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    try {
      // 2. Cek username unik
      final usernameQuery = await _db
          .collection(_usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (usernameQuery.docs.isNotEmpty) {
        await credential.user!.delete();
        throw Exception('Username already exists');
      }

      // 3. Simpan profil ke Firestore
      final userData = {
        'id': uid,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': role,
        'dinasId': dinasId,
        'isEmailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _db.collection(_usersCollection).doc(uid).set(userData);

      return User(
        id: uid,
        username: username,
        email: email,
        password: '',
        fullName: fullName,
        role: role,
        dinasId: dinasId,
        isEmailVerified: false,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      if (e.toString().contains('Username already exists')) rethrow;
      try { await credential.user!.delete(); } catch (_) {}
      rethrow;
    }
  }

  // ─── Login ───────────────────────────────────────────────────────────────
  Future<User?> login(String usernameOrEmail, String password) async {
    String email = usernameOrEmail;

    if (!usernameOrEmail.contains('@')) {
      final q = await _db
          .collection(_usersCollection)
          .where('username', isEqualTo: usernameOrEmail)
          .limit(1)
          .get();
      if (q.docs.isEmpty) throw Exception('User not found');
      email = q.docs.first.data()['email'] as String;
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return await _getUserById(credential.user!.uid);
  }

  // ─── Logout ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── Change Password ─────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
    if (fbUser.email == null) throw Exception('Akun tidak memiliki email terdaftar.');

    try {
      final credential = fb.EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Password saat ini salah.');
      }
      throw Exception('Gagal verifikasi: ${e.message}');
    }

    try {
      await fbUser.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Password baru terlalu lemah. Gunakan minimal 6 karakter.');
      }
      throw Exception('Gagal mengubah password: ${e.message}');
    }
  }

  // ─── Get Current User ────────────────────────────────────────────────────
  Future<User?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return await _getUserById(fbUser.uid);
  }

  bool get isLoggedIn => _auth.currentUser != null;

  // ─── Get All Users ───────────────────────────────────────────────────────
  Future<List<User>> getAllUsers() async {
    final snapshot = await _db.collection(_usersCollection).get();
    return snapshot.docs.map((doc) => _docToUser(doc)).toList();
  }

  /// Get users yang tergabung dalam dinas tertentu (untuk admin dinas)
  Future<List<User>> getUsersByDinas(String dinasId) async {
    final snapshot = await _db
        .collection(_usersCollection)
        .where('dinasId', isEqualTo: dinasId)
        .get();
    return snapshot.docs.map((doc) => _docToUser(doc)).toList();
  }

  // ─── Update User ─────────────────────────────────────────────────────────
  Future<void> updateUser(User user) async {
    await _db.collection(_usersCollection).doc(user.id).update({
      'username': user.username,
      'fullName': user.fullName,
      'role': user.role,
      'dinasId': user.dinasId,
      'isEmailVerified': user.isEmailVerified,
    });
  }

  // ─── Update Profile Photo ─────────────────────────────────────────────────
  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    await _db.collection(_usersCollection).doc(userId).update({
      'photoUrl': photoUrl,
    });
  }

  // ─── Update Role & Dinas ─────────────────────────────────────────────────
  Future<bool> updateUserRole(String email, String newRole, {String? dinasId}) async {
    final q = await _db
        .collection(_usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return false;
    await q.docs.first.reference.update({
      'role': newRole,
      'dinasId': dinasId, // selalu update (null jika superadmin)
    });
    return true;
  }

  /// Update hanya field dinasId user
  Future<void> updateUserDinas(String userId, String? dinasId) async {
    await _db.collection(_usersCollection).doc(userId).update({
      'dinasId': dinasId,
    });
  }

  // ─── Delete User ─────────────────────────────────────────────────────────
  Future<bool> deleteUser(String id) async {
    try {
      await _db.collection(_usersCollection).doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUserByEmail(String email) async {
    final q = await _db
        .collection(_usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return false;
    await q.docs.first.reference.delete();
    return true;
  }

  // ─── Seed Dinas Awal ─────────────────────────────────────────────────────
  /// Buat 3 dinas awal jika belum ada di Firestore.
  Future<void> seedDinasIfNeeded() async {
    final dinasCol = _db.collection('dinas');
    for (final seed in Dinas.seedDinas) {
      final doc = await dinasCol.doc(seed['id']).get();
      if (!doc.exists) {
        await dinasCol.doc(seed['id']).set({
          ...seed,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────
  Future<User?> _getUserById(String uid) async {
    final doc = await _db.collection(_usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return _docToUser(doc);
  }

  User _docToUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      username: data['username'] as String,
      email: data['email'] as String,
      password: '',
      fullName: data['fullName'] as String,
      role: data['role'] as String? ?? 'member',
      dinasId: data['dinasId'] as String?,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
