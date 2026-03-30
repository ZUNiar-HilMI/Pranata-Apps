import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static const int maxInputSizeBytes = 3 * 1024 * 1024; // 3MB
  static const int targetQuality = 70; // 70% JPEG quality
  static const int maxWidthHeight = 1024; // max dimension
  static const _imgbbApiKey = '5b93bc47e3792118f19b1ce649f0f2c1';

  /// Upload bytes ke ImgBB dan return URL publik permanen.
  static Future<String?> uploadToImgBB(Uint8List bytes, String fileName) async {
    try {
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {
          'image': base64Image,
          'name': fileName,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final url = json['data']['url'] as String;
          debugPrint('🖼️ ImgBB uploaded: $url');
          return url;
        }
      }
      debugPrint('⚠️ ImgBB upload failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ uploadToImgBB error: $e');
      return null;
    }
  }

  /// Compress File lalu upload ke ImgBB. Return URL publik.
  static Future<String?> compressAndUpload(File file, String fileName) async {
    try {
      final bytes = await compressImage(file) ?? await file.readAsBytes();
      return await uploadToImgBB(bytes, fileName);
    } catch (e) {
      debugPrint('❌ compressAndUpload error: $e');
      return null;
    }
  }

  /// Compress an image file and return compressed bytes.
  /// Throws [Exception] if input file exceeds 3MB.
  static Future<Uint8List?> compressImage(File file) async {
    final fileSize = await file.length();

    if (fileSize > maxInputSizeBytes) {
      throw Exception(
        'Ukuran gambar terlalu besar (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Maksimum 3MB.',
      );
    }

    // Web platform: flutter_image_compress not supported, return original
    if (kIsWeb) {
      return await file.readAsBytes();
    }

    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: maxWidthHeight,
        minHeight: maxWidthHeight,
        quality: targetQuality,
        format: CompressFormat.jpeg,
      );
      debugPrint(
        '🖼️ Image compressed: ${(fileSize / 1024).toStringAsFixed(0)}KB → '
        '${compressed != null ? (compressed.length / 1024).toStringAsFixed(0) : "?"}KB',
      );
      return compressed;
    } catch (e) {
      debugPrint('⚠️ Compression failed, using original: $e');
      return await file.readAsBytes();
    }
  }

  /// Save compressed bytes to app documents directory.
  /// Returns the saved file path.
  static Future<String> saveImageToFile(
    Uint8List bytes,
    String fileName,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/sigap_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = path.extension(fileName).isEmpty ? '.jpg' : path.extension(fileName);
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = File('${imagesDir.path}/$uniqueName');
    await savedFile.writeAsBytes(bytes);
    debugPrint('💾 Image saved: ${savedFile.path}');
    return savedFile.path;
  }

  /// Convert image file to base64 string (for SharedPreferences storage).
  static Future<String?> imageToBase64(File file) async {
    try {
      final compressed = await compressImage(file);
      if (compressed == null) return null;
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('❌ imageToBase64 error: $e');
      return null;
    }
  }

  /// Convert base64 string back to image bytes.
  static Uint8List? base64ToBytes(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      final cleanBase64 = base64Str.contains(',')
          ? base64Str.split(',').last
          : base64Str;
      return base64Decode(cleanBase64);
    } catch (e) {
      return null;
    }
  }

  /// Get human-readable file size string.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}
