import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/meditrack_theme.dart';

class FloatingNodesBackground extends StatefulWidget {
  final Widget child;
  const FloatingNodesBackground({super.key, required this.child});

  @override
  State<FloatingNodesBackground> createState() =>
      _FloatingNodesBackgroundState();
}

class _FloatingNodesBackgroundState extends State<FloatingNodesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _velocities = [];
  final List<Offset> _positions = [];
  final List<double> _radii = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _positions.add(Offset(_random.nextDouble(), _random.nextDouble()));
      _velocities.add(Offset((_random.nextDouble() - 0.5) * 0.08,
          (_random.nextDouble() - 0.5) * 0.08));
      _radii.add(_random.nextDouble() * 100 + 150);
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParallaxNodesPainter(
            positions: _positions,
            velocities: _velocities,
            radii: _radii,
            progress: _controller.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class ParallaxNodesPainter extends CustomPainter {
  final List<Offset> positions;
  final List<Offset> velocities;
  final List<double> radii;
  final double progress;

  ParallaxNodesPainter({
    required this.positions,
    required this.velocities,
    required this.radii,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid light Ice Blue canvas (#E0F7FA)
    final bgPaint = Paint()..color = const Color(0xFFE0F7FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Faint medical grid lines
    final gridPaint = Paint()
      ..color = const Color(0x120D9488) // subtle primary teal grid
      ..strokeWidth = 0.8;

    double gridStep = 32.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw dual flowing animated ECG heartbeat wave paths
    final ecgPaintPrimary = Paint()
      ..color = const Color(0x1F0D9488) // primary teal with low opacity
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ecgPaintSecondary = Paint()
      ..color = const Color(0x0F10B981) // accent green with lower opacity
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw at 30% and 75% height levels of screen
    _drawEcgTrace(canvas, size, size.height * 0.3, progress, ecgPaintPrimary, cycleWidth: 260.0);
    _drawEcgTrace(canvas, size, size.height * 0.75, progress + 0.4, ecgPaintSecondary, cycleWidth: 300.0);
  }

  void _drawEcgTrace(Canvas canvas, Size size, double centerY, double animValue, Paint paint, {required double cycleWidth}) {
    final path = Path();
    double startX = -((animValue % 1.0) * cycleWidth);

    path.moveTo(startX, centerY);

    while (startX < size.width + cycleWidth) {
      double w = cycleWidth;
      
      // Flat segment (PR interval start)
      double p1 = startX + w * 0.2;
      path.lineTo(p1, centerY);

      // P wave (atrial depolarization)
      path.quadraticBezierTo(p1 + w * 0.05, centerY - 6, p1 + w * 0.1, centerY);

      // Flat segment (PR segment)
      double p2 = p1 + w * 0.15;
      path.lineTo(p2, centerY);

      // QRS Complex (ventricular depolarization)
      path.lineTo(p2 + w * 0.02, centerY + 5);    // Q
      path.lineTo(p2 + w * 0.05, centerY - 25);   // R
      path.lineTo(p2 + w * 0.08, centerY + 20);   // S
      path.lineTo(p2 + w * 0.1, centerY);         // baseline return

      // Flat segment (ST segment)
      double p3 = p2 + w * 0.15;
      path.lineTo(p3, centerY);

      // T wave (ventricular repolarization)
      path.quadraticBezierTo(p3 + w * 0.06, centerY - 10, p3 + w * 0.12, centerY);

      // Final flat segment of the cycle
      startX += w;
      path.lineTo(startX, centerY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ParallaxNodesPainter oldDelegate) => true;
}
