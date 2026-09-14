import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/quran_audio_engine.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/theme_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../search/data/data_sources/search_local_data_source.dart';

/// صفحة الإعدادات - Settings Page
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = '${info.version}+${info.buildNumber}';
      });
    } on Object {
      // Platform channel unavailable (e.g. tests) — keep the fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final hapticEnabled = ref.watch(hapticEnabledProvider);
    final fontScale = ref.watch(fontScaleProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? NoorDesignSystem.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: NoorDesignSystem.textTheme.titleLarge),
        backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.creamWhite,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(NoorDesignSystem.spacingL),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NoorDesignSystem.emeraldGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_suggest_rounded, size: 48, color: NoorDesignSystem.emeraldGreen),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.settingsHeader,
                  style: NoorDesignSystem.textTheme.titleMedium,
                ),
                Text(
                  l10n.settingsHeaderSubtitle,
                  style: NoorDesignSystem.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Theme Mode
          _buildSectionHeader(l10n.settingsAppearance, Icons.palette_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Row(
              children: [
                _buildThemeModeChip(ThemeMode.light, l10n.settingsThemeLight, Icons.wb_sunny_rounded, themeMode),
                _buildThemeModeChip(ThemeMode.dark, l10n.settingsThemeDark, Icons.nightlight_round, themeMode),
                _buildThemeModeChip(ThemeMode.system, l10n.settingsThemeSystem, Icons.brightness_auto_rounded, themeMode),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Display
          _buildSectionHeader(l10n.settingsReading, Icons.text_fields_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Material(
              type: MaterialType.card,
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.settingsFontSize, style: NoorDesignSystem.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('أ', style: NoorDesignSystem.textTheme.bodySmall),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: NoorDesignSystem.emeraldGreen,
                            inactiveTrackColor: NoorDesignSystem.emeraldGreen.withValues(alpha: 0.2),
                            thumbColor: NoorDesignSystem.emeraldGreen,
                          ),
                          child: Slider(
                            value: fontScale,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            onChanged: (value) {
                              ref.read(fontScaleProvider.notifier).state = value;
                              ThemeService.setFontScale(value);
                            },
                          ),
                        ),
                      ),
                      Text('أ', style: NoorDesignSystem.textTheme.titleLarge),
                    ],
                  ),
                  Center(
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: GoogleFonts.amiri(
                        fontSize: 18 * fontScale,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Settings List
          _buildSectionHeader(l10n.settingsGeneral, Icons.tune_rounded),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Material(
              type: MaterialType.card,
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: l10n.settingsHaptics,
                    subtitle: l10n.settingsHapticsSubtitle,
                    value: hapticEnabled,
                    onChanged: (value) {
                      ref.read(hapticEnabledProvider.notifier).state = value;
                      ThemeService.setHapticEnabled(enabled: value);
                      if (value) HapticFeedback.lightImpact();
                    },
                  ),
                  const Divider(height: 1),
                  // Anonymous usage statistics: off by default, persisted.
                  _buildSwitchTile(
                    title: l10n.settingsAnalytics,
                    subtitle: AnalyticsService.optedIn
                        ? l10n.settingsAnalyticsOn
                        : l10n.settingsAnalyticsOff,
                    value: AnalyticsService.optedIn,
                    onChanged: (value) {
                      AnalyticsService.setOptedIn(value: value);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    title: l10n.settingsClearCache,
                    subtitle: l10n.settingsClearCacheSubtitle,
                    icon: Icons.delete_outline_rounded,
                    onTap: _showClearCacheDialog,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Advanced Settings Navigation
          _buildSectionHeader(l10n.settingsAdvanced, Icons.widgets_rounded),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Material(
              type: MaterialType.card,
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildListTile(
                    title: l10n.settingsNotifications,
                    subtitle: l10n.settingsNotificationsSubtitle,
                    icon: Icons.notifications_rounded,
                    onTap: () => context.go('/tools/settings/notifications'),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    title: l10n.settingsStorage,
                    subtitle: l10n.settingsStorageSubtitle,
                    icon: Icons.storage_rounded,
                    onTap: () => context.go('/tools/settings/storage'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Privacy
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Material(
              type: MaterialType.card,
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildListTile(
                    title: l10n.settingsPrivacy,
                    subtitle: l10n.settingsPrivacySubtitle,
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => _showPrivacySheet(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // About
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Material(
              type: MaterialType.card,
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildListTile(
                    title: l10n.settingsAbout,
                    icon: Icons.info_outline_rounded,
                    onTap: () => _showAboutSheet(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 50),
          Center(
            child: Text(
              l10n.settingsAppVersion(_version),
              style: NoorDesignSystem.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Honest privacy statement — what the app collects and what it does not.
  void _showPrivacySheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsPrivacy,
                style: NoorDesignSystem.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _PrivacyRow(
                icon: Icons.check_circle_outline,
                text: l10n.settingsPrivacyRowOffline,
              ),
              _PrivacyRow(
                icon: Icons.check_circle_outline,
                text: l10n.settingsPrivacyRowTracking,
              ),
              _PrivacyRow(
                icon: Icons.bar_chart_rounded,
                text: l10n.settingsAnalyticsPrivacy,
              ),
              _PrivacyRow(
                icon: Icons.location_on_outlined,
                text: l10n.settingsPrivacyRowLocation,
              ),
              _PrivacyRow(
                icon: Icons.bug_report_outlined,
                text: l10n.settingsPrivacyRowCrash,
              ),
              _PrivacyRow(
                icon: Icons.lock_outline,
                text: l10n.settingsPrivacyRowNotes,
              ),
              _PrivacyRow(
                icon: Icons.cloud_off_outlined,
                text: l10n.settingsPrivacyRowSync,
              ),
              _PrivacyRow(
                icon: Icons.link_outlined,
                text: l10n.settingsPrivacyRowNetwork,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settingsAppName,
                style: NoorDesignSystem.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NoorDesignSystem.emeraldGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.settingsAboutBody,
                textAlign: TextAlign.center,
                style: NoorDesignSystem.textTheme.bodyMedium?.copyWith(
                  color: NoorDesignSystem.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.settingsAppVersion(_version),
                style: NoorDesignSystem.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: NoorDesignSystem.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: NoorDesignSystem.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 20, color: NoorDesignSystem.emeraldGreen),
      ],
    );
  }

  Widget _buildThemeModeChip(ThemeMode mode, String label, IconData icon, ThemeMode current) {
    final isSelected = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(themeModeProvider.notifier).state = mode;
          ThemeService.setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? NoorDesignSystem.emeraldGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium - 4),
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.white : NoorDesignSystem.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : NoorDesignSystem.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: NoorDesignSystem.textTheme.labelLarge),
      subtitle: Text(subtitle, style: NoorDesignSystem.textTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: NoorDesignSystem.emeraldGreen,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    // Wrapped in a Material so the ListTile paints its ink on its own surface
    // (the surrounding white DecoratedBox would otherwise hide it and trip the
    // framework's debug assertion).
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: NoorDesignSystem.textTheme.labelLarge),
        subtitle: subtitle != null ? Text(subtitle, style: NoorDesignSystem.textTheme.bodySmall) : null,
        leading: icon != null ? Icon(icon, color: NoorDesignSystem.textSecondary, size: 20) : null,
        trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: NoorDesignSystem.textSecondary),
      ),
    );
  }

  void _showClearCacheDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(l10n.settingsClearCacheTitle, textAlign: TextAlign.start),
        content: Text(
          l10n.settingsClearCacheBody,
          textAlign: TextAlign.start,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsCancel, style: const TextStyle(color: NoorDesignSystem.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await HiveService.clearAll();
              await QuranAudioEngine.clearCache();
              await SearchLocalDataSource.clearIndex();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settingsCacheCleared)),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: NoorDesignSystem.error),
            child: Text(l10n.settingsClear),
          ),
        ],
      ),
    );
  }
}

/// Row used in the privacy sheet.
class _PrivacyRow extends StatelessWidget {

  const _PrivacyRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: NoorDesignSystem.emeraldGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: NoorDesignSystem.textTheme.bodyMedium,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
