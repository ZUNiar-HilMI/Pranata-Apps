import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/otp_service.dart';

void main() {
  group('OTPService Tests', () {
    late OTPService otpService;

    setUp(() {
      otpService = OTPService();
    });

    test('generateOTP should create 6-digit code', () {
      final otp = otpService.generateOTP();
      
      expect(otp.length, equals(6));
      expect(int.tryParse(otp), isNotNull);
      expect(int.parse(otp), greaterThanOrEqualTo(100000));
      expect(int.parse(otp), lessThan(1000000));
    });

    test('generateOTP should create different codes', () {
      final otp1 = otpService.generateOTP();
      final otp2 = otpService.generateOTP();
      
      // While theoretically they could be the same, statistically very unlikely
      expect(otp1, isNot(equals(otp2)));
    });

    test('verifyOTP should return success for correct OTP', () {
      const email = 'test@example.com';
      final otp = otpService.generateOTP();
      otpService.storeOTP(email, otp);
      
      final result = otpService.verifyOTP(email, otp);
      
      expect(result['success'], isTrue);
      expect(result['message'], contains('verified successfully'));
    });

    test('verifyOTP should return failure for incorrect OTP', () {
      const email = 'test@example.com';
      final correctOTP = otpService.generateOTP();
      const wrongOTP = '999999';
      otpService.storeOTP(email, correctOTP);
      
      final result = otpService.verifyOTP(email, wrongOTP);
      
      expect(result['success'], isFalse);
      expect(result['message'], contains('Invalid OTP'));
    });

    test('verifyOTP should return failure for non-existent email', () {
      const email = 'nonexistent@example.com';
      const otp = '123456';
      
      final result = otpService.verifyOTP(email, otp);
      
      expect(result['success'], isFalse);
      expect(result['message'], contains('No OTP found'));
    });

    test('verifyOTP should increment attempts on wrong OTP', () {
      const email = 'test@example.com';
      final correctOTP = otpService.generateOTP();
      const wrongOTP = '999999';
      otpService.storeOTP(email, correctOTP);
      
      // First wrong attempt
      otpService.verifyOTP(email, wrongOTP);
      // Second wrong attempt
      otpService.verifyOTP(email, wrongOTP);
      // Third wrong attempt
      final result = otpService.verifyOTP(email, wrongOTP);
      
      expect(result['success'], isFalse);
    });

    test('verifyOTP should fail after 3 wrong attempts', () {
      const email = 'test@example.com';
      final correctOTP = otpService.generateOTP();
      const wrongOTP = '999999';
      otpService.storeOTP(email, correctOTP);
      
      // 3 wrong attempts
      otpService.verifyOTP(email, wrongOTP);
      otpService.verifyOTP(email, wrongOTP);
      otpService.verifyOTP(email, wrongOTP);
      
      // 4th attempt should fail even with correct OTP
      final result = otpService.verifyOTP(email, correctOTP);
      
      expect(result['success'], isFalse);
      expect(result['message'], contains('Too many failed attempts'));
    });

    test('verifyOTP should remove OTP after successful verification', () {
      const email = 'test@example.com';
      final otp = otpService.generateOTP();
      otpService.storeOTP(email, otp);
      
      // First verification succeeds
      final result1 = otpService.verifyOTP(email, otp);
      expect(result1['success'], isTrue);
      
      // Second verification should fail (OTP removed)
      final result2 = otpService.verifyOTP(email, otp);
      expect(result2['success'], isFalse);
      expect(result2['message'], contains('No OTP found'));
    });

    test('hasOTP should return true for stored OTP', () {
      const email = 'test@example.com';
      final otp = otpService.generateOTP();
      otpService.storeOTP(email, otp);
      
      expect(otpService.hasOTP(email), isTrue);
    });

    test('hasOTP should return false for non-existent OTP', () {
      const email = 'nonexistent@example.com';
      
      expect(otpService.hasOTP(email), isFalse);
    });

    test('clearOTP should remove stored OTP', () {
      const email = 'test@example.com';
      final otp = otpService.generateOTP();
      otpService.storeOTP(email, otp);
      
      expect(otpService.hasOTP(email), isTrue);
      
      otpService.clearOTP(email);
      
      expect(otpService.hasOTP(email), isFalse);
    });

    test('getRemainingTime should return duration for valid OTP', () {
      const email = 'test@example.com';
      final otp = otpService.generateOTP();
      otpService.storeOTP(email, otp);
      
      final remainingTime = otpService.getRemainingTime(email);
      
      expect(remainingTime, isNotNull);
      expect(remainingTime!.inMinutes, lessThanOrEqualTo(5));
    });

    test('getRemainingTime should return null for non-existent OTP', () {
      const email = 'nonexistent@example.com';
      
      final remainingTime = otpService.getRemainingTime(email);
      
      expect(remainingTime, isNull);
    });

    test('sendOTPEmail should generate and store OTP', () async {
      const email = 'test@example.com';
      const userName = 'Test User';
      
      final result = await otpService.sendOTPEmail(email, userName);
      
      expect(result['success'], isTrue);
      expect(result['message'], contains('OTP sent'));
      expect(result['otp'], isNotNull); // Demo mode includes OTP
      expect(otpService.hasOTP(email), isTrue);
    });

    test('sendOTPEmail should create 6-digit OTP', () async {
      const email = 'test@example.com';
      const userName = 'Test User';
      
      final result = await otpService.sendOTPEmail(email, userName);
      final otp = result['otp'] as String;
      
      expect(otp.length, equals(6));
      expect(int.tryParse(otp), isNotNull);
    });
  });
}
