import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_auth_service.dart';
import '../models/user.dart';
import '../config/app_theme.dart';

class UserRoleScreen extends StatefulWidget {
  const UserRoleScreen({super.key});

  @override
  State<UserRoleScreen> createState() => _UserRoleScreenState();
}

class _UserRoleScreenState extends State<UserRoleScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'Semua'; // Semua / admin / member
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    List<User> users;
    if (currentUser != null && currentUser.isAdminDinas && currentUser.dinasId != null) {
      // Admin dinas hanya melihat user dari dinas mereka sendiri
      users = await _authService.getUsersByDinas(currentUser.dinasId!);
    } else {
      // SuperAdmin melihat semua user
      users = await _authService.getAllUsers();
    }

    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  List<User> get _filteredUsers {
    return _users.where((u) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q);
      final matchesRole =
          _roleFilter == 'Semua' || u.role == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  // ── Avatar / initials helper ───────────────────────────────────────────────
  Widget _buildAvatar(User user, {double radius = 22}) {
    final initials = user.fullName.isNotEmpty
        ? user.fullName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : user.username.substring(0, 1).toUpperCase();

    final Color color = user.role == 'admin'
        ? AppColors.goldLight
        : AppColors.success;

    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withOpacity(0.15),
        backgroundImage: NetworkImage(user.photoUrl!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.63,
        ),
      ),
    );
  }

  // ── Role chip ──────────────────────────────────────────────────────────────
  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.goldLight.withOpacity(0.12)
            : AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.shield : Icons.person,
            size: 11,
            color: isAdmin ? AppColors.goldLight : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'Admin' : 'Member',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isAdmin ? AppColors.goldLight : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ── Change role dialog ─────────────────────────────────────────────────────
  void _showChangeRoleDialog(User user) {
    String selectedRole = user.role;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.navyCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.goldMid.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ubah Role — ${user.fullName}',
                style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold,
                  color: AppColors.goldLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                user.email,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildRoleOption(
                icon: Icons.shield_outlined,
                title: 'Administrator',
                description: 'Akses penuh: verifikasi, manajemen user, laporan',
                value: 'admin',
                groupValue: selectedRole,
                onChanged: (v) => setModal(() => selectedRole = v!),
              ),
              const SizedBox(height: 12),
              _buildRoleOption(
                icon: Icons.person_outline,
                title: 'Member',
                description: 'Input kegiatan dan lihat laporan sendiri',
                value: 'member',
                groupValue: selectedRole,
                onChanged: (v) => setModal(() => selectedRole = v!),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRole == user.role
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _applyRoleChange(user, selectedRole);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyRoleChange(User user, String newRole) async {
    final success = await _authService.updateUserRole(user.email, newRole, dinasId: user.dinasId);
    if (!mounted) return;
    if (success) {
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Role ${user.fullName} diubah ke ${newRole == "admin" ? "Admin" : "Member"}'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ Gagal mengubah role'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Delete confirmation ────────────────────────────────────────────────────
  void _showDeleteDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus User', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus akun "${user.fullName}"?\nAksi ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteUser(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    await _authService.deleteUser(user.id);
    await _loadUsers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🗑️ Akun ${user.fullName} dihapus'),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Bulk delete ────────────────────────────────────────────────────────────
  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus ${_selectedIds.length} User',
          style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus ${_selectedIds.length} user terpilih? Aksi ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final count = _selectedIds.length;
              for (final id in List<String>.from(_selectedIds)) {
                await _authService.deleteUser(id);
              }
              _selectedIds.clear();
              setState(() => _isSelectionMode = false);
              await _loadUsers();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('🗑️ $count user dihapus'),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Bulk role change ───────────────────────────────────────────────────────
  void _showBulkRoleSheet() {
    String? selectedRole;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.navyCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.goldMid.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text(
                'Ubah Role ${_selectedIds.length} User',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.goldLight),
              ),
              const SizedBox(height: 24),
              _buildRoleOption(
                icon: Icons.shield_outlined,
                title: 'Administrator',
                description: 'Akses penuh',
                value: 'admin',
                groupValue: selectedRole,
                onChanged: (v) => setModal(() => selectedRole = v),
              ),
              const SizedBox(height: 12),
              _buildRoleOption(
                icon: Icons.person_outline,
                title: 'Member',
                description: 'Input kegiatan sendiri',
                value: 'member',
                groupValue: selectedRole,
                onChanged: (v) => setModal(() => selectedRole = v),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRole == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          for (final id in List<String>.from(_selectedIds)) {
                            final user = _users.firstWhere((u) => u.id == id);
                            await _authService.updateUserRole(user.email, selectedRole!);
                          }
                          _selectedIds.clear();
                          setState(() => _isSelectionMode = false);
                          await _loadUsers();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('✅ Role diubah ke ${selectedRole == "admin" ? "Admin" : "Member"}'),
                            backgroundColor: const Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                          ));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldMid,
                    disabledBackgroundColor: AppColors.navyLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Simpan', style: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── User detail sheet ──────────────────────────────────────────────────────
  void _showUserDetail(User user) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final isSelf = currentUser?.id == user.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.goldMid.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            _buildAvatar(user, radius: 36),
            const SizedBox(height: 12),
            Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.goldLight)),
            const SizedBox(height: 4),
            Text('@${user.username}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _buildRoleBadge(user.role),
            const SizedBox(height: 20),
            const Divider(),
            _infoRow(Icons.email_outlined, 'Email', user.email),
            _infoRow(Icons.calendar_today_outlined, 'Bergabung', _formatDate(user.createdAt)),
            _infoRow(Icons.badge_outlined, 'ID', user.id),
            const SizedBox(height: 20),
            if (!isSelf) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showChangeRoleDialog(user);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Ubah Role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldMid,
                    foregroundColor: AppColors.navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDeleteDialog(user);
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                  label: const Text('Hapus Akun', style: TextStyle(color: Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Color(0xFF38BDF8)),
                    SizedBox(width: 6),
                    Text('Ini adalah akun Anda yang sedang login', style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    final adminCount = _users.where((u) => u.role == 'admin').length;
    final memberCount = _users.where((u) => u.role == 'member').length;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildSearchAndFilter(),
                // Stats row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      _buildStatPill(Icons.people, '${_users.length}', 'Total', const Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      _buildStatPill(Icons.shield, '$adminCount', 'Admin', const Color(0xFFEC4899)),
                      const SizedBox(width: 8),
                      _buildStatPill(Icons.person, '$memberCount', 'Member', const Color(0xFF059669)),
                    ],
                  ),
                ),
                // User list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _loadUsers,
                              color: const Color(0xFF2563EB),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) => _buildUserCard(filtered[i]),
                              ),
                            ),
                ),
              ],
            ),

            // Bottom action bar (selection mode)
            if (_isSelectionMode && _selectedIds.isNotEmpty)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, -4))],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showBulkRoleSheet,
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text('Ubah Role (${_selectedIds.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showBulkDeleteDialog,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Hapus'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
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
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        border: const Border(bottom: BorderSide(color: AppColors.goldMid, width: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: Icon(
                _isSelectionMode ? Icons.close : Icons.chevron_left,
                color: AppColors.goldLight, size: 28,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isSelectionMode
                    ? '${_selectedIds.length} dipilih'
                    : 'Manajemen User',
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: AppColors.goldLight, letterSpacing: -0.3,
                ),
              ),
            ),
            if (!_isSelectionMode)
              TextButton.icon(
                onPressed: () => setState(() => _isSelectionMode = true),
                icon: const Icon(Icons.check_box_outline_blank, size: 16, color: AppColors.goldMid),
                label: const Text('Pilih', style: TextStyle(color: AppColors.goldMid, fontWeight: FontWeight.w600)),
              )
            else
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedIds.length == _filteredUsers.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(_filteredUsers.map((u) => u.id));
                    }
                  });
                },
                child: Text(
                  _selectedIds.length == _filteredUsers.length ? 'Hapus pilihan' : 'Pilih semua',
                  style: const TextStyle(color: AppColors.goldMid, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Search
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.navyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari nama, email, username...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() => _searchQuery = ''),
                        child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Role filter chips
          Row(
            children: ['Semua', 'admin', 'member'].map((role) {
              final isActive = _roleFilter == role;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _roleFilter = role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      role == 'admin' ? 'Admin' : role == 'member' ? 'Member' : role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final isSelected = _selectedIds.contains(user.id);
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final isSelf = currentUser?.id == user.id;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(user.id);
            } else {
              _selectedIds.add(user.id);
            }
          });
        } else {
          _showUserDetail(user);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedIds.add(user.id);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.goldMid.withOpacity(0.08)
              : AppColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.goldMid : AppColors.goldMid.withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? []
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Selection checkbox or avatar
              if (_isSelectionMode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                )
              else
                _buildAvatar(user),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Anda', style: TextStyle(fontSize: 10, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildRoleBadge(user.role),
                  if (!_isSelectionMode) ...[
                    const SizedBox(height: 6),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCBD5E1)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, size: 36, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          const Text('Tidak ada user ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F1629))),
          const SizedBox(height: 8),
          const Text('Coba ubah filter atau kata pencarian', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required IconData icon,
    required String title,
    required String description,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB).withOpacity(0.06) : const Color(0xFFF8FAFC),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB).withOpacity(0.15) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F1629))),
                  Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }
}
