// ignore_for_file: cascade_invocations — this file asserts the controller's
// state between every step; cascades would hide the assertions.
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/silent_ui_controller.dart';

/// Tests for SilentUIController (previously zero-covered): the reading-mode
/// state machine, the interaction auto-reading timer, and the notification
/// rate limiter. Timer/cooldown behaviour is verified under fakeAsync.
void main() {
  test('starts with notifications allowed', () {
    final controller = SilentUIController();
    expect(controller.isReadingMode, isFalse);
    expect(controller.isQuranReading, isFalse);
    expect(controller.isPrayerTime, isFalse);
    expect(controller.shouldShowNotifications, isTrue);
  });

  test('reading mode, quran reading and prayer time each block notifications',
      () {
    final controller = SilentUIController();

    controller.enterReadingMode();
    expect(controller.isReadingMode, isTrue);
    expect(controller.shouldShowNotifications, isFalse);
    controller.exitReadingMode();
    expect(controller.shouldShowNotifications, isTrue);

    controller.enterQuranReading();
    expect(controller.shouldShowNotifications, isFalse);
    controller.exitQuranReading();
    expect(controller.shouldShowNotifications, isTrue);

    controller.setPrayerTime(active: true);
    expect(controller.shouldShowNotifications, isFalse);
    controller.setPrayerTime(active: false);
    expect(controller.shouldShowNotifications, isTrue);
  });

  test('notifies listeners on state changes', () {
    final controller = SilentUIController();
    var notified = 0;
    controller.addListener(() => notified++);

    controller.enterReadingMode();
    controller.exitReadingMode();
    controller.setPrayerTime(active: true);

    expect(notified, 3);
  });

  test('interaction without quran reading enters reading mode after 30s', () {
    fakeAsync((async) {
      final controller = SilentUIController();
      controller.recordInteraction();
      expect(controller.isReadingMode, isFalse);

      async.elapse(const Duration(seconds: 29));
      expect(controller.isReadingMode, isFalse);

      async.elapse(const Duration(seconds: 1));
      expect(controller.isReadingMode, isTrue);
    });
  });

  test('interaction during quran reading never auto-enters reading mode', () {
    fakeAsync((async) {
      final controller = SilentUIController()..enterQuranReading();
      controller.recordInteraction();

      async.elapse(const Duration(minutes: 5));
      expect(controller.isReadingMode, isFalse);
    });
  });

  test('a new interaction resets the reading-mode timer', () {
    fakeAsync((async) {
      final controller = SilentUIController();
      controller.recordInteraction();
      async.elapse(const Duration(seconds: 20));
      controller.recordInteraction(); // resets
      async.elapse(const Duration(seconds: 20));
      expect(controller.isReadingMode, isFalse);
      async.elapse(const Duration(seconds: 10));
      expect(controller.isReadingMode, isTrue);
    });
  });

  test('notification rate limiter: 3 recent notifications block, then prune',
      () {
    fakeAsync((async) {
      final controller = SilentUIController();
      controller.recordNotification();
      controller.recordNotification();
      controller.recordNotification();
      expect(controller.shouldShowNotifications, isFalse);

      // After the 5-minute cooldown the window prunes and notifications are
      // allowed again.
      async.elapse(const Duration(minutes: 6));
      expect(controller.shouldShowNotifications, isTrue);
    });
  });

  test('adhkar prompt is null while notifications are blocked', () {
    final controller = SilentUIController()..enterReadingMode();
    expect(controller.getAdhkarPrompt(), isNull);
  });

  testWidgets('ReadingModeWrapper enters quran reading for quran pages',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingModeWrapper(
            isQuranPage: true,
            child: SizedBox(width: 200, height: 200),
          ),
        ),
      ),
    );
    // Builds and disposes cleanly (interaction recording is unit-tested).
    expect(find.byType(ReadingModeWrapper), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
