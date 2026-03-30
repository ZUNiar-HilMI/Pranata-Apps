import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/user.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('User Model Tests', () {
    test('hashPassword should create consistent hash', () {
      const password = 'testPassword123';
      final hash1 = User.hashPassword(password);
      final hash2 = User.hashPassword(password);
      
      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(password)));
    });

    test('verifyPassword should return true for correct password', () {
      const password = 'correctPassword';
      final user = TestData.createTestUser(password: password);
      
      expect(user.verifyPassword(password), isTrue);
    });

    test('verifyPassword should return false for incorrect password', () {
      const correctPassword = 'correctPassword';
      const wrongPassword = 'wrongPassword';
      final user = TestData.createTestUser(password: correctPassword);
      
      expect(user.verifyPassword(wrongPassword), isFalse);
    });

    test('toJson should serialize user correctly', () {
      final user = TestData.createTestUser(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'member',
      );

      final json = user.toJson();

      expect(json['id'], equals('123'));
      expect(json['username'], equals('testuser'));
      expect(json['email'], equals('test@example.com'));
      expect(json['fullName'], equals('Test User'));
      expect(json['role'], equals('member'));
      expect(json['isEmailVerified'], isA<bool>());
      expect(json['createdAt'], isA<String>());
    });

    test('fromJson should deserialize user correctly', () {
      final json = {
        'id': '456',
        'username': 'jsonuser',
        'email': 'json@example.com',
        'password': User.hashPassword('password'),
        'fullName': 'JSON User',
        'role': 'admin',
        'isEmailVerified': true,
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
      };

      final user = User.fromJson(json);

      expect(user.id, equals('456'));
      expect(user.username, equals('jsonuser'));
      expect(user.email, equals('json@example.com'));
      expect(user.fullName, equals('JSON User'));
      expect(user.role, equals('admin'));
      expect(user.isEmailVerified, isTrue);
    });

    test('copyWith should create new user with updated fields', () {
      final original = TestData.createTestUser(
        username: 'original',
        email: 'original@example.com',
        role: 'member',
      );

      final updated = original.copyWith(
        username: 'updated',
        role: 'admin',
      );

      expect(updated.username, equals('updated'));
      expect(updated.role, equals('admin'));
      expect(updated.email, equals('original@example.com')); // unchanged
      expect(updated.id, equals(original.id)); // unchanged
    });

    test('copyWith with no parameters should return identical user', () {
      final original = TestData.createTestUser();
      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.username, equals(original.username));
      expect(copy.email, equals(original.email));
      expect(copy.fullName, equals(original.fullName));
      expect(copy.role, equals(original.role));
    });

    test('admin user should have admin role', () {
      final admin = TestData.createAdminUser();
      
      expect(admin.role, equals('admin'));
    });

    test('default user should have member role', () {
      final user = TestData.createTestUser();
      
      expect(user.role, equals('member'));
    });
  });
}
