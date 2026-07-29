import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class ExecQuickActionsWidget extends StatelessWidget {
  const ExecQuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = [
      _Action(
        'Register',
        'add_circle_outline',
        AppTheme.primary,
        AppRoutes.universalRegistrationWizardScreen,
      ),
      _Action(
        'Analytics',
        'analytics',
        const Color(0xFF6366F1),
        AppRoutes.analyticsScreen,
      ),
      _Action(
        'Reports',
        'description',
        const Color(0xFF10B981),
        AppRoutes.enterpriseReportingScreen,
      ),
      _Action(
        'Wealth Plan',
        'account_balance_wallet',
        const Color(0xFFF59E0B),
        AppRoutes.wealthPlanningScreen,
      ),
      _Action(
        'AI Brain',
        'psychology',
        const Color(0xFFEC4899),
        AppRoutes.aiBrainScreen,
      ),
      _Action(
        'Goals',
        'flag',
        const Color(0xFF06B6D4),
        AppRoutes.financialGoalsScreen,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((a) => _buildAction(context, a)).toList(),
    );
  }

  Widget _buildAction(BuildContext context, _Action action) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.go(action.route),
      child: Container(
        width: (MediaQuery.of(context).size.width - 52) / 3,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomIconWidget(
                iconName: action.icon,
                color: action.color,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  final String label;
  final String icon;
  final Color color;
  final String route;
  const _Action(this.label, this.icon, this.color, this.route);
}
