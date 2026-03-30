import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/activity.dart';
import '../../services/firestore_service.dart';
import '../../services/export_service.dart';

class GlobalReportScreen extends StatefulWidget {
  const GlobalReportScreen({super.key});

  @override
  State<GlobalReportScreen> createState() => _GlobalReportScreenState();
}

class _GlobalReportScreenState extends State<GlobalReportScreen> {
  final FirestoreService _storage = FirestoreService();
  final NumberFormat _rupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat _dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

  String _filterStatus = 'Semua';
  bool _isExporting = false;

  final _statusOptions = ['Semua', 'approved', 'pending', 'rejected'];
  final _statusLabel = {
    'Semua': 'Semua',
    'approved': 'Disetujui',
    'pending': 'Menunggu',
    'rejected': 'Ditolak',
  };
  final _statusColor = {
    'approved': AppColors.success,
    'pending': AppColors.goldMid,
    'rejected': AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<Activity>>(
                future: _storage.getActivities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.goldMid),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.error)),
                    );
                  }
                  final all = snapshot.data ?? [];
                  final filtered = _filterStatus == 'Semua'
                      ? all
                      : all.where((a) => a.status == _filterStatus).toList();
                  filtered.sort((a, b) => b.date.compareTo(a.date));

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildSummary(all)),
                      SliverToBoxAdapter(child: _buildFilterRow()),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            '${filtered.length} kegiatan ditemukan',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Text('Tidak ada data',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildActivityItem(filtered[i]),
                            childCount: filtered.length,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.navyMid,
        border: Border(bottom: BorderSide(color: AppColors.goldMid, width: 0.3)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.goldLight),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Laporan Global',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLight),
            ),
          ),
          // Export Button
          FutureBuilder<List<Activity>>(
            future: _storage.getActivities(),
            builder: (ctx, snap) {
              final approved = (snap.data ?? [])
                  .where((a) => a.status == 'approved')
                  .toList();
              return PopupMenuButton<String>(
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.goldMid, strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined,
                        color: AppColors.goldLight),
                color: AppColors.navyCard,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (type) => _export(type, approved),
                itemBuilder: (_) => [
                  _popupItem('excel', Icons.table_chart_outlined,
                      'Export Excel', AppColors.success),
                  _popupItem('pdf', Icons.picture_as_pdf_outlined,
                      'Export PDF', AppColors.error),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
      String val, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      ]),
    );
  }

  Widget _buildSummary(List<Activity> all) {
    final approved = all.where((a) => a.status == 'approved').toList();
    final pending = all.where((a) => a.status == 'pending').toList();
    final totalBudget = approved.fold(0.0, (s, a) => s + a.budget);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RINGKASAN',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Row(
            children: [
              _statCard('Total Kegiatan', '${all.length}',
                  Icons.event_note, AppColors.goldLight),
              const SizedBox(width: 10),
              _statCard('Disetujui', '${approved.length}',
                  Icons.check_circle_outline, AppColors.success),
              const SizedBox(width: 10),
              _statCard('Pending', '${pending.length}',
                  Icons.hourglass_empty, AppColors.goldMid),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.navyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldMid.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.goldMid, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Anggaran Disetujui',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    Text(
                      _rupiah.format(totalBudget),
                      style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((s) {
            final selected = _filterStatus == s;
            final color = s == 'Semua'
                ? AppColors.goldMid
                : (_statusColor[s] ?? AppColors.goldMid);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterStatus = s),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.2)
                        : AppColors.navyCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? color : AppColors.goldMid.withOpacity(0.3)),
                  ),
                  child: Text(
                    _statusLabel[s] ?? s,
                    style: TextStyle(
                        color: selected ? color : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActivityItem(Activity a) {
    final statusColor = _statusColor[a.status] ?? AppColors.textSecondary;
    final statusText = {
          'approved': 'Disetujui',
          'pending': 'Menunggu',
          'rejected': 'Ditolak',
        }[a.status] ??
        a.status;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_dateFmt.format(a.date),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.location_on_outlined,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(a.location,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _rupiah.format(a.budget),
            style: const TextStyle(
                color: AppColors.goldLight,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _export(String type, List<Activity> approved) async {
    if (approved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada kegiatan yang disetujui untuk diekspor'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _isExporting = true);
    try {
      if (type == 'excel') {
        await ExportService.exportToExcel(approved);
      } else {
        await ExportService.exportToPdf(approved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export gagal: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
