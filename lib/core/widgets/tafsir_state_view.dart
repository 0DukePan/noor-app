import 'package:flutter/material.dart';

import '../models/tafsir_models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SHARED TAFSIR VIEW (TAF-02)
//
// One composable presentation contract for every Tafsir surface: the Mushaf
// preview sheet, the inline excerpt, the full reader, and the comparison
// view render their content through this switch. Variants differ only in
// the `content` they supply and the strings/styling they pass — loading,
// empty, failure, and retry behave identically everywhere.
// ═══════════════════════════════════════════════════════════════════════════

/// Renders a [TafsirViewState]: spinner, caller content, truthful empty
/// text, or failure text with one safe retry. All strings are caller-
/// supplied (localized at the call site); no hard-coded chrome lives here.
class TafsirStateView extends StatelessWidget {
  const TafsirStateView({
    required this.state,
    required this.contentBuilder,
    required this.onRetry,
    required this.emptyText,
    required this.failureText,
    required this.retryText,
    this.textColor,
    this.accentColor,
    this.emptyBuilder,
    this.failureBuilder,
    super.key,
  });

  /// Shared contract state (see `tafsirViewStateFor`).
  final TafsirViewState state;

  /// Builds the [TafsirViewContent] body. Invoked only when the state holds
  /// an entry — never during loading/empty/failure — so the builder may
  /// safely use [TafsirViewContent.entry]. List variants (full surah,
  /// comparison) ignore the argument and render their own guarded list.
  final Widget Function(TafsirEntry entry) contentBuilder;

  /// Safe retry for [TafsirViewFailure] (re-runs verified init; re-copy
  /// only after checksum verification at the data layer).
  final VoidCallback onRetry;

  final String emptyText;
  final String failureText;
  final String retryText;
  final Color? textColor;
  final Color? accentColor;

  /// Optional variant overrides (e.g. comparison partial rows). When null,
  /// the standard text / text+retry layouts render.
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? failureBuilder;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    switch (state) {
      case TafsirViewLoading():
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
              ),
            ),
          ),
        );
      case TafsirViewContent(:final entry):
        return contentBuilder(entry);
      case TafsirViewEmpty():
        if (emptyBuilder != null) return emptyBuilder!(context);
        return Text(
          emptyText,
          style: TextStyle(
            fontSize: 14,
            color: (textColor ?? Theme.of(context).colorScheme.onSurface)
                .withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        );
      case TafsirViewFailure():
        if (failureBuilder != null) return failureBuilder!(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failureText,
              style: TextStyle(
                fontSize: 14,
                color: (textColor ?? Theme.of(context).colorScheme.onSurface)
                    .withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryText),
              ),
            ),
          ],
        );
    }
  }
}
