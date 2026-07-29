import 'package:flutter/material.dart';

import '../core/app_export.dart';

/// CNA Module Navigation Drawer
/// Provides unified navigation across all CNA modules.
class CnaModuleDrawer extends StatelessWidget {
  const CnaModuleDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CustomIconWidget(
                        iconName: 'account_balance',
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Capital Nexus AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Enterprise Platform',
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSection(context, 'Core', [
                    _NavItem('Dashboard', 'home', AppRoutes.dashboardScreen),
                    _NavItem(
                      'Executive Dashboard',
                      'dashboard_customize',
                      AppRoutes.executiveDashboardScreen,
                    ),
                    _NavItem(
                      'Profile & Settings',
                      'person',
                      AppRoutes.profileSettingsScreen,
                    ),
                    _NavItem(
                      'Notifications',
                      'notifications',
                      AppRoutes.notificationCenterScreen,
                    ),
                  ]),
                  _buildSection(context, 'Finance', [
                    _NavItem(
                      'Finance Dashboard',
                      'account_balance',
                      AppRoutes.financeDashboardScreen,
                    ),
                    _NavItem(
                      'Accounts',
                      'credit_card',
                      AppRoutes.accountsScreen,
                    ),
                    _NavItem(
                      'Transactions',
                      'receipt_long',
                      AppRoutes.transactionHistoryScreen,
                    ),
                    _NavItem(
                      'Budget Planner',
                      'pie_chart',
                      AppRoutes.budgetPlannerScreen,
                    ),
                    _NavItem(
                      'Financial Goals',
                      'flag',
                      AppRoutes.financialGoalsScreen,
                    ),
                    _NavItem(
                      'Net Worth',
                      'bar_chart',
                      AppRoutes.netWorthScreen,
                    ),
                  ]),
                  _buildSection(context, 'Assets', [
                    _NavItem(
                      'Asset Dashboard',
                      'real_estate_agent',
                      AppRoutes.assetDashboardScreen,
                    ),
                    _NavItem(
                      'Asset Portfolio',
                      'folder_special',
                      AppRoutes.assetPortfolioScreen,
                    ),
                    _NavItem(
                      'AI Asset Advisor',
                      'psychology',
                      AppRoutes.aiAssetAdvisorScreen,
                    ),
                  ]),
                  _buildSection(context, 'Loans', [
                    _NavItem(
                      'Loan Dashboard',
                      'account_balance_wallet',
                      AppRoutes.loanDashboardScreen,
                    ),
                    _NavItem(
                      'Loans Receivable',
                      'payments',
                      AppRoutes.loansReceivableScreen,
                    ),
                    _NavItem(
                      'Loan Simulator',
                      'calculate',
                      AppRoutes.loanSimulatorScreen,
                    ),
                    _NavItem(
                      'Repayment Calendar',
                      'calendar_month',
                      AppRoutes.loanRepaymentCalendarScreen,
                    ),
                    _NavItem(
                      'AI Debt Advisor',
                      'psychology',
                      AppRoutes.aiDebtAdvisorScreen,
                    ),
                  ]),
                  _buildSection(context, 'Business', [
                    _NavItem(
                      'Business Dashboard',
                      'business_center',
                      AppRoutes.businessDashboardScreen,
                    ),
                    _NavItem(
                      'Branch Management',
                      'store',
                      AppRoutes.branchManagementScreen,
                    ),
                    _NavItem(
                      'Employee Management',
                      'group',
                      AppRoutes.employeeManagementScreen,
                    ),
                    _NavItem(
                      'Business Transactions',
                      'swap_horiz',
                      AppRoutes.businessTransactionsScreen,
                    ),
                    _NavItem(
                      'AI Business Advisor',
                      'psychology',
                      AppRoutes.aiBusinessAdvisorScreen,
                    ),
                  ]),
                  _buildSection(context, 'Investments', [
                    _NavItem(
                      'Investment Dashboard',
                      'trending_up',
                      AppRoutes.investmentDashboardScreen,
                    ),
                    _NavItem(
                      'Portfolio Analysis',
                      'donut_large',
                      AppRoutes.investmentPortfolioAnalysisScreen,
                    ),
                    _NavItem(
                      'Investment Simulator',
                      'calculate',
                      AppRoutes.investmentSimulatorScreen,
                    ),
                    _NavItem(
                      'AI Investment Advisor',
                      'psychology',
                      AppRoutes.aiInvestmentAdvisorScreen,
                    ),
                  ]),
                  _buildSection(context, 'Intelligence', [
                    _NavItem('AI Brain', 'psychology', AppRoutes.aiBrainScreen),
                    _NavItem(
                      'AI Workspace',
                      'workspaces',
                      AppRoutes.aiWorkspaceScreen,
                    ),
                    _NavItem(
                      'Future Planning',
                      'timeline',
                      AppRoutes.futurePlanningScreen,
                    ),
                    _NavItem(
                      'Wealth Planning',
                      'account_balance_wallet',
                      AppRoutes.wealthPlanningScreen,
                    ),
                    _NavItem(
                      'Advanced Decisions',
                      'psychology_alt',
                      AppRoutes.advancedDecisionScreen,
                    ),
                    _NavItem(
                      'Analytics',
                      'analytics',
                      AppRoutes.analyticsScreen,
                    ),
                    _NavItem(
                      'Reports',
                      'description',
                      AppRoutes.enterpriseReportingScreen,
                    ),
                  ]),
                  _buildSection(context, 'Operations', [
                    _NavItem('Automation', 'bolt', AppRoutes.automationScreen),
                    _NavItem(
                      'Integrations',
                      'extension',
                      AppRoutes.integrationScreen,
                    ),
                    _NavItem(
                      'System Monitor',
                      'monitor_heart',
                      AppRoutes.systemMonitorScreen,
                    ),
                  ]),
                  _buildSection(context, 'Administration', [
                    _NavItem(
                      'Enterprise Admin',
                      'admin_panel_settings',
                      AppRoutes.enterpriseAdminScreen,
                    ),
                    _NavItem(
                      'Security Dashboard',
                      'security',
                      AppRoutes.securityDashboardScreen,
                    ),
                    _NavItem(
                      'Organization',
                      'corporate_fare',
                      AppRoutes.organizationDashboardScreen,
                    ),
                  ]),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CNA v1.0 — Enterprise Platform',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<_NavItem> items,
  ) {
    final theme = Theme.of(context);
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) {
          final isActive = currentRoute == item.route;
          return InkWell(
            onTap: () {
              Navigator.of(context).pop();
              context.go(item.route);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary.withAlpha(15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: item.icon,
                    color: isActive
                        ? AppTheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppTheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _NavItem {
  final String label;
  final String icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}
