import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../../../core/services/smart_notification_service.dart';

/// صفحة إعدادات الإشعارات - Notification Settings Page
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _prayerNotifications = true;
  bool _prePrayerReminder = true;
  bool _autoDnd = true;
  int _autoDndDuration = 30;
  bool _morningAdhkar = true;
  bool _eveningAdhkar = true;
  bool _dailyQuran = true;
  TimeOfDay _quranReminderTime = const TimeOfDay(hour: 10, minute: 0);
  bool _weeklySummary = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await SmartNotificationService.areNotificationsEnabled();
    if (!hasPermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: NoorTheme.primary),
            SizedBox(width: 8),
            Text('تفعيل الإشعارات'),
          ],
        ),
        content: const Text(
          'للحصول على تذكير بمواقيت الصلاة والأذكار، يرجى السماح بالإشعارات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SmartNotificationService.requestPermission();
            },
            child: const Text('السماح'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات الذكية'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NoorTheme.spacingMd),
        children: [
          // DND Status Card
          if (SmartNotificationService.isDndActive)
            Container(
              margin: const EdgeInsets.only(bottom: NoorTheme.spacingMd),
              padding: const EdgeInsets.all(NoorTheme.spacingMd),
              decoration: BoxDecoration(
                color: NoorTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                border: Border.all(color: NoorTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.do_not_disturb_on_rounded, color: NoorTheme.primary),
                  const SizedBox(width: NoorTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'وضع الصمت مفعّل 🤫',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: NoorTheme.primary,
                              ),
                        ),
                        if (SmartNotificationService.dndEndTime != null)
                          Text(
                            'سينتهي الساعة ${SmartNotificationService.dndEndTime!.hour}:${SmartNotificationService.dndEndTime!.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Disable DND manually
                      setState(() {});
                    },
                    child: const Text('إيقاف'),
                  ),
                ],
              ),
            ),

          // Prayer Notifications Section
          _SectionHeader(title: 'تذكير الصلاة 🕌'),
          _SettingTile(
            title: 'إشعارات وقت الصلاة',
            subtitle: 'تنبيه عند دخول وقت الصلاة',
            value: _prayerNotifications,
            onChanged: (value) => setState(() => _prayerNotifications = value),
          ),
          _SettingTile(
            title: 'تذكير قبل الصلاة',
            subtitle: 'تنبيه قبل 15 دقيقة من وقت الصلاة',
            value: _prePrayerReminder,
            onChanged: (value) => setState(() => _prePrayerReminder = value),
            enabled: _prayerNotifications,
          ),

          const SizedBox(height: NoorTheme.spacingMd),

          // Auto DND Section
          _SectionHeader(title: 'وضع الصمت التلقائي 🤫'),
          _SettingTile(
            title: 'صامت وقت الصلاة',
            subtitle: 'تفعيل الوضع الصامت تلقائياً عند دخول وقت الصلاة',
            value: _autoDnd,
            onChanged: (value) => setState(() => _autoDnd = value),
          ),
          if (_autoDnd)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NoorTheme.spacingMd,
                vertical: NoorTheme.spacingSm,
              ),
              child: Row(
                children: [
                  const Text('مدة الصمت:'),
                  const Spacer(),
                  DropdownButton<int>(
                    value: _autoDndDuration,
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                      DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                      DropdownMenuItem(value: 45, child: Text('45 دقيقة')),
                      DropdownMenuItem(value: 60, child: Text('ساعة')),
                    ],
                    onChanged: (value) => setState(() => _autoDndDuration = value!),
                  ),
                ],
              ),
            ),

          const SizedBox(height: NoorTheme.spacingMd),

          // Adhkar Section
          _SectionHeader(title: 'تذكير الأذكار 📿'),
          _SettingTile(
            title: 'أذكار الصباح',
            subtitle: 'تذكير يومي بأذكار الصباح',
            value: _morningAdhkar,
            onChanged: (value) async {
              setState(() => _morningAdhkar = value);
              if (value) {
                await SmartNotificationService.scheduleMorningAdhkar();
              }
            },
          ),
          _SettingTile(
            title: 'أذكار المساء',
            subtitle: 'تذكير يومي بأذكار المساء',
            value: _eveningAdhkar,
            onChanged: (value) async {
              setState(() => _eveningAdhkar = value);
              if (value) {
                await SmartNotificationService.scheduleEveningAdhkar();
              }
            },
          ),

          const SizedBox(height: NoorTheme.spacingMd),

          // Quran Section
          _SectionHeader(title: 'تذكير القرآن 📖'),
          _SettingTile(
            title: 'وردك اليومي',
            subtitle: 'تذكير يومي بتلاوة القرآن',
            value: _dailyQuran,
            onChanged: (value) async {
              setState(() => _dailyQuran = value);
              if (value) {
                await SmartNotificationService.scheduleDailyQuranReminder(
                  hour: _quranReminderTime.hour,
                  minute: _quranReminderTime.minute,
                );
              }
            },
          ),
          if (_dailyQuran)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NoorTheme.spacingMd,
                vertical: NoorTheme.spacingSm,
              ),
              child: Row(
                children: [
                  const Text('وقت التذكير:'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _quranReminderTime,
                      );
                      if (time != null) {
                        setState(() => _quranReminderTime = time);
                        await SmartNotificationService.scheduleDailyQuranReminder(
                          hour: time.hour,
                          minute: time.minute,
                        );
                      }
                    },
                    child: Text(
                      '${_quranReminderTime.hour}:${_quranReminderTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: NoorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: NoorTheme.spacingMd),

          // Summary Section
          _SectionHeader(title: 'ملخص الأسبوع 📊'),
          _SettingTile(
            title: 'ملخص أسبوعي',
            subtitle: 'إحصائيات العبادة كل جمعة',
            value: _weeklySummary,
            onChanged: (value) => setState(() => _weeklySummary = value),
          ),

          const SizedBox(height: NoorTheme.spacingXl),

          // Quick Actions
          _SectionHeader(title: 'إجراءات سريعة'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await HapticFeedback.mediumImpact();
                    await SmartNotificationService.enableSilentMode(
                      durationMinutes: _autoDndDuration,
                    );
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('وضع الصمت مفعل لمدة $_autoDndDuration دقيقة'),
                          backgroundColor: NoorTheme.primary,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.do_not_disturb_on_rounded),
                  label: const Text('تفعيل الصامت'),
                ),
              ),
              const SizedBox(width: NoorTheme.spacingMd),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await SmartNotificationService.showWeeklySummary(
                      prayersCompleted: 35,
                      adhkarCompleted: 120,
                      pagesRead: 15,
                    );
                  },
                  icon: const Icon(Icons.preview_rounded),
                  label: const Text('معاينة الملخص'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: NoorTheme.spacingMd,
        bottom: NoorTheme.spacingSm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value && enabled,
        onChanged: enabled ? onChanged : null,
        activeColor: NoorTheme.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
