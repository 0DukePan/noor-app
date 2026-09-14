import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/hifz_ayah_card.dart';
import '../providers/hifz_providers.dart';
import 'hifz_session_page.dart';

/// صفحة الحفظ — لوحة متابعة حفظ القرآن مع المراجعة المتباعدة (FSRS).
class HifzPage extends ConsumerStatefulWidget {
  const HifzPage({super.key});

  @override
  ConsumerState<HifzPage> createState() => _HifzPageState();
}

class _HifzPageState extends ConsumerState<HifzPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hifz = ref.watch(hifzProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final due = hifz.dueCards;
    final newCards = hifz.newCards;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(
          l10n.toolsHifz,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Streak + stats banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [NoorDesignSystem.primaryGreen, NoorDesignSystem.primaryLight],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hifzStreakLine(hifz.streak.streakEmoji),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.hifzDays(hifz.streak.currentStreak),
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatChip(
                      label: l10n.hifzToMemorize,
                      value: newCards.length,
                    ),
                    const SizedBox(height: 8),
                    _StatChip(
                      label: l10n.hifzToReview,
                      value: due.length,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Session entry
          if (due.isNotEmpty || newCards.isNotEmpty)
            FilledButton.icon(
              onPressed: () => _openSession(due.isNotEmpty ? due : newCards),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                due.isNotEmpty
                    ? l10n.hifzStartReview(due.length)
                    : l10n.hifzStartNew(newCards.length),
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: NoorDesignSystem.deepTeal,
              ),
            ),

          const SizedBox(height: 24),

          // Cards list
          if (hifz.cards.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 72,
                    color: NoorDesignSystem.deepTeal.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.hifzEmpty,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              l10n.hifzMyCards(hifz.cards.length),
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...hifz.cards.map((card) => _HifzCardTile(
                  card: card,
                  onRepeatChanged: (count) => ref
                      .read(hifzProvider.notifier)
                      .setRepeatCount(card.id, count),
                  onDelete: () =>
                      ref.read(hifzProvider.notifier).removeAyah(card.id),
                  onReview: () => _openSession([card]),
                ),),
          ],
        ],
      ),
    );
  }

  void _openSession(List<HifzAyahCard> cards) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HifzSessionPage(cards: cards),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {

  const _StatChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HifzCardTile extends StatelessWidget {

  const _HifzCardTile({
    required this.card,
    required this.onRepeatChanged,
    required this.onDelete,
    required this.onReview,
  });
  final HifzAyahCard card;
  final ValueChanged<int> onRepeatChanged;
  final VoidCallback onDelete;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.isDue
              ? NoorDesignSystem.goldAccent.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: onDelete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                    onPressed: onReview,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.hifzCardRef(card.surah, card.ayah),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    card.isNew
                        ? l10n.hifzNew
                        : card.isDue
                            ? l10n.hifzDueToday
                            : l10n.hifzAfterDays(card.daysUntilReview),
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: card.isDue
                          ? NoorDesignSystem.goldAccent
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.arabicText.isEmpty ? '—' : card.arabicText,
            style: GoogleFonts.amiri(
              fontSize: 18,
              height: 1.8,
              color: theme.colorScheme.onSurface,
            ),
            textDirection: TextDirection.rtl,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                AppLocalizations.of(context).hifzRepeat,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              ...List.generate(5, (i) {
                final count = i + 1;
                return GestureDetector(
                  onTap: () => onRepeatChanged(count),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: card.repeatCount == count
                          ? NoorDesignSystem.deepTeal
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NoorDesignSystem.deepTeal.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: card.repeatCount == count
                            ? Colors.white
                            : NoorDesignSystem.deepTeal,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
