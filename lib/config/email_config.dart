import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailConfig {
  // EmailJS Service Configuration
  // Jangan taruh kunci publik/email service yang sensitif di kode produksi.
  // Untuk produksi, gunakan backend yang aman jika memungkinkan.
  static String get serviceId => dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
  static String get templateId => dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
  static String get publicKey => dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';
  
  // Email Settings
  static String get fromName => dotenv.env['EMAIL_FROM_NAME'] ?? 'SIGAP App';
  static String get fromEmail => dotenv.env['EMAIL_FROM_ADDRESS'] ?? 'noreply@sigap.app';
  
  // EmailJS API Endpoint
  static const String apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  
  // Template Variables
  static const String userNameVar = 'user_name';
  static const String otpCodeVar = 'otp_code';
  static const String toEmailVar = 'to_email';
}
