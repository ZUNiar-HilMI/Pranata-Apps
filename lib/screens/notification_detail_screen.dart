import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../config/app_theme.dart';

/// Halaman detail satu notifikasi.
/// Menampilkan seluruh informasi kegiatan yang terkait dengan notifikasi tersebut.
class NotificationDetailScreen extends StatelessWidget {
  final Activity activity;
  final bool isAdmin;

  const NotificationDetailScreen({
    super.key,
    required this.activity,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt    = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFmt    = DateFormat('dd MMM yyyy, HH:mm');

    final (icon, color, badgeLabel, badgeBg) = _statusMeta(activity.status);

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(context, icon, color, badgeLabel, badgeBg),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul kegiatan
                    Text(
                      activity.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeFmt.format(activity.createdAt),
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 20),

                    // Info cards
                    _infoCard(context, Icons.description_outlined, 'Deskripsi',
                        activity.description.isNotEmpty ? activity.description : '(Tidak ada deskripsi)'),
                    _infoCard(context, Icons.calendar_today_outlined, 'Tanggal Kegiatan',
                        dateFmt.format(activity.date)),
                    _infoCard(context, Icons.account_balance_wallet_outlined, 'Anggaran',
                        currencyFmt.format(activity.budget),
                        valueColor: theme.colorScheme.primary),
                    _infoCard(context, Icons.location_on_outlined, 'Lokasi', activity.location),
                    if (activity.latitude != null && activity.longitude != null)
                      _infoCard(context, Icons.my_location_outlined, 'Koordinat GPS',
                          '${activity.latitude!.toStringAsFixed(6)}, ${activity.longitude!.toStringAsFixed(6)}'),

                    // Foto dokumentasi
                    if (activity.photoBefore != null || activity.photoAfter != null) ...[
                      const SizedBox(height: 8),
                      Text('DOKUMENTASI',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodySmall?.color,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (activity.photoBefore != null)
                            Expanded(child: _photoCard(context, activity.photoBefore!, 'Foto Sebelum')),
                          if (activity.photoBefore != null && activity.photoAfter != null)
                            const SizedBox(width: 10),
                          if (activity.photoAfter != null)
                            Expanded(child: _photoCard(context, activity.photoAfter!, 'Foto Sesudah')),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Meta info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dibuat: ${timeFmt.format(activity.createdAt)}',
                              style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                          if (isAdmin) ...[
                            const SizedBox(height: 4),
                            Text('User ID: ${activity.userId}',
                                style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header dengan status badge ──────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    IconData icon,
    Color color,
    String badgeLabel,
    Color badgeBg,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), theme.colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
      child: Row(
        children: [
          // Tombol kembali
          IconButton(
            icon: Icon(Icons.chevron_left, color: theme.colorScheme.primary, size: 28),
            onPressed: () => Navigator.pop(context),
          ),

          // Ikon status
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // Judul & badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Notifikasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card ───────────────────────────────────────────────────────────
  Widget _infoCard(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? theme.textTheme.bodyLarge?.color,
                    fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo card ──────────────────────────────────────────────────────────
  Widget _photoCard(BuildContext context, String url, String label) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showFullScreenPhoto(context, url, label),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 160,
                          color: theme.cardTheme.color ?? theme.colorScheme.surface,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: theme.colorScheme.primary, strokeWidth: 2),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: theme.textTheme.bodySmall?.color, size: 40),
                          const SizedBox(height: 6),
                          Text('Gagal memuat gambar',
                              style: TextStyle(
                                  fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Tap to view hint overlay
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, color: Colors.white, size: 14),
                      SizedBox(width: 3),
                      Text('Perbesar',
                          style: TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullScreenPhoto(BuildContext context, String url, String label) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                  errorBuilder: (_, __, ___) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, color: Colors.white54, size: 60),
                      SizedBox(height: 12),
                      Text('Gagal memuat gambar',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status metadata ─────────────────────────────────────────────────────
  (IconData, Color, String, Color) _statusMeta(String status) {
    switch (status) {
      case 'approved':
        return (Icons.check_circle, AppColors.success, 'Disetujui ✅',
            AppColors.success.withValues(alpha: 0.15));
      case 'rejected':
        return (Icons.cancel, AppColors.error, 'Ditolak ❌',
            AppColors.error.withValues(alpha: 0.15));
      default:
        // pending — use a neutral amber/orange that is visible in both themes
        return (Icons.hourglass_empty, const Color(0xFFD97706), 'Menunggu Verifikasi ⏳',
            const Color(0xFFD97706).withValues(alpha: 0.12));
    }
  }
}
