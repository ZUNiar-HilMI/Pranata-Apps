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
    final dateFormat = DateFormat('MMM dd, yyyy');

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
              child: const Icon(
                Icons.person,
                color: AppColors.goldMid,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activity.userId} • ${dateFormat.format(activity.date)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(activity.budget),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldMid,
                    ),
                  ),
                ],
              ),
            ),
            // Actions - Only show for admins on pending items
            if (isAdmin && currentStatus == 'pending') ...[
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 80,
                color: AppColors.goldMid.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _approveActivity(activity),
                    icon: const Icon(Icons.check_circle),
                    color: AppColors.success,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.success.withOpacity(0.15),
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: () => _rejectActivity(activity),
                    icon: const Icon(Icons.cancel),
                    color: AppColors.error,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.12),
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 80,
                color: AppColors.goldMid.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    activity.status == 'approved' ? Icons.check : Icons.close,
                    color: activity.status == 'approved'
                        ? AppColors.success
                        : AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
