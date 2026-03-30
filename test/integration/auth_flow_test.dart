import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/services/otp_service.dart';
import '../../lib/models/user.dart';

/// Integration tests for the full auth flow:
/// register → OTP generate → OTP verify → login → logout
void main() {
  late AuthService authService;
  late OTPService otpService;

  setUp(() async {
    // Use in-memory SharedPreferences for tests
    SharedPreferences.setMockInitialValues({});
    authService = AuthService();
    otpService = OTPService();
  });

  group('Full Auth Flow Integration', () {
    const testEmail = 'testuser@example.com';
    const testUsername = 'testuser';
    const testPassword = 'password123';
    const testFullName = 'Test User';

    test('Complete registration and login flow', () async {
      // Step 1: No users initially
      final initialUsers = await authService.getAllUsers();
      expect(initialUsers, isEmpty);

      // Step 2: Register a new user
      final registered = await authService.register(
        username: testUsername,
        email: testEmail,
        password: testPassword,
        fullName: testFullName,
      );
      expect(registered, isNotNull);
      expect(registered!.username, equals(testUsername));
      expect(registered.email, equals(testEmail));
      expect(registered.role, equals('member'));

      // Step 3: Verify user is persisted
      final users = await authService.getAllUsers();
      expect(users.length, equals(1));

      // Step 4: Login with correct credentials
      final loggedIn = await authService.login(testUsername, testPassword);
      expect(loggedIn, isNotNull);
      expect(loggedIn!.username, equals(testUsername));

      // Step 5: Verify current user is set
      final currentUser = await authService.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.email, equals(testEmail));

      // Step 6: Logout
      await authService.logout();
      final afterLogout = await authService.getCurrentUser();
      expect(afterLogout, isNull);
    });

    test('Registration prevents duplicate email', () async {
      await authService.register(
        username: testUsername,
        email: testEmail,
        password: testPassword,
        fullName: testFullName,
      );

      expect(
        () => authService.register(
          username: 'otheruser',
          email: testEmail, // duplicate email
          password: 'pass456',
          fullName: 'Other User',
        ),
        throwsException,
      );
    });

    test('Registration prevents duplicate username', () async {
      await authService.register(
        username: testUsername,
        email: testEmail,
        password: testPassword,
        fullName: testFullName,
      );

      expect(
        () => authService.register(
          username: testUsername, // duplicate username
          email: 'other@example.com',
          password: 'pass456',
          fullName: 'Other User',
        ),
        throwsException,
      );
    });

    test('Login fails with wrong password', () async {
      await authService.register(
        username: testUsername,
        email: testEmail,
        password: testPassword,
        fullName: testFullName,
      );

      expect(
        () => authService.login(testUsername, 'wrongpassword'),
        throwsException,
      );
    });

    test('Login accepts email as identifier', () async {
      await authService.register(
        username: testUsername,
        email: testEmail,
        password: testPassword,
        fullName: testFullName,
      );

      // Login with email instead of username
      final loggedIn = await authService.login(testEmail, testPassword);
      expect(loggedIn, isNotNull);
    });
  });

  group('OTP Flow Integration', () {
    const testEmail = 'otptest@example.com';

    test('OTP is generated and can be verified', () {
      // Generate OTP
      final otp = OTPService.generateOTP();
      expect(otp.length, equals(6));
      expect(int.tryParse(otp), isNotNull);

      // Store and verify OTP
      otpService.storeOTPForTesting(testEmail, otp);
      final result = otpService.verifyOTP(testEmail, otp);
      expect(result['success'], isTrue);
    });

    test('Wrong OTP fails verification', () {
      final otp = OTPService.generateOTP();
      otpService.storeOTPForTesting(testEmail, otp);

      final result = otpService.verifyOTP(testEmail, '000000');
      expect(result['success'], isFalse);
    });

    test('OTP can only be verified once', () {
      final otp = OTPService.generateOTP();
      otpService.storeOTPForTesting(testEmail, otp);

      final first = otpService.verifyOTP(testEmail, otp);
      expect(first['success'], isTrue);

      // Second attempt fails - OTP cleared after use
      final second = otpService.verifyOTP(testEmail, otp);
      expect(second['success'], isFalse);
    });
  });

  group('Role Management Integration', () {
    test('Admin can update user role', () async {
      SharedPreferences.setMockInitialValues({});

      await authService.register(
        username: 'member1',
        email: 'member1@example.com',
        password: 'pass123',
        fullName: 'Member One',
      );

      final updated = await authService.updateUserRole(
        'member1@example.com',
        'admin',
      );
      expect(updated, isTrue);

      final users = await authService.getAllUsers();
      final user = users.firstWhere((u) => u.email == 'member1@example.com');
      expect(user.role, equals('admin'));
    });
  });
}
