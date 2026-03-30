import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  // Get all users
  Future<List<User>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson.map((json) => User.fromJson(jsonDecode(json))).toList();
  }

  // Save users
  Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  // Register new user
  Future<User?> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String role = 'member',
  }) async {
    try {
      final users = await _getUsers();

      // Check if username or email already exists
      if (users.any((u) => u.username == username)) {
        throw Exception('Username already exists');
      }
      if (users.any((u) => u.email == email)) {
        throw Exception('Email already exists');
      }

      // Create new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        email: email,
        password: User.hashPassword(password),
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
      );

      // Add to users list
      users.add(newUser);
      await _saveUsers(users);

      // Don't auto-login, user must login manually
      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<User?> login(String username, String password) async {
    try {
      final users = await _getUsers();

      // Find user by username or email
      final user = users.firstWhere(
        (u) => u.username == username || u.email == username,
        orElse: () => throw Exception('User not found'),
      );

      // Verify password
      if (!user.verifyPassword(password)) {
        throw Exception('Invalid password');
      }

      // Save current user
      await _setCurrentUser(user);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Get all users (for checking duplicates)
  Future<List<User>> getAllUsers() async {
    return await _getUsers();
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get current logged-in user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      if (userJson == null) return null;
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // Set current user
  Future<void> _setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  // Update user
  Future<void> updateUser(User user) async {
    final users = await _getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = user;
      await _saveUsers(users);
      
      // Update current user if it's the same user
      final currentUser = await getCurrentUser();
      if (currentUser?.id == user.id) {
        await _setCurrentUser(user);
      }
    }
  }

  // Update user role by email
  Future<bool> updateUserRole(String email, String newRole) async {
    try {
      final users = await _getUsers();
      final userIndex = users.indexWhere((u) => u.email == email);
      
      if (userIndex == -1) {
        return false; // User not found
      }

      // Update user with new role
      final user = users[userIndex];
      final updatedUser = user.copyWith(role: newRole);
      users[userIndex] = updatedUser;
      
      await _saveUsers(users);
      
      // Update current user if it's the same user
      final currentUser = await getCurrentUser();
      if (currentUser?.email == email) {
        await _setCurrentUser(updatedUser);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete all non-default users (keep admin & member default accounts)
  Future<int> deleteNonDefaultUsers() async {
    final defaultEmails = ['admin@example.com', 'member@example.com'];
    final users = await _getUsers();
    final filtered = users.where((u) => defaultEmails.contains(u.email)).toList();
    final deletedCount = users.length - filtered.length;
    await _saveUsers(filtered);
    return deletedCount;
  }

  // Delete user by email
  Future<bool> deleteUserByEmail(String email) async {
    final users = await _getUsers();
    final filtered = users.where((u) => u.email != email).toList();
    if (filtered.length == users.length) return false; // not found
    await _saveUsers(filtered);
    return true;
  }

  // Delete user by ID
  Future<bool> deleteUser(String id) async {
    final users = await _getUsers();
    final filtered = users.where((u) => u.id != id).toList();
    if (filtered.length == users.length) return false;
    await _saveUsers(filtered);
    return true;
  }
}
