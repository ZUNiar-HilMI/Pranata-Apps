import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  String _language = 'Bahasa Indonesia';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? true;
      _language = prefs.getString('language') ?? 'Bahasa Indonesia';
    });
  }

  Future<void> _saveBoolean(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Umum'),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildSwitchTile(
                        icon: Icons.notifications_outlined,
                        iconColor: AppColors.goldLight,
                        iconBg: AppColors.goldMid.withOpacity(0.15),
                        title: 'Notifikasi',
                        subtitle: 'Terima pemberitahuan aktivitas',
                        value: _notificationsEnabled,
                        onChanged: (val) {
                          setState(() => _notificationsEnabled = val);
                          _saveBoolean('notifications_enabled', val);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        iconColor: AppColors.goldLight,
                        iconBg: AppColors.goldMid.withOpacity(0.15),
                        title: 'Mode Gelap',
                        subtitle: 'Tampilan dark mode',
                        value: _darkMode,
                        onChanged: (val) {
                          setState(() => _darkMode = val);
                          _saveBoolean('dark_mode', val);
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Preferensi'),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildTapTile(
                        icon: Icons.language,
                        title: 'Bahasa',
                        trailing: _language,
                        onTap: _showLanguageSelector,
                      ),
                      _buildDivider(),
                      _buildTapTile(
                        icon: Icons.text_fields,
                        title: 'Ukuran Font',
                        trailing: 'Normal',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur ukuran font segera hadir!'),
                              backgroundColor: AppColors.navyCard,
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Data'),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildTapTile(
                        icon: Icons.cached,
                        title: 'Hapus Cache',
                        trailing: '',
                        iconColor: AppColors.error,
                        onTap: _showClearCacheDialog,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Tentang'),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildTapTile(
                        icon: Icons.info_outline,
                        title: 'Versi Aplikasi',
                        trailing: 'v2.4.0',
                        onTap: () {},
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
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        border: const Border(bottom: BorderSide(color: AppColors.goldMid, width: 0.3)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.goldLight),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'Pengaturan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.goldLight),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => Container(
    height: 0.4, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.goldMid.withOpacity(0.3));

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.goldMid),
        ],
      ),
    );
  }

  Widget _buildTapTile({
    required IconData icon,
    required String title,
    required String trailing,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
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
                color: (iconColor ?? AppColors.goldMid).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.goldLight, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            if (trailing.isNotEmpty)
              Text(trailing, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final languages = ['Bahasa Indonesia', 'English'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.navyMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.goldMid.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Bahasa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
            const SizedBox(height: 16),
            ...languages.map((lang) => ListTile(
              title: Text(
                lang,
                style: TextStyle(
                  fontWeight: lang == _language ? FontWeight.bold : FontWeight.w500,
                  color: lang == _language ? AppColors.goldLight : AppColors.textPrimary,
                ),
              ),
              trailing: lang == _language ? const Icon(Icons.check_circle, color: AppColors.goldMid) : null,
              onTap: () {
                setState(() => _language = lang);
                _saveString('language', lang);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.goldMid, width: 0.4),
        ),
        title: const Row(
          children: [
            Icon(Icons.cached, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Cache', style: TextStyle(color: AppColors.goldLight)),
          ],
        ),
        content: const Text(
          'Hapus semua data cache aplikasi? Ini tidak akan menghapus data akun Anda.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Cache berhasil dihapus'), backgroundColor: AppColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
