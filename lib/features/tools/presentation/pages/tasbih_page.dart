import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> with SingleTickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _increment() {
    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());
    
    setState(() {
      _count++;
      if (_target > 0 && _count == _target) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _count = 0;
    });
  }

  void _setTarget(int target) {
    setState(() {
      _target = target;
      if (_count > target && target > 0) {
        _count = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _target > 0 ? (_count / _target).clamp(0.0, 1.0) : 0.0;
    final isComplete = _target > 0 && _count >= _target;

    return Scaffold(
      backgroundColor: NoorDesignSystem.background,
      appBar: AppBar(
        title: Text(
          'المسبحة الإلكترونية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: NoorDesignSystem.naskhBlack),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: NoorDesignSystem.naskhBlack),
            onPressed: _reset,
            tooltip: 'تصفير',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Presets
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PresetChip(
                      label: '٣٣',
                      value: 33,
                      selectedValue: _target,
                      onTap: () => _setTarget(33),
                    ),
                    const SizedBox(width: 12),
                    _PresetChip(
                      label: '١٠٠',
                      value: 100,
                      selectedValue: _target,
                      onTap: () => _setTarget(100),
                    ),
                    const SizedBox(width: 12),
                    _PresetChip(
                      label: 'مفتوح',
                      value: 0,
                      selectedValue: _target,
                      onTap: () => _setTarget(0),
                    ),
                  ],
                ),
              ),
            ),
            
            // Immersive Tap Area
            Expanded(
              child: GestureDetector(
                onTap: _increment,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress Circle
                        if (_target > 0)
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: NoorDesignSystem.primaryContainer,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isComplete ? NoorDesignSystem.goldAccent : NoorDesignSystem.primaryGreen,
                              ),
                            ),
                          ),
                        
                        // Main Counter Container
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isComplete 
                                ? NoorDesignSystem.goldAccent.withOpacity(0.1) 
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: (isComplete ? NoorDesignSystem.goldAccent : NoorDesignSystem.primaryGreen).withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_count',
                                style: GoogleFonts.cairo(
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  color: isComplete ? NoorDesignSystem.goldAccent : NoorDesignSystem.primaryGreen,
                                ),
                              ),
                              if (_target > 0)
                                Text(
                                  '/ $_target',
                                  style: GoogleFonts.cairo(
                                    fontSize: 24,
                                    color: NoorDesignSystem.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Helpful text
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Text(
                'اضغط في أي مكان للشاشة للعد',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: NoorDesignSystem.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final int value;
  final int selectedValue;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? NoorDesignSystem.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? NoorDesignSystem.primaryGreen : NoorDesignSystem.primaryContainer,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: NoorDesignSystem.primaryGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : NoorDesignSystem.primaryGreen,
          ),
        ),
      ),
    );
  }
}
