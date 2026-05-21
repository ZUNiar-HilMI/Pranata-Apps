import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: const Text('Kebijakan Privasi'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kebijakan Privasi PRANATA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aplikasi PRANATA menghargai privasi pengguna dan berkomitmen untuk melindungi data pribadi Anda.',
                style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(context, '1. Informasi yang Dikumpulkan'),
              const SizedBox(height: 8),
              _buildParagraph(context, 'Aplikasi ini mengumpulkan informasi berikut saat Anda mendaftar atau menggunakan layanan:'),
              const SizedBox(height: 8),
              _buildBullet(context, 'Nama lengkap'),
              _buildBullet(context, 'Alamat email'),
              _buildBullet(context, 'Username'),
              _buildBullet(context, 'Password untuk autentikasi Firebase Auth'),
              _buildBullet(context, 'Pilihan dinas'),
              _buildBullet(context, 'Data koordinat lokasi geografis (GPS) saat mencatat aktivitas'),
              _buildBullet(context, 'Unggahan foto Sebelum & Sesudah untuk dokumentasi kegiatan'),
              _buildBullet(context, 'Data aktivitas dan anggaran yang Anda simpan di aplikasi'),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '2. Tujuan Penggunaan Data'),
              const SizedBox(height: 8),
              _buildParagraph(context, 'Data digunakan untuk:'),
              const SizedBox(height: 8),
              _buildBullet(context, 'Memproses pendaftaran dan autentikasi pengguna secara aman'),
              _buildBullet(context, 'Menampilkan profil, laporan dinas, dan aktivitas Anda'),
              _buildBullet(context, 'Mencatat koordinat GPS kegiatan secara presisi untuk memverifikasi lokasi fisik aktivitas dinas'),
              _buildBullet(context, 'Mengunggah dan menyimpan foto dokumentasi laporan aktivitas Sebelum & Sesudah'),
              _buildBullet(context, 'Mengirimkan kode OTP untuk verifikasi akun via email'),
              _buildBullet(context, 'Mengelola preferensi serta melakukan ekspor laporan ke format Excel/PDF secara lokal'),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '3. Keamanan Data'),
              const SizedBox(height: 8),
              _buildParagraph(context, 'Kami menggunakan metode keamanan berikut untuk melindungi data Anda:'),
              const SizedBox(height: 8),
              _buildBullet(context, 'Password tidak disimpan secara langsung di Firestore.'),
              _buildBullet(context, 'Autentikasi menggunakan Firebase Auth.'),
              _buildBullet(context, 'Aturan keamanan Firestore menjaga akses data hanya untuk pengguna yang berwenang.'),
              _buildBullet(context, 'Data cache aplikasi dapat dihapus dari halaman pengaturan.'),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '4. Pihak Ketiga'),
              const SizedBox(height: 8),
              _buildParagraph(context, 'Aplikasi ini dapat bekerja dengan layanan pihak ketiga sebagai berikut:'),
              const SizedBox(height: 8),
              _buildBullet(context, 'Firebase (Authentication, Firestore)'),
              _buildBullet(context, 'Cloudinary untuk unggahan gambar'),
              _buildBullet(context, 'EmailJS atau layanan email lain untuk OTP'),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '5. Kontrol Pengguna'),
              const SizedBox(height: 8),
              _buildParagraph(context, 'Anda dapat mengelola privasi dalam aplikasi dengan cara berikut:'),
              const SizedBox(height: 8),
              _buildBullet(context, 'Mematikan notifikasi di pengaturan aplikasi'),
              _buildBullet(context, 'Menghapus cache aplikasi jika diperlukan'),
              _buildBullet(context, 'Meminta penghapusan akun atau data melalui admin jika tersedia'),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '6. Perubahan Kebijakan'),
              const SizedBox(height: 8),
              _buildParagraph(context, 'Kebijakan ini dapat diperbarui dari waktu ke waktu. Perubahan akan diumumkan dalam aplikasi atau dokumentasi terkait.'),
              const SizedBox(height: 24),

              Text(
                'Jika Anda memiliki pertanyaan mengenai privasi, silakan hubungi tim pengembang.',
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }
}
