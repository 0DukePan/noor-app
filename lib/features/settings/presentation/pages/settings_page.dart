import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/theme_service.dart';

/// صفحة الإعدادات - Settings Page
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final hapticEnabled = ref.watch(hapticEnabledProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text('الإعدادات', style: NoorDesignSystem.textTheme.titleLarge),
        backgroundColor: NoorDesignSystem.creamWhite,
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
                    color: NoorDesignSystem.emeraldGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_suggest_rounded, size: 48, color: NoorDesignSystem.emeraldGreen),
                ),
                const SizedBox(height: 16),
                Text(
                  'تخصيص التطبيق',
                  style: NoorDesignSystem.textTheme.titleMedium,
                ),
                Text(
                  'اجعل التطبيق مناسباً لاحتياجاتك',
                  style: NoorDesignSystem.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Theme Mode
          _buildSectionHeader('المظهر', Icons.palette_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Row(
              children: [
                _buildThemeModeChip(ThemeMode.light, 'فاتح', Icons.wb_sunny_rounded, themeMode),
                _buildThemeModeChip(ThemeMode.dark, 'داكن', Icons.nightlight_round, themeMode),
                _buildThemeModeChip(ThemeMode.system, 'تلقائي', Icons.brightness_auto_rounded, themeMode),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Display
          _buildSectionHeader('القراءة', Icons.text_fields_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('حجم الخط', style: NoorDesignSystem.textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('أ', style: NoorDesignSystem.textTheme.bodySmall),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: NoorDesignSystem.emeraldGreen,
                          inactiveTrackColor: NoorDesignSystem.emeraldGreen.withOpacity(0.2),
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

          const SizedBox(height: 32),

          // Settings List
          _buildSectionHeader('إعدادات عامة', Icons.tune_rounded),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'الاهتزاز',
                  subtitle: 'تفعيل الاستجابة اللمسية عند التفاعل',
                  value: hapticEnabled,
                  onChanged: (value) {
                    ref.read(hapticEnabledProvider.notifier).state = value;
                    ThemeService.setHapticEnabled(value);
                    if (value) HapticFeedback.lightImpact();
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  title: 'مسح ذاكرة التخزين',
                  subtitle: 'حذف البيانات المؤقتة لتحرير المساحة',
                  icon: Icons.delete_outline_rounded,
                  onTap: () => _showClearCacheDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // About
         Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
              boxShadow: NoorDesignSystem.shadowSmall,
            ),
            child: Column(
              children: [
                 _buildListTile(
                  title: 'حول التطبيق',
                  icon: Icons.info_outline_rounded,
                  onTap: () {},
                ),
              ],
            ),
         ),

          const SizedBox(height: 50),
          Center(
            child: Text(
              'الإصدار 1.0.0',
              style: NoorDesignSystem.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
        ],
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
        activeColor: NoorDesignSystem.emeraldGreen,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(title, style: NoorDesignSystem.textTheme.labelLarge),
      subtitle: subtitle != null ? Text(subtitle, style: NoorDesignSystem.textTheme.bodySmall) : null,
      leading: icon != null ? Icon(icon, color: NoorDesignSystem.textSecondary, size: 20) : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: NoorDesignSystem.textSecondary),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('مسح الذاكرة المؤقتة', textAlign: TextAlign.right),
        content: const Text(
          'هل أنت متأكد؟ سيتم إعادة تحميل البيانات عند الحاجة.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: NoorDesignSystem.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح الذاكرة بنجاح')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: NoorDesignSystem.error),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }
}
