import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/analytics_service.dart';
import '../../services/finance_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_module_drawer.dart';
import './widgets/exec_ai_briefing_widget.dart';
import './widgets/exec_chart_section_widget.dart';
import './widgets/exec_financial_health_widget.dart';
import './widgets/exec_kpi_card_widget.dart';
import './widgets/exec_notification_panel_widget.dart';
import './widgets/exec_quick_actions_widget.dart';
import './widgets/exec_recent_activity_widget.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  State<ExecutiveDashboardScreen> createState() =>
      _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _kpiData = {};
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic> _analyticsData = {};
  late TabController _sectionController;
  int _selectedPeriod = 1; // 0=week, 1=month, 2=quarter, 3=year

  final List<String> _periods = ['Week', 'Month', 'Quarter', 'Year'];

  @override
  void initState() {
    super.initState();
    _sectionController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        FinanceService.instance.getDashboardSummary(),
        FinanceService.instance.getRecentTransactions(limit: 8),
        _loadNotifications(),
        AnalyticsService.instance.getDashboardData(),
      ]);
      if (mounted) {
        setState(() {
          _kpiData = results[0] as Map<String, dynamic>;
          _recentActivity = results[1] as List<Map<String, dynamic>>;
          _notifications = results[2] as List<Map<String, dynamic>>;
          _analyticsData = results[3] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];
      final res = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  String _fmt(double v) {
    if (v >= 1000000000) return 'TZS ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
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
          onRefresh: _loadData,
          color: AppTheme.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildDashboard(context),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final netWorth = (_kpiData['netWorth'] as double?) ?? 0;
    final totalAssets = (_kpiData['totalAssets'] as double?) ?? 0;
    final totalLiabilities = (_kpiData['totalLiabilities'] as double?) ?? 0;
    final cash = (_kpiData['availableCash'] as double?) ?? 0;
    final income = (_kpiData['monthlyIncome'] as double?) ?? 0;
    final expenses = (_kpiData['monthlyExpenses'] as double?) ?? 0;
    final investments = (_kpiData['totalInvestments'] as double?) ?? 0;
    final bizValue = (_kpiData['totalBusinessValue'] as double?) ?? 0;
    final savings = (_kpiData['save'] as double?) ?? 0;
    final netProfit = income - expenses;
    final profitMargin = income > 0 ? (netProfit / income * 100) : 0.0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: CustomIconWidget(
                iconName: 'menu',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Text(
            'Executive Dashboard',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'notifications_outlined',
                color: theme.colorScheme.onSurface,
                size: 22,
              ),
              onPressed: () => context.go(AppRoutes.notificationCenterScreen),
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.onSurface,
                size: 22,
              ),
              onPressed: _loadData,
            ),
          ],
        ),

        // Hero Net Worth Banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A5F7A),
                  Color(0xFF2D9CDB),
                  Color(0xFF0EA5E9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Net Worth',
                      style: GoogleFonts.manrope(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Live',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _fmt(netWorth),
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _heroStat('Assets', _fmt(totalAssets), Colors.white),
                    const SizedBox(width: 24),
                    _heroStat(
                      'Liabilities',
                      _fmt(totalLiabilities),
                      Colors.white70,
                    ),
                    const SizedBox(width: 24),
                    _heroStat(
                      'Profit Margin',
                      '${profitMargin.toStringAsFixed(1)}%',
                      profitMargin >= 0
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Period Filter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: List.generate(_periods.length, (i) {
                final selected = i == _selectedPeriod;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      _periods[i],
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // Section Label: Executive Summary
        SliverToBoxAdapter(
          child: _sectionHeader(
            context,
            'Executive Summary',
            'account_balance',
          ),
        ),

        // KPI Cards Grid — Row 1
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Net Worth',
                        value: _fmt(netWorth),
                        icon: 'bar_chart',
                        color: AppTheme.primary,
                        subtitle: 'Assets − Liabilities',
                        trend: netWorth >= 0 ? 'up' : 'down',
                        onTap: () => context.go(AppRoutes.netWorthScreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Cash Available',
                        value: _fmt(cash),
                        icon: 'account_balance_wallet',
                        color: const Color(0xFF0EA5E9),
                        subtitle: 'All accounts',
                        trend: 'neutral',
                        onTap: () => context.go(AppRoutes.accountsScreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Total Assets',
                        value: _fmt(totalAssets),
                        icon: 'real_estate_agent',
                        color: const Color(0xFF8B5CF6),
                        subtitle: 'All asset classes',
                        trend: 'up',
                        onTap: () => context.go(AppRoutes.assetDashboardScreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Total Liabilities',
                        value: _fmt(totalLiabilities),
                        icon: 'credit_score',
                        color: const Color(0xFFEF4444),
                        subtitle: 'Loans & obligations',
                        trend: totalLiabilities > 0 ? 'down' : 'neutral',
                        onTap: () => context.go(AppRoutes.loanDashboardScreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Monthly Income',
                        value: _fmt(income),
                        icon: 'trending_up',
                        color: const Color(0xFF10B981),
                        subtitle: 'This month',
                        trend: 'up',
                        onTap: () =>
                            context.go(AppRoutes.financeDashboardScreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Monthly Expenses',
                        value: _fmt(expenses),
                        icon: 'trending_down',
                        color: const Color(0xFFF59E0B),
                        subtitle: 'This month',
                        trend: 'neutral',
                        onTap: () =>
                            context.go(AppRoutes.transactionHistoryScreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Net Profit',
                        value: _fmt(netProfit),
                        icon: netProfit >= 0
                            ? 'arrow_upward'
                            : 'arrow_downward',
                        color: netProfit >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        subtitle: '${profitMargin.toStringAsFixed(1)}% margin',
                        trend: netProfit >= 0 ? 'up' : 'down',
                        onTap: () =>
                            context.go(AppRoutes.financeDashboardScreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Savings',
                        value: _fmt(savings),
                        icon: 'savings',
                        color: const Color(0xFF06B6D4),
                        subtitle: 'Total saved',
                        trend: 'up',
                        onTap: () => context.go(AppRoutes.financialGoalsScreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Investments',
                        value: _fmt(investments),
                        icon: 'show_chart',
                        color: const Color(0xFF6366F1),
                        subtitle: 'Portfolio value',
                        trend: 'up',
                        onTap: () =>
                            context.go(AppRoutes.investmentDashboardScreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExecKpiCardWidget(
                        title: 'Businesses',
                        value: _fmt(bizValue),
                        icon: 'business_center',
                        color: const Color(0xFFEC4899),
                        subtitle: 'Combined value',
                        trend: 'up',
                        onTap: () =>
                            context.go(AppRoutes.businessDashboardScreen),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Financial Health Section
        SliverToBoxAdapter(
          child: _sectionHeader(
            context,
            'Financial Health',
            'health_and_safety',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExecFinancialHealthWidget(kpiData: _kpiData),
          ),
        ),

        // Charts Section
        SliverToBoxAdapter(
          child: _sectionHeader(context, 'Financial Intelligence', 'analytics'),
        ),
        SliverToBoxAdapter(
          child: ExecChartSectionWidget(
            period: _selectedPeriod,
            analyticsData: _analyticsData,
          ),
        ),

        // AI Daily Briefing
        SliverToBoxAdapter(
          child: _sectionHeader(context, 'AI Executive Briefing', 'psychology'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExecAiBriefingWidget(kpiData: _kpiData),
          ),
        ),

        // Notifications
        if (_notifications.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _sectionHeader(
              context,
              'Notifications',
              'notifications_active',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ExecNotificationPanelWidget(notifications: _notifications),
            ),
          ),
        ],

        // Recent Activity
        SliverToBoxAdapter(
          child: _sectionHeader(
            context,
            'Recent Financial Activity',
            'history',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExecRecentActivityWidget(transactions: _recentActivity),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: _sectionHeader(context, 'Quick Actions', 'flash_on'),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ExecQuickActionsWidget(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _heroStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: AppTheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
