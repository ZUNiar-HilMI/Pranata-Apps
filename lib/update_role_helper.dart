import 'package:flutter/material.dart';
import 'services/auth_service.dart';

/// Helper script to update user role
/// Run this in your app to update zun@example.com to admin
Future<void> updateZunToAdmin() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final result = await authService.updateUserRole('zun@example.com', 'admin');
  
  if (result) {
    debugPrint('✅ SUCCESS: zun@example.com has been updated to admin role');
  } else {
    debugPrint('❌ FAILED: User zun@example.com not found');
  }
}

// You can call this function from anywhere in your app
// For example, add a debug button in home_screen.dart:
// 
// TextButton(
//   onPressed: () async {
//     await updateZunToAdmin();
//   },
//   child: Text('Make Zun Admin'),
// )
