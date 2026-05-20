import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/activity.dart';
import '../config/app_theme.dart';
import 'admin_verification_screen.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final storageService = FirestoreService();
  final Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    // Mark notifications as read when screen opens
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      NotificationService().markNotificationsRead(user.id);
    }
  }

  Future<List<Activity>> _getActivities(String? userId, bool isAdmin) async {
    if (isAdmin) {
      final all = await storageService.getActivities();
      return all.where((a) => a.status == 'pending').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      final all = await storageService.getActivitiesByUser(userId ?? '');
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inHours < 1) return '${d.inMinutes} menit lalu';
    if (d.inDays < 1) return '${d.inHours} jam lalu';
    if (d.inDays == 1) return 'Kemarin';
    if (d.inDays < 7) return '${d.inDays} hari lalu';
    return '${(d.inDays / 7).floor()} minggu lalu';
  }

  String _timeCategory(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays == 0) return 'Hari Ini';
    if (d.inDays == 1) return 'Kemarin';
    return 'Lebih Lama';
  }

  Future<void> _handleApprove(Activity activity) async {
    await storageService.updateActivityStatus(activity.id, 'approved');
    setState(() {});
  }

  Future<void> _handleReject(Activity activity) async {
    await storageService.updateActivityStatus(activity.id, 'rejected');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final isAdmin = user?.role == 'admin';

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isAdmin, context),
            Expanded(
              child: FutureBuilder<List<Activity>>(
                future: _getActivities(user?.id, isAdmin),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                  }
                  final activities = snapshot.data ?? [];
                  if (activities.isEmpty) return _buildEmptyState(isAdmin);

                  final groups = <String, List<Activity>>{
                    'Hari Ini': [],
                    'Kemarin': [],
                    'Lebih Lama': [],
                  };
                  for (var a in activities) {
                    groups[_timeCategory(a.createdAt)]?.add(a);
                  }

                  return RefreshIndicator(
                    color: theme.colorScheme.primary,
                    onRefresh: () async => setState(() {}),
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (isAdmin) ...[
                          _buildAdminBanner(activities.length),
                          const SizedBox(height: 12),
                        ],
                        for (final cat in ['Hari Ini', 'Kemarin', 'Lebih Lama'])
                          if (groups[cat]!.isNotEmpty) ...[
                            _buildSectionHeader(cat),
                            ...groups[cat]!.map((a) => isAdmin ? _buildAdminCard(a, context) : _buildMemberCard(a, context)),
                          ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAdmin, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.chevron_left, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary),
                    ),
                    if (isAdmin)
                      Text('Kegiatan menunggu verifikasi',
                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                  ],
                ),
              ],
            ),
            if (isAdmin)
              TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminVerificationScreen())),
                icon: Icon(Icons.verified_user, size: 14, color: theme.colorScheme.secondary),
                label: Text(
                  'Verifikasi',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              )
            else
              TextButton(
                onPressed: () => setState(() {}),
                child: Text('Refresh',
                    style: TextStyle(
                        color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBanner(int pendingCount) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle),
                child: Icon(Icons.pending_actions, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$pendingCount kegiatan menunggu',
                        style: TextStyle(
                            color: theme.colorScheme.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('Approve atau reject langsung dari sini',
                        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall?.color,
              letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildAdminCard(Activity activity, BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = activity.photoBefore != null || activity.photoAfter != null;
    final photoUrl = activity.photoBefore ?? activity.photoAfter;

    return GestureDetector(
      onTap: () => _showActivityDetailSheet(activity),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Thumbnail jika ada foto
                  if (hasPhoto && photoUrl != null)
                    _buildThumbnail(photoUrl, theme)
                  else
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.pending_actions, color: theme.colorScheme.primary, size: 20),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.name,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(_timeAgo(activity.createdAt),
                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('Pending',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary)),
                  ),
                ],
              ),
              if (activity.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(activity.description,
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              // Foto preview strip jika ada lebih dari 1 foto
              if (activity.photoBefore != null && activity.photoAfter != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPhotoStrip(activity.photoBefore!, 'Sebelum', theme),
                    const SizedBox(width: 6),
                    _buildPhotoStrip(activity.photoAfter!, 'Sesudah', theme),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showActivityDetailSheet(activity),
                      icon: Icon(Icons.visibility_outlined,
                          size: 14, color: theme.colorScheme.primary),
                      label: Text('Detail',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReject(activity),
                      icon: Icon(Icons.close, size: 14, color: theme.colorScheme.error),
                      label: Text('Tolak',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.error)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleApprove(activity),
                      icon: Icon(Icons.check, size: 14, color: theme.colorScheme.onPrimary),
                      label: Text('Setujui',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimary)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thumbnail kecil (38x38) untuk kartu notifikasi
  Widget _buildThumbnail(String url, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: theme.colorScheme.primary, strokeWidth: 2),
                    ),
                  ),
                ),
          errorBuilder: (_, __, ___) => Container(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(Icons.image_not_supported_outlined,
                color: theme.colorScheme.primary, size: 18),
          ),
        ),
      ),
    );
  }

  /// Strip foto dengan label (untuk preview 2 foto sebelum/sesudah)
  Widget _buildPhotoStrip(String url, String label, ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                color: theme.colorScheme.primary, strokeWidth: 1.5),
                          ),
                        ),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.broken_image_outlined,
                      color: theme.textTheme.bodySmall?.color, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity Detail Bottom Sheet ─────────────────────────────────────────
  void _showActivityDetailSheet(Activity activity) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          activity.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _detailInfoCard(
                            Icons.description_outlined,
                            'Deskripsi',
                            activity.description.isNotEmpty
                                ? activity.description
                                : '(Tidak ada deskripsi)',
                            ctx),
                        _detailInfoCard(Icons.calendar_today_outlined, 'Tanggal Kegiatan',
                            dateFormat.format(activity.date), ctx),
                        _detailInfoCard(
                            Icons.account_balance_wallet_outlined,
                            'Anggaran',
                            currencyFormat.format(activity.budget),
                            ctx,
                            valueColor: theme.colorScheme.primary),
                        _detailInfoCard(
                            Icons.location_on_outlined, 'Lokasi', activity.location, ctx),
                        if (activity.latitude != null && activity.longitude != null)
                          _detailInfoCard(
                              Icons.map_outlined,
                              'Koordinat',
                              '${activity.latitude!.toStringAsFixed(6)}, ${activity.longitude!.toStringAsFixed(6)}',
                              ctx),

                        // Photos
                        if (activity.photoBefore != null || activity.photoAfter != null) ...[
                          const SizedBox(height: 16),
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
                                Expanded(
                                    child: _detailPhoto(
                                        activity.photoBefore!, 'Foto Sebelum', ctx)),
                              if (activity.photoBefore != null && activity.photoAfter != null)
                                const SizedBox(width: 10),
                              if (activity.photoAfter != null)
                                Expanded(
                                    child:
                                        _detailPhoto(activity.photoAfter!, 'Foto Sesudah', ctx)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(activity.createdAt)}',
                                  style: TextStyle(
                                      fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                              const SizedBox(height: 4),
                              Text('User ID: ${activity.userId}',
                                  style: TextStyle(
                                      fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Bottom action buttons
                if (activity.status == 'pending')
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        20, 12, 20, MediaQuery.of(ctx).padding.bottom + 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                          top: BorderSide(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleReject(activity);
                            },
                            icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
                            label: Text('Tolak',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleApprove(activity);
                            },
                            icon: Icon(Icons.check,
                                size: 18, color: theme.colorScheme.onPrimary),
                            label: Text('Setujui',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailInfoCard(IconData icon, String label, String value, BuildContext context,
      {Color? valueColor}) {
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
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      fontSize: 14,
                      color: valueColor ?? theme.textTheme.bodyLarge?.color,
                      fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPhoto(String url, String label, BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showFullScreenPhoto(url, label),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) => progress == null
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
                          color: theme.textTheme.bodySmall?.color, size: 36),
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
        ),
      ],
    );
  }

  void _showFullScreenPhoto(String url, String label) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen image
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                  errorBuilder: (_, __, ___) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image_outlined,
                          color: Colors.white54, size: 60),
                      const SizedBox(height: 12),
                      const Text('Gagal memuat gambar',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
            // Label + close button
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

  Widget _buildMemberCard(Activity activity, BuildContext context) {
    final theme = Theme.of(context);
    final isRead = _readIds.contains(activity.id);
    final hasPhoto = activity.photoBefore != null || activity.photoAfter != null;
    final photoUrl = activity.photoBefore ?? activity.photoAfter;

    IconData icon;
    Color iconColor;
    String title, message;

    switch (activity.status) {
      case 'approved':
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        title = 'Kegiatan Disetujui ✅';
        message = '"${activity.name}" telah disetujui oleh Admin.';
        break;
      case 'rejected':
        icon = Icons.cancel;
        iconColor = theme.colorScheme.error;
        title = 'Kegiatan Ditolak ❌';
        message = '"${activity.name}" ditolak. Silakan tinjau dan ajukan ulang.';
        break;
      default:
        icon = Icons.hourglass_empty;
        iconColor = theme.colorScheme.secondary;
        title = 'Menunggu Verifikasi ⏳';
        message = '"${activity.name}" sedang menunggu persetujuan Admin.';
    }

    return GestureDetector(
      onTap: () async {
        // Tandai lokal sebagai read (feedback visual instan)
        setState(() => _readIds.add(activity.id));

        // Navigasi ke halaman detail
        final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailScreen(activity: activity),
          ),
        );

        // Setelah kembali dari detail, mark as read agar badge hilang
        if (user != null && mounted) {
          await NotificationService().markNotificationsRead(user.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isRead
              ? theme.scaffoldBackgroundColor
              : (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isRead
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration:
                        BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(icon,
                        color: isRead ? theme.textTheme.bodySmall?.color : iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(title,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isRead
                                          ? theme.textTheme.bodySmall?.color
                                          : theme.textTheme.bodyLarge?.color)),
                            ),
                            Text(_timeAgo(activity.createdAt),
                                style: TextStyle(
                                    fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(message,
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: isRead
                                    ? (theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
                                        Colors.grey)
                                    : theme.textTheme.bodySmall?.color)),
                      ],
                    ),
                  ),
                  if (!isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
              // Thumbnail foto jika ada
              if (hasPhoto && photoUrl != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (activity.photoBefore != null)
                      Expanded(
                          child: _buildPhotoStrip(activity.photoBefore!, 'Sebelum', theme)),
                    if (activity.photoBefore != null && activity.photoAfter != null)
                      const SizedBox(width: 6),
                    if (activity.photoAfter != null)
                      Expanded(
                          child: _buildPhotoStrip(activity.photoAfter!, 'Sesudah', theme)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAdmin) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(isAdmin ? Icons.verified : Icons.notifications_none,
                    size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                isAdmin ? 'Semua Bersih! 🎉' : 'Belum Ada Notifikasi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                isAdmin
                    ? 'Tidak ada kegiatan yang menunggu verifikasi.'
                    : 'Tambahkan kegiatan untuk mulai menerima notifikasi.',
                style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
