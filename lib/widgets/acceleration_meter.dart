import 'dart:math' as math;

import 'package:flutter/material.dart';

class AccelerationMeter extends StatelessWidget {
  const AccelerationMeter({
    required this.force,
    required this.threshold,
    super.key,
  });

  final double force;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final double absoluteForce = force.abs();
    final bool aboveThreshold = force > threshold;
    final Color accent = aboveThreshold
        ? const Color(0xFFFF5C6A)
        : const Color(0xFF37D4D1);
    return SizedBox(
      height: 266,
      child: CustomPaint(
        painter: _MeterPainter(
          reading: absoluteForce,
          threshold: threshold,
          accent: accent,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                force.toStringAsFixed(2),
                style: TextStyle(
                  color: accent,
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'FUERZA NETA · VECTORIAL',
                style: TextStyle(
                  color: Color(0xFF8DA0B4),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'm/s²',
                style: TextStyle(
                  color: Color(0xFFEAF2F8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter({
    required this.reading,
    required this.threshold,
    required this.accent,
  });

  final double reading;
  final double threshold;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * 0.4;
    const double start = math.pi * 0.75;
    const double sweep = math.pi * 1.5;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.08),
            const Color(0x00070B12),
          ],
        ).createShader(arcRect),
    );
    final Paint track = Paint()
      ..color = const Color(0xFF243448)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, start, sweep, false, track);

    final double progress = (reading / 50).clamp(0, 1);
    final Paint active = Paint()
      ..shader = LinearGradient(
        colors: <Color>[accent.withValues(alpha: 0.38), accent],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, start, sweep * progress, false, active);

    final double thresholdProgress = (threshold / 50).clamp(0, 1);
    final double markerAngle = start + sweep * thresholdProgress;
    final Offset marker = Offset(
      center.dx + math.cos(markerAngle) * radius,
      center.dy + math.sin(markerAngle) * radius,
    );
    canvas.drawCircle(
      marker,
      9,
      Paint()..color = const Color(0xFFF6B94A).withValues(alpha: 0.18),
    );
    canvas.drawCircle(marker, 5, Paint()..color = const Color(0xFFF6B94A));
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) {
    return oldDelegate.reading != reading ||
        oldDelegate.threshold != threshold ||
        oldDelegate.accent != accent;
  }
}
