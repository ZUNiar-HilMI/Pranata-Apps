import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_activity_screen.dart';
import 'reports_screen.dart';
import 'user_role_screen.dart';
import 'login_screen.dart';
import 'admin_verification_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/activity.dart';
import '../models/user.dart';
import '../widgets/offline_banner.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../config/cloudinary_config.dart';
import '../services/cloudinary_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isSpeedDialOpen = false;
  bool _isUploadingPhoto = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  int _selectedYear = DateTime.now().year;
  // Key to force-refresh recent items after add/delete
  int _recentItemsKey = 0;

  // Notification badge
  int _notificationCount = 0;
  StreamSubscription<int>? _notifSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Subscribe to notification count
    _initNotificationBadge();
  }

  void _initNotificationBadge() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    bool hasShownPopup = false;
    final notifService = NotificationService();
    _notifSubscription = notifService
        .getUnreadCountStream(
          userId: user.id,
          isAdmin: user.isAdminDinas,
          dinasId: user.dinasId,
        )
        .listen((count) {
          if (mounted) {
            setState(() => _notificationCount = count);

            // Show popup for member when unread notifications exist
            if (count > 0 && !hasShownPopup && !user.isAdminDinas) {
              hasShownPopup = true;
              _showNotificationPopup(count);
            }
            // Reset popup flag when count drops to 0 (user read all)
            if (count == 0) hasShownPopup = false;
          }
        });
  }

  void _showNotificationPopup(int count) {
    // Small delay to let the UI settle
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Notifikasi Baru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Anda memiliki $count notifikasi yang belum dibaca',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.goldDark,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.white,
            onPressed: () async {
              final user = Provider.of<AuthProvider>(
                context,
                listen: false,
              ).currentUser;
              if (user != null) {
                await NotificationService().markNotificationsRead(user.id);
              }
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
                if (user != null) {
                  await NotificationService().markNotificationsRead(user.id);
                }
              }
            },
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _openActivityForm(String activityType) {
    // Close speed dial first
    _toggleSpeedDial();

    Future.delayed(const Duration(milliseconds: 200), () async {
      if (activityType == 'User Role') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserRoleScreen()),
        );
      } else {
        // Wait for modal result (true = activity saved)
        final result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            final th = Theme.of(context);
            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) => Container(
                decoration: BoxDecoration(
                  color: th.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: const AddActivityScreen(),
              ),
            );
          },
        );
        // If activity was saved, refresh the recent items list
        if (result == true && mounted) {
          setState(() => _recentItemsKey++);
        }
      }
    });
  }

  void _showEditTotalBudgetDialog(double currentBudget) {
    final TextEditingController budgetController = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.primary, width: 0.4),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Edit Total Anggaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan batas total anggaran baru:',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: 'Total Anggaran (IDR)',
                labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                prefixText: 'Rp ',
                prefixStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saran: Rp 1.000.000.000 (1 Miliar)',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBudget = double.tryParse(budgetController.text);
              if (newBudget != null && newBudget > 0) {
                final storageService = FirestoreService();
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await storageService.setTotalBudgetLimit(
                  newBudget,
                  dinasId: authProvider.currentUser?.isAdminDinas == true
                      ? authProvider.currentUser?.dinasId
                      : null,
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Total anggaran diperbarui ke ${_formatCurrency(newBudget)}',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Masukkan jumlah anggaran yang valid'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 2020 + 1,
      (index) => currentYear - index,
    );
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor:
            theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.primary, width: 0.4),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pilih Tahun',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    final isSelected = year == _selectedYear;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedYear = year);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              year.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.secondary
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Offline Banner (at top, above everything)
          const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),

          // Main content
          Column(
            children: [
              // Header
              _buildHeader(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final isAdmin =
                            authProvider.currentUser?.isAdminDinas ?? false;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Admin-only: pending activities banner
                            if (isAdmin) _buildAdminPendingBanner(context),
                            if (isAdmin) const SizedBox(height: 12),

                            // Statistics Cards
                            _buildStatsCards(),
                            const SizedBox(height: 16),

                            // Yearly Chart
                            _buildYearlyChart(),
                            const SizedBox(height: 16),

                            // Recent Items
                            _buildRecentItems(),
                            const SizedBox(height: 80), // Space for bottom nav
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Speed dial overlay (full screen)
          if (_isSpeedDialOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSpeedDial,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),

          // Speed dial menu items - WhatsApp style (vertikal di kanan bawah)
          if (_isSpeedDialOpen)
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  final isAdmin =
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).currentUser?.isAdminDinas ??
                      false;

                  // Jarak dari bawah untuk item pertama (paling bawah)
                  const double startBottom = 100.0;
                  // Jarak antar item
                  const double itemSpacing = 65.0;
                  // Margin dari kanan layar
                  const double rightMargin = 16.0;

                  if (isAdmin) {
                    // ADMIN popup: aksi yang TIDAK ada di footer
                    // Footer sudah punya: Home, Reports (laporan+export), Notifications, Profile
                    // Popup berisi: Input Kegiatan, Verifikasi, Kelola User
                    final items = <Map<String, dynamic>>[
                      {
                        'icon': Icons.edit_note,
                        'label': 'Input Kegiatan',
                        'color': const Color(0xFF2563EB),
                        'onTap': () => _openActivityForm('input kegiatan'),
                      },
                      {
                        'icon': Icons.verified_user,
                        'label': 'Verifikasi',
                        'color': const Color(0xFFEC4899),
                        'onTap': () {
                          _toggleSpeedDial();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminVerificationScreen(),
                            ),
                          );
                        },
                      },
                      {
                        'icon': Icons.manage_accounts,
                        'label': 'Kelola User',
                        'color': const Color(0xFFD97706),
                        'onTap': () {
                          _toggleSpeedDial();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserRoleScreen(),
                            ),
                          );
                        },
                      },
                    ];

                    return Stack(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        return Positioned(
                          bottom: startBottom + index * itemSpacing,
                          right: rightMargin,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildSpeedDialOption(
                              icon: item['icon'] as IconData,
                              label: item['label'] as String,
                              color: item['color'] as Color,
                              onTap: item['onTap'] as VoidCallback,
                            ),
                          ),
                        );
                      }),
                    );
                  } else {
                    // MEMBER: Input Kegiatan (satu-satunya aksi utama member)
                    return Stack(
                      children: [
                        Positioned(
                          bottom: startBottom,
                          right: rightMargin,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildSpeedDialOption(
                              icon: Icons.edit_note,
                              label: 'Input Kegiatan',
                              color: const Color(0xFF2563EB),
                              onTap: () => _openActivityForm('input kegiatan'),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleSpeedDial,
        backgroundColor: theme.colorScheme.primary,
        elevation: 6,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: Icon(
            _isSpeedDialOpen ? Icons.close : Icons.add,
            size: 28,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRAWER — full profile panel
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        final isAdmin = user?.isAdminDinas ?? false;
        return Drawer(
          backgroundColor: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              // ── Scrollable profile content ────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: avatar + nama + role
                      _buildDrawerProfileHeader(user, authProvider),

                      // Identity card: email + departemen
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                theme.cardTheme.color ??
                                theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDrawerInfoRow(
                                Icons.mail_outline,
                                'EMAIL',
                                user?.email ?? '-',
                                context,
                              ),
                              Container(
                                height: 0.4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                              _buildDrawerInfoRow(
                                Icons.corporate_fare,
                                'DINAS',
                                isAdmin
                                    ? DinasTheme.dinasLabel(user?.dinasId)
                                    : DinasTheme.dinasLabel(user?.dinasId),
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Statistik
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistik',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<List<Activity>>(
                              future: isAdmin
                                  ? FirestoreService().getActivities(
                                      dinasId: user?.dinasId,
                                    )
                                  : FirestoreService().getActivitiesByUser(
                                      user?.id ?? '',
                                    ),
                              builder: (context, snapshot) {
                                final all = snapshot.data ?? [];
                                final approved = all
                                    .where((a) => a.status == 'approved')
                                    .length;
                                final pending = all
                                    .where((a) => a.status == 'pending')
                                    .length;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildDrawerStatCard(
                                        'Total',
                                        all.length.toString(),
                                        Icons.list_alt,
                                        theme.colorScheme.primary,
                                        context,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildDrawerStatCard(
                                        'Disetujui',
                                        approved.toString(),
                                        Icons.check_circle_outline,
                                        theme.colorScheme.primary,
                                        context,
                                      ),
                                    ), // Assuming no specific success color in standard theme
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildDrawerStatCard(
                                        'Pending',
                                        pending.toString(),
                                        Icons.hourglass_top_outlined,
                                        (isAdmin && pending > 0)
                                            ? theme.colorScheme.error
                                            : theme.colorScheme.secondary,
                                        context,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Pengaturan Akun
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengaturan Akun',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    theme.cardTheme.color ??
                                    theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildDrawerMenuItem(
                                    Icons.photo_camera_outlined,
                                    'Ganti Foto Profil',
                                    _showPhotoSourceSheet,
                                    context,
                                  ),
                                  _drawerMenuDivider(context),
                                  _buildDrawerMenuItem(
                                    Icons.lock_outline,
                                    'Keamanan & Password',
                                    _showChangePasswordSheet,
                                    context,
                                  ),
                                  _drawerMenuDivider(context),
                                  _buildDrawerMenuItem(
                                    Icons.info_outline,
                                    'Tentang Aplikasi',
                                    _showAboutSheet,
                                    context,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Logout (fixed bottom) ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 0.3),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: Icon(
                      Icons.logout,
                      color: theme.colorScheme.error,
                      size: 18,
                    ),
                    label: Text(
                      'Keluar',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.error,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Drawer: profile header ────────────────────────────────────────────────
  Widget _buildDrawerProfileHeader(dynamic user, AuthProvider authProvider) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Avatar
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _showPhotoSourceSheet,
                    child: Stack(
                      children: [
                        Container(
                          width: 94,
                          height: 94,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _isUploadingPhoto
                                ? Container(
                                    color: theme.colorScheme.surface,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  )
                                : (user?.photoUrl != null &&
                                      user!.photoUrl!.isNotEmpty)
                                ? Image.network(
                                    user.photoUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, prog) =>
                                        prog == null
                                        ? child
                                        : Container(
                                            color: theme.colorScheme.surface,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color:
                                                    theme.colorScheme.primary,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                    errorBuilder: (ctx, error, stackTrace) =>
                                        _drawerDefaultAvatar(user?.fullName),
                                  )
                                : _drawerDefaultAvatar(user?.fullName),
                          ),
                        ),
                        if (!_isUploadingPhoto)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: theme.colorScheme.onPrimary,
                                size: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'User',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      user?.isAdminDinas == true
                          ? 'Administrator Dinas'
                          : 'Member',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drawerDefaultAvatar(String? name) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          color: theme.colorScheme.surface,
          child: Center(
            child: Text(
              (name != null && name.isNotEmpty)
                  ? name
                        .trim()
                        .split(' ')
                        .map((w) => w[0])
                        .take(2)
                        .join()
                        .toUpperCase()
                  : 'U',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerInfoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerMenuDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 0.4,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: theme.colorScheme.primary.withValues(alpha: 0.25),
    );
  }

  // ── Photo upload ──────────────────────────────────────────────────────────
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
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.updateProfilePhoto(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Foto profil berhasil diperbarui!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else if (mounted) {
        _showDrawerError('Upload gagal. Periksa koneksi internet.');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        // Periksa jika error terkait Cloudinary config
        if (errorMsg.contains('upload preset tidak dikonfigurasi') ||
            errorMsg.contains('Upload preset not found')) {
          _showDrawerError(
            'Gagal mengunggah foto: Upload Preset tidak ditemukan di akun Cloudinary Anda.\n'
            'Konfigurasi Aktif: Cloud="${CloudinaryConfig.cloudName}", Preset="${CloudinaryConfig.uploadPreset}", Folder="${CloudinaryConfig.folder}"\n'
            'Harap buat Unsigned Preset tersebut di Dashboard Cloudinary.',
          );
        } else {
          _showDrawerError(
            'Gagal mengunggah foto: $errorMsg (Cloud: "${CloudinaryConfig.cloudName}", Preset: "${CloudinaryConfig.uploadPreset}")',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showDrawerError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
                color: theme.colorScheme.secondary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildPhotoSourceTile(
              Icons.photo_library_outlined,
              'Galeri',
              'Pilih dari galeri foto',
              () => _pickAndUploadPhoto(ImageSource.gallery),
              theme,
            ),
            const SizedBox(height: 10),
            _buildPhotoSourceTile(
              Icons.camera_alt_outlined,
              'Kamera',
              'Ambil foto baru',
              () => _pickAndUploadPhoto(ImageSource.camera),
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSourceTile(
    IconData icon,
    String label,
    String sub,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
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
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Change Password ───────────────────────────────────────────────────────
  void _showChangePasswordSheet() {
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false,
        showNew = false,
        showConfirm = false,
        isLoading = false;

    final th = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: th.cardTheme.color ?? th.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                        color: th.colorScheme.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ganti Password',
                    style: TextStyle(
                      color: th.colorScheme.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masukkan password lama dan password baru Anda',
                    style: TextStyle(
                      color: th.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _drawerPasswordField(
                    controller: currentCtrl,
                    label: 'Password Saat Ini',
                    obscure: !showCurrent,
                    toggle: () => setModal(() => showCurrent = !showCurrent),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    theme: th,
                  ),
                  const SizedBox(height: 14),
                  _drawerPasswordField(
                    controller: newCtrl,
                    label: 'Password Baru',
                    obscure: !showNew,
                    toggle: () => setModal(() => showNew = !showNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (v.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                    theme: th,
                  ),
                  const SizedBox(height: 14),
                  _drawerPasswordField(
                    controller: confirmCtrl,
                    label: 'Konfirmasi Password Baru',
                    obscure: !showConfirm,
                    toggle: () => setModal(() => showConfirm = !showConfirm),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (v != newCtrl.text) return 'Password tidak cocok';
                      return null;
                    },
                    theme: th,
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
                                final auth = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                await auth.changePassword(
                                  currentPassword: currentCtrl.text.trim(),
                                  newPassword: newCtrl.text.trim(),
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Password berhasil diubah!'),
                                        ],
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModal(() => isLoading = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              e.toString().replaceAll(
                                                'Exception: ',
                                                '',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: th.colorScheme.primary,
                        disabledBackgroundColor: th.colorScheme.primary
                            .withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: th.colorScheme.onPrimary,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Simpan Password',
                              style: TextStyle(
                                color: th.colorScheme.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
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

  Widget _drawerPasswordField({
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
        labelStyle: TextStyle(
          color: theme.textTheme.bodySmall?.color,
          fontSize: 13,
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
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

  // ── About ─────────────────────────────────────────────────────────────────
  void _showAboutSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PRANATA',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Proses Anggaran lan Tata Data',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Versi 2.4.0',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 0.5,
              color: theme.colorScheme.primary.withOpacity(0.25),
            ),
            const SizedBox(height: 20),
            Text(
              '© 2026 Muhammad Zuniar Hilmi. All rights reserved.',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Admin: pending activities banner ──────────────────────────────────────
  Widget _buildAdminPendingBanner(BuildContext context) {
    final theme = Theme.of(context);
    final storageService = FirestoreService();
    return FutureBuilder<List<Activity>>(
      future: storageService.getActivities(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final pending = all.where((a) => a.status == 'pending').toList();
        if (pending.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pending_actions,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pending.length} kegiatan menunggu verifikasi',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ketuk untuk review dan verifikasi',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.textTheme.bodySmall?.color,
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dinasId = authProvider.dinasId;
    final dinasCode = DinasTheme.dinasCode(dinasId);
    final dinasLabel = DinasTheme.dinasLabel(dinasId);
    final isAdmin = authProvider.isAdminDinas;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            Color.lerp(
              theme.colorScheme.surface,
              theme.colorScheme.primary,
              0.20,
            )!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Menu button
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),

              // Center: dinas badge + title
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dinas badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dinasCode,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dinasLabel,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Year selector
              GestureDetector(
                onTap: _showYearSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedYear.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Activity>> _loadVisibleActivities(
    FirestoreService storageService,
    User? currentUser,
  ) {
    if (currentUser?.isSuperAdmin == true) {
      return storageService.getActivities();
    }

    if (currentUser?.isAdminDinas == true) {
      return currentUser?.dinasId == null
          ? Future.value(<Activity>[])
          : storageService.getActivities(dinasId: currentUser?.dinasId);
    }

    return storageService.getActivitiesByUser(currentUser?.id ?? '');
  }

  Widget _buildStatsCards() {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final storageService = FirestoreService();

    return FutureBuilder<Map<String, dynamic>>(
      future: () async {
        final activities = await _loadVisibleActivities(
          storageService,
          currentUser,
        );
        final yearlyActivities = activities
            .where((activity) => activity.date.year == _selectedYear)
            .toList();
        final usedBudget = yearlyActivities.fold<double>(
          0,
          (sum, activity) => sum + activity.budget,
        );
        final totalBudgetLimit = await storageService.getTotalBudgetLimit(
          dinasId: currentUser?.isAdminDinas == true
              ? currentUser?.dinasId
              : null,
        );
        return {
          'totalActivities': yearlyActivities.length,
          'totalBudget': usedBudget,
          'pendingActivities': yearlyActivities
              .where((activity) => activity.status == 'pending')
              .length,
          'approvedActivities': yearlyActivities
              .where((activity) => activity.status == 'approved')
              .length,
          'totalBudgetLimit': totalBudgetLimit,
        };
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingStatsCards();
        }

        final data =
            snapshot.data ??
            {
              'totalActivities': 0,
              'totalBudget': 0.0,
              'pendingActivities': 0,
              'approvedActivities': 0,
              'totalBudgetLimit': 1000000000.0,
            };

        final totalActivities = data['totalActivities'] as int;
        final totalBudget = data['totalBudget'] as double;
        final totalBudgetLimit = data['totalBudgetLimit'] as double;

        final usedBudget = totalBudget;
        final remainingBudget = totalBudgetLimit - usedBudget;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          padding: EdgeInsets.zero,
          children: [
            _buildStatCard(
              context: context,
              icon: Icons.list_alt,
              label: 'Total Aktivitas',
              value: totalActivities.toString(),
              color: Theme.of(context).colorScheme.primary,
              bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            ),
            GestureDetector(
              onTap: currentUser?.isAdminDinas == true
                  ? () => _showEditTotalBudgetDialog(totalBudgetLimit)
                  : null,
              child: _buildStatCard(
                context: context,
                icon: Icons.attach_money,
                label: currentUser?.isAdminDinas == true
                    ? 'Total Budget (Tap)'
                    : 'Total Budget',
                value: _formatCurrency(totalBudgetLimit),
                color: Theme.of(context).colorScheme.primary,
                bgColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.15),
              ),
            ),
            _buildStatCard(
              context: context,
              icon: Icons.pie_chart,
              label: 'Budget Terpakai',
              value: _formatCurrency(usedBudget),
              color: Theme.of(context).colorScheme.primary,
              bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            ),
            _buildStatCard(
              context: context,
              icon: Icons.account_balance_wallet,
              label: 'Sisa Budget',
              value: _formatCurrency(remainingBudget),
              color: Theme.of(context).colorScheme.primary,
              bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              isHighlight: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      padding: EdgeInsets.zero,
      children: [
        Builder(
          builder: (context) => _buildStatCard(
            context: context,
            icon: Icons.list_alt,
            label: 'Total Aktivitas',
            value: '...',
            color: Theme.of(context).colorScheme.primary,
            bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          ),
        ),
        Builder(
          builder: (context) => _buildStatCard(
            context: context,
            icon: Icons.attach_money,
            label: 'Total Budget',
            value: '...',
            color: Theme.of(context).colorScheme.primary,
            bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          ),
        ),
        Builder(
          builder: (context) => _buildStatCard(
            context: context,
            icon: Icons.pie_chart,
            label: 'Budget Terpakai',
            value: '...',
            color: Theme.of(context).colorScheme.primary,
            bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          ),
        ),
        Builder(
          builder: (context) => _buildStatCard(
            context: context,
            icon: Icons.account_balance_wallet,
            label: 'Sisa Budget',
            value: '...',
            color: Theme.of(context).colorScheme.primary,
            bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            isHighlight: true,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(2)}B';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight
            ? theme.colorScheme.primary.withOpacity(0.2)
            : theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(
            isHighlight ? 0.5 : 0.25,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isHighlight ? theme.colorScheme.surface : bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyChart() {
    final theme = Theme.of(context);
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final storageService = FirestoreService();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Tahunan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Jan - Des $_selectedYear',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.more_horiz, color: theme.iconTheme.color),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<double>>(
            future: storageService.getMonthlyBudget(
              userId: currentUser?.isAdminDinas == true
                  ? null
                  : currentUser?.id,
              dinasId: currentUser?.isAdminDinas == true
                  ? currentUser?.dinasId
                  : null,
              year: _selectedYear,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 130,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final monthlyBudgets =
                  snapshot.data ?? List<double>.filled(12, 0.0);
              final maxBudget = monthlyBudgets.reduce((a, b) => a > b ? a : b);

              // Calculate heights as ratio of max (avoid division by zero)
              final heights = monthlyBudgets.map((budget) {
                if (maxBudget == 0) return 0.0;
                return budget / maxBudget;
              }).toList();

              return SizedBox(
                height: 130,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 100 * heights[index],
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              months[index],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRecentItems() {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final storageService = FirestoreService();

    return FutureBuilder<List<Activity>>(
      key: ValueKey(_recentItemsKey),
      future: currentUser?.isAdminDinas == true
          ? storageService.getActivities(dinasId: currentUser?.dinasId)
          : storageService.getActivitiesByUser(currentUser?.id ?? ''),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];
        // Show last 5 activities, newest first
        final recent = activities.reversed.take(5).toList();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kegiatan Terbaru',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 40,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada kegiatan',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recent.map(
                (activity) => _buildActivityCard(activity, storageService),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(
    Activity activity,
    FirestoreService storageService,
  ) {
    final theme = Theme.of(context);
    final statusColor = activity.status == 'approved'
        ? theme
              .colorScheme
              .primary // Using primary to represent success dynamically or keeping specific colors
        : activity.status == 'rejected'
        ? theme.colorScheme.error
        : theme.colorScheme.secondary;
    final statusIcon = activity.status == 'approved'
        ? Icons.check_circle_outline
        : activity.status == 'rejected'
        ? Icons.cancel_outlined
        : Icons.hourglass_empty;

    return Dismissible(
      key: Key(activity.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Hapus Kegiatan?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Yakin ingin menghapus "${activity.name}"?',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) async {
        await storageService.deleteActivity(activity.id);
        if (mounted) {
          setState(() => _recentItemsKey++);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${activity.name}" dihapus'),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Lihat',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activity.date.day}/${activity.date.month}/${activity.date.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${activity.budget.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    activity.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
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

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.analytics_outlined, 'Reports', 1),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(
              Icons.notifications_outlined,
              'Notifications',
              2,
              badgeCount: _notificationCount,
            ),
            _buildNavItem(Icons.settings_outlined, 'Settings', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () async {
        if (index == 1) {
          // Navigate to Reports screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsScreen()),
          );
        } else if (index == 2) {
          // Navigate to Notifications screen & mark as read
          final user = Provider.of<AuthProvider>(
            context,
            listen: false,
          ).currentUser;
          if (user != null) {
            await NotificationService().markNotificationsRead(user.id);
          }
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
            // Re-mark as read when returning (in case new notifs came while viewing)
            if (user != null) {
              await NotificationService().markNotificationsRead(user.id);
            }
          }
        } else if (index == 3) {
          // Navigate to Settings screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
                size: 24,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onError,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label pill di sebelah kiri
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Ikon lingkaran berwarna di sebelah kanan
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}
