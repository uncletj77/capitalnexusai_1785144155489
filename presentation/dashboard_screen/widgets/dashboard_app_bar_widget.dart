import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DashboardAppBarWidget extends StatelessWidget {
  const DashboardAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Grid menu icon
          _NavIconButton(iconName: 'grid_view', onTap: () {}),
          const Spacer(),
          // Account selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'AH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'PERSONAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 4),
                CustomIconWidget(
                  iconName: 'fiber_manual_record',
                  color: AppTheme.primary,
                  size: 6,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Notification
          _NavIconButton(iconName: 'notifications_outlined', onTap: () {}),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final String iconName;
  final VoidCallback onTap;

  const _NavIconButton({required this.iconName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.onSurfaceLight,
            size: 20,
          ),
        ),
      ),
    );
  }
}
