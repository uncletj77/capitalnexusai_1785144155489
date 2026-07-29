import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AssetsFilterWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool vertical;

  const AssetsFilterWidget({
    required this.selectedIndex,
    required this.onSelected,
    this.vertical = false,
    super.key,
  });

  // Matches asset_category enum: fixed, current, permanent_strategic, temporary
  static const List<Map<String, String>> _filters = [
    {'label': 'All', 'icon': 'apps'},
    {'label': 'Fixed', 'icon': 'home_work'},
    {'label': 'Current', 'icon': 'payments'},
    {'label': 'Strategic', 'icon': 'trending_up'},
    {'label': 'Temporary', 'icon': 'trending_down'},
  ];

  static const List<Color> _filterColors = [
    AppTheme.primary,
    AppTheme.fixedAssetColor,
    AppTheme.currentAssetColor,
    AppTheme.appreciatingColor,
    AppTheme.depreciatingColor,
  ];

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        children: List.generate(_filters.length, (i) => _buildChip(context, i)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_filters.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildChip(context, i),
          );
        }),
      ),
    );
  }

  Widget _buildChip(BuildContext context, int i) {
    final theme = Theme.of(context);
    final isSelected = i == selectedIndex;
    final color = _filterColors[i];

    return GestureDetector(
      onTap: () => onSelected(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: vertical ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          _filters[i]['label']!,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : AppTheme.mutedLight,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
