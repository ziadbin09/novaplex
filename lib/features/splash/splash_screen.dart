import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Teal glow behind icon
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentTeal.withValues(alpha: 0.25),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 800.ms),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentTeal.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // App name: Man(teal) + zar(amber)
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Man',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentTeal,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'zar',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentAmber,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        delay: 300.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(delay: 300.ms, duration: 500.ms),

                  const SizedBox(height: 8),

                  // Tagline
                  const Text(
                    'Your Cinema, Everywhere',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryDark,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                ],
              ),
            ),

            // Bottom: pulsing dots + label
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const _PulsingDots(),
                  const SizedBox(height: 12),
                  Text(
                    'LOADING',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
                ],
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final pulse = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentTeal
                    .withValues(alpha: 0.3 + pulse * 0.7),
              ),
            );
          },
        );
      }),
    );
  }
}
