import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/services/image_service.dart';

void main() {
  group('ImageService', () {
    test('formatFileSize formats bytes correctly', () {
      expect(ImageService.formatFileSize(512), equals('512B'));
      expect(ImageService.formatFileSize(1536), equals('1.5KB'));
      expect(ImageService.formatFileSize(2 * 1024 * 1024), equals('2.0MB'));
    });

    test('base64ToBytes returns null for null input', () {
      expect(ImageService.base64ToBytes(null), isNull);
    });

    test('base64ToBytes returns null for empty string', () {
      expect(ImageService.base64ToBytes(''), isNull);
    });

    test('base64ToBytes handles data URI prefix', () {
      // Encode a simple byte to base64
      final bytes = ImageService.base64ToBytes('data:image/jpeg;base64,SGVsbG8=');
      expect(bytes, isNotNull);
    });

    test('base64ToBytes decodes valid base64', () {
      final bytes = ImageService.base64ToBytes('SGVsbG8='); // "Hello"
      expect(bytes, isNotNull);
      expect(bytes!.length, equals(5));
    });

    test('maxInputSizeBytes is 3MB', () {
      expect(ImageService.maxInputSizeBytes, equals(3 * 1024 * 1024));
    });

    test('targetQuality is 70', () {
      expect(ImageService.targetQuality, equals(70));
    });

    test('maxWidthHeight is 1024', () {
      expect(ImageService.maxWidthHeight, equals(1024));
    });
  });
}
