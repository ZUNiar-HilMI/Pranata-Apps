import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user.dart';
import '../../models/dinas.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  List<User> _allUsers = [];
  List<Dinas> _dinasList = [];
  bool _isLoading = true;

  // Filter
  String _filterRole = 'all';   // 'all' | 'superadmin' | 'admin' | 'member'
  String? _filterDinas;         // null = semua dinas
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await _authService.getAllUsers();
    final dinas = await _firestoreService.getDinasList();
    setState(() {
      _allUsers = users;
      _dinasList = dinas;
      _isLoading = false;
    });
  }

  List<User> get _filteredUsers {
    final roleFilter = ['all', 'superadmin', 'admin'][_tabController.index];
    return _allUsers.where((u) {
      // Tab filter
      if (roleFilter == 'superadmin' && !u.isSuperAdmin) return false;
      if (roleFilter == 'admin' && !u.isAdminDinas) return false;
      if (roleFilter == 'all' && u.isSuperAdmin) return false; // 'all' = member only in that tab? 
      // Actually: Tab 0 = Member, Tab 1 = Admin, Tab 2 = SuperAdmin
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!u.fullName.toLowerCase().contains(q) &&
            !u.username.toLowerCase().contains(q) &&
            !u.email.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  // Correct mapping for tab → role
  List<User> _getUsersForTab(int tabIndex) {
    return _allUsers.where((u) {
      bool roleMatch;
      if (tabIndex == 0) roleMatch = u.isMember;
      else if (tabIndex == 1) roleMatch = u.isAdminDinas;
      else roleMatch = u.isSuperAdmin;

      if (!roleMatch) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!u.fullName.toLowerCase().contains(q) &&
            !u.username.toLowerCase().contains(q) &&
            !u.email.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = _allUsers.where((u) => u.isMember).length;
    final adminCount = _allUsers.where((u) => u.isAdminDinas).length;
    final superAdminCount = _allUsers.where((u) => u.isSuperAdmin).length;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        title: const Text('Kelola User'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: AppColors.goldLight,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.goldMid,
          tabs: [
            Tab(text: 'Member ($memberCount)'),
            Tab(text: 'Admin ($adminCount)'),
            Tab(text: 'Super ($superAdminCount)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Search Bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari nama, username, atau email...',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.goldMid, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.navyCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.goldMid, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.goldMid, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.goldLight, width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ─── User List ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserList(_getUsersForTab(0)),
                      _buildUserList(_getUsersForTab(1)),
                      _buildUserList(_getUsersForTab(2)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─── User List ─────────────────────────────────────────────────────────────
  Widget _buildUserList(List<User> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, color: AppColors.textSecondary, size: 56),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'Tidak ditemukan' : 'Belum ada user',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: users.length,
        itemBuilder: (ctx, i) => _buildUserCard(users[i]),
      ),
    );
  }

  // ─── User Card ─────────────────────────────────────────────────────────────
  Widget _buildUserCard(User user) {
    final accent = DinasTheme.primaryAccent(user.dinasId);
    final dinasLabel = DinasTheme.dinasLabel(user.dinasId);
    final initials = user.fullName.trim().split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.25), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── Avatar ─────────────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.8), accent.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: user.photoUrl != null
                    ? ClipOval(
                        child: Image.network(user.photoUrl!, fit: BoxFit.cover, width: 48, height: 48),
                      )
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _roleBadge(user),
                      const SizedBox(width: 6),
                      if (user.dinasId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accent.withOpacity(0.4), width: 0.5),
                          ),
                          child: Text(
                            DinasTheme.dinasCode(user.dinasId),
                            style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Actions ────────────────────────────────────────────────
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.goldLight, size: 20),
              tooltip: 'Edit Role & Dinas',
              onPressed: () => _showEditDialog(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(User user) {
    Color color;
    String label;
    if (user.isSuperAdmin) {
      color = AppColors.goldMid;
      label = 'SuperAdmin';
    } else if (user.isAdminDinas) {
      color = const Color(0xFF00B4D8);
      label = 'Admin';
    } else {
      color = AppColors.textSecondary;
      label = 'Member';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ─── Edit Dialog ───────────────────────────────────────────────────────────
  void _showEditDialog(User user) {
    String selectedRole = user.role;
    String? selectedDinasId = user.dinasId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            backgroundColor: AppColors.navyMid,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 16),
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Role Picker ─────────────────────────────────────────
                const Text('Role', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                _buildRoleSelector(selectedRole, (r) {
                  setDlgState(() {
                    selectedRole = r;
                    // Jika superadmin, hapus dinasId
                    if (r == 'superadmin') selectedDinasId = null;
                  });
                }),
                const SizedBox(height: 16),

                // ── Dinas Picker (hanya untuk admin & member) ───────────
                if (selectedRole != 'superadmin') ...[
                  const Text('Dinas', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButton<String?>(
                    value: selectedDinasId,
                    isExpanded: true,
                    dropdownColor: AppColors.navyCard,
                    underline: Container(height: 0.5, color: AppColors.goldMid),
                    hint: const Text('Pilih dinas', style: TextStyle(color: AppColors.textHint)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— Tidak ada —', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ..._dinasList.map((d) {
                        final accent = DinasTheme.primaryAccent(d.id);
                        return DropdownMenuItem<String?>(
                          value: d.id,
                          child: Text(
                            '${d.code} – ${d.name}',
                            style: TextStyle(
                              color: DinasTheme.primaryAccent(d.id),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) => setDlgState(() => selectedDinasId = v),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _saveUserChanges(user, selectedRole, selectedDinasId);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleSelector(String current, void Function(String) onChanged) {
    final roles = [
      ('member', 'Member', AppColors.textSecondary),
      ('admin', 'Admin Dinas', const Color(0xFF00B4D8)),
      ('superadmin', 'Super Admin', AppColors.goldMid),
    ];

    return Row(
      children: roles.map((r) {
        final (value, label, color) = r;
        final isSelected = current == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppColors.navyCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : AppColors.goldMid.withOpacity(0.3),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveUserChanges(User user, String newRole, String? newDinasId) async {
    try {
      await _authService.updateUserRole(user.email, newRole, dinasId: newDinasId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} berhasil diperbarui!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
