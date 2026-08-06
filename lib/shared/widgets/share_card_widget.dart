import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/noor_theme.dart';
import '../../../core/services/export_share_service.dart';

/// بطاقة المشاركة - Share Card Widget
/// Beautiful card for sharing verses or hadiths on social media
class ShareCardWidget extends StatelessWidget {
  final GlobalKey cardKey;
  final String arabicText;
  final String source;
  final String? translation;
  final ShareCardStyle style;

  const ShareCardWidget({
    super.key,
    required this.cardKey,
    required this.arabicText,
    required this.source,
    this.translation,
    this.style = ShareCardStyle.elegant,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey,
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    switch (style) {
      case ShareCardStyle.elegant:
        return _ElegantCard(
          arabicText: arabicText,
          source: source,
          translation: translation,
        );
      case ShareCardStyle.minimal:
        return _MinimalCard(
          arabicText: arabicText,
          source: source,
          translation: translation,
        );
      case ShareCardStyle.gradient:
        return _GradientCard(
          arabicText: arabicText,
          source: source,
          translation: translation,
        );
      case ShareCardStyle.dark:
        return _DarkCard(
          arabicText: arabicText,
          source: source,
          translation: translation,
        );
    }
  }
}

enum ShareCardStyle { elegant, minimal, gradient, dark }

/// Elegant style card
class _ElegantCard extends StatelessWidget {
  final String arabicText;
  final String source;
  final String? translation;

  const _ElegantCard({
    required this.arabicText,
    required this.source,
    this.translation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NoorTheme.accentGold.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decorative top
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 1, color: NoorTheme.accentGold),
              const SizedBox(width: 8),
              Icon(Icons.auto_awesome, color: NoorTheme.accentGold, size: 16),
              const SizedBox(width: 8),
              Container(width: 40, height: 1, color: NoorTheme.accentGold),
            ],
          ),
          const SizedBox(height: 24),

          // Arabic text
          Text(
            arabicText,
            style: const TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 26,
              height: 2.2,
              color: NoorTheme.textArabic,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),

          if (translation != null) ...[
            const SizedBox(height: 16),
            Text(
              translation!,
              style: TextStyle(
                fontSize: 14,
                color: NoorTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // Source
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: NoorTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              source,
              style: TextStyle(
                color: NoorTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // App branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'نور',
                style: TextStyle(
                  color: NoorTheme.accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Minimal style card
class _MinimalCard extends StatelessWidget {
  final String arabicText;
  final String source;
  final String? translation;

  const _MinimalCard({
    required this.arabicText,
    required this.source,
    this.translation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabicText,
            style: const TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 28,
              height: 2.0,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 24),
          Text(
            '— $source',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient style card
class _GradientCard extends StatelessWidget {
  final String arabicText;
  final String source;
  final String? translation;

  const _GradientCard({
    required this.arabicText,
    required this.source,
    this.translation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NoorTheme.primary,
            NoorTheme.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.format_quote_rounded, color: Colors.white38, size: 32),
          const SizedBox(height: 16),
          Text(
            arabicText,
            style: const TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 24,
              height: 2.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              source,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('نور 🌙', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Dark style card
class _DarkCard extends StatelessWidget {
  final String arabicText;
  final String source;
  final String? translation;

  const _DarkCard({
    required this.arabicText,
    required this.source,
    this.translation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NoorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stars decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.star,
                color: NoorTheme.accentGold.withOpacity(0.3 + i * 0.1),
                size: 8,
              ),
            )),
          ),
          const SizedBox(height: 24),
          Text(
            arabicText,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 24,
              height: 2.0,
              color: NoorTheme.accentGold,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),
          Text(
            source,
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                'نور',
                style: TextStyle(color: NoorTheme.accentGold, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Share card preview dialog
class ShareCardPreviewDialog extends StatefulWidget {
  final String arabicText;
  final String source;
  final String? translation;

  const ShareCardPreviewDialog({
    super.key,
    required this.arabicText,
    required this.source,
    this.translation,
  });

  @override
  State<ShareCardPreviewDialog> createState() => _ShareCardPreviewDialogState();
}

class _ShareCardPreviewDialogState extends State<ShareCardPreviewDialog> {
  final GlobalKey _cardKey = GlobalKey();
  ShareCardStyle _selectedStyle = ShareCardStyle.elegant;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Style selector
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ShareCardStyle.values.map((style) {
                  final isSelected = style == _selectedStyle;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStyle = style),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? NoorTheme.primary : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStyleName(style),
                        style: TextStyle(
                          color: isSelected ? Colors.white : NoorTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Card preview
            ShareCardWidget(
              cardKey: _cardKey,
              arabicText: widget.arabicText,
              source: widget.source,
              translation: widget.translation,
              style: _selectedStyle,
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _shareCard,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('مشاركة'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStyleName(ShareCardStyle style) {
    switch (style) {
      case ShareCardStyle.elegant:
        return 'أنيق';
      case ShareCardStyle.minimal:
        return 'بسيط';
      case ShareCardStyle.gradient:
        return 'ملون';
      case ShareCardStyle.dark:
        return 'داكن';
    }
  }

  Future<void> _shareCard() async {
    HapticFeedback.mediumImpact();

    // Wait for next frame to ensure widget is rendered
    await Future.delayed(const Duration(milliseconds: 100));

    final imageBytes = await ExportShareService.generateShareCard(_cardKey);
    if (imageBytes != null) {
      await ExportShareService.shareImage(imageBytes, 'noor_share');
    }
  }
}

/// Show share card dialog
void showShareCardDialog(
  BuildContext context, {
  required String arabicText,
  required String source,
  String? translation,
}) {
  showDialog(
    context: context,
    builder: (context) => ShareCardPreviewDialog(
      arabicText: arabicText,
      source: source,
      translation: translation,
    ),
  );
}
