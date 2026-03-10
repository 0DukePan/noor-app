import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// سياسة الخشوع - Khushu Policy
/// Enforces calm, distraction-free user experience at the code level.
/// Every feature MUST respect this policy.
abstract class KhushuPolicy {
  /// Whether notifications can be shown in the current context.
  /// Returns false during Quran reading, prayer times, etc.
  bool canShowNotification(BuildContext context);

  /// Minimum transition duration for animations.
  /// Khushu mode requires gentle, slow transitions.
  Duration getTransitionDuration();

  /// Whether entering this mode requires a breathing delay.
  /// True for Khushu mode to allow mental preparation.
  bool requiresBreathingDelay();

  /// Get the breathing delay duration (1 second fade-in + haptic)
  Duration getBreathingDelayDuration() => const Duration(milliseconds: 1000);

  /// Perform the breathing delay transition with optional haptic feedback
  Future<void> performBreathingDelay({bool withHaptic = true}) async {
    if (withHaptic) {
      await HapticFeedback.lightImpact();
    }
    await Future.delayed(getBreathingDelayDuration());
  }
}

/// Default implementation of Khushu Policy
class DefaultKhushuPolicy implements KhushuPolicy {
  final bool _isKhushuModeActive;

  const DefaultKhushuPolicy({bool isKhushuModeActive = false})
      : _isKhushuModeActive = isKhushuModeActive;

  @override
  bool canShowNotification(BuildContext context) {
    // Never show notifications in Khushu mode
    return !_isKhushuModeActive;
  }

  @override
  Duration getTransitionDuration() {
    // Khushu mode: slower, more peaceful transitions
    return _isKhushuModeActive
        ? const Duration(milliseconds: 500)
        : const Duration(milliseconds: 300);
  }

  @override
  bool requiresBreathingDelay() {
    return _isKhushuModeActive;
  }

  @override
  Duration getBreathingDelayDuration() => const Duration(milliseconds: 1000);

  @override
  Future<void> performBreathingDelay({bool withHaptic = true}) async {
    if (withHaptic) {
      await HapticFeedback.lightImpact();
    }
    await Future.delayed(getBreathingDelayDuration());
  }
}

/// Khushu mode specific policy with stricter rules
class KhushuModePolicy implements KhushuPolicy {
  const KhushuModePolicy();

  @override
  bool canShowNotification(BuildContext context) => false;

  @override
  Duration getTransitionDuration() => const Duration(milliseconds: 500);

  @override
  bool requiresBreathingDelay() => true;

  @override
  Duration getBreathingDelayDuration() => const Duration(milliseconds: 1000);

  @override
  Future<void> performBreathingDelay({bool withHaptic = true}) async {
    if (withHaptic) {
      await HapticFeedback.lightImpact();
    }
    await Future.delayed(getBreathingDelayDuration());
  }
}
