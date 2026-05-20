import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, settings),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Umum ─────────────────────────────────────────────
                        _buildSectionTitle('UMUM', context),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildSwitchTile(
                            context: context,
                            icon: Icons.notifications_outlined,
                            iconColor: Theme.of(context).colorScheme.primary,
                            iconBg: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            title: 'Notifikasi',
                            subtitle: settings.notificationsEnabled
                                ? 'Notifikasi aktif'
                                : 'Notifikasi dinonaktifkan',
                            value: settings.notificationsEnabled,
                            onChanged: (val) {
                              context.read<SettingsProvider>().setNotificationsEnabled(val);
                            },
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            context: context,
                            icon: Icons.dark_mode_outlined,
                            iconColor: Theme.of(context).colorScheme.primary,
                            iconBg: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            title: 'Mode Gelap',
                            subtitle: settings.isDarkMode
                                ? 'Tema gelap aktif'
                                : 'Tema terang aktif',
                            value: settings.isDarkMode,
                            onChanged: (val) {
                              context.read<SettingsProvider>().setDarkMode(val);
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // ── Tampilan ──────────────────────────────────────────
                        _buildSectionTitle('TAMPILAN', context),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildTapTile(
                            context: context,
                            icon: Icons.text_fields,
                            title: 'Ukuran Font',
                            trailing: settings.fontSize,
                            onTap: () => _showFontSizeSelector(context, settings),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // ── Data & Penyimpanan ─────────────────────────────────
                        _buildSectionTitle('DATA & PENYIMPANAN', context),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildTapTile(
                            context: context,
                            icon: Icons.cached,
                            title: 'Hapus Cache',
                            trailing: _isClearing ? '...' : '',
                            iconColor: Theme.of(context).colorScheme.error,
                            onTap: _isClearing
                                ? null
                                : () => _showClearCacheDialog(context, settings),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // ── Tentang ───────────────────────────────────────────
                        _buildSectionTitle('TENTANG', context),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildTapTile(
                            context: context,
                            icon: Icons.info_outline,
                            title: 'Versi Aplikasi',
                            trailing: 'v2.4.0',
                            onTap: () => _showAppInfoDialog(context),
                          ),
                        ]),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, SettingsProvider settings) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.3)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.primary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Pengaturan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ),
          // Badge aktif/tidak notifikasi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: settings.notificationsEnabled
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: settings.notificationsEnabled ? AppColors.success : AppColors.error,
                  width: 0.5,
                ),
              ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: settings.notificationsEnabled ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  settings.notificationsEnabled ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    color: settings.notificationsEnabled ? AppColors.success : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).textTheme.bodySmall?.color,
        letterSpacing: 1.2,
      ),
    );
  }

  // ─── Card Container ────────────────────────────────────────────────────────
  Widget _buildCard(List<Widget> children) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(children: children),
        );
      }
    );
  }

  Widget _buildDivider() => Builder(
    builder: (context) => Container(
      height: 0.4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
    ),
  );

  // ─── Switch Tile ───────────────────────────────────────────────────────────
  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: theme.colorScheme.primary),
        ],
      ),
    );
  }

  // ─── Tap Tile ──────────────────────────────────────────────────────────────
  Widget _buildTapTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String trailing,
    required VoidCallback? onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
            ),
            if (trailing.isNotEmpty)
              Text(trailing, style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Font Size Selector ────────────────────────────────────────────────────
  void _showFontSizeSelector(BuildContext context, SettingsProvider settings) {
    final theme = Theme.of(context);
    final sizes = <Map<String, dynamic>>[
      {'label': 'Kecil',  'description': '85% ukuran normal', 'scale': 0.85},
      {'label': 'Normal', 'description': 'Ukuran default',    'scale': 1.00},
      {'label': 'Besar',  'description': '115% ukuran normal','scale': 1.15},
    ];

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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Ukuran Font',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            Text(
              'Perubahan berlaku langsung di seluruh aplikasi',
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
            ...sizes.map((size) {
              final isSelected = size['label'] == settings.fontSize;
              return InkWell(
                onTap: () {
                  settings.setFontSize(size['label'] as String);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ukuran font diubah ke ${size['label']}'),
                      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                        : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              size['label'] as String,
                              style: TextStyle(
                                fontSize: 14 * (size['scale'] as double),
                                fontWeight: FontWeight.w600,
                                color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            Text(
                              size['description'] as String,
                              style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Clear Cache Dialog ────────────────────────────────────────────────────
  void _showClearCacheDialog(BuildContext context, SettingsProvider settings) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.primary, width: 0.4),
        ),
        title: Row(
          children: [
            Icon(Icons.cached, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Text('Hapus Cache', style: TextStyle(color: theme.colorScheme.primary)),
          ],
        ),
        content: Text(
          'Hapus semua data cache aplikasi? Ini tidak akan menghapus data akun, kegiatan, atau foto Anda.',
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isClearing = true);
              await settings.clearCache();
              if (!mounted) return;
              setState(() => _isClearing = false);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Cache berhasil dihapus', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ─── App Info Dialog ───────────────────────────────────────────────────────
  void _showAppInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.primary, width: 0.4),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              'PRANATA',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Proses Anggaran lan Tata Data',
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Versi', 'v2.4.0', context),
            _buildInfoRow('Build', '2026.05', context),
            _buildInfoRow('Platform', 'Android / iOS / Web', context),
            const SizedBox(height: 12),
            Container(height: 0.5, color: theme.colorScheme.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              '© 2026 Muhammad Zuniar Hilmi.\nAll rights reserved.',
              style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }
}
