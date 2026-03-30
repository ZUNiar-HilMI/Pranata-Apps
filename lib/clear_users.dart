import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Clear all users from storage
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('users');
  await prefs.remove('current_user');
  print('✅ All users cleared!');
  print('✅ Current session cleared!');
}
