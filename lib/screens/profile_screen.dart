import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../config/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storageService = FirestoreService();
  bool _isUploadingPhoto = false;

  // ── Pick & upload photo ────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    Navigator.pop(context); // dismiss bottom sheet

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return; // user cancelled

    setState(() => _isUploadingPhoto = true);
    try {
      // Read bytes directly from XFile — works on all platforms
      final bytes = await picked.readAsBytes();
      debugPrint('📷 Picked image: ${picked.name}, size: ${(bytes.length / 1024).toStringAsFixed(1)}KB');

      final url = await CloudinaryService.uploadBytes(bytes, folder: 'profile_photos');
      debugPrint('✅ Upload result: $url');

      if (url != null && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.updateProfilePhoto(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Foto profil berhasil diperbarui!'),
              ]),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else if (mounted) {
        _showErrorSnackBar('Upload gagal. Periksa koneksi internet.');
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (mounted) {
        _showErrorSnackBar('Gagal mengunggah foto: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


  // ── Bottom sheet: pilih sumber foto ───────────────────────────────────────
  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.goldMid.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(color: AppColors.goldLight, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Galeri',
              sub: 'Pilih dari galeri foto',
              onTap: () => _pickAndUploadPhoto(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _buildSourceTile(
              icon: Icons.camera_alt_outlined,
              label: 'Kamera',
              sub: 'Ambil foto baru',
              onTap: () => _pickAndUploadPhoto(ImageSource.camera),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTile({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.navyMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.goldMid.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.goldMid.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.goldMid, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user),
              _buildIdentityCard(user),
              _buildStatistics(user),
              _buildMenuOptions(),
              _buildLogoutButton(context, authProvider),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyMid, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.goldMid.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 56),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.goldLight),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Profil', style: TextStyle(color: AppColors.goldLight, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Avatar with camera button ──────────────────────────────
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showPhotoSourceSheet,
                  child: Stack(
                    children: [
                      // Avatar circle
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.goldMid, width: 3),
                        ),
                        child: ClipOval(
                          child: _isUploadingPhoto
                              ? Container(
                                  color: AppColors.navyMid,
                                  child: const Center(
                                    child: CircularProgressIndicator(color: AppColors.goldMid, strokeWidth: 2.5),
                                  ),
                                )
                              : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                  ? Image.network(
                                      user.photoUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (ctx, child, progress) => progress == null
                                          ? child
                                          : Container(
                                              color: AppColors.navyMid,
                                              child: const Center(
                                                child: CircularProgressIndicator(color: AppColors.goldMid, strokeWidth: 2),
                                              ),
                                            ),
                                      errorBuilder: (ctx, _, __) => _defaultAvatar(user?.fullName),
                                    )
                                  : _defaultAvatar(user?.fullName),
                        ),
                      ),
                      // Online indicator
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.navyMid, width: 2),
                          ),
                        ),
                      ),
                      // Camera icon overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _isUploadingPhoto
                            ? const SizedBox.shrink()
                            : Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.goldMid,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.navyMid, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                                ),
                                child: const Icon(Icons.camera_alt, color: AppColors.navyDark, size: 16),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.role == 'admin' ? 'Administrator' : 'Member',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(String? name) {
    return Container(
      color: AppColors.navyMid,
      child: Center(
        child: Text(
          (name != null && name.isNotEmpty)
              ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
              : 'U',
          style: const TextStyle(color: AppColors.goldLight, fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildIdentityCard(user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Transform.translate(
        offset: const Offset(0, -28),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.goldMid.withOpacity(0.35)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.mail, 'EMAIL', user?.email ?? '-'),
              Container(height: 0.4, margin: const EdgeInsets.symmetric(horizontal: 20), color: AppColors.goldMid.withOpacity(0.3)),
              _buildInfoRow(Icons.corporate_fare, 'DEPARTEMEN', user?.role == 'admin' ? 'Operasional & Anggaran' : 'Member Operasional'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldMid.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.goldMid, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statistik', style: TextStyle(color: AppColors.goldLight, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          FutureBuilder<Map<String, dynamic>>(
            future: storageService.getStatistics(userId: user?.role == 'admin' ? null : user?.id),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {'totalActivities': 0, 'approvedActivities': 0};
              return Row(
                children: [
                  Expanded(child: _buildStatCard('Aktivitas', stats['totalActivities'].toString(), Icons.trending_up, AppColors.success, '+12% bulan ini')),
                  const SizedBox(width: 14),
                  Expanded(child: _buildStatCard('Disetujui', stats['approvedActivities'].toString(), Icons.speed, AppColors.goldLight, 'Efisiensi Tinggi')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: AppColors.goldLight, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(child: Text(sub, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            _buildMenuItem(Icons.photo_camera_outlined, 'Ganti Foto Profil', _showPhotoSourceSheet),
            _buildDivider(),
            _buildMenuItem(Icons.lock_outline, 'Keamanan & Password', _showChangePasswordSheet),
            _buildDivider(),
            _buildMenuItem(Icons.info_outline, 'Tentang Aplikasi', _showAboutSheet),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.navyCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.goldMid.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ganti Password',
                    style: TextStyle(color: AppColors.goldLight, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masukkan password lama dan password baru Anda',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  // Current password
                  _passwordField(
                    controller: currentCtrl,
                    label: 'Password Saat Ini',
                    obscure: !showCurrent,
                    toggle: () => setModal(() => showCurrent = !showCurrent),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  // New password
                  _passwordField(
                    controller: newCtrl,
                    label: 'Password Baru',
                    obscure: !showNew,
                    toggle: () => setModal(() => showNew = !showNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (v.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // Confirm new password
                  _passwordField(
                    controller: confirmCtrl,
                    label: 'Konfirmasi Password Baru',
                    obscure: !showConfirm,
                    toggle: () => setModal(() => showConfirm = !showConfirm),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (v != newCtrl.text) return 'Password tidak cocok';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModal(() => isLoading = true);
                        try {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.changePassword(
                            currentPassword: currentCtrl.text.trim(),
                            newPassword: newCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Password berhasil diubah!'),
                                ]),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          setModal(() => isLoading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
                                ]),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldMid,
                        disabledBackgroundColor: AppColors.navyLight,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(color: AppColors.navyDark, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Simpan Password',
                              style: TextStyle(color: AppColors.navyDark, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.navyMid,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.goldMid.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.goldMid.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.goldMid, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.goldMid.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            // App icon area
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navyMid, AppColors.navyLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldMid, width: 2),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.goldLight, size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'PRANATA',
              style: TextStyle(
                color: AppColors.goldLight,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Proses Anggaran lan Tata Data',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldMid.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Versi 2.4.0',
                style: TextStyle(color: AppColors.goldMid, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 28),
            // Divider
            Container(height: 0.5, color: AppColors.goldMid.withOpacity(0.25)),
            const SizedBox(height: 24),
            // Credit section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navyMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.goldMid.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DIKEMBANGKAN OLEH',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.goldMid.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.goldMid.withOpacity(0.4)),
                        ),
                        child: const Center(
                          child: Text('MZH', style: TextStyle(color: AppColors.goldLight, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Muhammad Zuniar Hilmi',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mobile App Developer',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Info section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navyMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.goldMid.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  _aboutRow(Icons.calendar_today_outlined, 'Tahun Rilis', '2026'),
                  const SizedBox(height: 10),
                  _aboutRow(Icons.phone_android_outlined, 'Platform', 'Android & iOS'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '© 2026 Muhammad Zuniar Hilmi. All rights reserved.',
              style: TextStyle(color: AppColors.textHint, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.goldMid),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.goldMid, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(height: 0.4, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.goldMid.withOpacity(0.25));

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
              label: const Text('Keluar', style: TextStyle(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('VERSION 2.4.0', style: TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
