import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/activity.dart';
import '../config/app_theme.dart';
import 'admin_verification_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final storageService = FirestoreService();
  final Set<String> _readIds = {};

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

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isAdmin),
            Expanded(
              child: FutureBuilder<List<Activity>>(
                future: _getActivities(user?.id, isAdmin),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.goldMid));
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
                    color: AppColors.goldMid,
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
                            ...groups[cat]!.map((a) => isAdmin ? _buildAdminCard(a) : _buildMemberCard(a)),
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

  Widget _buildHeader(bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        border: const Border(bottom: BorderSide(color: AppColors.goldMid, width: 0.3)),
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
                  child: const Icon(Icons.chevron_left, color: AppColors.goldLight, size: 28),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
                    if (isAdmin)
                      const Text('Kegiatan menunggu verifikasi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            if (isAdmin)
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen())),
                icon: const Icon(Icons.verified_user, size: 14, color: AppColors.goldMid),
                label: const Text('Verifikasi', style: TextStyle(color: AppColors.goldLight, fontSize: 13, fontWeight: FontWeight.w600)),
              )
            else
              TextButton(
                onPressed: () => setState(() {}),
                child: const Text('Refresh', style: TextStyle(color: AppColors.goldLight, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBanner(int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.navyDark.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.pending_actions, color: AppColors.navyDark, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$pendingCount kegiatan menunggu',
                    style: const TextStyle(color: AppColors.navyDark, fontSize: 15, fontWeight: FontWeight.bold)),
                const Text('Approve atau reject langsung dari sini',
                    style: TextStyle(color: AppColors.navyMid, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildAdminCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.goldMid.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pending_actions, color: AppColors.goldMid, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(_timeAgo(activity.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.goldMid.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.goldLight)),
                ),
              ],
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(activity.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(activity),
                    icon: const Icon(Icons.close, size: 14, color: AppColors.error),
                    label: const Text('Tolak', style: TextStyle(fontSize: 12, color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(activity),
                    icon: const Icon(Icons.check, size: 14, color: AppColors.navyDark),
                    label: const Text('Setujui', style: TextStyle(fontSize: 12, color: AppColors.navyDark)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldMid,
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
    );
  }

  Widget _buildMemberCard(Activity activity) {
    final isRead = _readIds.contains(activity.id);

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
        iconColor = AppColors.error;
        title = 'Kegiatan Ditolak ❌';
        message = '"${activity.name}" ditolak. Silakan tinjau dan ajukan ulang.';
        break;
      default:
        icon = Icons.hourglass_empty;
        iconColor = AppColors.goldMid;
        title = 'Menunggu Verifikasi ⏳';
        message = '"${activity.name}" sedang menunggu persetujuan Admin.';
    }

    return GestureDetector(
      onTap: () => setState(() => _readIds.add(activity.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isRead ? AppColors.navyMid : AppColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isRead ? AppColors.goldMid.withOpacity(0.15) : AppColors.goldMid.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: isRead ? AppColors.textSecondary : iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isRead ? AppColors.textSecondary : AppColors.textPrimary))),
                        Text(_timeAgo(activity.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(message, style: TextStyle(fontSize: 12, height: 1.5, color: isRead ? AppColors.textHint : AppColors.textSecondary)),
                  ],
                ),
              ),
              if (!isRead) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.goldMid, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAdmin) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.goldMid.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isAdmin ? Icons.verified : Icons.notifications_none, size: 40, color: AppColors.goldMid),
          ),
          const SizedBox(height: 16),
          Text(isAdmin ? 'Semua Bersih! 🎉' : 'Belum Ada Notifikasi',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
          const SizedBox(height: 8),
          Text(
            isAdmin ? 'Tidak ada kegiatan yang menunggu verifikasi.' : 'Tambahkan kegiatan untuk mulai menerima notifikasi.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
