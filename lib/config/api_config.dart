import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      // Jika di Android Emulator dan URL menggunakan localhost, ganti otomatis ke 10.0.2.2
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        if (envUrl.contains('localhost')) {
          return envUrl.replaceAll('localhost', '10.0.2.2');
        }
        if (envUrl.contains('127.0.0.1')) {
          return envUrl.replaceAll('127.0.0.1', '10.0.2.2');
        }
      }
      return envUrl;
    }

    // Default fallback jika .env kosong
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  static bool get useCustomBackend {
    return dotenv.env['USE_CUSTOM_BACKEND']?.toLowerCase() == 'true';
  }
}
