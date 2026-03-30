import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/dinas.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../screens/superadmin/manage_dinas_screen.dart';
import '../../screens/superadmin/manage_users_screen.dart';
import '../../screens/superadmin/global_report_screen.dart';
import '../login_screen.dart';
import '../settings_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.goldDark, AppColors.goldMid],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SUPER ADMIN',
                style: TextStyle(
                  color: AppColors.navyDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.goldLight),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Yakin ingin keluar?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Greeting Card ────────────────────────────────────────
            _buildGreetingCard(user.fullName),
            const SizedBox(height: 20),

            // ─── Stats Global ─────────────────────────────────────────
            _buildGlobalStats(context),
            const SizedBox(height: 20),

            // ─── Dinas Cards ──────────────────────────────────────────
            Row(
              children: const [
                Icon(Icons.apartment, color: AppColors.goldLight, size: 20),
                SizedBox(width: 8),
                Text(
                  'Dinas Aktif',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDinasGrid(context),
            const SizedBox(height: 20),

            // ─── Menu SuperAdmin ──────────────────────────────────────
            Row(
              children: const [
                Icon(Icons.admin_panel_settings, color: AppColors.goldLight, size: 20),
                SizedBox(width: 8),
                Text(
                  'Kelola Sistem',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMenuGrid(context),
          ],
        ),
      ),
    );
  }

  // ─── Greeting Card ─────────────────────────────────────────────────────────
  Widget _buildGreetingCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyLight, AppColors.navyCard],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldMid, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.goldLight, AppColors.goldDark],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: AppColors.navyDark, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Super Administrator',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Global Stats ──────────────────────────────────────────────────────────
  Widget _buildGlobalStats(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = FirebaseAuthService();

    return FutureBuilder(
      future: Future.wait([
        firestoreService.getStatistics(),
        authService.getAllUsers(),
        firestoreService.getDinasList(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        final stats = snapshot.data?[0] as Map<String, dynamic>? ?? {};
        final users = snapshot.data?[1] as List? ?? [];
        final dinasList = snapshot.data?[2] as List? ?? [];

        return Row(
          children: [
            _statCard('Total Kegiatan', '${stats['totalActivities'] ?? 0}', Icons.event_note, AppColors.goldLight),
            const SizedBox(width: 10),
            _statCard('Total Dinas', '${dinasList.length}', Icons.apartment, const Color(0xFF00B4D8)),
            const SizedBox(width: 10),
            _statCard('Total User', '${users.length}', Icons.people, const Color(0xFF52B788)),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dinas Grid ────────────────────────────────────────────────────────────
  Widget _buildDinasGrid(BuildContext context) {
    final firestoreService = FirestoreService();
    return StreamBuilder<List<Dinas>>(
      stream: firestoreService.dinasStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final dinasList = snapshot.data!;
        return Column(
          children: dinasList.map((dinas) => _buildDinasCard(context, dinas)).toList(),
        );
      },
    );
  }

  Widget _buildDinasCard(BuildContext context, Dinas dinas) {
    final accent = DinasTheme.primaryAccent(dinas.id);
    final cardBg = DinasTheme.cardBg(dinas.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {}, // bisa navigate ke detail dinas
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.4), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      DinasTheme.dinasCode(dinas.id),
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dinas.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dinas.description,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Aktif',
                    style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Menu Grid ─────────────────────────────────────────────────────────────
  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _menuCard(
          context,
          icon: Icons.apartment,
          label: 'Kelola Dinas',
          color: const Color(0xFF00B4D8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageDinasScreen()),
          ),
        ),
        _menuCard(
          context,
          icon: Icons.people,
          label: 'Kelola User',
          color: const Color(0xFF52B788),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
          ),
        ),
        _menuCard(
          context,
          icon: Icons.bar_chart,
          label: 'Laporan Global',
          color: AppColors.goldMid,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GlobalReportScreen()),
          ),
        ),
        _menuCard(
          context,
          icon: Icons.settings,
          label: 'Pengaturan',
          color: AppColors.textSecondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _menuCard(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.navyCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
