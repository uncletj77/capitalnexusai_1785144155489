import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../routes/app_routes.dart';
import 'package:go_router/go_router.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'label': 'Register',
        'icon': 'add_circle',
        'color': const Color(0xFF1A5F7A),
        'route': AppRoutes.universalRegistrationWizardScreen,
        'extra': null,
        'isPrimary': true,
      },
      {
        'label': 'Income',
        'icon': 'trending_up',
        'color': const Color(0xFF10B981),
        'route': AppRoutes.universalRegistrationWizardScreen,
        'extra': {'category': 'transaction', 'type': 'income'},
        'isPrimary': false,
      },
      {
        'label': 'Expense',
        'icon': 'trending_down',
        'color': const Color(0xFFEF4444),
        'route': AppRoutes.universalRegistrationWizardScreen,
        'extra': {'category': 'transaction', 'type': 'expense'},
        'isPrimary': false,
      },
      {
        'label': 'Transfer',
        'icon': 'swap_horiz',
        'color': const Color(0xFF2D9CDB),
        'route': AppRoutes.universalRegistrationWizardScreen,
        'extra': {'category': 'transaction', 'type': 'transfer'},
        'isPrimary': false,
      },
      {
        'label': 'Add Asset',
        'icon': 'real_estate_agent',
        'color': const Color(0xFF8B5CF6),
        'route': AppRoutes.universalRegistrationWizardScreen,
        'extra': {'category': 'asset'},
        'isPrimary': false,
      },
      {
        'label': 'Business',
        'icon': 'business_center',
        'color': const Color(0xFF059669),
        'route': AppRoutes.businessDashboardScreen,
        'extra': null,
        'isPrimary': false,
      },
      {
        'label': 'Invest',
        'icon': 'show_chart',
        'color': const Color(0xFF0EA5E9),
        'route': AppRoutes.universalRegistrationWizardScreen,
        'extra': {'category': 'investment'},
        'isPrimary': false,
      },
      {
        'label': 'Loans',
        'icon': 'account_balance',
        'color': const Color(0xFF1A5F7A),
        'route': AppRoutes.loanDashboardScreen,
        'extra': null,
        'isPrimary': false,
      },
      {
        'label': 'Net Worth',
        'icon': 'bar_chart',
        'color': const Color(0xFFF59E0B),
        'route': AppRoutes.netWorthScreen,
        'extra': null,
        'isPrimary': false,
      },
      {
        'label': 'AI Brain',
        'icon': 'psychology',
        'color': const Color(0xFF8B5CF6),
        'route': AppRoutes.aiAssistantScreen,
        'extra': null,
        'isPrimary': false,
      },
      {
        'label': 'Future Plan',
        'icon': 'timeline',
        'color': const Color(0xFF1A5F7A),
        'route': AppRoutes.futurePlanningScreen,
        'extra': null,
        'isPrimary': false,
      },
      {
        'label': 'Analytics',
        'icon': 'analytics',
        'color': const Color(0xFF0EA5E9),
        'route': AppRoutes.analyticsScreen,
        'extra': null,
        'isPrimary': false,
      },
      {
        'label': 'Automation',
        'icon': 'bolt',
        'color': const Color(0xFFF59E0B),
        'route': AppRoutes.automationScreen,
        'extra': null,
        'isPrimary': false,
      },
      {
        'label': 'Admin',
        'icon': 'admin_panel_settings',
        'color': const Color(0xFF1A5F7A),
        'route': AppRoutes.enterpriseAdminScreen,
        'extra': null,
        'isPrimary': false,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final action = actions[i];
                final color = action['color'] as Color;
                final isPrimary = action['isPrimary'] as bool;
                return GestureDetector(
                  onTap: () {
                    final extra = action['extra'];
                    context.push(action['route'] as String, extra: extra);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: isPrimary ? 52 : 48,
                        height: isPrimary ? 52 : 48,
                        decoration: BoxDecoration(
                          color: isPrimary ? color : color.withAlpha(18),
                          borderRadius: BorderRadius.circular(
                            isPrimary ? 16 : 14,
                          ),
                          border: Border.all(
                            color: isPrimary ? color : color.withAlpha(40),
                            width: isPrimary ? 0 : 1,
                          ),
                          boxShadow: isPrimary
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(60),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: action['icon'] as String,
                            color: isPrimary ? Colors.white : color,
                            size: isPrimary ? 24 : 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: isPrimary
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isPrimary
                              ? AppTheme.primary
                              : AppTheme.mutedLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
