import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/location_trust_engine.dart';
import '../../../../core/services/smart_notification_engine.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 🔔 إعدادات الإشعارات — Notification Settings
/// Wires SmartNotificationEngine settings into a toggle-based UI
class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  late NotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = SmartNotificationEngine.getSettings();
  }

  Future<void> _updateSettings(NotificationSettings newSettings) async {
    setState(() => _settings = newSettings);
    await SmartNotificationEngine.saveSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.bgLight,
      appBar: AppBar(
        title: Text(l10n.notifTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Adhkar Reminders ──
          _SectionHeader(icon: Icons.wb_sunny_rounded, title: l10n.notifAdhkarSection),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _SettingsTile(
              icon: Icons.wb_sunny_rounded,
              iconColor: NoorDesignSystem.morningColor,
              title: l10n.notifMorning,
              subtitle: l10n.notifMorningSubtitle,
              value: _settings.adhkarMorningEnabled,
              onChanged: (v) => _updateSettings(
                _settings.copyWith(adhkarMorningEnabled: v),
              ),
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.nightlight_rounded,
              iconColor: NoorDesignSystem.eveningColor,
              title: l10n.notifEvening,
              subtitle: l10n.notifEveningSubtitle,
              value: _settings.adhkarEveningEnabled,
              onChanged: (v) => _updateSettings(
                _settings.copyWith(adhkarEveningEnabled: v),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Prayer Notifications ──
          _SectionHeader(icon: Icons.mosque_rounded, title: l10n.notifPrayerSection),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _SettingsTile(
              icon: Icons.notifications_active_rounded,
              iconColor: NoorDesignSystem.primaryGreen,
              title: l10n.notifBeforePrayer,
              subtitle: l10n.notifBeforeMinutes(_settings.prayerNotificationMinutesBefore),
              value: _settings.prayerNotificationsEnabled,
              onChanged: (v) => _updateSettings(
                _settings.copyWith(prayerNotificationsEnabled: v),
              ),
            ),
            if (_settings.prayerNotificationsEnabled) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.notifBeforeLabel, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
                    Text(l10n.notifBeforeMinutes(_settings.prayerNotificationMinutesBefore),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),),
                  ],
                ),
              ),
              Slider(
                value: _settings.prayerNotificationMinutesBefore.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                activeColor: NoorDesignSystem.primaryGreen,
                label: l10n.notifMinutesShort(_settings.prayerNotificationMinutesBefore),
                onChanged: (v) => _updateSettings(
                  _settings.copyWith(prayerNotificationMinutesBefore: v.round()),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 24),

          // ── Khatmah Reminder ──
          _SectionHeader(icon: Icons.auto_stories_rounded, title: l10n.notifDailySection),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _SettingsTile(
              icon: Icons.auto_stories_rounded,
              iconColor: NoorDesignSystem.goldAccent,
              title: l10n.notifKhatmah,
              subtitle: _settings.khatmahReminderEnabled
                  ? l10n.notifAtTime('${_settings.khatmahReminderHour.toString().padLeft(2, '0')}:${_settings.khatmahReminderMinute.toString().padLeft(2, '0')}')
                  : l10n.notifDisabled,
              value: _settings.khatmahReminderEnabled,
              onChanged: (v) => _updateSettings(
                _settings.copyWith(khatmahReminderEnabled: v),
              ),
            ),
            if (_settings.khatmahReminderEnabled) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 20, color: NoorDesignSystem.goldAccent),
                    const SizedBox(width: 12),
                    Text(l10n.notifReminderTime, style: GoogleFonts.cairo(fontSize: 14)),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _pickTime,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NoorDesignSystem.goldAccent,
                        side: const BorderSide(color: NoorDesignSystem.goldAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        '${_settings.khatmahReminderHour.toString().padLeft(2, '0')}:${_settings.khatmahReminderMinute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ]),
          const SizedBox(height: 24),

          // ── Quiet Hours ──
          _SectionHeader(icon: Icons.do_not_disturb_rounded, title: l10n.notifQuietSection),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _SettingsTile(
              icon: Icons.do_not_disturb_on_rounded,
              iconColor: NoorDesignSystem.sleepColor,
              title: l10n.notifQuiet,
              subtitle: _settings.quietHoursEnabled
                  ? l10n.notifQuietRange(_settings.quietHoursStart, _settings.quietHoursEnd)
                  : l10n.notifDisabled,
              value: _settings.quietHoursEnabled,
              onChanged: (v) => _updateSettings(
                _settings.copyWith(quietHoursEnabled: v),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Apply Button ──
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                unawaited(HapticFeedback.mediumImpact());
                // Apply all notification schedules — using the user's real
                // (trusted) location, falling back to Mecca only when the
                // device has no stored location.
                final location = LocationTrustEngine.cachedLocation;
                final lat = location?.latitude ?? 21.4225;
                final lng = location?.longitude ?? 39.8262;
                if (_settings.adhkarMorningEnabled || _settings.adhkarEveningEnabled) {
                  await SmartNotificationEngine.scheduleAdhkarNotifications(
                    latitude: lat,
                    longitude: lng,
                    morningEnabled: _settings.adhkarMorningEnabled,
                    eveningEnabled: _settings.adhkarEveningEnabled,
                  );
                }
                if (_settings.khatmahReminderEnabled) {
                  await SmartNotificationEngine.scheduleKhatmahReminder(
                    hour: _settings.khatmahReminderHour,
                    minute: _settings.khatmahReminderMinute,
                    message: l10n.notifKhatmahMessage,
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.notifUpdated, style: GoogleFonts.cairo()),
                      backgroundColor: NoorDesignSystem.primaryGreen,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.notifApply, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: NoorDesignSystem.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Material(
        type: MaterialType.card,
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _settings.khatmahReminderHour, minute: _settings.khatmahReminderMinute),
    );
    if (picked != null) {
      unawaited(
        _updateSettings(
          _settings.copyWith(
            khatmahReminderHour: picked.hour,
            khatmahReminderMinute: picked.minute,
          ),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: NoorDesignSystem.primaryGreen),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
      value: value,
      activeThumbColor: NoorDesignSystem.primaryGreen,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
    );
  }
}
