import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 📤 خدمة مشاركة الآيات والأحاديث كصور
/// 
/// Features:
/// - Generate beautiful verse/hadith images
/// - Multiple design templates
/// - Social media ready
/// - Arabic typography optimized
class ShareAsImageService {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN SHARING
  // ═══════════════════════════════════════════════════════════════════════════

  /// مشاركة آية كصورة
  static Future<void> shareQuranVerse({
    required BuildContext context,
    required String verseText,
    required int surah,
    required int ayah,
    required String surahName,
    VerseDesign design = VerseDesign.classic,
  }) async {
    final widget = _QuranVerseImage(
      verseText: verseText,
      surah: surah,
      ayah: ayah,
      surahName: surahName,
      design: design,
    );
    
    await _shareWidget(context, widget, 'quran_$surah\_$ayah');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH SHARING
  // ═══════════════════════════════════════════════════════════════════════════

  /// مشاركة حديث كصورة
  static Future<void> shareHadith({
    required BuildContext context,
    required String hadithText,
    required String source,
    required String narrator,
    String? grade,
    HadithDesign design = HadithDesign.elegant,
  }) async {
    final widget = _HadithImage(
      hadithText: hadithText,
      source: source,
      narrator: narrator,
      grade: grade,
      design: design,
    );
    
    await _shareWidget(context, widget, 'hadith_${DateTime.now().millisecondsSinceEpoch}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE SHARING
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _shareWidget(
    BuildContext context,
    Widget widget,
    String filename,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Create image
      final image = await _widgetToImage(widget);
      
      // Save to temp
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename.png');
      await file.writeAsBytes(image);
      
      // Close loading
      Navigator.of(context).pop();
      
      // Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'من تطبيق نور الإسلامي',
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المشاركة: $e')),
      );
    }
  }

  static Future<Uint8List> _widgetToImage(Widget widget) async {
    final repaintBoundary = RenderRepaintBoundary();
    
    final view = ui.PlatformDispatcher.instance.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints(
          maxWidth: 1080,
          maxHeight: 1920,
        ),
        devicePixelRatio: 3.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(child: widget),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum VerseDesign {
  classic,    // كلاسيكي أخضر
  golden,     // ذهبي فاخر
  minimal,    // بسيط أبيض
  night,      // ليلي داكن
}

enum HadithDesign {
  elegant,    // أنيق
  simple,     // بسيط
  scholarly,  // علمي
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// صورة الآية القرآنية
class _QuranVerseImage extends StatelessWidget {
  final String verseText;
  final int surah;
  final int ayah;
  final String surahName;
  final VerseDesign design;

  const _QuranVerseImage({
    required this.verseText,
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: _getGradient(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // بسملة أو زخرفة
          Text(
            '﷽',
            style: TextStyle(
              fontSize: 48,
              color: _getTextColor(),
              fontFamily: 'Amiri',
            ),
          ),
          
          const SizedBox(height: 40),
          
          // زخرفة علوية
          _buildOrnament(),
          
          const SizedBox(height: 40),
          
          // نص الآية
          Text(
            verseText,
            style: TextStyle(
              fontSize: 36,
              height: 2.2,
              color: _getTextColor(),
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          
          const SizedBox(height: 40),
          
          // زخرفة سفلية
          _buildOrnament(),
          
          const SizedBox(height: 40),
          
          // المصدر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _getAccentColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '[ سورة $surahName : $ayah ]',
              style: TextStyle(
                fontSize: 24,
                color: _getTextColor().withOpacity(0.8),
                fontFamily: 'Amiri',
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // شعار التطبيق
          Text(
            'تطبيق نور الإسلامي',
            style: TextStyle(
              fontSize: 18,
              color: _getTextColor().withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (design) {
      case VerseDesign.classic:
        return const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case VerseDesign.golden:
        return const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case VerseDesign.minimal:
        return const LinearGradient(
          colors: [Color(0xFFFAFAFA), Color(0xFFEEEEEE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case VerseDesign.night:
        return const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }

  Color _getTextColor() {
    switch (design) {
      case VerseDesign.minimal:
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  Color _getAccentColor() {
    switch (design) {
      case VerseDesign.golden:
        return const Color(0xFFFFD700);
      case VerseDesign.minimal:
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  Widget _buildOrnament() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 2,
          color: _getAccentColor().withOpacity(0.5),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.brightness_1,
          size: 8,
          color: _getAccentColor(),
        ),
        const SizedBox(width: 16),
        Container(
          width: 60,
          height: 2,
          color: _getAccentColor().withOpacity(0.5),
        ),
      ],
    );
  }
}

/// صورة الحديث
class _HadithImage extends StatelessWidget {
  final String hadithText;
  final String source;
  final String narrator;
  final String? grade;
  final HadithDesign design;

  const _HadithImage({
    required this.hadithText,
    required this.source,
    required this.narrator,
    this.grade,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF37474F),
            const Color(0xFF263238),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // عنوان
          Text(
            'حديث شريف',
            style: TextStyle(
              fontSize: 28,
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Amiri',
            ),
          ),
          
          const SizedBox(height: 40),
          
          // زخرفة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 80, height: 1, color: Colors.white24),
              const SizedBox(width: 16),
              const Icon(Icons.format_quote, color: Colors.white38, size: 32),
              const SizedBox(width: 16),
              Container(width: 80, height: 1, color: Colors.white24),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // نص الحديث
          Text(
            hadithText,
            style: const TextStyle(
              fontSize: 32,
              height: 2.0,
              color: Colors.white,
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          
          const SizedBox(height: 40),
          
          // الراوي
          Text(
            '— $narrator —',
            style: TextStyle(
              fontSize: 22,
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // المصدر والدرجة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  source,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ),
              if (grade != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade!).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    grade!,
                    style: TextStyle(
                      fontSize: 16,
                      color: _getGradeColor(grade!),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 40),
          
          // شعار
          Text(
            'تطبيق نور الإسلامي',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.contains('صحيح')) return Colors.green;
    if (grade.contains('حسن')) return Colors.lightGreen;
    if (grade.contains('ضعيف')) return Colors.orange;
    return Colors.grey;
  }
}
