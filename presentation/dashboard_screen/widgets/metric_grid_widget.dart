import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MetricGridWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const MetricGridWidget({required this.data, super.key});

  String _formatTZS(double value) {
    if (value >= 1000000) return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    return 'TZS ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final metrics = [
      {
        'label': 'SPEND',
        'value': _formatTZS(data['spend'] as double),
        'sub': '4 ACCOUNTS',
        'icon': 'shopping_bag_outlined',
        'color': AppTheme.error,
      },
      {
        'label': 'SAVE',
        'value': _formatTZS(data['save'] as double),
        'sub': '23.8%',
        'icon': 'savings_outlined',
        'color': AppTheme.success,
      },
      {
        'label': 'INVEST',
        'value': _formatTZS(data['invest'] as double),
        'sub': '32.4%',
        'icon': 'trending_up',
        'color': AppTheme.primary,
      },
      {
        'label': 'BORROW',
        'value': '${data['borrowCount']}',
        'sub': 'LOANS',
        'icon': 'account_balance_outlined',
        'color': AppTheme.warning,
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

    return Container(
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
                  color: color.withOpacity(0.1),
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
          Text(
            metric['sub'] as String,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
