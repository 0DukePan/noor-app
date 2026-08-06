import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/qibla_engine.dart';

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
  String? _locationError;
  
  // UI State
  bool _isLocked = false;
  double _lockedDirection = 0;
  bool _mosqueMode = false;
  bool _showDebug = false;
  
  // Timers
  Timer? _autoTimeoutTimer;
  
  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
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
      _locationError = null;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'الرجاء تفعيل صلاحية الموقع من الإعدادات';
          _isLoadingLocation = false;
        });
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
    } catch (e) {
      setState(() {
        _locationError = 'فشل تحديد الموقع: $e';
        _isLoadingLocation = false;
        
        // Fallback to default location (Riyadh)
        _qiblaResult = QiblaResult.calculate(
          latitude: 24.7136,
          longitude: 46.6753,
        );
      });
    }
  }

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (!mounted || _isLocked) return;
      
      setState(() {
        _currentHeading = event.heading ?? 0;
        _compassAccuracy = event.accuracy ?? -1;
      });
    });
  }

  void _startAutoTimeout() {
    if (_mosqueMode) return;
    
    _autoTimeoutTimer?.cancel();
    _autoTimeoutTimer = Timer(const Duration(seconds: 60), () {
      if (mounted && !_isLocked && !_mosqueMode) {
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.battery_saver),
        title: Text('توفير الطاقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل تريد متابعة تحديد القبلة؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('إغلاق', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startAutoTimeout();
            },
            child: Text('متابعة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleLock() async {
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

  void _toggleMosqueMode() async {
    await HapticFeedback.heavyImpact();
    
    setState(() {
      _mosqueMode = !_mosqueMode;
      if (_mosqueMode) {
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
          _mosqueMode ? '🕌 تم تفعيل وضع المسجد' : 'تم إلغاء وضع المسجد',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: _mosqueMode ? Colors.green : null,
      ),
    );
  }

  void _showCalibrationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.help_outline, size: 48),
        title: Text('معايرة البوصلة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'لتحسين دقة البوصلة:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('1. أبعد الهاتف عن أي معادن', style: GoogleFonts.cairo()),
            Text('2. حرّك الهاتف بشكل 8', style: GoogleFonts.cairo()),
            Text('3. كرر حتى تتحسن الدقة', style: GoogleFonts.cairo()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
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
            child: Text('فهمت', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
    QiblaAlignment alignment = QiblaAlignment.far;
    
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
        title: Text('اتجاه القبلة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
              theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoadingLocation
              ? _buildLoadingView()
              : _locationError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off_rounded, size: 64, color: Colors.amber),
                          const SizedBox(height: 16),
                          Text(
                            _locationError!,
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _getLocation,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : _buildQiblaView(theme, accuracy, qiblaDeviation, alignment),
        ),
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
            'جارٍ تحديد موقعك...',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
          child: _buildCompass(deviation, alignment),
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
            ? Colors.green.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: alignment.isAligned 
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Accuracy indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getAccuracyColor(accuracy).withOpacity(0.2),
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
                  ? (_mosqueMode ? '🕌 وضع المسجد' : '🔒 تم التثبيت')
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
              tooltip: 'معايرة مطلوبة',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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
                Colors.white.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
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
            scale: alignment.isAligned ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation_rounded,
                  size: 80,
                  color: alignment.isAligned ? const Color(0xFF4CAF50) : const Color(0xFFFFD700),
                  shadows: [
                    BoxShadow(
                      color: (alignment.isAligned ? Colors.green : Colors.amber).withOpacity(0.5),
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
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (alignment.isAligned ? Colors.green : const Color(0xFFFFD700))
                          .withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '🕋 الكعبة',
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
                color: _mosqueMode ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _mosqueMode ? Colors.green : Colors.blue,
                ),
              ),
              child: Icon(
                _mosqueMode ? Icons.mosque : Icons.lock,
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoItem(
            icon: Icons.explore_rounded,
            label: 'اتجاه القبلة',
            value: '${_qiblaResult!.trueQiblaDirection.toStringAsFixed(1)}°',
          ),
          Container(height: 40, width: 1, color: Colors.white.withOpacity(0.1)),
          _InfoItem(
            icon: Icons.straighten_rounded,
            label: 'المسافة',
            value: QiblaEngine.formatDistance(_qiblaResult!.distanceToKaaba),
          ),
          Container(height: 40, width: 1, color: Colors.white.withOpacity(0.1)),
          _InfoItem(
            icon: Icons.near_me_rounded,
            label: 'الاتجاه',
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
                _isLocked ? 'إلغاء' : 'تثبيت',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _isLocked ? Colors.green : Colors.white.withOpacity(0.1),
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
              backgroundColor: _mosqueMode 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Icon(
              Icons.mosque_rounded,
              color: _mosqueMode ? Colors.green : Colors.white,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Refresh location
          FilledButton.tonal(
            onPressed: _getLocation,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
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
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧭 Heading: ${_currentHeading.toStringAsFixed(1)}°', 
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('🕋 Qibla: ${_qiblaResult?.magneticQiblaDirection.toStringAsFixed(1) ?? '--'}°', 
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('📐 Deviation: ${deviation.toStringAsFixed(1)}°', 
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('🧲 Declination: ${_qiblaResult?.declination.toStringAsFixed(1) ?? '--'}°', 
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('📊 Accuracy: ${_compassAccuracy.toStringAsFixed(1)}° (${accuracy.arabicName})', 
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white.withOpacity(0.6),
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
  final double heading;
  final double qiblaDirection;
  final bool isAligned;

  _CompassPainter({
    required this.heading,
    required this.qiblaDirection,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    for (var i = 0; i < 360; i += 10) {
      final angle = (i - heading) * (math.pi / 180) - math.pi / 2;
      final isCardinal = i % 90 == 0;
      final innerRadius = isCardinal ? radius - 15 : radius - 8;
      
      final x1 = center.dx + radius * math.cos(angle);
      final y1 = center.dy + radius * math.sin(angle);
      final x2 = center.dx + innerRadius * math.cos(angle);
      final y2 = center.dy + innerRadius * math.sin(angle);
      
      tickPaint.strokeWidth = isCardinal ? 2 : 1;
      tickPaint.color = isCardinal 
          ? Colors.white.withOpacity(0.6)
          : Colors.white.withOpacity(0.2);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // Draw cardinal directions
    final directions = ['ش', 'شر', 'ج', 'غ'];
    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    
    for (var i = 0; i < 4; i++) {
      final angle = (i * 90 - heading) * (math.pi / 180) - math.pi / 2;
      final x = center.dx + (radius - 35) * math.cos(angle);
      final y = center.dy + (radius - 35) * math.sin(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: i == 0 ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.6),
          fontSize: i == 0 ? 18 : 14,
          fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(
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
