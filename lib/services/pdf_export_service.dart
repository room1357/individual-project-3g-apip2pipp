// lib/services/pdf_export_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ⬇️ SESUAIKAN DENGAN STRUKTUR KAMU: "model" atau "models"
import '../models/expense.dart'; // ganti ke '../model/expense.dart' jika perlu

class PdfExportService {
  PdfExportService._();

  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final _fmtDate = DateFormat('dd MMM yyyy', 'id_ID');
  static final _fmtNow = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  static Future<Uint8List> buildPdfBytes(List<Expense> expenses) async {
    final data = List<Expense>.from(expenses);

    final total = data.fold<double>(0, (s, e) => s + e.amount);
    final perKategori = <String, double>{};
    for (final e in data) {
      perKategori.update(
        e.category,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        header:
            (_) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Laporan Pengeluaran',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _fmtNow.format(DateTime.now()),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ],
            ),
        footer:
            (c) => pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Hal. ${c.pageNumber}/${c.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF666666),
                ),
              ),
            ),
        build:
            (context) => [
              // Ringkasan total
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Pengeluaran',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      _currency.format(total),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Ringkasan per kategori
              if (perKategori.isNotEmpty) ...[
                pw.Text(
                  'Ringkasan per Kategori',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _cell('Kategori', bold: true),
                        _cell('Jumlah', bold: true, alignRight: true),
                      ],
                    ),
                    ...perKategori.entries.map(
                      (e) => pw.TableRow(
                        children: [
                          _cell(e.key),
                          _cell(_currency.format(e.value), alignRight: true),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
              ],

              // Detail transaksi
              pw.Text(
                'Detail Transaksi',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2),
                  1: const pw.FlexColumnWidth(2.6),
                  2: const pw.FlexColumnWidth(1.6),
                  3: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _cell('Tanggal', bold: true),
                      _cell('Judul', bold: true),
                      _cell('Kategori', bold: true),
                      _cell('Jumlah', bold: true, alignRight: true),
                    ],
                  ),
                  ...data.map(
                    (e) => pw.TableRow(
                      children: [
                        _cell(_fmtDate.format(e.date)),
                        _cell(e.title),
                        _cell(e.category),
                        _cell(_currency.format(e.amount), alignRight: true),
                      ],
                    ),
                  ),
                ],
              ),
            ],
      ),
    );

    return pdf.save();
  }

  static Future<File> savePdfTemp(List<Expense> expenses) async {
    final bytes = await buildPdfBytes(expenses);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // helper cell tabel
  static pw.Widget _cell(
    String text, {
    bool bold = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}
