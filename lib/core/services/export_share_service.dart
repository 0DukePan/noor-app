import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// خدمة التصدير والمشاركة - Export & Share Service
class ExportShareService {
  /// Generate PDF from list of verses or hadiths
  static Future<Uint8List> generatePdf({
    required String title,
    required List<ExportItem> items,
    String? subtitle,
    bool includeWatermark = true,
  }) async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.amiriRegular();
    final arabicBoldFont = await PdfGoogleFonts.amiriBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(title, subtitle, arabicBoldFont),
        footer: (context) => _buildPdfFooter(context, includeWatermark),
        build: (context) => items.map((item) => _buildPdfItem(item, arabicFont, arabicBoldFont)).toList(),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfHeader(String title, String? subtitle, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 24,
            color: PdfColors.green800,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        if (subtitle != null)
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              color: PdfColors.grey600,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.green200),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context, bool includeWatermark) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            if (includeWatermark)
              pw.Text(
                'تطبيق نور',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.green600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPdfItem(ExportItem item, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Main text (verse or hadith)
          pw.Text(
            item.arabicText,
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              height: 2.0,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 10),
          // Source/reference
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (item.grade != null)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _getGradeColor(item.grade!),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    item.grade!,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                  ),
                ),
              pw.Text(
                item.source,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: PdfColors.green700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          // Translation if available
          if (item.translation != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              item.translation!,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static PdfColor _getGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'صحيح':
      case 'sahih':
        return PdfColors.green600;
      case 'حسن':
      case 'hasan':
        return PdfColors.blue600;
      case 'ضعيف':
      case 'daif':
        return PdfColors.orange600;
      default:
        return PdfColors.grey600;
    }
  }

  /// Print PDF directly
  static Future<void> printPdf(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: title,
    );
  }

  /// Save PDF to file
  static Future<File> savePdfToFile(Uint8List pdfBytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// Share PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String title) async {
    final file = await savePdfToFile(pdfBytes, title);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'تم التصدير من تطبيق نور',
    );
  }

  /// Generate share card image from widget
  static Future<Uint8List?> generateShareCard(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Share image
  static Future<void> shareImage(Uint8List imageBytes, String title) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$title.png');
    await file.writeAsBytes(imageBytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'من تطبيق نور 🌙',
    );
  }

  /// Share text directly
  static Future<void> shareText(String text, {String? source}) async {
    final fullText = source != null ? '$text\n\n— $source\n\nمن تطبيق نور' : '$text\n\nمن تطبيق نور';
    await Share.share(fullText);
  }
}

/// Export item model
class ExportItem {
  final String arabicText;
  final String source;
  final String? translation;
  final String? grade;
  final int? number;

  ExportItem({
    required this.arabicText,
    required this.source,
    this.translation,
    this.grade,
    this.number,
  });
}
