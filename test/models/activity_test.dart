import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/activity.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Activity Model Tests', () {
    test('toJson should serialize activity correctly', () {
      final activity = TestData.createTestActivity(
        id: '123',
        name: 'Test Activity',
        description: 'Test Description',
        budget: 1500000,
        location: 'Jakarta',
        latitude: -6.2088,
        longitude: 106.8456,
        status: 'pending',
      );

      final json = activity.toJson();

      expect(json['id'], equals('123'));
      expect(json['name'], equals('Test Activity'));
      expect(json['description'], equals('Test Description'));
      expect(json['budget'], equals(1500000));
      expect(json['location'], equals('Jakarta'));
      expect(json['latitude'], equals(-6.2088));
      expect(json['longitude'], equals(106.8456));
      expect(json['status'], equals('pending'));
      expect(json['date'], isA<String>());
      expect(json['createdAt'], isA<String>());
    });

    test('fromJson should deserialize activity correctly', () {
      final json = {
        'id': '456',
        'name': 'JSON Activity',
        'description': 'JSON Description',
        'budget': 2000000,
        'date': DateTime(2024, 2, 15).toIso8601String(),
        'location': 'Bandung',
        'latitude': -6.9175,
        'longitude': 107.6191,
        'photoBefore': '/path/before.jpg',
        'photoAfter': '/path/after.jpg',
        'userId': 'user-123',
        'status': 'approved',
        'createdAt': DateTime(2024, 2, 1).toIso8601String(),
      };

      final activity = Activity.fromJson(json);

      expect(activity.id, equals('456'));
      expect(activity.name, equals('JSON Activity'));
      expect(activity.description, equals('JSON Description'));
      expect(activity.budget, equals(2000000));
      expect(activity.location, equals('Bandung'));
      expect(activity.latitude, equals(-6.9175));
      expect(activity.longitude, equals(107.6191));
      expect(activity.photoBefore, equals('/path/before.jpg'));
      expect(activity.photoAfter, equals('/path/after.jpg'));
      expect(activity.userId, equals('user-123'));
      expect(activity.status, equals('approved'));
    });

    test('copyWith should create new activity with updated fields', () {
      final original = TestData.createTestActivity(
        name: 'Original Name',
        budget: 1000000,
        status: 'pending',
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        status: 'approved',
      );

      expect(updated.name, equals('Updated Name'));
      expect(updated.status, equals('approved'));
      expect(updated.budget, equals(1000000)); // unchanged
      expect(updated.id, equals(original.id)); // unchanged
    });

    test('copyWith with no parameters should return identical activity', () {
      final original = TestData.createTestActivity();
      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.name, equals(original.name));
      expect(copy.budget, equals(original.budget));
      expect(copy.status, equals(original.status));
    });

    test('activity should handle null photo fields', () {
      final activity = TestData.createTestActivity(
        photoBefore: null,
        photoAfter: null,
      );

      expect(activity.photoBefore, isNull);
      expect(activity.photoAfter, isNull);
    });

    test('activity should handle null location coordinates', () {
      final activity = TestData.createTestActivity(
        latitude: null,
        longitude: null,
      );

      expect(activity.latitude, isNull);
      expect(activity.longitude, isNull);
    });

    test('approved activity should have approved status', () {
      final activity = TestData.createApprovedActivity();
      
      expect(activity.status, equals('approved'));
    });

    test('rejected activity should have rejected status', () {
      final activity = TestData.createRejectedActivity();
      
      expect(activity.status, equals('rejected'));
    });

    test('default activity should have pending status', () {
      final activity = TestData.createTestActivity();
      
      expect(activity.status, equals('pending'));
    });

    test('budget should be stored as double', () {
      final activity = TestData.createTestActivity(budget: 1500000);
      
      expect(activity.budget, isA<double>());
      expect(activity.budget, equals(1500000.0));
    });

    test('JSON with integer budget should convert to double', () {
      final json = {
        'id': '789',
        'name': 'Test',
        'description': 'Test',
        'budget': 1000000, // integer
        'date': DateTime.now().toIso8601String(),
        'location': 'Jakarta',
        'userId': 'user-1',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final activity = Activity.fromJson(json);
      
      expect(activity.budget, isA<double>());
      expect(activity.budget, equals(1000000.0));
    });
  });
}
