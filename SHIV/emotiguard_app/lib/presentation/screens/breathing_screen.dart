import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

enum BreathPhase { inhale, hold, exhale }

class _BreathingScreenState extends State<BreathingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _phaseTimer;

  BreathPhase _currentPhase = BreathPhase.inhale;
  int _secondsRemaining = 4;
  int _completedCycles = 0;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.65, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _startBreathingCycle();
  }

  void _startBreathingCycle() {
    _startInhale();
  }

  void _startInhale() {
    if (!mounted || !_isActive) return;
    setState(() {
      _currentPhase = BreathPhase.inhale;
      _secondsRemaining = 4;
    });

    _controller.duration = const Duration(seconds: 4);
    _controller.forward(from: 0.0);

    _runCountdown(4, onFinished: _startHold);
  }

  void _startHold() {
    if (!mounted || !_isActive) return;
    setState(() {
      _currentPhase = BreathPhase.hold;
      _secondsRemaining = 7;
    });

    _runCountdown(7, onFinished: _startExhale);
  }

  void _startExhale() {
    if (!mounted || !_isActive) return;
    setState(() {
      _currentPhase = BreathPhase.exhale;
      _secondsRemaining = 8;
    });

    _controller.duration = const Duration(seconds: 8);
    _controller.reverse(from: 1.0);

    _runCountdown(8, onFinished: () {
      setState(() => _completedCycles++);
      _startInhale();
    });
  }

  void _runCountdown(int seconds, {required VoidCallback onFinished}) {
    _phaseTimer?.cancel();
    _secondsRemaining = seconds;

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          onFinished();
        }
      });
    });
  }

  @override
  void dispose() {
    _isActive = false;
    _phaseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _phaseTitle {
    switch (_currentPhase) {
      case BreathPhase.inhale:
        return 'Inhale Gently';
      case BreathPhase.hold:
        return 'Hold Your Breath';
      case BreathPhase.exhale:
        return 'Release & Exhale';
    }
  }

  String get _phaseInstruction {
    switch (_currentPhase) {
      case BreathPhase.inhale:
        return 'Breathe in slowly through your nose...';
      case BreathPhase.hold:
        return 'Softly retain the air, relaxing your shoulders...';
      case BreathPhase.exhale:
        return 'Blow out completely through your mouth...';
    }
  }

  Color get _phaseColor {
    switch (_currentPhase) {
      case BreathPhase.inhale:
        return AppColors.primaryLight;
      case BreathPhase.hold:
        return AppColors.softLavender;
      case BreathPhase.exhale:
        return AppColors.primaryTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('4-7-8 Guided Breathing'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Cycle: $_completedCycles',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Text(
              _phaseTitle,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _phaseColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _phaseInstruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const Spacer(flex: 2),

            // Animated Breathing Orb
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _phaseColor.withOpacity(0.4),
                            _phaseColor.withOpacity(0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.4, 0.8, 1.0],
                        ),
                        border: Border.all(
                          color: _phaseColor.withOpacity(0.6),
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$_secondsRemaining',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: _phaseColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Spacer(flex: 3),
            // Helpful scientific context
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primaryTeal, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '4-7-8 pacing stimulates the vagus nerve, rapidly lowering heart rate and signaling safety to your nervous system.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Finish Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
