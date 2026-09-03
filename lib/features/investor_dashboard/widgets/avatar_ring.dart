import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small avatar with a profile-completion ring around it — same idea as
/// [CircularProgressRing] (share-payment progress) but sized for a header
/// avatar, with a photo (or placeholder icon) in the center instead of text.
/// Ring color steps amber (<50%) -> blue (50-99%) -> green (100%), matching
/// the website's `AvatarRing` in InvestorDashboard.jsx.
class AvatarRing extends StatelessWidget {
  final String? photoUrl;
  final int percent;
  final double size;

  const AvatarRing({super.key, this.photoUrl, required this.percent, this.size = 44});

  Color _ringColor() {
    if (percent >= 100) return const Color(0xFF10B981);
    if (percent >= 50) return const Color(0xFF3B82F6);
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // A little extra height so the percentage badge below has room to
      // overlap the ring's bottom edge without getting clipped by a parent
      // that sizes tightly to this widget (e.g. an AppBar's title Row).
      width: size,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(percent: percent.clamp(0, 100), color: _ringColor()),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: Container(
                    color: _ringColor().withValues(alpha: 0.08),
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.person_outline, color: _ringColor().withValues(alpha: 0.6), size: size * 0.5),
                          )
                        : Icon(Icons.person_outline, color: _ringColor().withValues(alpha: 0.6), size: size * 0.5),
                  ),
                ),
              ),
            ),
          ),
          // Percentage badge overlapping the ring's bottom edge, colored to
          // match the ring's own progress color — keeps the number attached
          // to the ring itself instead of floating as a separate label
          // elsewhere on the page.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _ringColor(),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, height: 1.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int percent;
  final Color color;

  _RingPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 1.5;
    const strokeWidth = 3.0;

    final track = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * (percent / 100);
    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, progress);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}
