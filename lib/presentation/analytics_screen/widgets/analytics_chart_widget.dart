import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

enum AnalyticsChartType { line, bar, comparison }

class AnalyticsChartWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final AnalyticsChartType chartType;
  final String? primaryLabel;
  final String? secondaryLabel;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AnalyticsChartWidget({
    super.key,
    required this.title,
    required this.data,
    this.chartType = AnalyticsChartType.line,
    this.primaryLabel,
    this.secondaryLabel,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.outlineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              if (primaryLabel != null || secondaryLabel != null)
                Row(
                  children: [
                    if (primaryLabel != null)
                      _buildLegend(
                        primaryLabel!,
                        primaryColor ?? AppTheme.primary,
                      ),
                    if (secondaryLabel != null) ...[
                      const SizedBox(width: 12),
                      _buildLegend(
                        secondaryLabel!,
                        secondaryColor ?? AppTheme.error,
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  )
                : chartType == AnalyticsChartType.bar
                ? _buildBarChart()
                : _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppTheme.mutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final pColor = primaryColor ?? AppTheme.primary;
    final sColor = secondaryColor ?? AppTheme.error;
    final hasSecondary = data.isNotEmpty && data.first.containsKey('secondary');

    final primarySpots = data.asMap().entries.map((e) {
      final val =
          (e.value['value'] ?? e.value['income'] ?? e.value['net'] ?? 0.0);
      return FlSpot(e.key.toDouble(), (val as num).toDouble() / 1000000);
    }).toList();

    final secondarySpots = hasSecondary
        ? data.asMap().entries.map((e) {
            final val = (e.value['secondary'] ?? e.value['expenses'] ?? 0.0);
            return FlSpot(e.key.toDouble(), (val as num).toDouble() / 1000000);
          }).toList()
        : <FlSpot>[];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: AppTheme.outlineLight, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                final label = (data[idx]['month'] ?? '').toString();
                final shortLabel = label.length > 3
                    ? label.substring(0, 3)
                    : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    shortLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: primarySpots,
            isCurved: true,
            color: pColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: pColor.withAlpha(25)),
          ),
          if (secondarySpots.isNotEmpty)
            LineChartBarData(
              spots: secondarySpots,
              isCurved: true,
              color: sColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              dashArray: [4, 4],
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final pColor = primaryColor ?? AppTheme.primary;
    final sColor = secondaryColor ?? AppTheme.error;
    final hasSecondary =
        data.isNotEmpty &&
        (data.first.containsKey('secondary') ||
            data.first.containsKey('expenses'));

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: AppTheme.outlineLight, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                final label = (data[idx]['month'] ?? data[idx]['label'] ?? '')
                    .toString();
                final shortLabel = label.length > 3
                    ? label.substring(0, 3)
                    : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    shortLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          final primary =
              ((e.value['value'] ?? e.value['income'] ?? 0.0) as num)
                  .toDouble() /
              1000000;
          final secondary = hasSecondary
              ? ((e.value['secondary'] ?? e.value['expenses'] ?? 0.0) as num)
                        .toDouble() /
                    1000000
              : 0.0;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: primary,
                color: pColor,
                width: hasSecondary ? 6 : 12,
                borderRadius: BorderRadius.circular(4.0),
              ),
              if (hasSecondary)
                BarChartRodData(
                  toY: secondary,
                  color: sColor,
                  width: 6,
                  borderRadius: BorderRadius.circular(4.0),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
