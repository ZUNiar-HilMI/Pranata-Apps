import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/user.dart';

/// Script to create default admin and member accounts
/// Run this once to set up test accounts
Future<void> createDefaultUsers() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Create default admin user
  final admin = User(
    id: 'admin-001',
    username: 'admin',
    email: 'admin@example.com',
    password: User.hashPassword('admin123'),
    fullName: 'Admin User',
    role: 'admin',
    isEmailVerified: true,
    createdAt: DateTime.now(),
  );

  // Create default member user
  final member = User(
    id: 'member-001',
    username: 'member',
    email: 'member@example.com',
    password: User.hashPassword('member123'),
    fullName: 'Member User',
    role: 'member',
    isEmailVerified: true,
    createdAt: DateTime.now(),
  );

  // Get existing users or create empty list
  final existingUsers = prefs.getStringList('users') ?? [];
  
  // Convert to User objects
  final users = existingUsers
      .map((json) => User.fromJson(jsonDecode(json)))
      .toList();

  // Check if admin already exists
  final adminExists = users.any((u) => u.email == 'admin@example.com');
  if (!adminExists) {
    users.add(admin);
    print('✅ Admin account created: admin@example.com / admin123');
  } else {
    print('ℹ️  Admin account already exists');
  }

  // Check if member already exists
  final memberExists = users.any((u) => u.email == 'member@example.com');
  if (!memberExists) {
    users.add(member);
    print('✅ Member account created: member@example.com / member123');
  } else {
    print('ℹ️  Member account already exists');
  }

  // Save users back to storage
  final usersJson = users.map((u) => jsonEncode(u.toJson())).toList();
  await prefs.setStringList('users', usersJson);
  
  print('\n📋 Default Users Summary:');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Admin Account:');
  print('  Email: admin@example.com');
  print('  Password: admin123');
  print('  Role: Admin');
  print('');
  print('Member Account:');
  print('  Email: member@example.com');
  print('  Password: member123');
  print('  Role: Member');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}
