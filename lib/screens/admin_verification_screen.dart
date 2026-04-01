import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _storageService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveActivity(Activity activity) async {
    final updatedActivity = activity.copyWith(status: 'approved');
    await _storageService.updateActivity(updatedActivity);
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${activity.name} has been approved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectActivity(Activity activity) async {
    final updatedActivity = activity.copyWith(status: 'rejected');
    await _storageService.updateActivity(updatedActivity);
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${activity.name} has been rejected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isAdmin = currentUser?.role == 'admin';
    
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Column(
        children: [
          _buildHeader(isAdmin),
          _buildTabs(),
          _buildSummary(isAdmin, currentUser?.id),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList('pending', isAdmin, currentUser?.id),
                _buildActivityList('approved', isAdmin, currentUser?.id),
                _buildActivityList('rejected', isAdmin, currentUser?.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navyMid,
        border: Border(
          bottom: BorderSide(color: AppColors.goldMid, width: 0.3),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.goldLight),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isAdmin ? 'Verifikasi Admin' : 'Status Kegiatanku',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.goldLight),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.navyLight.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.goldMid,
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: AppColors.navyDark,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(bool isAdmin, String? userId) {
    return FutureBuilder<List<Activity>>(
      future: _storageService.getActivities(),
      builder: (context, snapshot) {
        final allActivities = snapshot.data ?? [];
        final activities = isAdmin 
            ? allActivities 
            : allActivities.where((a) => a.userId == userId).toList();
        final pendingCount = activities.where((a) => a.status == 'pending').length;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            isAdmin 
                ? '$pendingCount item menunggu review'
                : '$pendingCount kegiatan kamu pending',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityList(String status, bool isAdmin, String? userId) {
    return FutureBuilder<List<Activity>>(
      future: _storageService.getActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allActivities = (snapshot.data ?? [])
            .where((a) => a.status == status)
            .toList();
        
        // Filter by user if not admin
        final activities = isAdmin 
            ? allActivities 
            : allActivities.where((a) => a.userId == userId).toList();

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.inbox_outlined
                      : status == 'approved'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada kegiatan $status',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return _buildActivityCard(activities[index], status, isAdmin);
          },
        );
      },
    );
  }

  Widget _buildActivityCard(Activity activity, String currentStatus, bool isAdmin) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    Color statusColor;
    Color statusBgColor;
    String statusText;

    switch (activity.status) {
      case 'approved':
        statusColor = AppColors.success;
        statusBgColor = AppColors.success.withOpacity(0.15);
        statusText = 'Disetujui';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusBgColor = AppColors.error.withOpacity(0.15);
        statusText = 'Ditolak';
        break;
      default:
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warning.withOpacity(0.15);
        statusText = 'Pending';
    }

    return GestureDetector(
      onTap: () => _showActivityDetailSheet(activity, isAdmin),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.navyLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldMid.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.person, color: AppColors.goldMid, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(activity.date),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Budget
              Text(
                currencyFormat.format(activity.budget),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.goldMid),
              ),
              const SizedBox(height: 8),
              // Tap to view hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: AppColors.textSecondary.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    'Ketuk untuk lihat detail',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Activity Detail Bottom Sheet ─────────────────────────────────────────
  void _showActivityDetailSheet(Activity activity, bool isAdmin) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.navyDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: AppColors.goldMid.withOpacity(0.5),
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
                      // Header: title + status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              activity.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _statusBadge(activity.status),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Info cards
                      _detailInfoCard(
                        icon: Icons.description_outlined,
                        label: 'Deskripsi',
                        value: activity.description.isNotEmpty
                            ? activity.description
                            : '(Tidak ada deskripsi)',
                      ),
                      _detailInfoCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tanggal Kegiatan',
                        value: dateFormat.format(activity.date),
                      ),
                      _detailInfoCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Anggaran',
                        value: currencyFormat.format(activity.budget),
                        valueColor: AppColors.goldMid,
                      ),
                      _detailInfoCard(
                        icon: Icons.location_on_outlined,
                        label: 'Lokasi',
                        value: activity.location,
                      ),
                      if (activity.latitude != null && activity.longitude != null)
                        _detailInfoCard(
                          icon: Icons.map_outlined,
                          label: 'Koordinat',
                          value: '${activity.latitude!.toStringAsFixed(6)}, ${activity.longitude!.toStringAsFixed(6)}',
                        ),

                      // Photos
                      if (activity.photoBefore != null || activity.photoAfter != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'DOKUMENTASI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (activity.photoBefore != null)
                              Expanded(child: _detailPhoto(activity.photoBefore!, 'Foto Sebelum')),
                            if (activity.photoBefore != null && activity.photoAfter != null)
                              const SizedBox(width: 10),
                            if (activity.photoAfter != null)
                              Expanded(child: _detailPhoto(activity.photoAfter!, 'Foto Sesudah')),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Metadata
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.navyCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.goldMid.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(activity.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'User ID: ${activity.userId}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dinas: ${activity.dinasId}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons (admin pending only)
              if (isAdmin && activity.status == 'pending')
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: AppColors.navyMid,
                    border: Border(top: BorderSide(color: AppColors.goldMid.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _rejectActivity(activity);
                          },
                          icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                          label: const Text('Tolak', style: TextStyle(fontSize: 14, color: AppColors.error, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _approveActivity(activity);
                          },
                          icon: const Icon(Icons.check, size: 18, color: AppColors.navyDark),
                          label: const Text('Setujui', style: TextStyle(fontSize: 14, color: AppColors.navyDark, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldMid,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = AppColors.success;
        label = 'Disetujui';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Ditolak';
        break;
      default:
        color = AppColors.warning;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _detailInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldMid.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.goldMid, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? AppColors.textPrimary,
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

  Widget _detailPhoto(String url, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ClipRRect(
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
                    color: AppColors.navyCard,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.goldMid, strokeWidth: 2),
                    ),
                  ),
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.navyCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 40),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

