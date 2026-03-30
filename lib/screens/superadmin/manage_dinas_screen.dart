import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/dinas.dart';
import '../../services/firestore_service.dart';

class ManageDinasScreen extends StatefulWidget {
  const ManageDinasScreen({super.key});

  @override
  State<ManageDinasScreen> createState() => _ManageDinasScreenState();
}

class _ManageDinasScreenState extends State<ManageDinasScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        title: const Text('Kelola Dinas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.goldMid,
        foregroundColor: AppColors.navyDark,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Dinas'),
        onPressed: _showAddDinasDialog,
      ),
      body: StreamBuilder<List<Dinas>>(
        stream: _firestoreService.dinasStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.apartment, color: AppColors.textSecondary, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada dinas',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          final dinasList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: dinasList.length,
            itemBuilder: (ctx, i) => _buildDinasCard(dinasList[i]),
          );
        },
      ),
    );
  }

  // ─── Dinas Card ──────────────────────────────────────────────────────────────
  Widget _buildDinasCard(Dinas dinas) {
    final accent = DinasTheme.primaryAccent(dinas.id);
    final cardBg = DinasTheme.cardBg(dinas.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.4), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent, width: 0.5),
                  ),
                  child: Text(
                    dinas.code,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.goldLight, size: 20),
                  onPressed: () => _showEditDinasDialog(dinas),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDelete(dinas),
                  tooltip: 'Hapus',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dinas.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dinas.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.fingerprint, color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ID: ${dinas.id}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Add Dialog ──────────────────────────────────────────────────────────────
  void _showAddDinasDialog() {
    _idController.clear();
    _nameController.clear();
    _codeController.clear();
    _descController.clear();

    _openDinasDialog(
      title: 'Tambah Dinas Baru',
      showIdField: true,
      onSave: (formKey) async {
        if (!formKey.currentState!.validate()) return;
        final dinas = Dinas(
          id: _idController.text.trim().toLowerCase().replaceAll(' ', '_'),
          name: _nameController.text.trim(),
          code: _codeController.text.trim().toUpperCase(),
          description: _descController.text.trim(),
          createdAt: DateTime.now(),
        );
        await _firestoreService.createDinas(dinas);
        if (mounted) {
          Navigator.pop(context);
          _showSnack('Dinas berhasil ditambahkan!');
        }
      },
    );
  }

  // ─── Edit Dialog ─────────────────────────────────────────────────────────────
  void _showEditDinasDialog(Dinas dinas) {
    _nameController.text = dinas.name;
    _codeController.text = dinas.code;
    _descController.text = dinas.description;

    _openDinasDialog(
      title: 'Edit ${dinas.code}',
      showIdField: false,
      onSave: (formKey) async {
        if (!formKey.currentState!.validate()) return;
        final updated = dinas.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().toUpperCase(),
          description: _descController.text.trim(),
        );
        await _firestoreService.updateDinas(updated);
        if (mounted) {
          Navigator.pop(context);
          _showSnack('Dinas berhasil diperbarui!');
        }
      },
    );
  }

  // ─── Generic open-dialog helper ──────────────────────────────────────────────
  void _openDinasDialog({
    required String title,
    required bool showIdField,
    required Future<void> Function(GlobalKey<FormState> formKey) onSave,
  }) {
    // Buat GlobalKey baru tiap dialog agar state tidak bocor
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(title, style: const TextStyle(color: AppColors.goldLight)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIdField) ...[
                  TextFormField(
                    controller: _idController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'ID Dinas',
                      hintText: 'contoh: dinas_perkim',
                      prefixIcon: const Icon(Icons.fingerprint),
                      hintStyle: TextStyle(color: AppColors.textHint),
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'ID wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap Dinas',
                    prefixIcon: const Icon(Icons.apartment),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Kode Dinas',
                    hintText: 'contoh: PERKIM',
                    prefixIcon: const Icon(Icons.badge),
                    hintStyle: TextStyle(color: AppColors.textHint),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Kode wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    prefixIcon: const Icon(Icons.description),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => onSave(formKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldMid,
              foregroundColor: AppColors.navyDark,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ─── Confirm Delete ───────────────────────────────────────────────────────────
  void _confirmDelete(Dinas dinas) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        title: const Text('Hapus Dinas', style: TextStyle(color: AppColors.goldLight)),
        content: Text(
          'Yakin ingin menghapus "${dinas.name}"?\n\nData kegiatan yang terkait tidak akan terhapus.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await _firestoreService.deleteDinas(dinas.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _showSnack('Dinas "${dinas.name}" dihapus.');
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
