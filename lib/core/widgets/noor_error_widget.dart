import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Installs a branded replacement for Flutter's red error screen.
///
/// Debug builds keep the framework default: a developer needs the stack
/// context. Release builds get a calm, bilingual message — a red screen in a
/// worship app is alarming and tells the user nothing they can act on.
///
/// [debugOverride] exists so tests can exercise the release branch, which
/// `flutter test` would otherwise never reach (tests run in debug mode).
void installErrorWidgetBuilder({bool? debugOverride}) {
  if (debugOverride ?? kDebugMode) return;
  ErrorWidget.builder = (FlutterErrorDetails details) => const NoorErrorWidget();
}

/// The release-mode fallback shown wherever a widget failed to build.
///
/// Deliberately dependency-free: this can render above the theme, the router,
/// and the localization delegates, so it uses literal colours and explicit text
/// direction rather than theme or `AppLocalizations` lookups that could throw
/// again.
class NoorErrorWidget extends StatelessWidget {
  const NoorErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF5F2EA),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFF107A57),
              ),
              SizedBox(height: 12),
              Text(
                'حدث خطأ غير متوقع',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'أعد تشغيل التطبيق',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 14, color: Color(0xFF5A5A5A)),
              ),
              SizedBox(height: 12),
              Text(
                'Something went wrong — please restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF5A5A5A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
