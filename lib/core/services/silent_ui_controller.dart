import 'dart:async';
import 'package:flutter/material.dart';
import 'adhkar_timer_service.dart';

/// 🔇 واجهة صامتة محترمة - Silent UI Controller
/// لا popups مزعجة، لا وميض، كل شيء يظهر ويختفي بهدوء
class SilentUIController extends ChangeNotifier {
  // State
  bool _isReadingMode = false;
  bool _isQuranReading = false;
  bool _isPrayerTime = false;
  DateTime? _lastInteraction;
  
  // Settings
  static const Duration _readingModeDelay = Duration(seconds: 30);
  static const Duration _notificationCooldown = Duration(minutes: 5);
  
  Timer? _readingModeTimer;
  final List<DateTime> _recentNotifications = [];

  // ═══════════════════════════════════════════════════════════════════════════
  // READING MODE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if in reading mode (no interruptions)
  bool get isReadingMode => _isReadingMode;

  /// Check if user is reading Quran
  bool get isQuranReading => _isQuranReading;

  /// Check if it's prayer time
  bool get isPrayerTime => _isPrayerTime;

  /// Should we show notifications?
  bool get shouldShowNotifications {
    // Don't interrupt during:
    // 1. Reading mode
    // 2. Quran reading
    // 3. Prayer time
    // 4. Too many recent notifications
    
    if (_isReadingMode || _isQuranReading || _isPrayerTime) {
      return false;
    }
    
    // Rate limiting
    final now = DateTime.now();
    _recentNotifications.removeWhere(
      (time) => now.difference(time) > _notificationCooldown,
    );
    
    return _recentNotifications.length < 3;
  }

  /// Enter reading mode
  void enterReadingMode() {
    _isReadingMode = true;
    notifyListeners();
  }

  /// Exit reading mode
  void exitReadingMode() {
    _isReadingMode = false;
    notifyListeners();
  }

  /// Enter Quran reading
  void enterQuranReading() {
    _isQuranReading = true;
    notifyListeners();
  }

  /// Exit Quran reading
  void exitQuranReading() {
    _isQuranReading = false;
    notifyListeners();
  }

  /// Set prayer time status
  void setPrayerTime(bool active) {
    _isPrayerTime = active;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERACTION TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record user interaction
  void recordInteraction() {
    _lastInteraction = DateTime.now();
    
    // Reset reading mode timer
    _readingModeTimer?.cancel();
    _readingModeTimer = Timer(_readingModeDelay, () {
      if (!_isQuranReading) {
        enterReadingMode();
      }
    });
  }

  /// Record notification shown
  void recordNotification() {
    _recentNotifications.add(DateTime.now());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENTLE NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Show a gentle notification (non-intrusive)
  static void showGentleNotification(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _GentleNotificationWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );
    
    overlay.insert(entry);
  }

  /// Show success notification
  static void showSuccess(BuildContext context, String message) {
    showGentleNotification(
      context,
      message: message,
      icon: Icons.check_circle_outline,
    );
  }

  /// Show info notification
  static void showInfo(BuildContext context, String message) {
    showGentleNotification(
      context,
      message: message,
      icon: Icons.info_outline,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER TIME AWARENESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get current adhkar prompt (if available and appropriate to show)
  String? getAdhkarPrompt() {
    if (!shouldShowNotifications) return null;
    
    final currentType = AdhkarTimerService.getCurrentAdhkarType();
    if (currentType == null) return null;
    
    switch (currentType) {
      case AdhkarType.morning:
        return 'وقت أذكار الصباح ☀️';
      case AdhkarType.evening:
        return 'وقت أذكار المساء 🌙';
      case AdhkarType.afterPrayer:
        return 'لا تنسَ أذكار ما بعد الصلاة';
      default:
        return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _readingModeTimer?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GENTLE NOTIFICATION WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _GentleNotificationWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _GentleNotificationWidget({
    required this.message,
    this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_GentleNotificationWidget> createState() => _GentleNotificationWidgetState();
}

class _GentleNotificationWidgetState extends State<_GentleNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
    
    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// READING MODE WRAPPER
// ═══════════════════════════════════════════════════════════════════════════

/// Wrap pages that should be in "reading mode"
class ReadingModeWrapper extends StatefulWidget {
  final Widget child;
  final bool isQuranPage;

  const ReadingModeWrapper({
    super.key,
    required this.child,
    this.isQuranPage = false,
  });

  @override
  State<ReadingModeWrapper> createState() => _ReadingModeWrapperState();
}

class _ReadingModeWrapperState extends State<ReadingModeWrapper> with WidgetsBindingObserver {
  late SilentUIController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SilentUIController();
    
    if (widget.isQuranPage) {
      _controller.enterQuranReading();
    }
  }

  @override
  void dispose() {
    if (widget.isQuranPage) {
      _controller.exitQuranReading();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _controller.recordInteraction(),
      onPanDown: (_) => _controller.recordInteraction(),
      child: widget.child,
    );
  }
}
