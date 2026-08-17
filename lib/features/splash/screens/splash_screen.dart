import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Animated Splash Screen
/// Uses ONLY Flutter built-in animations — no extra packages.
/// Designed for maximum performance on all devices.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _exitController;

  // ── Pulse rings ────────────────────────────────────────────────────────────
  late Animation<double> _ring1Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring2Opacity;

  // ── Logo ──────────────────────────────────────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoY;

  // ── Text ──────────────────────────────────────────────────────────────────
  late Animation<double> _titleOpacity;
  late Animation<double> _titleY;
  late Animation<double> _subtitleOpacity;

  // ── Exit ──────────────────────────────────────────────────────────────────
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Pulse rings — repeating, very lightweight
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _ring1Scale = Tween<double>(begin: 0.6, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _ring1Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 70),
    ]).animate(_pulseController);

    _ring2Scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring2Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: const Interval(0.2, 1.0),
    ));

    // Logo entrance — scale from 0.5 + fade in + slide up
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoY = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Text appearance
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _titleY = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    // Exit fade
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  Future<void> _startSequence() async {
    // Small delay to let native splash hand off cleanly
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // Start pulsing rings immediately
    _pulseController.repeat();

    // Logo enters
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // Text slides in after logo settles
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _textController.forward();

    // Hold for brand moment
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Fade out entire splash
    _pulseController.stop();
    await _exitController.forward();

    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return FadeTransition(
      opacity: _exitOpacity,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo + pulse rings
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) => Transform.scale(
                        scale: _ring1Scale.value,
                        child: Opacity(
                          opacity: _ring1Opacity.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary700,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Inner pulse ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) => Transform.scale(
                        scale: _ring2Scale.value,
                        child: Opacity(
                          opacity: _ring2Opacity.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary700.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Orbiting gold dot
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final angle = _pulseController.value * 2 * math.pi;
                            final radius = 72.0;
                            final x = math.cos(angle) * radius;
                            final y = math.sin(angle) * radius;
                            return Opacity(
                              opacity: _logoOpacity.value * 0.8,
                              child: Transform.translate(
                                offset: Offset(x, y),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent500,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Logo — scale + fade + slide up
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _logoY.value),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: child,
                          ),
                        ),
                      ),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary700.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Hospital name
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _titleY.value),
                  child: Opacity(
                    opacity: _titleOpacity.value,
                    child: child,
                  ),
                ),
                child: Text(
                  'Sharfians Hospital',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) => Opacity(
                  opacity: _subtitleOpacity.value,
                  child: child,
                ),
                child: Text(
                  'Community Healthcare Investment',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Gold accent line
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) => Opacity(
                  opacity: _subtitleOpacity.value,
                  child: child,
                ),
                child: Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
