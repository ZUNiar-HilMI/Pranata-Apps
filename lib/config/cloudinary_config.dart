import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryConfig {
  // Isi dengan Cloud Name dari Cloudinary Dashboard
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dbv7vy9ku';

  // Unsigned upload preset (Hanya untuk development / uji coba).
  // Jangan gunakan preset unsigned tanpa membatasi file type dan ukuran di dashboard.
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  // Pengaturan Signed Upload (Lebih aman untuk Produksi)
  static bool get useSignedUpload =>
      dotenv.env['CLOUDINARY_USE_SIGNED_UPLOAD']?.toLowerCase() == 'true';

  // Isi dengan API Key dari Cloudinary Dashboard (hanya diperlukan untuk signed upload)
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';

  // Folder tujuan di Cloudinary
  static String get folder => dotenv.env['CLOUDINARY_FOLDER'] ?? 'profile_photos';

  // URL backend Anda untuk meminta tanda tangan digital (signature)
  static String get signatureBaseUrl =>
      dotenv.env['CLOUDINARY_SIGNATURE_URL'] ??
          'https://your-backend-api.com/api/cloudinary-signature';

  // Upload URL
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
