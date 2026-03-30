import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../services/firestore_service.dart';
import '../services/export_service.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _storage = FirestoreService();

  // Export state
  bool _isExporting = false;
  String? _exportingType;

  // Month picker state for export (admin only)
  int _exportMonth = DateTime.now().month;
  int _exportYear = DateTime.now().year;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load approved activities and apply filter + search
  Future<List<Activity>> _loadApprovedActivities(String? userId, bool isAdmin) async {
    final all = isAdmin
        ? await _storage.getActivities()
        : await _storage.getActivitiesByUser(userId ?? '');

    // Filter: only approved
    var approved = all.where((a) => a.status == 'approved').toList();

    // Period filter
    final now = DateTime.now();
    if (_selectedFilter == 'Bulan Ini') {
      approved = approved
          .where((a) => a.date.year == now.year && a.date.month == now.month)
          .toList();
    } else if (_selectedFilter == 'Tahun Ini') {
      approved = approved.where((a) => a.date.year == now.year).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      approved = approved
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q) ||
              a.location.toLowerCase().contains(q))
          .toList();
    }

    // Sort newest first
    approved.sort((a, b) => b.date.compareTo(a.date));
    return approved;
  }

  String _formatRupiah(double amount) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(amount)}';
  }

  // ── Export dengan filter bulan (admin only) ─────────────────────────────────
  Future<void> _showExportMonthPicker(String type) async {
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        int tempMonth = _exportMonth;
        int tempYear = _exportYear;

        return StatefulBuilder(builder: (ctx, setModal) {
          final screenHeight = MediaQuery.of(context).size.height;
          final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
            decoration: const BoxDecoration(
              color: AppColors.navyMid,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.goldMid.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pilih Periode Export ${type.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Data yang diexport hanya kegiatan yang disetujui pada periode terpilih.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Year picker
                Row(
                  children: [
                    const Text('Tahun:', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setModal(() => tempYear--),
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.goldMid),
                    ),
                    Text(
                      '$tempYear',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setModal(() => tempYear++),
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.goldMid),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Text('Bulan:', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                const SizedBox(height: 10),

                // Month grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (i) {
                    final month = i + 1;
                    final isSelected = tempMonth == month;
                    return GestureDetector(
                      onTap: () => setModal(() => tempMonth = month),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 48 - 8 * 3) / 4,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.goldMid : AppColors.navyLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.goldLight : AppColors.goldMid.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          monthNames[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? AppColors.navyDark : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Export button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() {
                              _exportMonth = tempMonth;
                              _exportYear = tempYear;
                              _isExporting = true;
                              _exportingType = type;
                            });
                            await _runExport(type, tempMonth, tempYear);
                            if (mounted) setState(() => _isExporting = false);
                          },
                    icon: type == 'pdf'
                        ? const Icon(Icons.picture_as_pdf)
                        : const Icon(Icons.table_view),
                    label: Text(
                      'Export ${type.toUpperCase()} — ${monthNames[tempMonth - 1]} $tempYear',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type == 'pdf'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          );
        });
      },
    );
  }

  Future<void> _runExport(String type, int month, int year) async {
    try {
      // Ambil semua activities yang approved & sesuai bulan/tahun
      final all = await _storage.getActivities();
      final filtered = all
          .where((a) =>
              a.status == 'approved' &&
              a.date.month == month &&
              a.date.year == year)
          .toList();

      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tidak ada kegiatan disetujui pada periode tersebut.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      if (type == 'pdf') {
        await ExportService.exportToPdf(filtered, month: month, year: year);
      } else {
        await ExportService.exportToExcel(filtered, month: month, year: year);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export ${type.toUpperCase()} berhasil (${filtered.length} kegiatan)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<Activity>>(
              future: _loadApprovedActivities(currentUser?.id, isAdmin),
              builder: (context, snapshot) {
                final activities = snapshot.data ?? [];
                final totalBudget = activities.fold<double>(
                  0, (sum, a) => sum + a.budget,
                );
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      _buildSummaryCard(
                        totalActivities: activities.length,
                        totalBudget: totalBudget,
                        isLoading: isLoading,
                      ),

                      // Export Buttons — ADMIN ONLY
                      if (isAdmin) _buildAdminExportSection(),

                      // Search Bar
                      _buildSearchBar(),

                      // Filter Chips
                      _buildFilterChips(),

                      // Activity Log
                      _buildActivityLog(activities, isLoading),

                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyMid, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.goldMid.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.goldLight, size: 20),
                ),
              ),
              const Expanded(
                child: Text(
                  'Laporan Kegiatan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int totalActivities,
    required double totalBudget,
    required bool isLoading,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.goldDark, AppColors.goldMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldMid.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Budget Digunakan',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Disetujui',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          isLoading
              ? const SizedBox(
                  height: 36,
                  child: Center(
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  ),
                )
              : Text(
                  _formatRupiah(totalBudget),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryChip(
                Icons.assignment_turned_in_outlined,
                '$totalActivities Kegiatan',
              ),
              const SizedBox(width: 10),
              _summaryChip(
                Icons.filter_list,
                _selectedFilter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Admin Export Section ────────────────────────────────────────────────────
  Widget _buildAdminExportSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.download_outlined, color: AppColors.goldLight, size: 16),
              SizedBox(width: 6),
              Text(
                'Export Laporan',
                style: TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih format dan bulan yang ingin diexport',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: const Color(0xFFEF4444),
                  onTap: _isExporting ? null : () => _showExportMonthPicker('pdf'),
                  isLoading: _isExporting && _exportingType == 'pdf',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  icon: Icons.table_view,
                  label: 'Excel',
                  color: const Color(0xFF10B981),
                  onTap: _isExporting ? null : () => _showExportMonthPicker('excel'),
                  isLoading: _isExporting && _exportingType == 'excel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                isLoading ? 'Mengexport...' : 'Export $label',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Cari kegiatan...',
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.navyCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Bulan Ini', 'Tahun Ini'];

    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? AppColors.navyDark : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.goldMid,
              backgroundColor: AppColors.navyCard,
              checkmarkColor: AppColors.navyDark,
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : AppColors.goldMid.withOpacity(0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onSelected: (_) => setState(() => _selectedFilter = filter),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityLog(List<Activity> activities, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Kegiatan (${activities.length})',
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (activities.isNotEmpty)
                Text(
                  _formatRupiah(
                    activities.fold(0, (s, a) => s + a.budget),
                  ),
                  style: const TextStyle(
                    color: AppColors.goldMid,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (activities.isEmpty)
            _buildEmptyState()
          else
            ...activities.map((a) => _buildActivityItem(a)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.assignment_outlined,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada hasil untuk "$_searchQuery"'
                : 'Belum ada kegiatan yang disetujui',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Kegiatan yang sudah disetujui admin\nakan muncul di sini',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    final date = DateFormat('dd MMM yyyy').format(activity.date);
    final createdTime = DateFormat('HH:mm').format(activity.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$date • $createdTime',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Budget
              Text(
                _formatRupiah(activity.budget),
                style: const TextStyle(
                  color: AppColors.goldMid,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Description
          if (activity.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.navyLight),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activity.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Location
          if (activity.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activity.location,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Photos row
          if (activity.photoBefore != null || activity.photoAfter != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (activity.photoBefore != null)
                  _buildPhotoThumb(activity.photoBefore!, 'Sebelum'),
                if (activity.photoBefore != null && activity.photoAfter != null)
                  const SizedBox(width: 8),
                if (activity.photoAfter != null)
                  _buildPhotoThumb(activity.photoAfter!, 'Sesudah'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(String path, String label) {
    Widget imgWidget;

    if (kIsWeb) {
      imgWidget = Container(
        color: AppColors.navyLight,
        child: const Icon(Icons.image, color: AppColors.textSecondary),
      );
    } else {
      final file = File(path);
      imgWidget = file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : Container(
              color: AppColors.navyLight,
              child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 72, height: 56, child: imgWidget),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
