import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/home_provider.dart';

class ContinueReadingCard extends StatelessWidget {

  const ContinueReadingCard({super.key, this.lastRead});
  final LastReadData? lastRead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (lastRead != null) {
          context.go('/quran/surah/${lastRead!.surah}');
        } else {
          context.go('/quran');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: NoorDesignSystem.shadowSmall,
        ),
        child: Row(
          children: [
            // Icon / Bookmark badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: NoorDesignSystem.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: NoorDesignSystem.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lastRead != null ? lastRead!.surahName : l10n.continueStart,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (lastRead != null)
                        Text(
                          l10n.continueSaved,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: NoorDesignSystem.goldAccent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (lastRead != null)
                    Text(
                      l10n.continueAyah(lastRead!.ayah),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    Text(
                      l10n.continueGo,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
