import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/theme/design_system.dart';

/// Bottom sheet that previews and shares a beautifully formatted Hadith image.
class HadithShareSheet extends StatefulWidget {
  final Hadith hadith;
  final String bookTitle;
  final Color bookColor;

  const HadithShareSheet({
    super.key,
    required this.hadith,
    required this.bookTitle,
    required this.bookColor,
  });

  /// Displays the share sheet
  static void show(BuildContext context, {
    required Hadith hadith,
    required String bookTitle,
    required Color bookColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HadithShareSheet(
        hadith: hadith,
        bookTitle: bookTitle,
        bookColor: bookColor,
      ),
    );
  }

  @override
  State<HadithShareSheet> createState() => _HadithShareSheetState();
}

class _HadithShareSheetState extends State<HadithShareSheet> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _captureAndShare() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Capture widget as image
      final boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // We use a high pixel ratio for a crisp, high-res image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 2. Save temporarily
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/hadith_${widget.hadith.idInBook}.png';
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      // 3. Share
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: '📖 ${widget.bookTitle} - حديث رقم ${widget.hadith.idInBook}\n\nتطبيق نور الإسلامي',
      );

      // Close bottom sheet if needed
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ الصورة: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NoorDesignSystem.creamWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: NoorDesignSystem.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'مشاركة كصورة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: NoorDesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // The card to be captured
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: RepaintBoundary(
                key: _globalKey,
                child: _buildShareCard(),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Share Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAndShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.bookColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share_rounded),
              label: Text(
                _isProcessing ? 'جاري التجهيز...' : 'مشاركة الآن',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The actual layout of the image to be exported
  Widget _buildShareCard() {
    // Determine gradient based on book color
    final Gradient bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        widget.bookColor.withOpacity(0.05),
        Colors.white,
        widget.bookColor.withOpacity(0.1),
      ],
    );

    // Truncate hadith if extremely long, or shrink font size.
    // For a square-ish share card, we'll just constrain and let text scale or clip.
    return Container(
      width: 1080 / 3, // Simulate high-res target width (360 logical pixels -> 1080px physically)
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: bgGradient,
        border: Border.all(color: widget.bookColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Logo / Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mosque_rounded, color: widget.bookColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'نور',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: widget.bookColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hadith Text
          Icon(
            Icons.format_quote_rounded,
            color: widget.bookColor.withOpacity(0.2),
            size: 40,
          ),
          
          Text(
            widget.hadith.arabic,
            style: GoogleFonts.amiri(
              fontSize: 20,
              height: 1.8,
              color: NoorDesignSystem.textPrimary,
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),

          if (widget.hadith.narratorEnglish.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.hadith.narratorEnglish,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: NoorDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),

          // Footer (Book details)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.bookColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.bookTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'حديث رقم ${widget.hadith.idInBook}',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: NoorDesignSystem.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
