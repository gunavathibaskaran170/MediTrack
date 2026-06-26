import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/meditrack_theme.dart';
import '../core/models.dart';

// ----------------------------------------------------
// HEART RATE VITAL CARD
// ----------------------------------------------------
class HeartRateVitalCard extends StatefulWidget {
  final double? heartRate;
  final Color statusColor;
  const HeartRateVitalCard({super.key, this.heartRate, required this.statusColor});

  @override
  State<HeartRateVitalCard> createState() => _HeartRateVitalCardState();
}

class _HeartRateVitalCardState extends State<HeartRateVitalCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final bpm = widget.heartRate ?? 70.0;
    final durationMs = (60000 / bpm).round();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void didUpdateWidget(covariant HeartRateVitalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heartRate != widget.heartRate) {
      final bpm = widget.heartRate ?? 70.0;
      final durationMs = (60000 / bpm).round();
      _controller.duration = Duration(milliseconds: durationMs);
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hrVal = widget.heartRate != null ? widget.heartRate!.toInt().toString() : '--';
    final targetColor = widget.heartRate != null
        ? ((widget.heartRate! > 100 || widget.heartRate! < 60)
            ? context.colors.errorSos
            : const Color(0xFF4CAF50)) // energetic Bright Green #4CAF50
        : context.colors.textHint;

    return _VitalCardScaffold(
      label: 'Heart Rate',
      statusColor: widget.statusColor,
      valueText: '$hrVal bpm',
      icon: Icons.monitor_heart,
      iconBgColor: targetColor,
      customIconWidget: PulsingHeartIcon(color: targetColor, bpm: widget.heartRate ?? 70.0),
      chartWidget: RepaintBoundary(
        child: SizedBox(
          width: 80,
          height: 36,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: context.colors.textHint, end: targetColor),
            duration: const Duration(milliseconds: 500),
            builder: (context, animatedColor, child) {
              final color = animatedColor ?? targetColor;
              return ClipRect(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: HeartbeatPainter(progress: _animation.value, color: color),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class HeartbeatPainter extends CustomPainter {
  final double progress;
  final Color color;
  HeartbeatPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double midY = h / 2;

    Path cycle(double startX, double width) {
      final p = Path();
      p.moveTo(startX, midY);

      double p1 = startX + width * 0.2;
      p.lineTo(p1, midY);

      // P-wave
      p.quadraticBezierTo(p1 + width * 0.05, midY - h * 0.25, p1 + width * 0.1, midY);

      double p2 = p1 + width * 0.15;
      p.lineTo(p2, midY);

      // QRS
      p.lineTo(p2 + width * 0.02, midY + h * 0.15); // Q
      p.lineTo(p2 + width * 0.05, midY - h * 0.45); // R
      p.lineTo(p2 + width * 0.08, midY + h * 0.4);  // S
      p.lineTo(p2 + width * 0.1, midY);             // Return

      double p3 = p2 + width * 0.15;
      p.lineTo(p3, midY);

      // T-wave
      p.quadraticBezierTo(p3 + width * 0.06, midY - h * 0.3, p3 + width * 0.12, midY);

      p.lineTo(startX + width, midY);
      return p;
    }

    final double cycleWidth = w;
    final double startX = -progress * cycleWidth;

    final path1 = cycle(startX, cycleWidth);
    final path2 = cycle(startX + cycleWidth, cycleWidth);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant HeartbeatPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ----------------------------------------------------
// BLOOD PRESSURE VITAL CARD
// ----------------------------------------------------
class BPVitalCard extends StatelessWidget {
  final double? systolic;
  final double? diastolic;
  final Color statusColor;
  final Color sysColor;
  final Color diaColor;
  const BPVitalCard({
    super.key,
    this.systolic,
    this.diastolic,
    required this.statusColor,
    required this.sysColor,
    required this.diaColor,
  });

  @override
  Widget build(BuildContext context) {
    final sysVal = systolic ?? 120.0;
    final diaVal = diastolic ?? 80.0;

    final double sysMax = 200.0;
    final double diaMax = 120.0;

    return _VitalCardScaffold(
      label: 'Blood Pressure',
      statusColor: statusColor,
      icon: Icons.biotech_rounded,
      iconBgColor: sysColor,
      customValueWidget: RichText(
        text: TextSpan(
          style: context.vitalValue.copyWith(fontSize: 16),
          children: [
            TextSpan(text: systolic != null ? '${systolic!.toInt()}' : '--'),
            TextSpan(text: ' / ', style: TextStyle(color: context.colors.textSecondary)),
            TextSpan(text: diastolic != null ? '${diastolic!.toInt()}' : '--'),
            TextSpan(text: ' mmHg', style: context.labelSmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
      chartWidget: SizedBox(
        width: 80,
        height: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Systolic bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: systolic != null ? sysVal / sysMax : 0.6),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return _buildHorizontalProgressBar(context, val, sysColor);
              },
            ),
            const SizedBox(height: 6),
            // Diastolic bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: diastolic != null ? diaVal / diaMax : 0.66),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return _buildHorizontalProgressBar(context, val, diaColor);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalProgressBar(BuildContext context, double value, Color barColor) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.dividerColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// BLOOD SUGAR VITAL CARD
// ----------------------------------------------------
class BloodSugarVitalCard extends StatefulWidget {
  final double? sugar;
  final String? type;
  final List<Vital> vitalsHistory;
  final Color statusColor;
  const BloodSugarVitalCard({
    super.key,
    this.sugar,
    this.type,
    required this.vitalsHistory,
    required this.statusColor,
  });

  @override
  State<BloodSugarVitalCard> createState() => _BloodSugarVitalCardState();
}

class _BloodSugarVitalCardState extends State<BloodSugarVitalCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sugarText = widget.sugar != null ? widget.sugar!.toInt().toString() : '--';
    final typeText = widget.type == 'fasting' ? 'F' : (widget.type == 'post_meal' ? 'PM' : '');

    // Get last 5 sugar readings
    final sugarHistory = widget.vitalsHistory
        .where((v) => v.bloodSugar != null)
        .toList();
    if (sugarHistory.length > 5) {
      sugarHistory.removeRange(0, sugarHistory.length - 5);
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < sugarHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), sugarHistory[i].bloodSugar!));
    }
    // If no history, add mock spots for rendering
    if (spots.isEmpty) {
      spots.addAll([
        const FlSpot(0, 90),
        const FlSpot(1, 95),
        const FlSpot(2, 92),
        const FlSpot(3, 98),
        const FlSpot(4, 94),
      ]);
    }

    return _VitalCardScaffold(
      label: 'Blood Sugar',
      statusColor: widget.statusColor,
      icon: Icons.water_drop_rounded,
      iconBgColor: widget.statusColor,
      customValueWidget: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(sugarText, style: context.vitalValue.copyWith(fontSize: 16)),
          if (typeText.isNotEmpty) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: widget.statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeText,
                style: TextStyle(
                  color: widget.statusColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(width: 2),
          Text(' mg/dL', style: context.labelSmall.copyWith(fontSize: 10)),
        ],
      ),
      chartWidget: SizedBox(
        width: 80,
        height: 36,
        child: Stack(
          children: [
            Positioned.fill(
              child: SugarWaveWidget(
                sugar: widget.sugar ?? 90,
                color: widget.statusColor,
              ),
            ),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final animatedSpots = <FlSpot>[];
                if (spots.isNotEmpty) {
                  final double baselineY = spots.first.y;
                  for (int i = 0; i < spots.length; i++) {
                    final spot = spots[i];
                    double spotProgress = (_animation.value * spots.length - i).clamp(0.0, 1.0);
                    double animatedY = baselineY + (spot.y - baselineY) * spotProgress;
                    animatedSpots.add(FlSpot(spot.x, animatedY));
                  }
                }
                return LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: spots.length - 1,
                    minY: 40,
                    maxY: 200,
                    lineTouchData: const LineTouchData(enabled: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: animatedSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: widget.statusColor,
                        barWidth: 2.2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              widget.statusColor.withOpacity(0.20),
                              widget.statusColor.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// TEMPERATURE VITAL CARD
// ----------------------------------------------------
class TemperatureVitalCard extends StatelessWidget {
  final double? temp;
  final Color statusColor;
  const TemperatureVitalCard({super.key, this.temp, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final tempText = temp != null ? temp!.toStringAsFixed(1) : '--';
    final val = temp ?? 36.6;

    Color mercuryColor = Colors.blue;
    if (val < 36.0) {
      mercuryColor = Colors.blue;
    } else if (val <= 37.2) {
      mercuryColor = context.colors.success;
    } else if (val <= 38.0) {
      mercuryColor = context.colors.warning;
    } else {
      mercuryColor = context.colors.errorSos;
    }

    return _VitalCardScaffold(
      label: 'Temperature',
      statusColor: statusColor,
      valueText: '$tempText °C',
      icon: Icons.thermostat_rounded,
      iconBgColor: mercuryColor,
      chartWidget: RepaintBoundary(
        child: SizedBox(
          width: 80,
          height: 48,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 34.0, end: val),
            duration: const Duration(milliseconds: 1200),
            curve: const ViscousFluidCurve(),
            builder: (context, animVal, child) {
              return CustomPaint(
                painter: ThermometerPainter(temp: animVal, color: mercuryColor),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ThermometerPainter extends CustomPainter {
  final double temp;
  final Color color;
  ThermometerPainter({required this.temp, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final double w = size.width;
    final double h = size.height;
    final double bulbRadius = 8.0;
    final double cx = w / 2;
    final double stemWidth = 6.0;
    final double stemLeft = cx - (stemWidth / 2);

    // Outline path
    final path = Path();
    path.moveTo(stemLeft, 4);
    path.arcToPoint(Offset(stemLeft + stemWidth, 4), radius: Radius.circular(stemWidth / 2));
    path.lineTo(stemLeft + stemWidth, h - bulbRadius - 2);

    // Bulb circle join
    path.arcToPoint(
      Offset(stemLeft, h - bulbRadius - 2),
      radius: Radius.circular(bulbRadius),
      largeArc: true,
    );
    path.close();

    canvas.drawPath(path, outlinePaint);

    // Fill bulb
    canvas.drawCircle(Offset(cx, h - bulbRadius), bulbRadius - 1.5, paint);

    // Fill stem proportional height (34°C - 42°C)
    double normalized = (temp - 34) / (42 - 34);
    normalized = normalized.clamp(0.0, 1.0);
    double maxFillHeight = h - bulbRadius - 8;
    double fillHeight = normalized * maxFillHeight;

    if (fillHeight > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(stemLeft + 1.2, h - bulbRadius - fillHeight, stemWidth - 2.4, fillHeight),
          Radius.circular((stemWidth - 2.4) / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ThermometerPainter oldDelegate) =>
      oldDelegate.temp != temp || oldDelegate.color != color;
}

class ViscousFluidCurve extends Curve {
  const ViscousFluidCurve();

  @override
  double transformInternal(double t) {
    if (t == 1.0) return 1.0;
    return 1.0 - math.exp(-4.0 * t) * math.cos(1.5 * math.pi * t);
  }
}

// ----------------------------------------------------
// WEIGHT VITAL CARD
// ----------------------------------------------------
class WeightVitalCard extends StatelessWidget {
  final double? weight;
  final double? prevWeight;
  final Color statusColor;
  const WeightVitalCard({super.key, this.weight, this.prevWeight, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final weightText = weight != null ? weight!.toStringAsFixed(1) : '--';
    final val = weight ?? 70.0;

    double delta = 0.0;
    if (weight != null && prevWeight != null) {
      delta = weight! - prevWeight!;
    }

    Widget deltaWidget = const SizedBox.shrink();
    if (delta != 0.0) {
      final isGain = delta > 0;
      final absVal = delta.abs().toStringAsFixed(1);
      final txt = '${isGain ? '▲' : '▼'} $absVal kg';
      final color = isGain ? context.colors.errorSos : context.colors.success;
      deltaWidget = Container(
        key: ValueKey(txt),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          txt,
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
        ),
      );
    }

    return _VitalCardScaffold(
      label: 'Weight',
      statusColor: statusColor,
      valueText: '$weightText kg',
      icon: Icons.scale_rounded,
      iconBgColor: context.colors.primary,
      extraValueWidget: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: deltaWidget,
      ),
      chartWidget: RepaintBoundary(
        child: SizedBox(
          width: 80,
          height: 36,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 40.0, end: val),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animVal, child) {
              return CustomPaint(
                painter: ScaleNeedlePainter(
                  weight: animVal,
                  needleColor: context.colors.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ScaleNeedlePainter extends CustomPainter {
  final double weight;
  final Color needleColor;
  ScaleNeedlePainter({required this.weight, required this.needleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final needlePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h - 2;

    // Draw scale dial arch
    canvas.drawArc(
      Rect.fromLTWH(w * 0.1, 4, w * 0.8, h * 2 - 8),
      3.14159,
      3.14159,
      false,
      paint,
    );

    // Map 40kg to -60 degrees, 150kg to +60 degrees
    double normalized = (weight - 40) / (150 - 40);
    normalized = normalized.clamp(0.0, 1.0);
    double maxRotation = 60.0 * (3.14159 / 180.0);
    double angle = -maxRotation + normalized * (maxRotation * 2);

    final double needleLength = h - 8;
    final double nx = cx + needleLength * math.sin(angle);
    final double ny = cy - needleLength * math.cos(angle);

    canvas.drawLine(Offset(cx, cy), Offset(nx, ny), needlePaint);
    canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant ScaleNeedlePainter oldDelegate) =>
      oldDelegate.weight != weight || oldDelegate.needleColor != needleColor;
}

// ----------------------------------------------------
// SPO2 VITAL CARD
// ----------------------------------------------------
class SpO2VitalCard extends StatelessWidget {
  final double? spo2;
  final Color statusColor;
  const SpO2VitalCard({super.key, this.spo2, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final spo2Text = spo2 != null ? spo2!.toInt().toString() : '--';
    final val = spo2 ?? 98.0;

    return _VitalCardScaffold(
      label: 'SpO2',
      statusColor: statusColor,
      icon: Icons.air_rounded,
      iconBgColor: statusColor,
      customValueWidget: RichText(
        text: TextSpan(
          style: context.vitalValue.copyWith(fontSize: 16),
          children: [
            TextSpan(text: spo2Text),
            TextSpan(text: ' %', style: context.labelSmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
      chartWidget: SizedBox(
        width: 48,
        height: 48,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: val),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.fastOutSlowIn,
          builder: (context, animVal, child) {
            return CustomPaint(
              painter: RadialProgressPainter(
                progress: animVal,
                color: statusColor,
                trackColor: context.colors.dividerColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class RadialProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  RadialProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw background track
    canvas.drawCircle(center, radius, trackPaint);

    // Draw animated progress arc
    double sweepAngle = (progress / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at 12 o'clock
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadialProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.trackColor != trackColor;
}

// ----------------------------------------------------
// COMMON CARD CONTAINER SCAFFOLD
// ----------------------------------------------------
class _VitalCardScaffold extends StatelessWidget {
  final String label;
  final Color statusColor;
  final String? valueText;
  final Widget? customValueWidget;
  final Widget? extraValueWidget;
  final Widget chartWidget;
  final IconData icon;
  final Color iconBgColor;
  final Widget? customIconWidget;

  const _VitalCardScaffold({
    required this.label,
    required this.statusColor,
    this.valueText,
    this.customValueWidget,
    this.extraValueWidget,
    required this.chartWidget,
    required this.icon,
    required this.iconBgColor,
    this.customIconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      height: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(MediTrackRadius.cards),
          border: Border.all(color: context.colors.dividerColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status bar indicator top
            Positioned(
              top: 0,
              left: 12,
              right: 12,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 2), // spacing from status bar
                  // Top Row: Icon container + Label
                  Row(
                    children: [
                      customIconWidget ?? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: iconBgColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 14,
                          color: iconBgColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          style: context.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Middle: Chart Widget
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: chartWidget,
                      ),
                    ),
                  ),
                  // Bottom Row: Value + Extra Widget
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      customValueWidget ??
                          Text(
                            valueText ?? '--',
                            style: context.vitalValue.copyWith(
                              fontSize: 15,
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      if (extraValueWidget != null) extraValueWidget!,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// PULSING HEART ICON (LIVE SYNC WITH BPM)
// ----------------------------------------------------
class PulsingHeartIcon extends StatefulWidget {
  final Color color;
  final double bpm;
  const PulsingHeartIcon({super.key, required this.color, required this.bpm});

  @override
  State<PulsingHeartIcon> createState() => _PulsingHeartIconState();
}

class _PulsingHeartIconState extends State<PulsingHeartIcon> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final durationMs = (60000 / widget.bpm).round();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant PulsingHeartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) {
      final durationMs = (60000 / widget.bpm).round();
      _pulseController.duration = Duration(milliseconds: durationMs);
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          Icons.favorite,
          size: 14,
          color: widget.color,
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// SUGAR LEVEL LIQUID WAVE ANIMATION
// ----------------------------------------------------
class SugarWaveWidget extends StatefulWidget {
  final double sugar;
  final Color color;
  const SugarWaveWidget({super.key, required this.sugar, required this.color});

  @override
  State<SugarWaveWidget> createState() => _SugarWaveWidgetState();
}

class _SugarWaveWidgetState extends State<SugarWaveWidget> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillPercentage = ((widget.sugar - 40) / 160).clamp(0.12, 0.88);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            painter: LiquidWavePainter(
              waveValue: _waveController.value,
              fillPercentage: fillPercentage,
              color: widget.color.withOpacity(0.08),
            ),
          );
        },
      ),
    );
  }
}

class LiquidWavePainter extends CustomPainter {
  final double waveValue;
  final double fillPercentage;
  final Color color;
  LiquidWavePainter({required this.waveValue, required this.fillPercentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double waveHeight = 3.0;
    final double baseHeight = size.height * (1.0 - fillPercentage);

    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      final double y = baseHeight + math.sin(x * 0.08 + waveValue * 2 * math.pi) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidWavePainter oldDelegate) =>
      oldDelegate.waveValue != waveValue ||
      oldDelegate.fillPercentage != fillPercentage ||
      oldDelegate.color != color;
}
