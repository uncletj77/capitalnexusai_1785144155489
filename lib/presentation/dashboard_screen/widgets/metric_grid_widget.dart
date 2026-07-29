import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class MetricGridWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const MetricGridWidget({required this.data, super.key});

  String _formatTZS(double value) {
    if (value >= 1000000000) {
      return 'TZS ${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    return 'TZS ${value.toStringAsFixed(0)}';
  }

  String _formatRate(double rate) => '${rate.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final spend = (data['spend'] as double?) ?? 0.0;
    final save = (data['save'] as double?) ?? 0.0;
    final invest = (data['invest'] as double?) ?? 0.0;
    final borrowCount = (data['borrowCount'] as int?) ?? 0;
    final savingsRate = (data['savingsRate'] as double?) ?? 0.0;
    final totalLiabilities = (data['totalLiabilities'] as double?) ?? 0.0;

    final metrics = [
      {
        'label': 'SPENT',
        'value': _formatTZS(spend),
        'sub': 'This Month',
        'icon': 'shopping_bag_outlined',
        'color': const Color(0xFFE53E3E),
        'route': AppRoutes.transactionHistoryScreen,
        'routeExtra': 'expense',
      },
      {
        'label': 'SAVED',
        'value': _formatTZS(save),
        'sub': '${_formatRate(savingsRate)} rate',
        'icon': 'savings_outlined',
        'color': const Color(0xFF27AE60),
        'route': AppRoutes.accountsScreen,
        'routeExtra': null,
      },
      {
        'label': 'INVEST',
        'value': _formatTZS(invest),
        'sub': 'Portfolio Value',
        'icon': 'trending_up',
        'color': const Color(0xFF1A5F7A),
        'route': AppRoutes.investmentDashboardScreen,
        'routeExtra': null,
      },
      {
        'label': 'BORROW',
        'value': borrowCount > 0
            ? _formatTZS(totalLiabilities)
            : '$borrowCount',
        'sub': '$borrowCount Active Loan${borrowCount != 1 ? 's' : ''}',
        'icon': 'account_balance_outlined',
        'color': const Color(0xFFF2994A),
        'route': AppRoutes.loanDashboardScreen,
        'routeExtra': null,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: metrics.map((m) => _MetricCard(metric: m)).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final Map<String, dynamic> metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = metric['color'] as Color;
    final route = metric['route'] as String?;

    return GestureDetector(
      onTap: route != null ? () => context.go(route) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  metric['label'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.mutedLight,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: metric['icon'] as String,
                      color: color,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              metric['value'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurfaceLight,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric['sub'] as String,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: color.withAlpha(150),
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
