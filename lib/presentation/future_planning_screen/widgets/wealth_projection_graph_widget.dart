import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class WealthProjectionGraphWidget extends StatelessWidget {
  final List<Map<String, dynamic>> projections;
  final double currentNetWorth;

  const WealthProjectionGraphWidget({
    super.key,
    required this.projections,
    required this.currentNetWorth,
  });

  String _formatM(double v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    return '${(v / 1000).toStringAsFixed(0)}K';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (projections.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No projection data', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    final allSpots = <FlSpot>[];
    allSpots.add(FlSpot(0, currentNetWorth / 1000000));
    for (int i = 0; i < projections.length; i++) {
      final nw =
          (projections[i]['projected_networth'] as num?)?.toDouble() ?? 0;
      allSpots.add(FlSpot((i + 1).toDouble(), nw / 1000000));
    }

    final maxY = allSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;
    final finalNW =
        (projections.last['projected_networth'] as num?)?.toDouble() ?? 0;
    final growth = currentNetWorth > 0
        ? ((finalNW - currentNetWorth) / currentNetWorth * 100)
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wealth Projection',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${projections.length}-Year Forecast',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${growth.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statChip('Now', _formatM(currentNetWorth), AppTheme.mutedLight),
              const SizedBox(width: 12),
              _statChip(
                '${projections.length}Y',
                _formatM(finalNW),
                AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: AppTheme.outlineLight, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(
                        _formatM(v * 1000000),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final idx = v.toInt();
                        if (idx == 0) {
                          return Text(
                            'Now',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppTheme.mutedLight,
                            ),
                          );
                        }
                        if (idx <= projections.length) {
                          return Text(
                            'Y$idx',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppTheme.mutedLight,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: allSpots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A5F7A), Color(0xFF10B981)],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                            radius: idx == 0 || idx == allSpots.length - 1
                                ? 5
                                : 3,
                            color: idx == allSpots.length - 1
                                ? AppTheme.success
                                : AppTheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withAlpha(40),
                          AppTheme.success.withAlpha(10),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedLight),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
