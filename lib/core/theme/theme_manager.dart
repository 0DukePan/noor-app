import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 🎨 مدير السمات - Theme Manager
/// 
/// Features:
/// - Dark/Light toggle
/// - System theme follow
/// - Persistent storage
/// - Smooth transitions
class ThemeManager {
  static Box? _settingsBox;
  
  static Future<void> init() async {
    _settingsBox = await Hive.openBox('theme_settings');
  }

  /// الوضع الحالي
  static ThemeMode getSavedThemeMode() {
    final mode = _settingsBox?.get('theme_mode', defaultValue: 'system');
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  /// حفظ الوضع
  static Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr;
    switch (mode) {
      case ThemeMode.light: modeStr = 'light'; break;
      case ThemeMode.dark: modeStr = 'dark'; break;
      default: modeStr = 'system';
    }
    await _settingsBox?.put('theme_mode', modeStr);
  }
}

/// Provider للسمة
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeManager.getSavedThemeMode());

  void setThemeMode(ThemeMode mode) {
    state = mode;
    ThemeManager.setThemeMode(mode);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  void cycleTheme() {
    switch (state) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
        break;
      default:
        setThemeMode(ThemeMode.light);
    }
  }
}

/// سمة فاتحة
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1B5E20), // Islamic green
    brightness: Brightness.light,
  ),
  fontFamily: 'Amiri',
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
);

/// سمة داكنة
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF4CAF50), // Lighter green for dark
    brightness: Brightness.dark,
  ),
  fontFamily: 'Amiri',
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Color(0xFF1E1E1E),
  ),
  cardTheme: CardTheme(
    elevation: 0,
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
);

/// أيقونة زر تبديل السمة
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return IconButton(
      icon: Icon(_getIcon(themeMode)),
      onPressed: () {
        ref.read(themeModeProvider.notifier).cycleTheme();
      },
      tooltip: _getTooltip(themeMode),
    );
  }

  IconData _getIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return Icons.light_mode;
      case ThemeMode.dark: return Icons.dark_mode;
      default: return Icons.brightness_auto;
    }
  }

  String _getTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'الوضع الفاتح';
      case ThemeMode.dark: return 'الوضع الداكن';
      default: return 'حسب النظام';
    }
  }
}

/// بطاقة اختيار السمة (للإعدادات)
class ThemeSelectorCard extends ConsumerWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المظهر',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ThemeOption(
                  icon: Icons.light_mode,
                  label: 'فاتح',
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  icon: Icons.dark_mode,
                  label: 'داكن',
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  icon: Icons.brightness_auto,
                  label: 'تلقائي',
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () => ref.read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primaryContainer 
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
