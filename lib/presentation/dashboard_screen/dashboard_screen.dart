import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/finance_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_module_drawer.dart';
import './widgets/account_cards_widget.dart';
import './widgets/ai_insights_widget.dart';
import './widgets/dashboard_app_bar_widget.dart';
import './widgets/debt_health_widget.dart';
import './widgets/executive_metrics_widget.dart';
import './widgets/hero_balance_widget.dart';
import './widgets/metric_grid_widget.dart';
import './widgets/overview_card_widget.dart';
import './widgets/period_filter_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/recent_activity_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _client = SupabaseService.client;
  int _selectedPeriod = 2;
  bool _isLoading = true;
  bool _isEmpty = false;

  Map<String, dynamic> _financialData = {
    'netWorth': 0.0,
    'totalAssets': 0.0,
    'totalLiabilities': 0.0,
    'availableCash': 0.0,
    'monthlyIncome': 0.0,
    'monthlyExpenses': 0.0,
    'totalInvestments': 0.0,
    'totalBusinessValue': 0.0,
    'spend': 0.0,
    'save': 0.0,
    'invest': 0.0,
    'borrowCount': 0,
    'savingsRate': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final summary = await FinanceService.instance.getDashboardSummary();

      // Check if user has any data
      final hasData =
          (summary['netWorth'] as double) != 0 ||
          (summary['monthlyIncome'] as double) != 0 ||
          (summary['monthlyExpenses'] as double) != 0 ||
          (summary['totalAssets'] as double) != 0 ||
          (summary['borrowCount'] as int) != 0;

      // Save net worth snapshot in background
      FinanceService.instance.saveNetWorthSnapshot();

      setState(() {
        _financialData = summary;
        _isEmpty = !hasData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const CnaModuleDrawer(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppTheme.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isEmpty
              ? _buildOnboardingDashboard(context)
              : _buildLiveDashboard(context),
        ),
      ),
    );
  }

  Widget _buildLiveDashboard(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: DashboardAppBarWidget()),
        SliverToBoxAdapter(
          child: HeroBalanceWidget(
            netWorth: _financialData['netWorth'] as double,
            totalAssets: _financialData['totalAssets'] as double,
            totalLiabilities: _financialData['totalLiabilities'] as double,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: PeriodFilterWidget(
              selectedIndex: _selectedPeriod,
              onSelected: (i) => setState(() => _selectedPeriod = i),
            ),
          ),
        ),
        // Executive Summary Cards (SPEND, SAVE, INVEST, BORROW)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: MetricGridWidget(data: _financialData),
          ),
        ),
        // Overview Graph — live data
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OverviewCardWidget(selectedPeriod: _selectedPeriod),
          ),
        ),
        // Executive Financial Metrics (12 KPIs)
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: ExecutiveMetricsWidget(data: _financialData)),
        // Debt Health Score
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DebtHealthWidget(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(child: QuickActionsWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(child: AiInsightsWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: AccountCardsWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(child: RecentActivityWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildOnboardingDashboard(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          DashboardAppBarWidget(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Capital Nexus AI',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your financial data will appear here once you start adding transactions, accounts, and assets.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Get Started',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._onboardingActions(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  List<Widget> _onboardingActions(BuildContext context) {
    final actions = [
      {
        'icon': 'credit_card',
        'title': 'Add an Account',
        'subtitle': 'Bank, mobile money, or cash',
        'route': '/accounts',
        'color': const Color(0xFF1A5F7A),
      },
      {
        'icon': 'receipt_long',
        'title': 'Record a Transaction',
        'subtitle': 'Income or expense',
        'route': '/transaction-history-screen',
        'color': const Color(0xFF27AE60),
      },
      {
        'icon': 'real_estate_agent',
        'title': 'Add an Asset',
        'subtitle': 'Property, vehicle, or equipment',
        'route': '/asset-dashboard',
        'color': const Color(0xFF4BB8A0),
      },
      {
        'icon': 'trending_up',
        'title': 'Track Investments',
        'subtitle': 'Stocks, bonds, or funds',
        'route': '/investment-dashboard',
        'color': const Color(0xFF2D9CDB),
      },
      {
        'icon': 'business_center',
        'title': 'Add a Business',
        'subtitle': 'Track business finances',
        'route': '/business-dashboard',
        'color': const Color(0xFF2980B9),
      },
      {
        'icon': 'flag',
        'title': 'Set Financial Goals',
        'subtitle': 'Savings and wealth targets',
        'route': '/financial-goals',
        'color': const Color(0xFF9B59B6),
      },
    ];

    return actions
        .map(
          (a) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: GestureDetector(
              onTap: () => context.go(a['route'] as String),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (a['color'] as Color).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: a['icon'] as String,
                          color: a['color'] as Color,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            a['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 12,
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
          ),
        )
        .toList();
  }
}
