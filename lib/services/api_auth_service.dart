import 'dart:io';
import '../models/user.dart';
import 'api_client.dart';

class ApiAuthService {
  final ApiClient _client = ApiClient();

  // ─── Register ────────────────────────────────────────────────────────────
  Future<User?> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String role = 'member',
    String? dinasId,
  }) async {
    final response = await _client.post('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      'dinasId': dinasId,
    });
    
    if (response == null) return null;
    return _mapToUser(response);
  }

  // ─── Login ───────────────────────────────────────────────────────────────
  Future<User?> login(String usernameOrEmail, String password) async {
    final response = await _client.post('/auth/login', {
      'identifier': usernameOrEmail,
      'password': password,
    });

    if (response == null || response['accessToken'] == null) {
      throw Exception('Login failed. Invalid token received.');
    }

    final token = response['accessToken'] as String;
    final userData = response['user'] as Map<String, dynamic>;

    // Save token and profile to client cache
    await _client.setToken(token);
    await _client.saveUserData(userData);

    return _mapToUser(userData);
  }

  // ─── Logout ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _client.clearAuth();
  }

  // ─── Change Password ─────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post('/auth/change-password', {
      'oldPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ─── Get Current User ────────────────────────────────────────────────────
  Future<User?> getCurrentUser() async {
    try {
      final token = await _client.getToken();
      if (token == null) return null;

      // 1. Try to fetch fresh data from backend
      try {
        final freshData = await _client.get('/auth/me');
        if (freshData != null) {
          await _client.saveUserData(freshData);
          return _mapToUser(freshData);
        }
      } catch (_) {
        // Fallback to local cache if offline or backend fails
      }

      // 2. Load from local cache
      final cachedData = await _client.getUserData();
      if (cachedData == null) return null;
      return _mapToUser(cachedData);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _client.getToken();
    return token != null;
  }

  // ─── Get All Users ───────────────────────────────────────────────────────
  Future<List<User>> getAllUsers() async {
    final response = await _client.get('/users');
    if (response == null) return [];
    final list = response as List;
    return list.map((u) => _mapToUser(u as Map<String, dynamic>)).toList();
  }

  /// Get users yang tergabung dalam dinas tertentu (untuk admin dinas)
  Future<List<User>> getUsersByDinas(String dinasId) async {
    // In our custom backend, GET /users automatically filters by Dinas ID if requesting user is ADMIN
    final response = await _client.get('/users');
    if (response == null) return [];
    final list = response as List;
    return list.map((u) => _mapToUser(u as Map<String, dynamic>)).toList();
  }

  // ─── Update User ─────────────────────────────────────────────────────────
  Future<void> updateUser(User user) async {
    final response = await _client.patch('/users/${user.id}', {
      'username': user.username,
      'email': user.email,
      'fullName': user.fullName,
      'dinasId': user.dinasId,
    });
    
    // Update local cache if updating self
    final currentUser = await getCurrentUser();
    if (currentUser?.id == user.id && response != null) {
      await _client.saveUserData(response);
    }
  }

  // ─── Update Profile Photo ─────────────────────────────────────────────────
  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    final response = await _client.patch('/users/$userId/photo', {
      'photoUrl': photoUrl,
    });

    // Update local cache if updating self
    final currentUser = await getCurrentUser();
    if (currentUser?.id == userId && response != null) {
      final cachedData = await _client.getUserData();
      if (cachedData != null) {
        cachedData['photoUrl'] = photoUrl;
        await _client.saveUserData(cachedData);
      }
    }
  }

  // ─── Update Role & Dinas ─────────────────────────────────────────────────
  Future<bool> updateUserRole(String email, String newRole, {String? dinasId}) async {
    try {
      // 1. Look up user by email
      final allUsers = await getAllUsers();
      final user = allUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // 2. Update role
      await _client.patch('/users/${user.id}/role', {
        'role': newRole.toUpperCase(),
      });

      // 3. If dinasId is modified, update user profile as well
      if (dinasId != user.dinasId) {
        await _client.patch('/users/${user.id}', {
          'dinasId': dinasId,
        });
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Delete User ─────────────────────────────────────────────────────────
  Future<void> updateUserDinas(String userId, String? dinasId) async {
    await _client.patch('/users/$userId', {
      'dinasId': dinasId,
    });
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _client.delete('/users/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUserByEmail(String email) async {
    try {
      final allUsers = await getAllUsers();
      final user = allUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );
      await _client.delete('/users/${user.id}');
      return true;
    } catch (_) {
      return false;
    }
  }

  // Helper map json to User model
  User _mapToUser(Map<String, dynamic> data) {
    return User(
      id: data['id'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
      password: '',
      fullName: data['fullName'] as String,
      role: (data['role'] as String).toLowerCase(),
      dinasId: data['dinasId'] as String?,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      photoUrl: data['photoUrl'] as String?,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'] as String) 
          : DateTime.now(),
    );
  }
}
