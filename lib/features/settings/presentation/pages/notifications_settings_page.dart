import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/services/smart_notification_engine.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.bgLight,
      appBar: AppBar(
        title: Text('الإشعارات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Adhkar Reminders ──
          _SectionHeader(icon: Icons.wb_sunny_rounded, title: 'تذكيرات الأذكار'),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _SettingsTile(
              icon: Icons.wb_sunny_rounded,
              iconColor: NoorDesignSystem.morningColor,
              title: 'أذكار الصباح',
              subtitle: 'بعد صلاة الفجر بـ 30 دقيقة',
              value: _settings.adhkarMorningEnabled,
              onChanged: (v) => _updateSettings(
                _settings.copyWith(adhkarMorningEnabled: v),
              ),
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.nightlight_rounded,
              iconColor: NoorDesignSystem.eveningColor,
              title: 'أذكار المساء',
              subtitle: 'قبل صلاة المغرب بـ 30 دقيقة',
              value: _settings.adhkarEveningEnabled,
              onChanged: (v) => _updateSettings(
                _settings.copyWith(adhkarEveningEnabled: v),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Prayer Notifications ──
          _SectionHeader(icon: Icons.mosque_rounded, title: 'إشعارات الصلاة'),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _SettingsTile(
              icon: Icons.notifications_active_rounded,
              iconColor: NoorDesignSystem.primaryGreen,
              title: 'تنبيه قبل الصلاة',
              subtitle: 'قبل ${_settings.prayerNotificationMinutesBefore} دقائق',
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
                    Text('قبل الصلاة بـ', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
                    Text('${_settings.prayerNotificationMinutesBefore} دقائق',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Slider(
                value: _settings.prayerNotificationMinutesBefore.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                activeColor: NoorDesignSystem.primaryGreen,
                label: '${_settings.prayerNotificationMinutesBefore} د',
                onChanged: (v) => _updateSettings(
                  _settings.copyWith(prayerNotificationMinutesBefore: v.round()),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 24),

          // ── Khatmah Reminder ──
          _SectionHeader(icon: Icons.auto_stories_rounded, title: 'تذكير القراءة اليومية'),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _SettingsTile(
              icon: Icons.auto_stories_rounded,
              iconColor: NoorDesignSystem.goldAccent,
              title: 'تذكير الختمة اليومي',
              subtitle: _settings.khatmahReminderEnabled
                  ? 'الساعة ${_settings.khatmahReminderHour.toString().padLeft(2, '0')}:${_settings.khatmahReminderMinute.toString().padLeft(2, '0')}'
                  : 'معطل',
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
                    Icon(Icons.access_time_rounded, size: 20, color: NoorDesignSystem.goldAccent),
                    const SizedBox(width: 12),
                    Text('وقت التذكير', style: GoogleFonts.cairo(fontSize: 14)),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => _pickTime(),
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
          _SectionHeader(icon: Icons.do_not_disturb_rounded, title: 'ساعات الهدوء'),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _SettingsTile(
              icon: Icons.do_not_disturb_on_rounded,
              iconColor: NoorDesignSystem.sleepColor,
              title: 'ساعات الهدوء',
              subtitle: _settings.quietHoursEnabled
                  ? 'من ${_settings.quietHoursStart}:00 إلى ${_settings.quietHoursEnd}:00'
                  : 'معطل',
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
                HapticFeedback.mediumImpact();
                // Apply all notification schedules
                if (_settings.adhkarMorningEnabled || _settings.adhkarEveningEnabled) {
                  await SmartNotificationEngine.scheduleAdhkarNotifications(
                    latitude: 21.4225,
                    longitude: 39.8262,
                    morningEnabled: _settings.adhkarMorningEnabled,
                    eveningEnabled: _settings.adhkarEveningEnabled,
                  );
                }
                if (_settings.khatmahReminderEnabled) {
                  await SmartNotificationEngine.scheduleKhatmahReminder(
                    hour: _settings.khatmahReminderHour,
                    minute: _settings.khatmahReminderMinute,
                    message: 'حان وقت ورد القراءة اليومي',
                  );
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ تم تحديث الإشعارات', style: GoogleFonts.cairo()),
                      backgroundColor: NoorDesignSystem.primaryGreen,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: Text('تطبيق الإعدادات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Column(children: children),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _settings.khatmahReminderHour, minute: _settings.khatmahReminderMinute),
    );
    if (picked != null) {
      _updateSettings(_settings.copyWith(
        khatmahReminderHour: picked.hour,
        khatmahReminderMinute: picked.minute,
      ));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

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
        )),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
      value: value,
      activeColor: NoorDesignSystem.primaryGreen,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
    );
  }
}
