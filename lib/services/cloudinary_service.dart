import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/cloudinary_config.dart';
import 'image_service.dart';

class CloudinaryService {
  /// Upload image file ke Cloudinary, return URL publik.
  /// Otomatis compress sebelum upload.
  static Future<String?> uploadImage(File file, {String? folder}) async {
    try {
      final bytes = await ImageService.compressImage(file);
      if (bytes == null) return null;
      return await uploadBytes(bytes, folder: folder);
    } catch (e) {
      debugPrint('❌ CloudinaryService.uploadImage error: $e');
      rethrow;
    }
  }

  /// Upload raw bytes ke Cloudinary, return URL publik.
  static Future<String?> uploadBytes(Uint8List bytes,
      {String? folder}) async {
    try {
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      debugPrint('☁️ Uploading to Cloudinary...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['secure_url'] as String?;
        debugPrint('✅ Cloudinary upload success: $url');
        return url;
      } else {
        throw Exception(
            'Cloudinary upload failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ CloudinaryService.uploadBytes error: $e');
      rethrow;
    }
  }

  /// Delete image dari Cloudinary menggunakan public_id.
  /// Memerlukan API Key & Secret (tidak tersedia di unsigned preset).
  /// Untuk sekarang dibiarkan kosong — gambar lama tetap ada di Cloudinary.
  static Future<void> deleteImage(String publicId) async {
    debugPrint('⚠️ Cloudinary delete not implemented (requires signed request): $publicId');
  }
}
