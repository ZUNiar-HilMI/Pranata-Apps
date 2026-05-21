import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../config/app_theme.dart';
import '../config/cloudinary_config.dart';
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
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      // Tampilkan pratinjau (preview) circular dan interactive crop sebelum mengunggah
      final Uint8List? croppedBytes = await showDialog<Uint8List?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ImageAdjustDialog(imageBytes: bytes),
      );

      if (croppedBytes == null) return; // User membatalkan

      setState(() => _isUploadingPhoto = true);
      
      // Unggah menggunakan folder dari konfigurasi .env
      final url = await CloudinaryService.uploadBytes(
        croppedBytes,
        folder: CloudinaryConfig.folder,
      );

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
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        // Periksa jika error terkait Cloudinary config
        if (errorMsg.contains('upload preset tidak dikonfigurasi') || 
            errorMsg.contains('Upload preset not found')) {
          _showErrorSnackBar(
            'Gagal mengunggah foto: Upload Preset tidak ditemukan di akun Cloudinary Anda.\n'
            'Harap buat Unsigned Upload Preset bernama "${CloudinaryConfig.uploadPreset}" di Dashboard Cloudinary Anda.',
          );
        } else {
          _showErrorSnackBar('Gagal mengunggah foto: $errorMsg');
        }
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
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                  color: theme.colorScheme.primary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Galeri',
              sub: 'Pilih dari galeri foto',
              onTap: () => _pickAndUploadPhoto(ImageSource.gallery),
              theme: theme,
            ),
            const SizedBox(height: 10),
            _buildSourceTile(
              icon: Icons.camera_alt_outlined,
              label: 'Kamera',
              sub: 'Ambil foto baru',
              onTap: () => _pickAndUploadPhoto(ImageSource.camera),
              theme: theme,
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
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(sub, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user, theme),
              _buildIdentityCard(user, theme),
              _buildStatistics(user, theme),
              _buildMenuOptions(theme),
              _buildLogoutButton(context, authProvider, theme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            Color.lerp(theme.colorScheme.surface, theme.colorScheme.primary, 0.15)!,
          ],
        ),
        borderRadius: const BorderRadius.only(
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
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
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
                      icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.secondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('Profil',
                        style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Avatar with camera button ──────────────────────────────
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showPhotoSourceSheet,
                  child: Stack(
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary, width: 3),
                        ),
                        child: ClipOval(
                          child: _isUploadingPhoto
                              ? Container(
                                  color: theme.colorScheme.surface,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary, strokeWidth: 2.5),
                                  ),
                                )
                              : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                  ? Image.network(
                                      user.photoUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (ctx, child, progress) =>
                                          progress == null
                                              ? child
                                              : Container(
                                                  color: theme.colorScheme.surface,
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                        color: theme.colorScheme.primary,
                                                        strokeWidth: 2),
                                                  ),
                                                ),
                                      errorBuilder: (ctx, error, stackTrace) =>
                                          _defaultAvatar(user?.fullName, theme),
                                    )
                                  : _defaultAvatar(user?.fullName, theme),
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
                            border: Border.all(color: theme.colorScheme.surface, width: 2),
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
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: theme.colorScheme.surface, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4)
                                  ],
                                ),
                                child: Icon(Icons.camera_alt,
                                    color: theme.colorScheme.onPrimary, size: 16),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.fullName ?? 'User',
                  style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.role == 'admin' ? 'Administrator' : 'Member',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(String? name, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Text(
          (name != null && name.isNotEmpty)
              ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
              : 'U',
          style: TextStyle(
              color: theme.colorScheme.secondary, fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildIdentityCard(dynamic user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Transform.translate(
        offset: const Offset(0, -28),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12)
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.mail, 'EMAIL', user?.email ?? '-', theme),
              Container(
                  height: 0.4,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              _buildInfoRow(
                Icons.corporate_fare,
                'DEPARTEMEN',
                user?.role == 'admin' ? 'Operasional & Anggaran' : 'Member Operasional',
                theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(dynamic user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistik',
              style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          FutureBuilder<Map<String, dynamic>>(
            future: storageService.getStatistics(
                userId: user?.role == 'admin' ? null : user?.id),
            builder: (context, snapshot) {
              final stats = snapshot.data ??
                  {'totalActivities': 0, 'approvedActivities': 0};
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Aktivitas',
                      stats['totalActivities'].toString(),
                      Icons.trending_up,
                      AppColors.success,
                      '+12% bulan ini',
                      theme,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      'Disetujui',
                      stats['approvedActivities'].toString(),
                      Icons.speed,
                      theme.colorScheme.secondary,
                      'Efisiensi Tinggi',
                      theme,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String sub, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(sub,
                      style: TextStyle(
                          color: color, fontSize: 10, fontWeight: FontWeight.w600))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            _buildMenuItem(Icons.photo_camera_outlined, 'Ganti Foto Profil',
                _showPhotoSourceSheet, theme),
            _buildDivider(theme),
            _buildMenuItem(Icons.lock_outline, 'Keamanan & Password',
                _showChangePasswordSheet, theme),
            _buildDivider(theme),
            _buildMenuItem(Icons.info_outline, 'Tentang Aplikasi', _showAboutSheet, theme),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    final theme = Theme.of(context);
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
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Ganti Password',
                      style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Masukkan password lama dan password baru Anda',
                      style: TextStyle(
                          color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                  const SizedBox(height: 24),
                  _passwordField(
                    controller: currentCtrl,
                    label: 'Password Saat Ini',
                    obscure: !showCurrent,
                    toggle: () => setModal(() => showCurrent = !showCurrent),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
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
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
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
                    theme: theme,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModal(() => isLoading = true);
                              try {
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                await authProvider.changePassword(
                                  currentPassword: currentCtrl.text.trim(),
                                  newPassword: newCtrl.text.trim(),
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Password berhasil diubah!'),
                                      ]),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModal(() => isLoading = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Row(children: [
                                        const Icon(Icons.error_outline,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(e
                                                .toString()
                                                .replaceAll('Exception: ', ''))),
                                      ]),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        disabledBackgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: theme.colorScheme.onPrimary, strokeWidth: 2.5))
                          : Text('Simpan Password',
                              style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
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
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        errorStyle: TextStyle(color: theme.colorScheme.error, fontSize: 11),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: theme.textTheme.bodySmall?.color,
            size: 20,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  void _showAboutSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Icon(Icons.shield_outlined,
                  color: theme.colorScheme.secondary, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              'PRANATA',
              style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3),
            ),
            const SizedBox(height: 4),
            Text('Proses Anggaran lan Tata Data',
                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('Versi 2.4.0',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 28),
            Container(
                height: 0.5,
                color: theme.colorScheme.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DIKEMBANGKAN OLEH',
                      style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text('MZH',
                              style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Muhammad Zuniar Hilmi',
                            style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text('Mobile App Developer',
                              style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  _aboutRow(Icons.calendar_today_outlined, 'Tahun Rilis', '2026', theme),
                  const SizedBox(height: 10),
                  _aboutRow(
                      Icons.phone_android_outlined, 'Platform', 'Android & iOS', theme),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '© 2026 Muhammad Zuniar Hilmi. All rights reserved.',
              style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMenuItem(
      IconData icon, String title, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) => Container(
        height: 0.4,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: theme.colorScheme.primary.withValues(alpha: 0.25));

  Widget _buildLogoutButton(
      BuildContext context, AuthProvider authProvider, ThemeData theme) {
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
              icon: Icon(Icons.logout, color: theme.colorScheme.error, size: 20),
              label: Text('Keluar',
                  style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.error, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('VERSION 2.4.0',
              style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

// ── Dialog Penyesuaian Foto Profil Interaktif ───────────────────────────────
class ImageAdjustDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageAdjustDialog({super.key, required this.imageBytes});

  @override
  State<ImageAdjustDialog> createState() => _ImageAdjustDialogState();
}

class _ImageAdjustDialogState extends State<ImageAdjustDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  double _zoom = 1.0;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _transformController.addListener(() {
      final value = _transformController.value.getMaxScaleOnAxis();
      if (value != _zoom) {
        setState(() {
          _zoom = value.clamp(1.0, 4.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureCroppedImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sesuaikan Foto Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cubit / geser foto untuk mengatur posisi terbaik',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: Container(
                        width: 194,
                        height: 194,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black12,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          boundaryMargin: const EdgeInsets.all(100),
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.zoom_out, color: theme.textTheme.bodySmall?.color, size: 18),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 1.0,
                    max: 4.0,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    onChanged: (val) {
                      setState(() {
                        _zoom = val;
                        final double currentScale = _transformController.value.getMaxScaleOnAxis();
                        final double scaleFactor = val / currentScale;
                        _transformController.value = _transformController.value *
                            Matrix4.diagonal3Values(scaleFactor, scaleFactor, 1.0);
                      });
                    },
                  ),
                ),
                Icon(Icons.zoom_in, color: theme.textTheme.bodySmall?.color, size: 18),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final croppedBytes = await _captureCroppedImage();
                      if (context.mounted) {
                        Navigator.pop(context, croppedBytes);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      'Simpan',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
