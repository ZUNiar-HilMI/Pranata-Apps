import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/email_config.dart';


class OTPService {
  // Singleton pattern — semua screen pakai instance yang sama
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  // Store OTP with timestamp for expiry check
  final Map<String, Map<String, dynamic>> _otpStore = {};
  
  // OTP expiry time (5 minutes)
  static const int otpExpiryMinutes = 5;

  // Generate 6-digit OTP
  static String generateOTP() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  /// Test helper: store OTP directly without sending email
  void storeOTPForTesting(String email, String otp) {
    storeOTP(email, otp);
  }

  // Store OTP with email and timestamp
  void storeOTP(String email, String otp) {
    _otpStore[email] = {
      'otp': otp,
      'timestamp': DateTime.now(),
      'attempts': 0,
    };
  }

  // Verify OTP
  Map<String, dynamic> verifyOTP(String email, String inputOTP) {
    if (!_otpStore.containsKey(email)) {
      return {
        'success': false,
        'message': 'No OTP found. Please request a new one.',
      };
    }

    final otpData = _otpStore[email]!;
    final storedOTP = otpData['otp'] as String;
    final timestamp = otpData['timestamp'] as DateTime;
    final attempts = otpData['attempts'] as int;

    // Check expiry
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes >= otpExpiryMinutes) {
      _otpStore.remove(email);
      return {
        'success': false,
        'message': 'OTP has expired. Please request a new one.',
      };
    }

    // Check attempts (max 3)
    if (attempts >= 3) {
      _otpStore.remove(email);
      return {
        'success': false,
        'message': 'Too many failed attempts. Please request a new OTP.',
      };
    }

    // Verify OTP
    if (storedOTP == inputOTP) {
      _otpStore.remove(email);
      return {
        'success': true,
        'message': 'OTP verified successfully!',
      };
    } else {
      // Increment attempts
      _otpStore[email]!['attempts'] = attempts + 1;
      return {
        'success': false,
        'message': 'Invalid OTP. Please try again.',
      };
    }
  }

  // Send OTP via EmailJS
  Future<Map<String, dynamic>> sendOTPEmail(String email, String userName) async {
    try {
      final otp = generateOTP();
      storeOTP(email, otp);

      // Try to send real email via EmailJS
      try {
        await _sendEmailViaEmailJS(email, userName, otp);
        
        debugPrint('✅ OTP email sent successfully to $email');
        
        return {
          'success': true,
          'message': 'OTP sent to $email',
        };
      } catch (emailError) {
        // If EmailJS fails, fall back to demo mode
        debugPrint('⚠️ EmailJS failed: $emailError');
        debugPrint('📱 Using DEMO mode instead');
        
        // Show OTP in console for demo/testing
        debugPrint('═══════════════════════════════════════');
        debugPrint('🔐 OTP for $email: $otp');
        debugPrint('📧 Email delivery failed - showing in console');
        debugPrint('⏰ Valid for $otpExpiryMinutes minutes');
        debugPrint('═══════════════════════════════════════');

        return {
          'success': true,
          'message': 'OTP sent to $email',
          'otp': otp, // Include OTP in demo mode
          'demo_mode': true,
        };
      }
    } catch (e) {
      debugPrint('❌ Error in sendOTPEmail: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again.',
      };
    }
  }

  // Private method to send email via EmailJS API
  Future<void> _sendEmailViaEmailJS(
    String toEmail,
    String userName,
    String otpCode,
  ) async {
    final url = Uri.parse(EmailConfig.apiUrl);
    
    final emailData = {
      'service_id': EmailConfig.serviceId,
      'template_id': EmailConfig.templateId,
      'user_id': EmailConfig.publicKey,
      'template_params': {
        'email': toEmail,         // matches {{email}} in template "To Email" field
        'to_name': userName,
        'user_name': userName,    // matches {{user_name}} in body
        'otp_code': otpCode,      // matches {{otp_code}} in body
        'from_name': 'SIGAP App',
      },
    };

    debugPrint('📤 Sending to EmailJS...');
    debugPrint('   Service: ${EmailConfig.serviceId}');
    debugPrint('   Template: ${EmailConfig.templateId}');
    debugPrint('   To: $toEmail');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost',
      },
      body: jsonEncode(emailData),
    ).timeout(const Duration(seconds: 10));

    debugPrint('📬 EmailJS Response: ${response.statusCode}');
    debugPrint('📬 EmailJS Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('EmailJS error ${response.statusCode}: ${response.body}');
    }
  }

  // Clear OTP for email
  void clearOTP(String email) {
    _otpStore.remove(email);
  }

  // Check if OTP exists for email
  bool hasOTP(String email) {
    return _otpStore.containsKey(email);
  }

  // Get remaining time for OTP
  Duration? getRemainingTime(String email) {
    if (!_otpStore.containsKey(email)) return null;
    
    final timestamp = _otpStore[email]!['timestamp'] as DateTime;
    final expiryTime = timestamp.add(Duration(minutes: otpExpiryMinutes));
    final now = DateTime.now();
    
    if (now.isAfter(expiryTime)) return null;
    
    return expiryTime.difference(now);
  }
}
