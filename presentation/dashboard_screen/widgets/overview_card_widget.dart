import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class OverviewCardWidget extends StatefulWidget {
  final int selectedPeriod;

  const OverviewCardWidget({required this.selectedPeriod, super.key});

  @override
  State<OverviewCardWidget> createState() => _OverviewCardWidgetState();
}

class _OverviewCardWidgetState extends State<OverviewCardWidget> {
  int? _touchedIndex;

  // Monthly income vs expenses data (TZS millions)
  final List<Map<String, dynamic>> _monthlyData = [
    {'label': 'Feb 1', 'income': 18.5, 'expense': 9.2},
    {'label': 'Feb 5', 'income': 22.1, 'expense': 11.4},
    {'label': 'Feb 8', 'income': 15.3, 'expense': 8.7},
    {'label': 'Feb 12', 'income': 28.4, 'expense': 14.1},
    {'label': 'Feb 15', 'income': 32.6, 'expense': 15.8},
    {'label': 'Feb 18', 'income': 19.2, 'expense': 10.3},
    {'label': 'Feb 22', 'income': 24.8, 'expense': 12.5},
    {'label': 'Feb 25', 'income': 21.3, 'expense': 9.8},
    {'label': 'Feb 28', 'income': 28.5, 'expense': 12.3},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.onSurfaceLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Feb 1–28, 2026',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'VIEW HISTORY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Legend
          Row(
            children: [
              _LegendItem(color: AppTheme.primary, label: 'Income'),
              const SizedBox(width: 16),
              _LegendItem(
                color: AppTheme.primaryLight.withOpacity(0.4),
                label: 'Expenses',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 40,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = _monthlyData[groupIndex];
                      final label = rodIndex == 0 ? 'Income' : 'Expense';
                      final value = rodIndex == 0 ? d['income'] : d['expense'];
                      return BarTooltipItem(
                        '$label\nTZS ${value}M',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.spot?.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i == 0) {
                          return Text(
                            'Feb 1',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.mutedLight,
                            ),
                          );
                        }
                        if (i == _monthlyData.length - 1) {
                          return Text(
                            'Feb 28',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.mutedLight,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.outlineLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_monthlyData.length, (i) {
                  final d = _monthlyData[i];
                  final isTouched = i == _touchedIndex;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (d['income'] as double),
                        color: isTouched
                            ? AppTheme.primary
                            : AppTheme.primary.withOpacity(0.85),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: (d['expense'] as double),
                        color: AppTheme.primaryLight.withOpacity(0.35),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    barsSpace: 3,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.mutedLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
