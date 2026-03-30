import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/models/user.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() async {
      // Initialize with empty preferences before each test
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    test('register should create new user successfully', () async {
      final user = await authService.register(
        username: 'newuser',
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
      );

      expect(user, isNotNull);
      expect(user!.username, equals('newuser'));
      expect(user.email, equals('new@example.com'));
      expect(user.fullName, equals('New User'));
      expect(user.role, equals('member')); // default role
    });

    test('register should hash password', () async {
      const plainPassword = 'myPassword123';
      
      final user = await authService.register(
        username: 'testuser',
        email: 'test@example.com',
        password: plainPassword,
        fullName: 'Test User',
      );

      expect(user!.password, isNot(equals(plainPassword)));
      expect(user.password.length, greaterThan(plainPassword.length));
    });

    test('register should allow admin role', () async {
      final user = await authService.register(
        username: 'admin',
        email: 'admin@example.com',
        password: 'admin123',
        fullName: 'Admin User',
        role: 'admin',
      );

      expect(user!.role, equals('admin'));
    });

    test('register should fail for duplicate username', () async {
      await authService.register(
        username: 'duplicateuser',
        email: 'first@example.com',
        password: 'password',
        fullName: 'First User',
      );

      expect(
        () => authService.register(
          username: 'duplicateuser',
          email: 'second@example.com',
          password: 'password',
          fullName: 'Second User',
        ),
        throwsException,
      );
    });

    test('register should fail for duplicate email', () async {
      await authService.register(
        username: 'user1',
        email: 'duplicate@example.com',
        password: 'password',
        fullName: 'First User',
      );

      expect(
        () => authService.register(
          username: 'user2',
          email: 'duplicate@example.com',
          password: 'password',
          fullName: 'Second User',
        ),
        throwsException,
      );
    });

    test('login should succeed with correct username and password', () async {
      const username = 'loginuser';
      const password = 'correctPassword';
      
      await authService.register(
        username: username,
        email: 'login@example.com',
        password: password,
        fullName: 'Login User',
      );

      final user = await authService.login(username, password);

      expect(user, isNotNull);
      expect(user!.username, equals(username));
    });

    test('login should succeed with email instead of username', () async {
      const email = 'login@example.com';
      const password = 'correctPassword';
      
      await authService.register(
        username: 'loginuser',
        email: email,
        password: password,
        fullName: 'Login User',
      );

      final user = await authService.login(email, password);

      expect(user, isNotNull);
      expect(user!.email, equals(email));
    });

    test('login should fail with incorrect password', () async {
      await authService.register(
        username: 'user',
        email: 'user@example.com',
        password: 'correctPassword',
        fullName: 'User',
      );

      expect(
        () => authService.login('user', 'wrongPassword'),
        throwsException,
      );
    });

    test('login should fail for non-existent user', () async {
      expect(
        () => authService.login('nonexistent', 'password'),
        throwsException,
      );
    });

    test('login should set current user', () async {
      const username = 'currentuser';
      const password = 'password';
      
      await authService.register(
        username: username,
        email: 'current@example.com',
        password: password,
        fullName: 'Current User',
      );

      await authService.login(username, password);
      
      final currentUser = await authService.getCurrentUser();
      
      expect(currentUser, isNotNull);
      expect(currentUser!.username, equals(username));
    });

    test('getCurrentUser should return null when not logged in', () async {
      final currentUser = await authService.getCurrentUser();
      
      expect(currentUser, isNull);
    });

    test('logout should clear current user', () async {
      await authService.register(
        username: 'logoutuser',
        email: 'logout@example.com',
        password: 'password',
        fullName: 'Logout User',
      );
      
      await authService.login('logoutuser', 'password');
      expect(await authService.getCurrentUser(), isNotNull);
      
      await authService.logout();
      
      final currentUser = await authService.getCurrentUser();
      expect(currentUser, isNull);
    });

    test('isLoggedIn should return true when user is logged in', () async {
      await authService.register(
        username: 'user',
        email: 'user@example.com',
        password: 'password',
        fullName: 'User',
      );
      
      await authService.login('user', 'password');
      
      final loggedIn = await authService.isLoggedIn();
      expect(loggedIn, isTrue);
    });

    test('isLoggedIn should return false when not logged in', () async {
      final loggedIn = await authService.isLoggedIn();
      expect(loggedIn, isFalse);
    });

    test('getAllUsers should return all registered users', () async {
      await authService.register(
        username: 'user1',
        email: 'user1@example.com',
        password: 'password',
        fullName: 'User 1',
      );
      await authService.register(
        username: 'user2',
        email: 'user2@example.com',
        password: 'password',
        fullName: 'User 2',
      );

      final users = await authService.getAllUsers();

      expect(users.length, equals(2));
    });

    test('updateUser should modify user data', () async {
      final originalUser = await authService.register(
        username: 'updateuser',
        email: 'update@example.com',
        password: 'password',
        fullName: 'Original Name',
      );

      final updatedUser = originalUser!.copyWith(
        fullName: 'Updated Name',
      );

      await authService.updateUser(updatedUser);

      final users = await authService.getAllUsers();
      final retrieved = users.firstWhere((u) => u.id == originalUser.id);
      
      expect(retrieved.fullName, equals('Updated Name'));
    });

    test('updateUser should update current user if same user', () async {
      await authService.register(
        username: 'currentuser',
        email: 'current@example.com',
        password: 'password',
        fullName: 'Original Name',
      );

      await authService.login('currentuser', 'password');
      
      final currentUser = await authService.getCurrentUser();
      final updatedUser = currentUser!.copyWith(fullName: 'New Name');
      
      await authService.updateUser(updatedUser);

      final newCurrentUser = await authService.getCurrentUser();
      expect(newCurrentUser!.fullName, equals('New Name'));
    });

    test('updateUserRole should change user role', () async {
      await authService.register(
        username: 'memberuser',
        email: 'member@example.com',
        password: 'password',
        fullName: 'Member User',
        role: 'member',
      );

      final success = await authService.updateUserRole('member@example.com', 'admin');

      expect(success, isTrue);
      
      final users = await authService.getAllUsers();
      final user = users.firstWhere((u) => u.email == 'member@example.com');
      expect(user.role, equals('admin'));
    });

    test('updateUserRole should return false for non-existent user', () async {
      final success = await authService.updateUserRole('nonexistent@example.com', 'admin');

      expect(success, isFalse);
    });

    test('updateUserRole should update current user if same user', () async {
      await authService.register(
        username: 'roleuser',
        email: 'role@example.com',
        password: 'password',
        fullName: 'Role User',
        role: 'member',
      );

      await authService.login('roleuser', 'password');
      
      await authService.updateUserRole('role@example.com', 'admin');

      final currentUser = await authService.getCurrentUser();
      expect(currentUser!.role, equals('admin'));
    });
  });
}
