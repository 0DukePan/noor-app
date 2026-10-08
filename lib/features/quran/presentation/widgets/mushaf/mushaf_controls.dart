import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/quran_providers.dart';
import 'mushaf_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MUSHAF CONTROLS OVERLAY — auto-hiding chrome, never overlapping text
// ═══════════════════════════════════════════════════════════════════════════

/// Top + bottom control zones rendered above the page canvas. Hidden as one
/// unit when the reader enters undistracted mode; the canvas reserves the
/// header/footer zones so controls never overlap text.
class MushafControlsOverlay extends StatelessWidget {
  const MushafControlsOverlay({
    required this.visible,
    required this.currentPage,
    required this.themeData,
    required this.onBack,
    required this.onTheme,
    required this.onPreview,
    required this.onSettle,
    super.key,
  });
  final bool visible;
  final int currentPage;
  final MushafThemeData themeData;
  final VoidCallback onBack;
  final VoidCallback onTheme;
  final ValueChanged<int> onPreview;
  final ValueChanged<int> onSettle;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: MushafTopBar(
            pageNumber: currentPage,
            themeData: themeData,
            onBack: onBack,
            onTheme: onTheme,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: MushafBottomBar(
            currentPage: currentPage,
            themeData: themeData,
            onPreview: onPreview,
            onSettle: onSettle,
          ),
        ),
      ],
    );
  }
}

class MushafTopBar extends StatelessWidget {
  const MushafTopBar({
    required this.pageNumber,
    required this.themeData,
    required this.onBack,
    required this.onTheme,
    super.key,
  });
  final int pageNumber;
  final MushafThemeData themeData;
  final VoidCallback onBack;
  final VoidCallback onTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        8,
        8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeData.backgroundColor,
            themeData.backgroundColor.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Transform.flip(
              flipX: true,
              child: Icon(Icons.arrow_back_rounded, color: themeData.textColor),
            ),
            tooltip: AppLocalizations.of(context).commonBack,
            onPressed: onBack,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.palette_rounded, color: themeData.textColor),
            tooltip: AppLocalizations.of(context).mushafAppearanceTooltip,
            onPressed: onTheme,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM BAR — preview live, persist on settle (QUR-03)
// ═══════════════════════════════════════════════════════════════════════════

class MushafBottomBar extends StatelessWidget {
  const MushafBottomBar({
    required this.currentPage,
    required this.themeData,
    required this.onPreview,
    required this.onSettle,
    super.key,
  });
  final int currentPage;
  final MushafThemeData themeData;
  final ValueChanged<int> onPreview;
  final ValueChanged<int> onSettle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            themeData.backgroundColor,
            themeData.backgroundColor.withValues(alpha: 0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page slider
          Directionality(
            textDirection: TextDirection.ltr,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: themeData.headerColor,
                inactiveTrackColor: themeData.borderColor,
                thumbColor: themeData.headerColor,
                overlayColor: themeData.headerColor.withValues(alpha: 0.2),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: currentPage.toDouble().clamp(1, 604),
                min: 1,
                max: 604,
                divisions: 603,
                label: '$currentPage',
                onChanged: (v) => onPreview(v.round()),
                onChangeEnd: (v) => onSettle(v.round()),
              ),
            ),
          ),
          Semantics(
            liveRegion: true,
            label: AppLocalizations.of(
              context,
            ).mushafPageIndicator(currentPage),
            child: Text(
              AppLocalizations.of(context).mushafPageIndicator(currentPage),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: themeData.textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zoom controls with 48dp targets and localized tooltips.
class MushafZoomControls extends ConsumerWidget {
  const MushafZoomControls({required this.themeData, super.key});
  final MushafThemeData themeData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final zoom = ref.watch(mushafZoomProvider);
    final idx = kMushafZoomLevels.indexOf(zoom);

    Future<void> setZoom(double value) async {
      ref.read(mushafZoomProvider.notifier).state = value;
      await MushafPreferenceStore.writeStored(
        MushafPreferences(
          theme: ref.read(mushafThemeProvider),
          zoom: value,
          showControls: ref.read(mushafShowControlsProvider),
          lastPage: ref.read(mushafCurrentPageProvider),
        ),
      );
    }

    return Semantics(
      container: true,
      label: l10n.surahAppearance,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: l10n.mushafZoomOut,
              onPressed: idx > 0
                  ? () => setZoom(kMushafZoomLevels[idx - 1])
                  : null,
              icon: const Icon(Icons.text_decrease_rounded),
              color: themeData.textColor,
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: l10n.mushafZoomReset,
              onPressed: zoom == 1.0 ? null : () => setZoom(1.0),
              icon: const Icon(Icons.format_size_rounded),
              color: themeData.textColor,
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: l10n.mushafZoomIn,
              onPressed: idx >= 0 && idx < kMushafZoomLevels.length - 1
                  ? () => setZoom(kMushafZoomLevels[idx + 1])
                  : null,
              icon: const Icon(Icons.text_increase_rounded),
              color: themeData.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTION BUTTON (circular icon + label, 48dp+ target with semantics)
// ═══════════════════════════════════════════════════════════════════════════

class MushafActionButton extends StatelessWidget {
  const MushafActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
