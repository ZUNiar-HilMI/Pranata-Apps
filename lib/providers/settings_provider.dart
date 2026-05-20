import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // ─── Keys ─────────────────────────────────────────────────────────────────
  static const String _kDarkMode      = 'dark_mode';
  static const String _kNotifications = 'notifications_enabled';
  static const String _kFontSize      = 'font_size';

  // ─── State ────────────────────────────────────────────────────────────────
  bool   _isDarkMode           = true;
  bool   _notificationsEnabled = true;
  String _fontSize             = 'Normal'; // 'Kecil' | 'Normal' | 'Besar'

  // ─── Getters ──────────────────────────────────────────────────────────────
  bool   get isDarkMode           => _isDarkMode;
  bool   get notificationsEnabled => _notificationsEnabled;
  String get fontSize             => _fontSize;

  /// Mapped textScaleFactor untuk dipakai di MaterialApp.builder
  double get textScaleFactor {
    switch (_fontSize) {
      case 'Kecil': return 0.85;
      case 'Besar': return 1.15;
      default:      return 1.0;
    }
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode           = prefs.getBool(_kDarkMode)      ?? true;
    _notificationsEnabled = prefs.getBool(_kNotifications) ?? true;
    _fontSize             = prefs.getString(_kFontSize)    ?? 'Normal';
    notifyListeners();
  }

  // ─── Setters ──────────────────────────────────────────────────────────────
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
  }

  Future<void> setFontSize(String value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontSize, value);
  }

  // ─── Clear Cache ──────────────────────────────────────────────────────────
  /// Benar-benar menghapus direktori cache sementara aplikasi.
  /// Aman: tidak menyentuh data pengguna atau Firestore.
  Future<void> clearCache() async {
    try {
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          // Hapus semua file di dalam direktori temp, bukan direktori-nya
          final files = tempDir.listSync(recursive: true);
          for (final entity in files) {
            try {
              if (entity is File) {
                await entity.delete();
              }
            } catch (_) {
              // Abaikan file yang tidak bisa dihapus (sedang dipakai)
            }
          }
        }
      }
    } catch (e) {
      // Abaikan error jika direktori tidak ada
    }
  }
}
