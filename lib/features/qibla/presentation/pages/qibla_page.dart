import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/qibla_engine.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 🧭 صفحة القبلة الاحترافية - Professional Qibla Page
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> with SingleTickerProviderStateMixin {
  // Compass data
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentHeading = 0;
  double _compassAccuracy = -1;
  
  // Location & Qibla
  QiblaResult? _qiblaResult;
  bool _isLoadingLocation = true;
  String? _locationWarning;
  
  // UI State
  bool _isLocked = false;
  double _lockedDirection = 0;
  bool _isDirectionLocked = false;
  bool _showDebug = false;
  
  // Timers
  Timer? _autoTimeoutTimer;
  
  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Locale cache (set in didChangeDependencies: safe before any channel
  // future resumes, and never touches context across an async gap).
  late AppLocalizations? _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.record('qibla_viewed');
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _initializeQibla();
  }

  Future<void> _initializeQibla() async {
    // 1. Get location
    await _getLocation();
    
    // 2. Start compass
    _startCompass();
    
    // 3. Start auto-timeout
    _startAutoTimeout();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationWarning = null;
    });

    try {
      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation(_l10n!.qiblaPermWarning);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Calculate Qibla
      final result = QiblaResult.calculate(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _qiblaResult = result;
        _isLoadingLocation = false;
      });
    } on Exception {
      // Location unavailable — show the fallback city's qibla with a warning
      // instead of blocking the whole screen on an error.
      _useFallbackLocation(_l10n!.qiblaFallbackWarning);
    }
  }

  /// Sets a fallback Qibla (Riyadh) and shows a warning banner.
  void _useFallbackLocation(String warning) {
    setState(() {
      _locationWarning = warning;
      _qiblaResult = QiblaResult.calculate(
        latitude: 24.7136,
        longitude: 46.6753,
      );
      _isLoadingLocation = false;
    });
  }

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (!mounted || _isLocked) return;

        setState(() {
          _currentHeading = event.heading ?? 0;
          _compassAccuracy = event.accuracy ?? -1;
        });
      },
      onError: (Object _) {
        // Compass unavailable (no sensor, plugin failure): degrade to
        // "unknown accuracy" instead of surfacing an unhandled stream error.
        if (!mounted) return;
        setState(() => _compassAccuracy = -1);
      },
    );
  }

  void _startAutoTimeout() {
    if (_isDirectionLocked) return;
    
    _autoTimeoutTimer?.cancel();
    _autoTimeoutTimer = Timer(const Duration(seconds: 60), () {
      if (mounted && !_isLocked && !_isDirectionLocked) {
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.battery_saver),
        title: Text(l10n.qiblaTimeoutTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(l10n.qiblaTimeoutBody, style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.qiblaClose, style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startAutoTimeout();
            },
            child: Text(l10n.qiblaContinue, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLock() async {
    await HapticFeedback.mediumImpact();
    
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _lockedDirection = _currentHeading;
        _autoTimeoutTimer?.cancel();
      } else {
        _startAutoTimeout();
      }
    });
  }

  Future<void> _toggleMosqueMode() async {
    await HapticFeedback.heavyImpact();
    if (!mounted) return;

    setState(() {
      _isDirectionLocked = !_isDirectionLocked;
      if (_isDirectionLocked) {
        _isLocked = true;
        _lockedDirection = _currentHeading;
        _autoTimeoutTimer?.cancel();
      } else {
        _isLocked = false;
        _startAutoTimeout();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isDirectionLocked
              ? AppLocalizations.of(context).qiblaLockedSnack
              : AppLocalizations.of(context).qiblaUnlockedSnack,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: _isDirectionLocked ? Colors.green : null,
      ),
    );
  }

  void _showCalibrationHelp() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.help_outline, size: 48),
        title: Text(l10n.qiblaCalibTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.qiblaCalibHint,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(l10n.qiblaCalib1, style: GoogleFonts.cairo()),
            Text(l10n.qiblaCalib2, style: GoogleFonts.cairo()),
            Text(l10n.qiblaCalib3, style: GoogleFonts.cairo()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '∞',
                style: TextStyle(fontSize: 48),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).tadGotIt, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Helper to prevent NaN in rotation calculations
  double _safeAngle(double qiblaAngle, double heading) {
    final angle = (qiblaAngle - heading) * (math.pi / 180);
    return angle.isFinite ? angle : 0.0;
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _autoTimeoutTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = QiblaEngine.evaluateAccuracy(_compassAccuracy);
    
    // Calculate Qibla deviation
    double qiblaDeviation = 0;
    var alignment = QiblaAlignment.far;
    
    if (_qiblaResult != null) {
      final heading = _isLocked ? _lockedDirection : _currentHeading;
      qiblaDeviation = QiblaEngine.getDeviationFromQibla(
        currentHeading: heading,
        qiblaDirection: _qiblaResult!.magneticQiblaDirection,
      );
      alignment = QiblaEngine.getAlignment(
        currentHeading: heading,
        qiblaDirection: _qiblaResult!.magneticQiblaDirection,
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent, // Handled by gradient container
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).qiblaTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // Debug toggle
          IconButton(
            icon: Icon(_showDebug ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () => setState(() => _showDebug = !_showDebug),
          ),
          // Calibration help
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showCalibrationHelp,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoadingLocation
              ? _buildLoadingView()
              : Column(
                  children: [
                    if (_locationWarning != null)
                      _buildLocationWarning(),
                    Expanded(
                      child: _buildQiblaView(theme, accuracy, qiblaDeviation, alignment),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLocationWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationWarning!,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _getLocation,
            child: Text(
              AppLocalizations.of(context).commonRetry,
              style: const TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).qiblaLocating,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaView(
    ThemeData theme,
    CompassAccuracy accuracy,
    double deviation,
    QiblaAlignment alignment,
  ) {
    return Column(
      children: [
        // Status bar
        _buildStatusBar(accuracy, alignment),
        
        // Compass
        Expanded(
          // The compass is purely visual; announce the two angles it shows so
          // a screen reader gets the same information (docs/accessibility.md).
          child: Semantics(
            label: AppLocalizations.of(context).a11yQiblaCompass(
              (_qiblaResult?.magneticQiblaDirection ?? 0).toStringAsFixed(0),
              (_isLocked ? _lockedDirection : _currentHeading)
                  .toStringAsFixed(0),
            ),
            child: _buildCompass(deviation, alignment),
          ),
        ),
        
        // Info & Controls
        _buildInfoPanel(alignment),
        
        // Action buttons
        _buildActionButtons(),
        
        // Debug info
        if (_showDebug) _buildDebugInfo(accuracy, deviation),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatusBar(CompassAccuracy accuracy, QiblaAlignment alignment) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: alignment.isAligned 
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: alignment.isAligned 
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Accuracy indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getAccuracyColor(accuracy).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(accuracy.icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  accuracy.arabicName,
                  style: GoogleFonts.cairo(
                    color: _getAccuracyColor(accuracy),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status message
          Expanded(
            child: Text(
              _isLocked
                  ? (_isDirectionLocked
                      ? AppLocalizations.of(context).qiblaLockedBadge
                      : AppLocalizations.of(context).qiblaPinned)
                  : alignment.message,
              style: GoogleFonts.cairo(
                color: alignment.isAligned ? Colors.green : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Calibration warning
          if (accuracy.needsCalibration)
            IconButton(
              icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              onPressed: _showCalibrationHelp,
              tooltip: AppLocalizations.of(context).qiblaCalibNeeded,
              padding: EdgeInsets.zero,
              // Keeps the small glyph but a >=48 dp tap target (a11y guideline).
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
        ],
      ),
    );
  }

  Widget _buildCompass(double deviation, QiblaAlignment alignment) {
    final qiblaAngle = _qiblaResult?.magneticQiblaDirection ?? 0;
    final heading = _isLocked ? _lockedDirection : _currentHeading;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Compass background
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: CustomPaint(
            painter: _CompassPainter(
              heading: heading,
              qiblaDirection: qiblaAngle,
              isAligned: alignment.isAligned,
            ),
          ),
        ),
        
        // Qibla arrow
        Transform.rotate(
          angle: _safeAngle(qiblaAngle, heading),
          child: ScaleTransition(
            scale: alignment.isAligned ? _pulseAnimation : const AlwaysStoppedAnimation(1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation_rounded,
                  size: 80,
                  color: alignment.isAligned ? const Color(0xFF4CAF50) : const Color(0xFFFFD700),
                  shadows: [
                    BoxShadow(
                      color: (alignment.isAligned ? Colors.green : Colors.amber).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: (alignment.isAligned ? Colors.green : const Color(0xFFFFD700))
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (alignment.isAligned ? Colors.green : const Color(0xFFFFD700))
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).qiblaKaaba,
                    style: GoogleFonts.cairo(
                      color: alignment.isAligned ? const Color(0xFF4CAF50) : const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Lock indicator
        if (_isLocked)
          Positioned(
            top: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDirectionLocked ? Colors.green.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isDirectionLocked ? Colors.green : Colors.blue,
                ),
              ),
              child: Icon(
                _isDirectionLocked ? Icons.mosque : Icons.lock,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoPanel(QiblaAlignment alignment) {
    if (_qiblaResult == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoItem(
            icon: Icons.explore_rounded,
            label: AppLocalizations.of(context).qiblaDirection,
            value: '${_qiblaResult!.trueQiblaDirection.toStringAsFixed(1)}°',
          ),
          Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.1)),
          _InfoItem(
            icon: Icons.straighten_rounded,
            label: AppLocalizations.of(context).qiblaDistance,
            value: QiblaEngine.formatDistance(_qiblaResult!.distanceToKaaba),
          ),
          Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.1)),
          _InfoItem(
            icon: Icons.near_me_rounded,
            label: AppLocalizations.of(context).qiblaBearing,
            value: _qiblaResult!.directionText,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Lock button
          Expanded(
            child: FilledButton.icon(
              onPressed: _toggleLock,
              icon: Icon(_isLocked ? Icons.lock_open_rounded : Icons.lock_rounded),
              label: Text(
                _isLocked
                    ? AppLocalizations.of(context).qiblaUnlock
                    : AppLocalizations.of(context).qiblaLock,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _isLocked ? Colors.green : Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Mosque mode
          FilledButton.tonal(
            onPressed: _toggleMosqueMode,
            style: FilledButton.styleFrom(
              backgroundColor: _isDirectionLocked 
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Icon(
              Icons.mosque_rounded,
              color: _isDirectionLocked ? Colors.green : Colors.white,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Refresh location
          FilledButton.tonal(
            onPressed: _getLocation,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Icon(Icons.my_location_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo(CompassAccuracy accuracy, double deviation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧭 Heading: ${_currentHeading.toStringAsFixed(1)}°', 
              style: const TextStyle(color: Colors.white70, fontSize: 12),),
          Text('🕋 Qibla: ${_qiblaResult?.magneticQiblaDirection.toStringAsFixed(1) ?? '--'}°', 
              style: const TextStyle(color: Colors.white70, fontSize: 12),),
          Text('📐 Deviation: ${deviation.toStringAsFixed(1)}°', 
              style: const TextStyle(color: Colors.white70, fontSize: 12),),
          Text('🧲 Declination: ${_qiblaResult?.declination.toStringAsFixed(1) ?? '--'}°', 
              style: const TextStyle(color: Colors.white70, fontSize: 12),),
          Text('📊 Accuracy: ${_compassAccuracy.toStringAsFixed(1)}° (${accuracy.arabicName})', 
              style: const TextStyle(color: Colors.white70, fontSize: 12),),
        ],
      ),
    );
  }

  Color _getAccuracyColor(CompassAccuracy accuracy) {
    switch (accuracy) {
      case CompassAccuracy.high: return Colors.green;
      case CompassAccuracy.medium: return Colors.yellow;
      case CompassAccuracy.low: return Colors.orange;
      case CompassAccuracy.unreliable: return Colors.red;
      case CompassAccuracy.unknown: return Colors.grey;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _InfoItem extends StatelessWidget {

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _CompassPainter extends CustomPainter {

  _CompassPainter({
    required this.heading,
    required this.qiblaDirection,
    required this.isAligned,
  });
  final double heading;
  final double qiblaDirection;
  final bool isAligned;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (var i = 0; i < 360; i += 10) {
      final angle = (i - heading) * (math.pi / 180) - math.pi / 2;
      final isCardinal = i % 90 == 0;
      final innerRadius = isCardinal ? radius - 15 : radius - 8;
      
      final x1 = center.dx + radius * math.cos(angle);
      final y1 = center.dy + radius * math.sin(angle);
      final x2 = center.dx + innerRadius * math.cos(angle);
      final y2 = center.dy + innerRadius * math.sin(angle);
      
      tickPaint
        ..strokeWidth = isCardinal ? 2 : 1
        ..color = isCardinal 
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.2);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // Draw cardinal directions
    final directions = ['ش', 'شر', 'ج', 'غ'];
    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    
    for (var i = 0; i < 4; i++) {
      final angle = (i * 90 - heading) * (math.pi / 180) - math.pi / 2;
      final x = center.dx + (radius - 35) * math.cos(angle);
      final y = center.dy + (radius - 35) * math.sin(angle);

      textPainter
        ..text = TextSpan(
          text: directions[i],
          style: TextStyle(
            color: i == 0 ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.6),
            fontSize: i == 0 ? 18 : 14,
            fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        )
        ..layout()
        ..paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.qiblaDirection != qiblaDirection ||
        oldDelegate.isAligned != isAligned;
  }
}
