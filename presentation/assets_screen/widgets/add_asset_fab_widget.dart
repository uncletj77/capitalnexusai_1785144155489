import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AddAssetFabWidget extends StatelessWidget {
  const AddAssetFabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        _showAddAssetSheet(context);
      },
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: CustomIconWidget(
        iconName: 'add_rounded',
        color: Colors.white,
        size: 20,
      ),
      label: const Text(
        'Add Asset',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  void _showAddAssetSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineLight,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add New Asset',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose the type of asset to add to your portfolio',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedLight,
              ),
            ),
            const SizedBox(height: 24),
            _CategoryOption(
              iconName: 'payments',
              label: 'Current Asset',
              subtitle: 'Cash, bank accounts, mobile money',
              color: AppTheme.currentAssetColor,
            ),
            const SizedBox(height: 12),
            _CategoryOption(
              iconName: 'home_work',
              label: 'Fixed Asset',
              subtitle: 'Land, buildings, property',
              color: AppTheme.fixedAssetColor,
            ),
            const SizedBox(height: 12),
            _CategoryOption(
              iconName: 'trending_down',
              label: 'Depreciating Asset',
              subtitle: 'Vehicles, electronics, machinery',
              color: AppTheme.depreciatingColor,
            ),
            const SizedBox(height: 12),
            _CategoryOption(
              iconName: 'trending_up',
              label: 'Appreciating Asset',
              subtitle: 'Investments, growing businesses',
              color: AppTheme.appreciatingColor,
            ),
            const SizedBox(height: 12),
            _CategoryOption(
              iconName: 'lightbulb_outline',
              label: 'Intangible Asset',
              subtitle: 'Licenses, brands, IP',
              color: AppTheme.intangibleColor,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  final String iconName;
  final String label;
  final String subtitle;
  final Color color;

  const _CategoryOption({
    required this.iconName,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: iconName,
                    color: color,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.onSurfaceLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.mutedLight,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
