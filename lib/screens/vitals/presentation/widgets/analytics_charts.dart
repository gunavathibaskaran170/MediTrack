import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A premium, responsive line chart widget for vitals analytics.
class VitalsLineChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<double> values;
  final List<double>? secondaryValues; // Used for Blood Pressure (Diastolic)
  final String label;
  final Color primaryColor;
  final Color? secondaryColor;

  const VitalsLineChart({
    Key? key,
    required this.dates,
    required this.values,
    this.secondaryValues,
    required this.label,
    required this.primaryColor,
    this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (dates.isEmpty || values.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No data recorded for this period',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final showBP = secondaryValues != null && secondaryValues!.length == values.length;

    // Generate spots for the primary line
    final List<FlSpot> primarySpots = [];
    for (int i = 0; i < values.length; i++) {
      primarySpots.add(FlSpot(i.toDouble(), values[i]));
    }

    // Generate spots for the secondary line (diastolic)
    final List<FlSpot> secondarySpots = [];
    if (showBP) {
      for (int i = 0; i < secondaryValues!.length; i++) {
        secondarySpots.add(FlSpot(i.toDouble(), secondaryValues![i]));
      }
    }

    // Determine min/max values for axis scaling
    double minVal = values.reduce((a, b) => a < b ? a : b);
    double maxVal = values.reduce((a, b) => a > b ? a : b);
    
    if (showBP) {
      final minDia = secondaryValues!.reduce((a, b) => a < b ? a : b);
      final maxSys = values.reduce((a, b) => a > b ? a : b);
      minVal = minDia < minVal ? minDia : minVal;
      maxVal = maxSys > maxVal ? maxSys : maxVal;
    }

    // Give some padding on top/bottom of Y axis
    final yInterval = ((maxVal - minVal) / 4).clamp(5.0, 50.0);
    final yMin = (minVal - yInterval / 2).floorToDouble().clamp(0.0, 300.0);
    final yMax = (maxVal + yInterval / 2).ceilToDouble().clamp(10.0, 400.0);

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 16, left: 8, top: 12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (dates.length / 5).clamp(1.0, 100.0).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                  final date = dates[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              left: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
          ),
          minX: 0,
          maxX: (dates.length - 1).toDouble(),
          minY: yMin,
          maxY: yMax,
          lineBarsData: [
            // Primary Line
            LineChartBarData(
              spots: primarySpots,
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: dates.length < 15,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: primaryColor,
                  strokeWidth: 1.5,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withOpacity(0.08),
              ),
            ),
            // Secondary Line (Diastolic)
            if (showBP)
              LineChartBarData(
                spots: secondarySpots,
                isCurved: true,
                color: secondaryColor ?? theme.colorScheme.secondary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: dates.length < 15,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: secondaryColor ?? theme.colorScheme.secondary,
                    strokeWidth: 1.5,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: (secondaryColor ?? theme.colorScheme.secondary).withOpacity(0.05),
                ),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => theme.colorScheme.surfaceContainer,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  final date = dates[index];
                  final formattedDate = DateFormat('MMM dd, hh:mm a').format(date);
                  
                  if (showBP) {
                    final isSys = touchedSpot.barIndex == 0;
                    return LineTooltipItem(
                      '$formattedDate\n${isSys ? 'Systolic' : 'Diastolic'}: ${touchedSpot.y.toStringAsFixed(0)} mmHg',
                      theme.textTheme.bodySmall!.copyWith(
                        color: touchedSpot.bar.color,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else {
                    return LineTooltipItem(
                      '$formattedDate\n$label: ${touchedSpot.y.toStringAsFixed(1)}',
                      theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
