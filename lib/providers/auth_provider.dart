import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/dinas.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // ─── Role / Dinas shortcuts ───────────────────────────────────────────────
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  bool get isAdminDinas => _currentUser?.isAdminDinas ?? false;
  bool get isMember => _currentUser?.isMember ?? true;
  String? get dinasId => _currentUser?.dinasId;

  // Expose service for direct access by screens
  FirebaseAuthService get authService => _authService;

  // ─── Initialize ───────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Seed 3 dinas awal ke Firestore jika belum ada
      await _authService.seedDinasIfNeeded();
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(username, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String role = 'member',
    String? dinasId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        dinasId: dinasId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // ─── Update User ──────────────────────────────────────────────────────────
  Future<void> updateUser(User user) async {
    await _authService.updateUser(user);
    _currentUser = user;
    notifyListeners();
  }

  // ─── Update Profile Photo ─────────────────────────────────────────────────
  Future<void> updateProfilePhoto(String photoUrl) async {
    if (_currentUser == null) return;
    await _authService.updateProfilePhoto(_currentUser!.id, photoUrl);
    _currentUser = _currentUser!.copyWith(photoUrl: photoUrl);
    notifyListeners();
  }

  // ─── Change Password ──────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // ─── Update Dinas (SuperAdmin assign admin ke dinas) ─────────────────────
  Future<void> updateUserDinas(String userId, String? newDinasId) async {
    await _authService.updateUserDinas(userId, newDinasId);
  }

  // ─── Clear error ──────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
