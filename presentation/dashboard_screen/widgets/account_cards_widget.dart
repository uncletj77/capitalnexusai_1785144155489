import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class AccountCardsWidget extends StatelessWidget {
  const AccountCardsWidget({super.key});

  final List<Map<String, dynamic>> _accounts = const [
    {
      'label': 'BUSINESS',
      'value': 228400000.0,
      'percentage': '32.4%',
      'trend': [12.0, 18.0, 14.0, 22.0, 19.0, 28.0, 24.0],
      'positive': true,
    },
    {
      'label': 'SAVINGS',
      'value': 125100000.0,
      'percentage': '23.8%',
      'trend': [8.0, 11.0, 9.0, 13.0, 10.0, 15.0, 12.0],
      'positive': true,
    },
    {
      'label': 'TRAVEL',
      'value': 56800000.0,
      'percentage': '14.6%',
      'trend': [6.0, 5.0, 7.0, 4.0, 8.0, 6.0, 5.0],
      'positive': false,
    },
    {
      'label': 'INVESTMENTS',
      'value': 185000000.0,
      'percentage': '+18.2%',
      'trend': [10.0, 12.0, 11.0, 15.0, 13.0, 18.0, 20.0],
      'positive': true,
    },
  ];

  String _formatValue(double v) {
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    return 'TZS ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _accounts.length,
        itemBuilder: (context, i) {
          final account = _accounts[i];
          return _AccountCard(
            account: account,
            formattedValue: _formatValue(account['value'] as double),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  final String formattedValue;

  const _AccountCard({required this.account, required this.formattedValue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = account['positive'] as bool;
    final trend = (account['trend'] as List<double>);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account['label'] as String,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 30,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(show: false),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(trend.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: trend[i],
                        color: isPositive
                            ? AppTheme.primary.withOpacity(0.7)
                            : AppTheme.mutedLight.withOpacity(0.5),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formattedValue,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.onSurfaceLight,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            account['percentage'] as String,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isPositive ? AppTheme.success : AppTheme.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
