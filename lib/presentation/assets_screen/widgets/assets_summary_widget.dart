import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AssetsSummaryWidget extends StatelessWidget {
  final double totalValue;
  final int count;

  const AssetsSummaryWidget({
    required this.totalValue,
    required this.count,
    super.key,
  });

  String _formatTZS(double value) {
    if (value >= 1000000000) {
      return 'TZS ${(value / 1000000000).toStringAsFixed(3)}B';
    } else if (value >= 1000000) {
      return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    }
    return 'TZS ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL ASSETS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withAlpha(179),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTZS(totalValue),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count assets tracked',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(179),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: CustomIconWidget(
              iconName: 'account_balance_wallet',
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
