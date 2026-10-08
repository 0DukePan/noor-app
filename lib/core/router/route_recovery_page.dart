import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../router/route_decoder.dart';

/// Localized safe recovery screen for invalid Qur'an routes (NAV-01, QUR-04).
///
/// Malformed, missing, and out-of-range input reaches here with a safe
/// return link — never an uncaught exception or a crashed PageController.
class RouteRecoveryPage extends StatelessWidget {
  const RouteRecoveryPage({
    super.key,
    required this.failure,
    required this.safeRoute,
  });

  final RouteFailure failure;
  final String safeRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeInvalidTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                l10n.routeInvalidBody(failure.reason),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (failure.rawValue != null)
                Text(
                  l10n.routeInvalidValue(failure.rawValue!),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('routeRecoveryBack'),
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(safeRoute),
                icon: const Icon(Icons.home_rounded),
                label: Text(l10n.routeInvalidBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
