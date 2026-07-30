import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_export.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/profile_settings_screen/profile_settings_screen.dart';
import '../presentation/security_dashboard_screen/security_dashboard_screen.dart';
import '../presentation/organization_dashboard_screen/organization_dashboard_screen.dart';
import '../presentation/finance_dashboard_screen/finance_dashboard_screen.dart';
import '../presentation/finance_module_screen/finance_module_screen.dart';
import '../presentation/accounts_screen/accounts_screen.dart';
import '../presentation/budget_planner_screen/budget_planner_screen.dart';
import '../presentation/financial_goals_screen/financial_goals_screen.dart';
import '../presentation/net_worth_screen/net_worth_screen.dart';
import '../presentation/transaction_history_screen/transaction_history_screen.dart';
// Asset Intelligence Engine screens
import '../presentation/asset_dashboard_screen/asset_dashboard_screen.dart';
import '../presentation/add_asset_screen/add_asset_screen.dart';
import '../presentation/asset_details_screen/asset_details_screen.dart';
import '../presentation/asset_portfolio_screen/asset_portfolio_screen.dart';
import '../presentation/ai_asset_advisor_screen/ai_asset_advisor_screen.dart';
// Loan & Liability Intelligence Engine screens
import '../presentation/loan_dashboard_screen/loan_dashboard_screen.dart';
import '../presentation/add_loan_screen/add_loan_screen.dart';
import '../presentation/loan_details_screen/loan_details_screen.dart';
import '../presentation/loan_repayment_calendar_screen/loan_repayment_calendar_screen.dart';
import '../presentation/loan_simulator_screen/loan_simulator_screen.dart';
import '../presentation/ai_debt_advisor_screen/ai_debt_advisor_screen.dart';
import '../presentation/loans_receivable_screen/loans_receivable_screen.dart';
// Business Intelligence Engine screens
import '../presentation/business_dashboard_screen/business_dashboard_screen.dart';
import '../presentation/add_business_screen/add_business_screen.dart';
import '../presentation/branch_management_screen/branch_management_screen.dart';
import '../presentation/employee_management_screen/employee_management_screen.dart';
import '../presentation/business_transactions_screen/business_transactions_screen.dart';
import '../presentation/ai_business_advisor_screen/ai_business_advisor_screen.dart';
// Investment Intelligence Engine screens
import '../presentation/investment_dashboard_screen/investment_dashboard_screen.dart';
import '../presentation/add_investment_screen/add_investment_screen.dart';
import '../presentation/investment_details_screen/investment_details_screen.dart';
import '../presentation/investment_portfolio_analysis_screen/investment_portfolio_analysis_screen.dart';
import '../presentation/investment_simulator_screen/investment_simulator_screen.dart';
import '../presentation/ai_investment_advisor_screen/ai_investment_advisor_screen.dart';
// Cash Flow Intelligence Engine screens
import '../presentation/ai_brain_screen/ai_brain_screen.dart';
import '../presentation/future_planning_screen/future_planning_screen.dart';
import '../presentation/advanced_decision_screen/advanced_decision_screen.dart';
import '../widgets/app_scaffold.dart';
// Analytics & Executive Intelligence Engine
import '../presentation/analytics_screen/analytics_screen.dart';
// Automation & Smart Assistant Engine
import '../presentation/automation_screen/automation_screen.dart';
import '../presentation/notification_center_screen/notification_center_screen.dart';
// Security & Administration Engine
import '../presentation/enterprise_admin_screen/enterprise_admin_screen.dart';
// Enterprise Integration & Extensibility Engine
import '../presentation/integration_screen/integration_screen.dart';
import '../presentation/system_monitor_screen/system_monitor_screen.dart';
// Universal Registration Wizard
import '../presentation/universal_registration_wizard_screen/universal_registration_wizard_screen.dart';
import '../services/universal_registration_service.dart';
// Wealth Planning Intelligence
import '../presentation/wealth_planning_screen/wealth_planning_screen.dart';
import '../presentation/executive_dashboard_screen/executive_dashboard_screen.dart';
import '../presentation/enterprise_reporting_screen/enterprise_reporting_screen.dart';
import '../presentation/ai_workspace_screen/ai_workspace_screen.dart';
import '../presentation/savings_centre_screen/savings_centre_screen.dart';
import '../presentation/financial_closing_screen/financial_closing_screen.dart';
import '../presentation/master_asset_registry_screen/master_asset_registry_screen.dart';
import '../presentation/enterprise_transaction_screen/enterprise_transaction_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String onboardingScreen = '/onboarding';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String loginScreen = '/login';
  static const String registrationScreen = '/register';
  static const String dashboardScreen = '/dashboard-screen';
  static const String assetsScreen = '/assets-screen';
  static const String transactionHistoryScreen = '/transaction-history-screen';
  static const String aiAssistantScreen = '/ai-assistant-screen';
  static const String profileSettingsScreen = '/profile-settings-screen';
  static const String securityDashboardScreen = '/security-dashboard';
  static const String organizationDashboardScreen = '/organization-dashboard';
  // Finance Center routes
  static const String financeDashboardScreen = '/finance-dashboard';
  static const String accountsScreen = '/accounts';
  static const String budgetPlannerScreen = '/budget-planner';
  static const String financialGoalsScreen = '/financial-goals';
  static const String netWorthScreen = '/net-worth';
  static const String financeModuleScreen = '/finance-module';
  // Asset Intelligence Engine routes
  static const String assetDashboardScreen = '/asset-dashboard';
  static const String addAssetScreen = '/add-asset';
  static const String assetDetailsScreen = '/asset-details';
  static const String assetPortfolioScreen = '/asset-portfolio';
  static const String aiAssetAdvisorScreen = '/ai-asset-advisor';
  // Loan & Liability Intelligence Engine routes
  static const String loanDashboardScreen = '/loan-dashboard';
  static const String addLoanScreen = '/add-loan';
  static const String loanDetailsScreen = '/loan-details';
  static const String loanRepaymentCalendarScreen = '/loan-repayment-calendar';
  static const String loanSimulatorScreen = '/loan-simulator';
  static const String aiDebtAdvisorScreen = '/ai-debt-advisor';
  static const String loansReceivableScreen = '/loans-receivable';
  // Business Intelligence Engine routes
  static const String businessDashboardScreen = '/business-dashboard';
  static const String addBusinessScreen = '/add-business';
  static const String businessProfileScreen = '/business-profile';
  static const String branchManagementScreen = '/branch-management';
  static const String employeeManagementScreen = '/employee-management';
  static const String businessTransactionsScreen = '/business-transactions';
  static const String addBusinessTransactionScreen =
      '/add-business-transaction';
  static const String businessInventoryScreen = '/business-inventory';
  static const String businessSimulatorScreen = '/business-simulator';
  static const String businessReportsScreen = '/business-reports';
  static const String aiBusinessAdvisorScreen = '/ai-business-advisor';
  // Investment Intelligence Engine routes
  static const String investmentDashboardScreen = '/investment-dashboard';
  static const String addInvestmentScreen = '/add-investment';
  static const String investmentDetailsScreen = '/investment-details';
  static const String investmentPortfolioAnalysisScreen =
      '/investment-portfolio-analysis';
  static const String investmentSimulatorScreen = '/investment-simulator';
  static const String aiInvestmentAdvisorScreen = '/ai-investment-advisor';
  // Cash Flow Intelligence Engine routes
  static const String futurePlanningScreen = '/future-planning';
  // AI Brain Engine routes
  static const String aiBrainScreen = '/ai-brain';
  // Advanced Decision Engine routes
  static const String advancedDecisionScreen = '/advanced-decision';
  // Analytics & Executive Intelligence Engine routes
  static const String analyticsScreen = '/analytics';
  // Automation & Smart Assistant Engine routes
  static const String automationScreen = '/automation';
  static const String notificationCenterScreen = '/notification-center';
  // Security & Administration Engine routes
  static const String enterpriseAdminScreen = '/enterprise-admin';
  // Enterprise Integration & Extensibility Engine routes
  static const String integrationScreen = '/integration';
  // System Monitor route
  static const String systemMonitorScreen = '/system-monitor';
  // Universal Registration Wizard
  static const String universalRegistrationWizardScreen =
      '/universal-registration-wizard';
  static const String wealthPlanningScreen = '/wealth-planning';
  static const String executiveDashboardScreen = '/executive-dashboard';
  static const String enterpriseReportingScreen = '/enterprise-reporting';
  static const String aiWorkspaceScreen = '/ai-workspace';
  static const String savingsCentreScreen = '/savings-centre';
  static const String financialClosingScreen = '/financial-closing';
  static const String masterAssetRegistryScreen = '/master-asset-registry';
  static const String enterpriseTransactionScreen = '/enterprise-transactions';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  redirect: (context, state) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAuthenticated = user != null;
    final isAuthRoute =
        state.matchedLocation == AppRoutes.signUpLoginScreen ||
        state.matchedLocation == AppRoutes.loginScreen ||
        state.matchedLocation == AppRoutes.registrationScreen ||
        state.matchedLocation == AppRoutes.onboardingScreen ||
        state.matchedLocation == AppRoutes.initial;

    // If not authenticated and trying to access protected route, redirect to login
    if (!isAuthenticated && !isAuthRoute) {
      return AppRoutes.signUpLoginScreen;
    }
    // If authenticated and on auth route, redirect to dashboard
    if (isAuthenticated &&
        isAuthRoute &&
        state.matchedLocation != AppRoutes.initial) {
      return AppRoutes.dashboardScreen;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboardingScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.signUpLoginScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.loginScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.registrationScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegistrationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.securityDashboardScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SecurityDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.organizationDashboardScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OrganizationDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.transactionHistoryScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const TransactionHistoryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Finance Center standalone routes
    GoRoute(
      path: AppRoutes.accountsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AccountsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.budgetPlannerScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BudgetPlannerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.financialGoalsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FinancialGoalsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.netWorthScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NetWorthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Asset Intelligence Engine routes
    GoRoute(
      path: AppRoutes.addAssetScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AddAssetScreen(
          existingAsset: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.assetDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AssetDetailsScreen(asset: state.extra as Map<String, dynamic>),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.assetPortfolioScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AssetPortfolioScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.aiAssetAdvisorScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiAssetAdvisorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Loan & Liability Intelligence Engine routes
    GoRoute(
      path: AppRoutes.loanDashboardScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoanDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.addLoanScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AddLoanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.loanDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: LoanDetailsScreen(loan: state.extra as Map<String, dynamic>),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.loanRepaymentCalendarScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoanRepaymentCalendarScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.loanSimulatorScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: LoanSimulatorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.aiDebtAdvisorScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiDebtAdvisorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.loansReceivableScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoansReceivableScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Business Intelligence Engine routes
    GoRoute(
      path: AppRoutes.addBusinessScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AddBusinessScreen(
          existingBusiness: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.businessProfileScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AddBusinessScreen(
          existingBusiness: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.branchManagementScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: BranchManagementScreen(
          business: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeManagementScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: EmployeeManagementScreen(
          business: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.businessTransactionsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: BusinessTransactionsScreen(
          business: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.addBusinessTransactionScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: BusinessTransactionsScreen(
          business: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.aiBusinessAdvisorScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AiBusinessAdvisorScreen(
          business: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.businessReportsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: BusinessTransactionsScreen(
          business: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.businessInventoryScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: BusinessTransactionsScreen(
          business: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Investment Intelligence Engine routes
    GoRoute(
      path: AppRoutes.addInvestmentScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AddInvestmentScreen(
          existingInvestment: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.investmentDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: InvestmentDetailsScreen(
          investment: state.extra as Map<String, dynamic>,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.investmentPortfolioAnalysisScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const InvestmentPortfolioAnalysisScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.investmentSimulatorScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const InvestmentSimulatorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.aiInvestmentAdvisorScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiInvestmentAdvisorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.businessSimulatorScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AiBusinessAdvisorScreen(
          business: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Cash Flow Intelligence Engine route
    GoRoute(
      path: AppRoutes.futurePlanningScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FuturePlanningScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // AI Brain Engine standalone route
    GoRoute(
      path: AppRoutes.aiBrainScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiBrainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Analytics & Executive Intelligence Engine route
    GoRoute(
      path: AppRoutes.analyticsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AnalyticsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.automationScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AutomationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.notificationCenterScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationCenterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // System Monitor route
    GoRoute(
      path: AppRoutes.systemMonitorScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SystemMonitorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Universal Registration Wizard
    GoRoute(
      path: AppRoutes.universalRegistrationWizardScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        RegistrationCategory? cat;
        String? type;
        if (extra != null) {
          final catStr = extra['category'] as String?;
          if (catStr != null) {
            cat = RegistrationCategory.values.firstWhere(
              (c) => c.name == catStr,
              orElse: () => RegistrationCategory.transaction,
            );
          }
          type = extra['type'] as String?;
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: UniversalRegistrationWizardScreen(
            initialCategory: cat,
            initialType: type,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 320),
        );
      },
    ),
    // Security & Administration Engine route
    GoRoute(
      path: AppRoutes.enterpriseAdminScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EnterpriseAdminScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    // Advanced Decision Engine route
    GoRoute(
      path: AppRoutes.advancedDecisionScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdvancedDecisionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboardScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.assetDashboardScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const AssetDashboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.financeDashboardScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const FinanceDashboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.businessDashboardScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const BusinessDashboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.investmentDashboardScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const InvestmentDashboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.aiAssistantScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const AiBrainScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileSettingsScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProfileSettingsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.integrationScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const IntegrationScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
          ],
        ),
      ],
    ),
    // Wealth Planning Intelligence
    GoRoute(
      path: AppRoutes.wealthPlanningScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WealthPlanningScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    // Executive Dashboard
    GoRoute(
      path: AppRoutes.executiveDashboardScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ExecutiveDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    // Enterprise Reporting
    GoRoute(
      path: AppRoutes.enterpriseReportingScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EnterpriseReportingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    // AI Workspace — Master Prompt 6
    GoRoute(
      path: AppRoutes.aiWorkspaceScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiWorkspaceScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.savingsCentreScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SavingsCentreScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.financialClosingScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FinancialClosingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.masterAssetRegistryScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MasterAssetRegistryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.enterpriseTransactionScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EnterpriseTransactionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.financeModuleScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FinanceModuleScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
  ],
);
