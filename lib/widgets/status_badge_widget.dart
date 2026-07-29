import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../theme/app_theme.dart';

enum BadgeType { success, warning, error, info, neutral }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final BadgeType type;
  final double? fontSize;

  const StatusBadgeWidget({
    required this.label,
    this.type = BadgeType.neutral,
    this.fontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize ?? 10,
          fontWeight: FontWeight.w700,
          color: colors.$2,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (Color, Color) _getColors() {
    switch (type) {
      case BadgeType.success:
        return (AppTheme.successContainer, AppTheme.success);
      case BadgeType.warning:
        return (AppTheme.warningContainer, AppTheme.warning);
      case BadgeType.error:
        return (AppTheme.dangerContainer, AppTheme.danger);
      case BadgeType.info:
        return (AppTheme.infoContainer, AppTheme.info);
      case BadgeType.neutral:
        return (AppTheme.neutralContainer, AppTheme.neutral);
    }
  }
}
