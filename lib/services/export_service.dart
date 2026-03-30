import 'dart:io' as io;
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/activity.dart';

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

  // ── Load image bytes: support http URL dan local file path ─────────────────
  static Future<Uint8List?> _downloadImageBytes(String? source) async {
    if (source == null || source.isEmpty) return null;
    // blob: URL hanya valid di browser tab yang sama — tidak bisa di-download
    if (source.startsWith('blob:') || source.startsWith('data:')) return null;
    try {
      if (source.startsWith('http')) {
        // Firebase Storage URL atau URL publik lainnya
        final response = await http
            .get(Uri.parse(source))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) return response.bodyBytes;
        return null;
      } else {
        // Local file path (foto lama sebelum Firebase Storage)
        final file = io.File(source);
        if (await file.exists()) return await file.readAsBytes();
        return null;
      }
    } catch (_) {
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
    sheet.setColumnWidth(0, 6);    // No
    sheet.setColumnWidth(1, 32);   // Nama Kegiatan
    sheet.setColumnWidth(2, 14);   // Tanggal
    sheet.setColumnWidth(3, 42);   // Link Lokasi (GMaps)
    sheet.setColumnWidth(4, 20);   // Anggaran
    sheet.setColumnWidth(5, 12);   // Status
    sheet.setColumnWidth(6, 42);   // Foto Sebelum
    sheet.setColumnWidth(7, 42);   // Foto Sesudah

    // Hyperlink style (biru & underline)
    final linkStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#4FC3F7'),
      underline: Underline.Single,
      verticalAlign: VerticalAlign.Center,
    );

    // ── Data rows
    for (int i = 0; i < activities.length; i++) {
      final a = activities[i];
      final rowIndex = i + 1;

      // Buat link Google Maps jika ada koordinat, fallback ke alamat teks
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

      // Kolom teks biasa
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

      // Kolom Foto Sebelum (kolom 6)
      {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
        final photoUrl = a.photoBefore ?? '';
        cell.value = TextCellValue(photoUrl.isEmpty ? '-' : photoUrl);
        cell.cellStyle = photoUrl.isEmpty
            ? rowStyle
            : linkStyle.copyWith(
                backgroundColorHexVal: rowIndex.isEven
                    ? ExcelColor.fromHexString(_hexNavyLight)
                    : ExcelColor.fromHexString(_hexNavyMid),
              );
      }

      // Kolom Foto Sesudah (kolom 7)
      {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex));
        final photoUrl = a.photoAfter ?? '';
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

    // ── Simpan sebagai bytes dan share
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
    final pdf = pw.Document();

    final headerColor  = PdfColor.fromHex(_hexNavyDark);
    final goldColor    = PdfColor.fromHex(_hexGold);
    final oddRowColor  = PdfColor.fromHex(_hexNavyMid);
    final evenRowColor = PdfColor.fromHex(_hexNavyLight);
    final borderColor  = PdfColor.fromHex(_hexNavyBorder);
    final textColor    = PdfColor.fromHex(_hexTextLight);

    // ── Download semua foto terlebih dahulu (paralel)
    final photoBeforeBytes = await Future.wait(
      activities.map((a) => _downloadImageBytes(a.photoBefore)),
    );
    final photoAfterBytes = await Future.wait(
      activities.map((a) => _downloadImageBytes(a.photoAfter)),
    );

    // ── Halaman 1: Tabel utama
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildPdfHeader(headerColor, goldColor),
        footer: (context) => _buildPdfFooter(context, activities.length, headerColor),
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
              // Data rows with zebra striping
              ...List.generate(activities.length, (i) {
                final a = activities[i];
                final isEven = i.isEven;
                final rowBg = isEven ? evenRowColor : oddRowColor;
                // Buat link Google Maps jika ada koordinat, fallback ke alamat teks
                final String lokasiText = (a.latitude != null && a.longitude != null)
                    ? 'https://maps.google.com/?q=${a.latitude!.toStringAsFixed(6)},${a.longitude!.toStringAsFixed(6)}'
                    : a.location;
                final bool hasCoords = a.latitude != null && a.longitude != null;
                final linkColor = PdfColor.fromHex('#4FC3F7');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    // No
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text('${i + 1}', textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                    // Nama Kegiatan
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(a.name, textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                    // Tanggal
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(_dateFmt.format(a.date), textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                    // Lokasi (link GMaps)
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
                    // Anggaran
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(_currencyFmt.format(a.budget), textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontSize: 8, color: textColor)),
                    ),
                    // Status
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
          _buildPdfSummary(activities, headerColor, goldColor, textColor),
        ],
      ),
    );

    // ── Halaman 2+: Foto kegiatan (hanya jika ada foto)
    final activitiesWithPhoto = <int>[];
    for (int i = 0; i < activities.length; i++) {
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
          footer: (context) => _buildPdfFooter(context, activities.length, headerColor),
          build: (context) => [
            for (final i in activitiesWithPhoto) ...[
              _buildPhotoSection(
                activities[i],
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

    // Preview + share PDF
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
    pw.Widget _photoBox(String label, Uint8List? bytes) {
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
              _photoBox('FOTO SEBELUM', beforeBytes),
              _photoBox('FOTO SESUDAH', afterBytes),
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
