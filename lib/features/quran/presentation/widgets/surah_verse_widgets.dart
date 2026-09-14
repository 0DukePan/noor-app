import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/surah.dart';
import '../providers/quran_providers.dart';

/// Verse-level widgets for the surah reader - surah_verse_widgets.dart
/// Extracted from surah_page.dart (Phase 1 god-file split).

class BismillahHeader extends StatelessWidget {

  const BismillahHeader({required this.surahNumber, super.key});
  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.horizontal_rule_rounded,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: GoogleFonts.amiri(
              fontSize: 26,
              color: theme.colorScheme.onSurface,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class DynamicVerseCard extends StatelessWidget {

  const DynamicVerseCard({
    required this.verse,
    required this.isKhushuMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    super.key,
    this.isPlaying = false,
    this.translation,
  });
  final Verse verse;
  final bool isKhushuMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// الآية قيد التلاوة حالياً (تظليل ذهبي خفيف).
  final bool isPlaying;

  /// ترجمة الآية (تفسير الميسر) — تُعرض عند تفعيل «إظهار الترجمة».
  final String? translation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: isKhushuMode ? 40 : 16),
        padding: EdgeInsets.all(isKhushuMode ? 24 : 16),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFFF3C623).withValues(alpha: 0.18)
              : isSelected
                  ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.05)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isPlaying
              ? Border.all(color: const Color(0xFFF3C623).withValues(alpha: 0.5))
              : isSelected
                  ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
                  : null,
        ),
        child: Column(
          children: [
            Text(
              verse.textUthmani,
              style: GoogleFonts.amiri(
                fontSize: isKhushuMode ? 32 : 26,
                height: 2.2, // Generous line height for Arabic
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isKhushuMode ? FontWeight.normal : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: isKhushuMode ? null : BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '﴿${verse.numberInSurah}﴾',
                style: GoogleFonts.cairo(
                  fontSize: isKhushuMode ? 18 : 14,
                  color: isKhushuMode ? const Color(0xFFF3C623) : theme.colorScheme.primary, // Local gold accent
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (translation != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  translation!,
                  style: GoogleFonts.cairo(
                    fontSize: isKhushuMode ? 16 : 14,
                    height: 1.7,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DynamicTafsirPanel extends ConsumerWidget {

  const DynamicTafsirPanel({
    required this.surahNumber,
    required this.verseNumber,
    required this.onClose,
    super.key,
  });
  final int surahNumber;
  final int verseNumber;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tafsirAsync = ref.watch(tafsirProvider((surahId: surahNumber, verseId: verseNumber)));
    final selectedBookId = ref.watch(selectedTafsirBookProvider);
    final availableBooks = ref.watch(availableTafsirBooksProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Selector
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBookId,
                          isDense: true,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                          items: availableBooks.map((book) {
                            return DropdownMenuItem(
                              value: book.id,
                              child: Text(book.nameArabic),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              ref.read(selectedTafsirBookProvider.notifier).state = id;
                            }
                          },
                        ),
                      ),
                      Text(
                        'الآية $verseNumber',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      // Open the standalone tafsir page
                      TextButton.icon(
                        onPressed: () => context.push(
                          '/tafsir?surah=$surahNumber&ayah=$verseNumber',
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: Text(
                          'التفسير الكامل',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tafsirAsync.isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  else if (tafsirAsync.hasError)
                     const Center(child: Text('غير متوفر'))
                  else if (tafsirAsync.value != null)
                     Text(
                      tafsirAsync.value!.text,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        height: 1.8,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                      textDirection: TextDirection.rtl,
                    )
                  else
                    const Center(child: Text('لا يوجد تفسير لهذا الكتاب')),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
