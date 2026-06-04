import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/location_trust_engine.dart';

/// ☁️ إعدادات السحابة والموقع — Cloud & Location Settings
/// Wires SupabaseService and LocationTrustEngine
class CloudSettingsPage extends StatefulWidget {
  const CloudSettingsPage({super.key});

  @override
  State<CloudSettingsPage> createState() => _CloudSettingsPageState();
}

class _CloudSettingsPageState extends State<CloudSettingsPage> {
  String _locationInfo = '';
  bool _fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _locationInfo = LocationTrustEngine.getLastLocationInfo();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.bgLight,
      appBar: AppBar(
        title: Text('السحابة والموقع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Location Trust ──
          _SectionHeader(icon: Icons.location_on_rounded, title: 'محرك ثقة الموقع'),
          const SizedBox(height: 8),
          _buildLocationCard(isDark),
          const SizedBox(height: 24),

          // ── Cloud Sync ──
          _SectionHeader(icon: Icons.cloud_rounded, title: 'المزامنة السحابية'),
          const SizedBox(height: 8),
          _buildCloudCard(isDark),
          const SizedBox(height: 24),

          // ── Auth Status ──
          _SectionHeader(icon: Icons.person_rounded, title: 'الحساب'),
          const SizedBox(height: 8),
          _buildAuthCard(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last location info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NoorDesignSystem.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gps_fixed_rounded, color: NoorDesignSystem.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('آخر موقع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(_locationInfo, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Refresh location
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetchingLocation ? null : _refreshLocation,
              icon: _fetchingLocation
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                _fetchingLocation ? 'جاري تحديث الموقع...' : 'تحديث الموقع',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: NoorDesignSystem.primaryGreen,
                side: const BorderSide(color: NoorDesignSystem.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Clear cache
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await LocationTrustEngine.clearCache();
                setState(() {
                  _locationInfo = LocationTrustEngine.getLastLocationInfo();
                });
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('مسح كاش الموقع', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudCard(bool isDark) {
    final isAuth = SupabaseService.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Column(
        children: [
          // Sync status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isAuth ? NoorDesignSystem.primaryGreen : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAuth ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isAuth ? NoorDesignSystem.primaryGreen : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuth ? 'متصل بالسحابة' : 'غير متصل',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      isAuth ? 'بيانات القراءة والمفضلة متزامنة' : 'سجّل دخولك لمزامنة البيانات',
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isAuth) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Sync reading progress
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.book_rounded, color: NoorDesignSystem.primaryGreen, size: 20),
              title: Text('مزامنة تقدم القراءة', style: GoogleFonts.cairo(fontSize: 14)),
              trailing: FilledButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await SupabaseService.syncReadingProgress(
                    surahNumber: 1,
                    verseNumber: 1,
                    page: 1,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ تمت المزامنة', style: GoogleFonts.cairo()),
                        backgroundColor: NoorDesignSystem.primaryGreen,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: NoorDesignSystem.primaryGreen,
                  minimumSize: const Size(80, 36),
                ),
                child: Text('مزامنة', style: GoogleFonts.cairo(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthCard(bool isDark) {
    final user = SupabaseService.currentUser;
    final isAuth = SupabaseService.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: NoorDesignSystem.primaryGreen.withOpacity(0.1),
            radius: 24,
            child: Icon(
              isAuth ? Icons.person_rounded : Icons.person_outline_rounded,
              color: NoorDesignSystem.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuth ? (user?.email ?? 'مستخدم') : 'ضيف',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  isAuth ? 'حساب مفعّل' : 'سجّل لمزامنة بياناتك عبر الأجهزة',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      await LocationTrustEngine.getTrustedLocation(forceRefresh: true);
      setState(() {
        _locationInfo = LocationTrustEngine.getLastLocationInfo();
      });
    } catch (e) {
      setState(() {
        _locationInfo = 'فشل تحديث الموقع: $e';
      });
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }
}

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
