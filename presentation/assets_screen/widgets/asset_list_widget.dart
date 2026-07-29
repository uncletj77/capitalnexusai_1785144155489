import 'package:flutter/material.dart';
import '../assets_screen.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class AssetListWidget extends StatelessWidget {
  final List<AssetModel> assets;
  final bool twoColumn;

  const AssetListWidget({
    required this.assets,
    this.twoColumn = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'account_balance_wallet_outlined',
                color: AppTheme.mutedLight,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'No assets in this category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add your first asset to start tracking wealth',
                style: TextStyle(fontSize: 13, color: AppTheme.mutedLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (twoColumn) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _AssetCard(asset: assets[i]),
          childCount: assets.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 350 + (i * 50).clamp(0, 400)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AssetCard(asset: assets[i]),
          ),
        );
      }, childCount: assets.length),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final AssetModel asset;

  const _AssetCard({required this.asset});

  String _formatTZS(double value) {
    if (value >= 1000000) return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    return 'TZS ${value.toStringAsFixed(0)}';
  }

  Color _getCategoryColor() {
    switch (asset.category) {
      case 'current':
        return AppTheme.currentAssetColor;
      case 'fixed':
        return AppTheme.fixedAssetColor;
      case 'depreciating':
        return AppTheme.depreciatingColor;
      case 'appreciating':
        return AppTheme.appreciatingColor;
      case 'intangible':
        return AppTheme.intangibleColor;
      default:
        return AppTheme.primary;
    }
  }

  String _getCategoryLabel() {
    switch (asset.category) {
      case 'current':
        return 'CURRENT';
      case 'fixed':
        return 'FIXED';
      case 'depreciating':
        return 'DEPREC.';
      case 'appreciating':
        return 'APPRECI.';
      case 'intangible':
        return 'INTANGIBLE';
      default:
        return asset.category.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor();
    final hasChange = asset.changePercent != 0;
    final isPositive = asset.changePercent >= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: categoryColor, width: 3),
          top: BorderSide(color: AppTheme.outlineLight),
          right: BorderSide(color: AppTheme.outlineLight),
          bottom: BorderSide(color: AppTheme.outlineLight),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          splashColor: categoryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: asset.iconName,
                          color: categoryColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.onSurfaceLight,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  _getCategoryLabel(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: categoryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              CustomIconWidget(
                                iconName: 'location_on_outlined',
                                color: AppTheme.mutedLight,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                asset.location,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.mutedLight,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (hasChange)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppTheme.successContainer
                              : AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: isPositive
                                  ? 'arrow_upward'
                                  : 'arrow_downward',
                              color: isPositive
                                  ? AppTheme.success
                                  : AppTheme.error,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${asset.changePercent.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isPositive
                                    ? AppTheme.success
                                    : AppTheme.error,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Value row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT VALUE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.mutedLight,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTZS(asset.currentValue),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.onSurfaceLight,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (asset.purchasePrice > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PURCHASE PRICE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.mutedLight,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTZS(asset.purchasePrice),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppTheme.mutedLight,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
