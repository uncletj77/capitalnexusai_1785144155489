import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class AssetsAppBarWidget extends StatelessWidget {
  const AssetsAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Assets',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.onSurfaceLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Jul 25, 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'search',
                color: AppTheme.onSurfaceLight,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'sort',
                color: AppTheme.onSurfaceLight,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
