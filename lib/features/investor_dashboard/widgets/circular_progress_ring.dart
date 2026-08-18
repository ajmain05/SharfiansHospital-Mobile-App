import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Port of the website's inline-SVG progress ring (InvestorDashboard.jsx's
/// `<CircularProgress>`), built with CustomPainter so no extra package is needed.
class CircularProgressRing extends StatelessWidget {
  final double percent;
  final double size;

  const CircularProgressRing({
    super.key,
    required this.percent,
    this.size = 145,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(percent: percent.clamp(0, 100), isDark: isDark),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percent.round()}%',
                style: GoogleFonts.publicSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'COMPLETED',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final bool isDark;

  _RingPainter({required this.percent, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 4;
    const strokeWidth = 8.0;

    final track = Paint()
      ..color = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * (percent / 100);
    final progress = Paint()
      ..color = AppColors.primary600
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.isDark != isDark;
}
