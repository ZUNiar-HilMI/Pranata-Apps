import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../services/api_client.dart';
import '../services/firestore_service.dart';

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
      // 1. Initialize API Client memory token from storage
      final token = await ApiClient().getToken();
      ApiClient().setMemoryToken(token);

      // Pre-load dynamic Dinas list so DinasTheme CUID mapping works instantly
      try {
        final dinasList = await FirestoreService().getDinasList();
        DinasTheme.setLoadedDinas(dinasList);
      } catch (_) {
        // Fail-safe (will use offline seed list / CUID static mapping fallback)
      }

      if (ApiConfig.useCustomBackend) {
        // Fetch current user from API if token exists
        if (token != null) {
          _currentUser = await _authService.getCurrentUser();
        }
      } else {
        // Seed 3 dinas awal ke Firestore jika belum ada
        await _authService.seedDinasIfNeeded();
        // ── [PERBAIKAN] Sign out agar user harus login ulang setiap buka app ──
        await _authService.logout();
        _currentUser = null;
      }
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

      // Refresh dynamic Dinas list upon successful login to ensure mappings are fresh
      try {
        final dinasList = await FirestoreService().getDinasList();
        DinasTheme.setLoadedDinas(dinasList);
      } catch (_) {}

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
