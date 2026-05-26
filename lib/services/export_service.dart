import 'dart:io' as io;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart'; // ← TAMBAHAN
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/activity.dart';
import '../config/api_config.dart';

class ExportService {
  // ── Warna tema (terpusat) ────────────────────────────────────────────────────
  static const _hexNavyDark   = '#0F1629';
  static const _hexNavyMid    = '#152237';
  static const _hexNavyLight  = '#1A2E47';
  static const _hexNavyBorder = '#1E3A5F';
  static const _hexGold       = '#E8C97A';
  static const _hexTextLight  = '#F5E6C8';

  static final _currencyFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  // ── [PERBAIKAN] Re-fetch aktivitas dari Firestore server (bukan cache) ──────
  // Dipanggil sebelum export agar URL foto Cloudinary pasti sudah ada,
  // terutama di Android yang sering membaca dari cache lokal.
  static Future<List<Activity>> _fetchFreshActivities(
    List<Activity> activities,
  ) async {
    if (activities.isEmpty || ApiConfig.useCustomBackend) return activities;

    try {
      // Ambil semua ID dari list yang dikirim
      final ids = activities.map((a) => a.id).whereType<String>().toList();
      if (ids.isEmpty) return activities;

      // Firestore hanya bisa where-in max 10 item, batch jika perlu
      final List<Activity> freshList = [];
      for (int i = 0; i < ids.length; i += 10) {
        final batchIds = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final snapshot = await FirebaseFirestore.instance
            .collection('activities') // sesuaikan nama collection Anda
            .where(FieldPath.documentId, whereIn: batchIds)
            .get(const GetOptions(source: Source.server)); // ← paksa dari server

        for (final doc in snapshot.docs) {
          final data = doc.data();
          freshList.add(Activity(
            id: doc.id,
            name: data['name'] as String,
            description: data['description'] as String,
            budget: (data['budget'] as num).toDouble(),
            date: (data['date'] as Timestamp).toDate(),
            location: data['location'] as String,
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
            photoBefore: data['photoBefore'] as String?,
            photoAfter: data['photoAfter'] as String?,
            userId: data['userId'] as String,
            dinasId: data['dinasId'] as String? ?? '',
            status: data['status'] as String? ?? 'pending',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }

      // Kembalikan dalam urutan yang sama dengan input
      final freshMap = {for (final a in freshList) a.id: a};
      return activities.map((a) => freshMap[a.id] ?? a).toList();
    } catch (e) {
      // Jika gagal fetch (misal offline), tetap gunakan data lama
      return activities;
    }
  }

  // ── Load image bytes: support http URL dan local file path ─────────────────
  static Future<Uint8List?> _downloadImageBytes(String? source) async {
    if (source == null || source.isEmpty) {
      debugPrint('📷 _downloadImageBytes: source is empty or null');
      return null;
    }
    if (source.startsWith('blob:') || source.startsWith('data:')) {
      debugPrint('📷 _downloadImageBytes: ignoring blob/data URI');
      return null;
    }
    try {
      if (source.startsWith('http')) {
        debugPrint('📷 _downloadImageBytes: downloading from HTTP URL: $source');
        final response = await http
            .get(Uri.parse(source))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          debugPrint('📷 _downloadImageBytes: download successful, bytes size: ${response.bodyBytes.length}');
          return response.bodyBytes;
        }
        debugPrint('📷 _downloadImageBytes: download failed with status code: ${response.statusCode}');
        return null;
      } else {
        debugPrint('📷 _downloadImageBytes: reading from local file path: $source');
        final file = io.File(source);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          debugPrint('📷 _downloadImageBytes: local read successful, bytes size: ${bytes.length}');
          return bytes;
        }
        debugPrint('📷 _downloadImageBytes: local file does not exist');
        return null;
      }
    } catch (e) {
      debugPrint('📷 _downloadImageBytes error: $e');
      return null;
    }
  }

  // ── Excel Export ─────────────────────────────────────────────────────────────
  static Future<void> exportToExcel(
    List<Activity> activities, {
    int? month,
    int? year,
  }) async {
    await initializeDateFormatting('id_ID', null);

    // ── [PERBAIKAN] Ambil data fresh dari Firestore sebelum mulai export ──────
    final freshActivities = await _fetchFreshActivities(activities);

    final excel = Excel.createExcel();
    final sheetName = 'Laporan Kegiatan';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    // ── Header styling
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString(_hexNavyDark),
      fontColorHex: ExcelColor.fromHexString(_hexGold),
    );

    final headers = [
      'No', 'Nama Kegiatan', 'Tanggal', 'Lokasi',
      'Anggaran', 'Status',
      'Foto Sebelum', 'Foto Sesudah',
    ];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Set column widths
    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 32);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 42);
    sheet.setColumnWidth(4, 20);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 42);
    sheet.setColumnWidth(7, 42);

    // Hyperlink style
    final linkStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#4FC3F7'),
      underline: Underline.Single,
      verticalAlign: VerticalAlign.Center,
    );

    // ── Data rows — gunakan freshActivities ───────────────────────────────────
    for (int i = 0; i < freshActivities.length; i++) {
      final a = freshActivities[i]; // ← pakai data fresh
      final rowIndex = i + 1;

      final String gmapsLink = (a.latitude != null && a.longitude != null)
          ? 'https://maps.google.com/?q=${a.latitude!.toStringAsFixed(6)},${a.longitude!.toStringAsFixed(6)}'
          : a.location;

      final rowStyle = CellStyle(
        backgroundColorHex: rowIndex.isEven
            ? ExcelColor.fromHexString(_hexNavyLight)
            : ExcelColor.fromHexString(_hexNavyMid),
        fontColorHex: ExcelColor.fromHexString(_hexTextLight),
        verticalAlign: VerticalAlign.Center,
      );

      final textData = [
        (0, TextCellValue((i + 1).toString())),
        (1, TextCellValue(a.name)),
        (2, TextCellValue(_dateFmt.format(a.date))),
        (4, TextCellValue(_currencyFmt.format(a.budget))),
        (5, TextCellValue(_statusLabel(a.status))),
      ];
      for (final (col, val) in textData) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
        cell.value = val;
        cell.cellStyle = rowStyle;
      }

      // Kolom link Google Maps (kolom 3)
      {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        cell.value = TextCellValue(gmapsLink);
        cell.cellStyle = (a.latitude != null && a.longitude != null)
            ? linkStyle.copyWith(
                backgroundColorHexVal: rowIndex.isEven
                    ? ExcelColor.fromHexString(_hexNavyLight)
                    : ExcelColor.fromHexString(_hexNavyMid),
              )
            : rowStyle;
      }

      // ── [PERBAIKAN] Kolom Foto Sebelum (kolom 6) ─────────────────────────
      // Sekarang a.photoBefore sudah fresh dari Firestore server
      {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
        final photoUrl = (a.photoBefore ?? '').trim();
        cell.value = TextCellValue(photoUrl.isEmpty ? '-' : photoUrl);
        cell.cellStyle = photoUrl.isEmpty
            ? rowStyle
            : linkStyle.copyWith(
                backgroundColorHexVal: rowIndex.isEven
                    ? ExcelColor.fromHexString(_hexNavyLight)
                    : ExcelColor.fromHexString(_hexNavyMid),
              );
      }

      // ── [PERBAIKAN] Kolom Foto Sesudah (kolom 7) ─────────────────────────
      {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex));
        final photoUrl = (a.photoAfter ?? '').trim();
        cell.value = TextCellValue(photoUrl.isEmpty ? '-' : photoUrl);
        cell.cellStyle = photoUrl.isEmpty
            ? rowStyle
            : linkStyle.copyWith(
                backgroundColorHexVal: rowIndex.isEven
                    ? ExcelColor.fromHexString(_hexNavyLight)
                    : ExcelColor.fromHexString(_hexNavyMid),
              );
      }
    }

    // ── Simpan dan share
    final bytes = excel.save();
    if (bytes == null) throw Exception('Gagal membuat file Excel');

    final bulanExcel = DateFormat('MMMM', 'id_ID').format(
        DateTime(year ?? DateTime.now().year, month ?? DateTime.now().month));
    final tahunExcel = year ?? DateTime.now().year;
    final fileName = 'Laporan_${bulanExcel}_$tahunExcel.xlsx';

    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: fileName,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: 'Laporan $bulanExcel $tahunExcel',
    );
  }

  // ── PDF Export ──────────────────────────────────────────────────────────────
  static Future<void> exportToPdf(
    List<Activity> activities, {
    int? month,
    int? year,
  }) async {
    await initializeDateFormatting('id_ID', null);

    // ── [PERBAIKAN] Ambil data fresh dari Firestore sebelum mulai export ──────
    final freshActivities = await _fetchFreshActivities(activities);

    final pdf = pw.Document();

    final headerColor  = PdfColor.fromHex(_hexNavyDark);
    final goldColor    = PdfColor.fromHex(_hexGold);
    final oddRowColor  = PdfColor.fromHex(_hexNavyMid);
    final evenRowColor = PdfColor.fromHex(_hexNavyLight);
    final borderColor  = PdfColor.fromHex(_hexNavyBorder);
    final textColor    = PdfColor.fromHex(_hexTextLight);

    // ── Download semua foto (paralel) — dari freshActivities ─────────────────
    final photoBeforeBytes = await Future.wait(
      freshActivities.map((a) => _downloadImageBytes(a.photoBefore)),
    );
    final photoAfterBytes = await Future.wait(
      freshActivities.map((a) => _downloadImageBytes(a.photoAfter)),
    );

    // ── Halaman 1: Tabel utama
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildPdfHeader(headerColor, goldColor),
        footer: (context) => _buildPdfFooter(context, freshActivities.length, headerColor),
        build: (context) => [
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FixedColumnWidth(62),
              3: const pw.FlexColumnWidth(3.5),
              4: const pw.FixedColumnWidth(80),
              5: const pw.FixedColumnWidth(58),
            },
            border: pw.TableBorder(
              bottom: pw.BorderSide(color: borderColor, width: 0.5),
              horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
            ),
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: headerColor),
                children: [
                  for (final h in ['No', 'Nama Kegiatan', 'Tanggal', 'Lokasi', 'Anggaran', 'Status'])
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                      child: pw.Text(
                        h,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: goldColor,
                          fontSize: 9,
                        ),
                      ),
                    ),
                ],
              ),
              // Data rows
              ...List.generate(freshActivities.length, (i) {
                final a = freshActivities[i];
                final isEven = i.isEven;
                final rowBg = isEven ? evenRowColor : oddRowColor;
                final String lokasiText = (a.latitude != null && a.longitude != null)
                    ? 'https://maps.google.com/?q=${a.latitude!.toStringAsFixed(6)},${a.longitude!.toStringAsFixed(6)}'
                    : a.location;
                final bool hasCoords = a.latitude != null && a.longitude != null;
                final linkColor = PdfColor.fromHex('#4FC3F7');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text('${i + 1}', textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(a.name, textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(_dateFmt.format(a.date), textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.UrlLink(
                        destination: hasCoords
                            ? 'https://maps.google.com/?q=${a.latitude!.toStringAsFixed(6)},${a.longitude!.toStringAsFixed(6)}'
                            : '',
                        child: pw.Text(
                          lokasiText,
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: hasCoords ? linkColor : textColor,
                            decoration: hasCoords ? pw.TextDecoration.underline : pw.TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(_currencyFmt.format(a.budget), textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(_statusLabel(a.status), textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildPdfSummary(freshActivities, headerColor, goldColor, textColor),
        ],
      ),
    );

    // ── Halaman foto
    final activitiesWithPhoto = <int>[];
    for (int i = 0; i < freshActivities.length; i++) {
      if (photoBeforeBytes[i] != null || photoAfterBytes[i] != null) {
        activitiesWithPhoto.add(i);
      }
    }

    if (activitiesWithPhoto.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => _buildPdfHeader(headerColor, goldColor, subtitle: 'Dokumentasi Foto'),
          footer: (context) => _buildPdfFooter(context, freshActivities.length, headerColor),
          build: (context) => [
            for (final i in activitiesWithPhoto) ...[
              _buildPhotoSection(
                freshActivities[i],
                i + 1,
                photoBeforeBytes[i],
                photoAfterBytes[i],
                headerColor,
                goldColor,
                textColor,
                borderColor,
              ),
              pw.SizedBox(height: 12),
            ],
          ],
        ),
      );
    }

    final bulanPdf = DateFormat('MMMM', 'id_ID').format(
        DateTime(year ?? DateTime.now().year, month ?? DateTime.now().month));
    final tahunPdf = year ?? DateTime.now().year;
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_${bulanPdf}_$tahunPdf',
    );
  }

  // ── PDF Header ──────────────────────────────────────────────────────────────
  static pw.Widget _buildPdfHeader(
    PdfColor headerColor,
    PdfColor goldColor, {
    String subtitle = 'Proses Anggaran lan Tata Data (PRANATA)',
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN KEGIATAN',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: headerColor,
                  ),
                ),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(fontSize: 10, color: headerColor),
                ),
              ],
            ),
            pw.Text(
              'Dicetak: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: headerColor),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: goldColor, thickness: 1.5),
        pw.SizedBox(height: 8),
      ],
    );
  }

  // ── PDF Footer ──────────────────────────────────────────────────────────────
  static pw.Widget _buildPdfFooter(
    pw.Context context,
    int totalActivities,
    PdfColor headerColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Total: $totalActivities kegiatan',
          style: pw.TextStyle(fontSize: 9, color: headerColor),
        ),
        pw.Text(
          'Halaman ${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 9, color: headerColor),
        ),
      ],
    );
  }

  // ── Foto section per kegiatan ────────────────────────────────────────────────
  static pw.Widget _buildPhotoSection(
    Activity activity,
    int no,
    Uint8List? beforeBytes,
    Uint8List? afterBytes,
    PdfColor headerColor,
    PdfColor goldColor,
    PdfColor textColor,
    PdfColor borderColor,
  ) {
    pw.Widget photoBox(String label, Uint8List? bytes) {
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(color: headerColor),
                child: pw.Text(
                  label,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: goldColor,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              if (bytes != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(
                    pw.MemoryImage(bytes),
                    height: 140,
                    fit: pw.BoxFit.contain,
                  ),
                )
              else
                pw.Container(
                  height: 140,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Tidak ada foto',
                    style: pw.TextStyle(color: textColor, fontSize: 8),
                  ),
                ),
              pw.SizedBox(height: 4),
            ],
          ),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex(_hexNavyMid),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$no. ${activity.name} — ${_dateFmt.format(activity.date)}',
            style: pw.TextStyle(
              color: goldColor,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              photoBox('FOTO SEBELUM', beforeBytes),
              photoBox('FOTO SESUDAH', afterBytes),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary row di PDF ──────────────────────────────────────────────────────
  static pw.Widget _buildPdfSummary(
    List<Activity> activities,
    PdfColor headerColor,
    PdfColor goldColor,
    PdfColor textColor,
  ) {
    final total = activities.fold<double>(0.0, (sum, a) => sum + a.budget);
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: headerColor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TOTAL ANGGARAN KEGIATAN',
            style: pw.TextStyle(
              color: goldColor,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
          pw.Text(
            _currencyFmt.format(total),
            style: pw.TextStyle(
              color: goldColor,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper ──────────────────────────────────────────────────────────────────
  static String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'pending':
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}