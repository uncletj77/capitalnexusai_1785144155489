import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CashFlowChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> forecasts;

  const CashFlowChartWidget({super.key, required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (forecasts.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No forecast data', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    final displayForecasts = forecasts.take(6).toList();
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final balanceSpots = <FlSpot>[];

    for (int i = 0; i < displayForecasts.length; i++) {
      final f = displayForecasts[i];
      final income =
          ((f['expected_income'] as num?)?.toDouble() ?? 0) +
          ((f['expected_business_income'] as num?)?.toDouble() ?? 0) +
          ((f['expected_investment_returns'] as num?)?.toDouble() ?? 0);
      final expense =
          ((f['expected_expenses'] as num?)?.toDouble() ?? 0) +
          ((f['expected_loan_payments'] as num?)?.toDouble() ?? 0);
      final balance = (f['projected_cash_balance'] as num?)?.toDouble() ?? 0;

      incomeSpots.add(FlSpot(i.toDouble(), income / 1000000));
      expenseSpots.add(FlSpot(i.toDouble(), expense / 1000000));
      balanceSpots.add(FlSpot(i.toDouble(), balance / 1000000));
    }

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
          Text(
            'Cash Flow Forecast',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Income vs Expenses vs Balance (TZS M)',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedLight),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
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
                      reservedSize: 36,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}M',
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
                        if (idx < 0 || idx >= displayForecasts.length) {
                          return const SizedBox.shrink();
                        }
                        final period =
                            displayForecasts[idx]['forecast_period']
                                as String? ??
                            '';
                        final parts = period.split('-');
                        if (parts.length >= 2) {
                          const months = [
                            '',
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ];
                          final m = int.tryParse(parts[1]) ?? 0;
                          return Text(
                            m > 0 && m <= 12 ? months[m] : '',
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
                  _buildLine(incomeSpots, AppTheme.success, 'Income'),
                  _buildLine(expenseSpots, AppTheme.error, 'Expenses'),
                  _buildLine(balanceSpots, AppTheme.primary, 'Balance'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(AppTheme.success, 'Inflow'),
              const SizedBox(width: 16),
              _legend(AppTheme.error, 'Outflow'),
              const SizedBox(width: 16),
              _legend(AppTheme.primary, 'Balance'),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color, String label) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withAlpha(20)),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 3, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedLight),
        ),
      ],
    );
  }
}
