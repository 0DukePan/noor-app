import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';

import '../../../../core/services/mosque_mode_service.dart';
import '../../../../core/services/seasonal_offsets_engine.dart';
import '../../../../core/services/prayer_health_check.dart';
import '../providers/prayer_providers.dart';

/// ⚙️ إعدادات الصلاة المتقدمة — Advanced Prayer Settings
/// Uses PrayerSettingsNotifier via Riverpod — zero setState
class PrayerSettingsPage extends ConsumerStatefulWidget {
  const PrayerSettingsPage({super.key});

  @override
  ConsumerState<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends ConsumerState<PrayerSettingsPage> {
  static const _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const _prayerLabels = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.bgLight,
      appBar: AppBar(
        title: Text('إعدادات الصلاة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Section 1: Adhan Sounds ──
          _SectionHeader(icon: Icons.volume_up_rounded, title: 'الأذان والتنبيهات'),
          const SizedBox(height: 8),
          _buildAdhanSection(theme, isDark),
          const SizedBox(height: 24),

          // ── Section 2: Mosque Mode ──
          _SectionHeader(icon: Icons.mosque_rounded, title: 'وضع المسجد'),
          const SizedBox(height: 8),
          _buildMosqueModeSection(theme, isDark),
          const SizedBox(height: 24),

          // ── Section 3: Seasonal Offsets ──
          _SectionHeader(icon: Icons.tune_rounded, title: 'الإزاحات الموسمية'),
          const SizedBox(height: 8),
          _buildOffsetsSection(theme, isDark),
          const SizedBox(height: 24),

          // ── Section 4: Prayer Health Check ──
          _SectionHeader(icon: Icons.health_and_safety_rounded, title: 'فحص النظام'),
          const SizedBox(height: 8),
          _buildHealthSection(theme, isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHAN SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAdhanSection(ThemeData theme, bool isDark) {
    final settings = ref.watch(prayerSettingsProvider);
    final notifier = ref.read(prayerSettingsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Column(
        children: _prayers.map((prayer) {
          final label = _prayerLabels[prayer] ?? prayer;
          final enabled = settings.adhanEnabled[prayer] ?? true;
          return Column(
            children: [
              SwitchListTile(
                title: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  enabled ? 'الأذان مفعل' : 'الأذان معطل',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: enabled ? NoorDesignSystem.primaryGreen : Colors.grey,
                  ),
                ),
                secondary: Icon(
                  enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: enabled ? NoorDesignSystem.primaryGreen : Colors.grey,
                ),
                value: enabled,
                activeColor: NoorDesignSystem.primaryGreen,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  notifier.toggleAdhan(prayer, v);
                },
              ),
              if (prayer != _prayers.last) Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOSQUE MODE SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMosqueModeSection(ThemeData theme, bool isDark) {
    final settings = ref.watch(prayerSettingsProvider);
    final notifier = ref.read(prayerSettingsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Global toggle
          SwitchListTile(
            title: Text('وضع المسجد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(
              settings.mosqueModeGlobal
                  ? 'يتم كتم الهاتف تلقائيًا عند وقت الصلاة'
                  : 'معطل — يدوي فقط',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            ),
            value: settings.mosqueModeGlobal,
            activeColor: NoorDesignSystem.primaryGreen,
            onChanged: (v) {
              HapticFeedback.mediumImpact();
              notifier.setMosqueMode(v);
            },
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(height: 24),

          // Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المدة', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey)),
              Text('${settings.mosqueDuration} دقيقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: settings.mosqueDuration.toDouble(),
            min: 10,
            max: 60,
            divisions: 5,
            activeColor: NoorDesignSystem.primaryGreen,
            label: '${settings.mosqueDuration} د',
            onChanged: (v) => notifier.setMosqueDuration(v.round()),
          ),

          const Divider(height: 16),

          // Quick buttons
          Text('تفعيل سريع', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _QuickMosqueButton(
                minutes: 10,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  MosqueModeService.quick10Minutes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🕌 وضع المسجد — 10 دقائق', style: GoogleFonts.cairo())),
                  );
                },
              ),
              const SizedBox(width: 8),
              _QuickMosqueButton(
                minutes: 20,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  MosqueModeService.quick20Minutes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🕌 وضع المسجد — 20 دقيقة', style: GoogleFonts.cairo())),
                  );
                },
              ),
              const SizedBox(width: 8),
              _QuickMosqueButton(
                minutes: 30,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  MosqueModeService.quick30Minutes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🕌 وضع المسجد — 30 دقيقة', style: GoogleFonts.cairo())),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEASONAL OFFSETS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOffsetsSection(ThemeData theme, bool isDark) {
    final season = SeasonalOffsetsEngine.getCurrentSeason();
    final offsets = SeasonalOffsetsEngine.getAllCurrentOffsets();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current season badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: NoorDesignSystem.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${season.icon} ${season.arabicName}',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: NoorDesignSystem.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Per-prayer offset rows
          ...offsets.entries.map((entry) {
            final prayerLabel = _prayerLabels[entry.key] ?? entry.key;
            final offsetMinutes = entry.value.inMinutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(prayerLabel, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Slider(
                      value: offsetMinutes.toDouble(),
                      min: -10,
                      max: 10,
                      divisions: 20,
                      activeColor: NoorDesignSystem.goldAccent,
                      label: '${offsetMinutes > 0 ? '+' : ''}$offsetMinutes د',
                      onChanged: (v) {
                        SeasonalOffsetsEngine.setCustomOffset(
                          prayer: entry.key,
                          summerMinutes: v.round(),
                          winterMinutes: v.round(),
                        );
                        ref.invalidate(prayerSettingsProvider);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${offsetMinutes > 0 ? '+' : ''}$offsetMinutes',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: offsetMinutes == 0 ? Colors.grey : NoorDesignSystem.goldAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Reset button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                SeasonalOffsetsEngine.resetOffsets();
                ref.invalidate(prayerSettingsProvider);
              },
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: Text('إعادة تعيين', style: GoogleFonts.cairo(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHealthSection(ThemeData theme, bool isDark) {
    final settings = ref.watch(prayerSettingsProvider);
    final notifier = ref.read(prayerSettingsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Run check button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: settings.healthLoading ? null : () => notifier.runHealthCheck(),
              icon: settings.healthLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.health_and_safety_rounded),
              label: Text(
                settings.healthLoading ? 'جاري الفحص...' : 'تشغيل فحص النظام',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: NoorDesignSystem.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Results
          if (settings.healthReport != null) ...[
            const SizedBox(height: 16),
            _HealthStatusBadge(status: settings.healthReport!.overallStatus),
            const SizedBox(height: 12),
            if (settings.healthReport!.issues.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    Text('كل شيء يعمل بشكل ممتاز!', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              ...settings.healthReport!.issues.map((issue) => _HealthIssueCard(
                issue: issue,
                onFix: () async {
                  await PrayerHealthCheck.attemptFix(issue);
                  notifier.runHealthCheck();
                },
              )),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
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
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUICK MOSQUE BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _QuickMosqueButton extends StatelessWidget {
  final int minutes;
  final VoidCallback onTap;

  const _QuickMosqueButton({required this.minutes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: NoorDesignSystem.primaryGreen,
          side: const BorderSide(color: NoorDesignSystem.primaryGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text('$minutes د', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEALTH STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════════

class _HealthStatusBadge extends StatelessWidget {
  final HealthStatus status;

  const _HealthStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      HealthStatus.healthy: Colors.green,
      HealthStatus.warning: Colors.orange,
      HealthStatus.critical: Colors.red,
    };
    final labels = {
      HealthStatus.healthy: 'النظام سليم',
      HealthStatus.warning: 'يوجد تحذيرات',
      HealthStatus.critical: 'يوجد مشاكل حرجة',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            labels[status] ?? '',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors[status],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEALTH ISSUE CARD
// ═══════════════════════════════════════════════════════════════════════════

class _HealthIssueCard extends StatelessWidget {
  final HealthIssue issue;
  final VoidCallback onFix;

  const _HealthIssueCard({required this.issue, required this.onFix});

  @override
  Widget build(BuildContext context) {
    final severityColors = {
      IssueSeverity.info: Colors.blue,
      IssueSeverity.warning: Colors.orange,
      IssueSeverity.critical: Colors.red,
    };
    final color = severityColors[issue.severity] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(issue.description, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (issue.canAutoFix)
            TextButton(
              onPressed: onFix,
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text('إصلاح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
