import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../config/cloudinary_config.dart';
import 'api_client.dart';
import 'image_service.dart';

class CloudinaryService {
  /// Upload image file ke Cloudinary, return URL publik.
  /// Otomatis compress sebelum upload.
  static Future<String?> uploadImage(File file, {String? folder}) async {
    try {
      final bytes = await ImageService.compressImage(file);
      if (bytes == null) return null;

      if (ApiConfig.useCustomBackend) {
        return await _uploadBytesToBackend(bytes, folder: folder ?? 'pranata');
      }

      return await uploadBytes(bytes, folder: folder);
    } catch (e) {
      debugPrint('CloudinaryService.uploadImage error: $e');
      rethrow;
    }
  }

  /// Upload raw bytes ke Cloudinary, return URL publik.
  static Future<String?> uploadBytes(Uint8List bytes, {String? folder}) async {
    try {
      if (ApiConfig.useCustomBackend) {
        return await _uploadBytesToBackend(bytes, folder: folder ?? 'pranata');
      }

      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      if (CloudinaryConfig.useSignedUpload) {
        final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
            .toString();
        final signatureParams = {
          'timestamp': timestamp,
          if (folder != null) 'folder': folder,
        };

        final signatureUri = Uri.parse(
          CloudinaryConfig.signatureBaseUrl,
        ).replace(queryParameters: signatureParams);

        debugPrint('Requesting signature from backend: $signatureUri');
        final sigResponse = await http.get(signatureUri);

        if (sigResponse.statusCode == 200) {
          final sigData = jsonDecode(sigResponse.body) as Map<String, dynamic>;
          final signature = sigData['signature'] as String;
          final returnedTimestamp =
              sigData['timestamp']?.toString() ?? timestamp;
          final apiKey =
              sigData['api_key'] as String? ?? CloudinaryConfig.apiKey;

          if (apiKey.isEmpty) {
            throw Exception(
              'Cloudinary API Key is empty. Please set it in CloudinaryConfig.',
            );
          }

          request.fields['signature'] = signature;
          request.fields['timestamp'] = returnedTimestamp;
          request.fields['api_key'] = apiKey;
          if (folder != null) {
            request.fields['folder'] = folder;
          }
        } else {
          throw Exception(
            'Gagal mendapatkan signature dari backend: '
            '${sigResponse.statusCode} ${sigResponse.body}',
          );
        }
      } else {
        if (CloudinaryConfig.uploadPreset.isEmpty) {
          throw Exception(
            'Cloudinary unsigned upload preset tidak dikonfigurasi. '
            'Set `uploadPreset` atau aktifkan signed upload.',
          );
        }

        request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
        if (folder != null) {
          request.fields['folder'] = folder;
        }
      }

      request.files.add(_jpgMultipart(bytes));

      debugPrint('Uploading to Cloudinary...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['secure_url'] as String?;
        debugPrint('Cloudinary upload success: $url');
        return url;
      }

      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      debugPrint('CloudinaryService.uploadBytes error: $e');
      rethrow;
    }
  }

  /// Delete image dari Cloudinary menggunakan public_id.
  /// Memerlukan API Key & Secret (tidak tersedia di unsigned preset).
  /// Untuk sekarang dibiarkan kosong, gambar lama tetap ada di Cloudinary.
  static Future<void> deleteImage(String publicId) async {
    debugPrint('Cloudinary delete not implemented: $publicId');
  }

  static http.MultipartFile _jpgMultipart(Uint8List bytes) {
    return http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
      contentType: MediaType('image', 'jpeg'),
    );
  }

  static Future<String?> _uploadBytesToBackend(
    Uint8List bytes, {
    required String folder,
  }) async {
    final uploadUri = Uri.parse(
      '${ApiConfig.baseUrl}/cloudinary/upload',
    ).replace(queryParameters: {'folder': folder});
    final request = http.MultipartRequest('POST', uploadUri);

    final token = await ApiClient().getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(_jpgMultipart(bytes));

    debugPrint('Uploading bytes to backend custom upload API: $uploadUri');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      debugPrint('Backend custom upload success: $url');
      return url;
    }

    throw Exception(
      'Backend upload failed: ${response.statusCode} ${response.body}',
    );
  }
}
