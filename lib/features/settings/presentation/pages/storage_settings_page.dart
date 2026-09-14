import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/hive_service.dart';
import '../../../../core/services/quran_audio_engine.dart';
import '../../../../core/services/silent_ui_controller.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../search/data/data_sources/search_local_data_source.dart';

/// 🗄️ إعدادات التخزين والأداء — Storage & Performance Settings
class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  Map<String, dynamic>? _cacheStats;
  bool _clearing = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    try {
      setState(() {
        _cacheStats = {
          'surahs_cached': HiveService.surahsBox.length,
          'hadiths_cached': HiveService.hadithsBox.length,
          'adhkar_cached': HiveService.adhkarBox.length,
        };
      });
    } on Exception catch (_) {
      setState(() => _cacheStats = {'surahs_cached': 0, 'hadiths_cached': 0, 'adhkar_cached': 0});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.bgLight,
      appBar: AppBar(
        title: Text(l10n.storageTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Cache Stats ──
          _SectionHeader(icon: Icons.storage_rounded, title: l10n.storageCacheSection),
          const SizedBox(height: 8),
          _buildCacheStatsCard(isDark, l10n),
          const SizedBox(height: 24),

          // ── Cache Actions ──
          _SectionHeader(icon: Icons.cleaning_services_rounded, title: l10n.storageManageSection),
          const SizedBox(height: 8),
          _buildCacheActionsCard(isDark, l10n),
          const SizedBox(height: 24),

          // ── Silent UI ──
          _SectionHeader(icon: Icons.notifications_paused_rounded, title: l10n.storageSilentSection),
          const SizedBox(height: 8),
          _buildSilentUICard(isDark, l10n),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCacheStatsCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Column(
        children: [
          if (_cacheStats != null) ...[
            _StatRow(label: l10n.storageSurahs, value: '${_cacheStats!['surahs_cached'] ?? 0}', icon: Icons.auto_stories_rounded),
            const Divider(height: 20),
            _StatRow(label: l10n.storageHadiths, value: '${_cacheStats!['hadiths_cached'] ?? 0}', icon: Icons.format_quote_rounded),
            const Divider(height: 20),
            _StatRow(label: l10n.storageAdhkar, value: '${_cacheStats!['adhkar_cached'] ?? 0}', icon: Icons.spa_rounded),
          ] else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildCacheActionsCard(bool isDark, AppLocalizations l10n) {
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Clear cache
              ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
            ),
            title: Text(l10n.storageClearTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.storageClearSubtitle, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
            trailing: _clearing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            onTap: _clearing ? null : _clearCache,
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(height: 24),

          // Refresh statistics (there is no cloud to sync with)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NoorDesignSystem.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, color: NoorDesignSystem.primaryGreen, size: 20),
            ),
            title: Text(l10n.storageRefreshTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.storageRefreshSubtitle, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
            trailing: _syncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            onTap: _syncing ? null : _refreshStats,
            contentPadding: EdgeInsets.zero,
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSilentUICard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.storageSilentBody,
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey, height: 1.6),
          ),
          const SizedBox(height: 16),

          // Test gentle notification
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                SilentUIController.showGentleNotification(
                  context,
                  message: l10n.storageGentleSample,
                  icon: Icons.info_outline_rounded,
                );
              },
              icon: const Icon(Icons.preview_rounded, size: 18),
              label: Text(l10n.storagePreviewGentle, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: NoorDesignSystem.primaryGreen,
                side: const BorderSide(color: NoorDesignSystem.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Test success notification
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                SilentUIController.showSuccess(context, l10n.storageSavedOk);
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(l10n.storagePreviewSuccess, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: NoorDesignSystem.goldAccent,
                side: const BorderSide(color: NoorDesignSystem.goldAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    setState(() => _clearing = true);
    try {
      await HiveService.clearAll();
      // Clear the downloaded recitation cache too.
      await QuranAudioEngine.clearCache();
      // Clear the unified search index (rebuilds lazily on next search).
      await SearchLocalDataSource.clearIndex();
      _loadStats();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SilentUIController.showSuccess(context, l10n.storageCacheCleared);
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _refreshStats() async {
    setState(() => _syncing = true);
    try {
      _loadStats();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SilentUIController.showSuccess(context, l10n.storageStatsUpdated);
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

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

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: NoorDesignSystem.primaryGreen.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.cairo(fontSize: 14))),
        Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
