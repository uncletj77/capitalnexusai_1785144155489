import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/enterprise_reconciliation_service.dart';
import '../../services/finance_service.dart';
import '../../services/master_asset_registry_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;

  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _netWorth = 0;
  double _totalAssets = 0;
  double _totalLiabilities = 0;
  double _savingsRate = 0;
  int _healthScore = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _accounts = [];
  List<FlSpot> _cashFlowSpots = [];
  bool _isReconciling = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        FinanceService.instance.getCashFlowSummary(
          startDate: monthStart,
          endDate: now,
        ),
        FinanceService.instance.getNetWorth(),
        FinanceService.instance.getRecentTransactions(limit: 5),
        FinanceService.instance.getAccountsWithBalances(),
        FinanceService.instance.getMonthlyCashFlow(months: 6),
      ]);

      final cf = results[0] as Map<String, double>;
      final nw = results[1] as Map<String, double>;
      final recentTx = results[2] as List<Map<String, dynamic>>;
      final accounts = results[3] as List<Map<String, dynamic>>;
      final monthlyCf = results[4] as List<Map<String, dynamic>>;

      final income = cf['income'] ?? 0;
      final expenses = cf['expenses'] ?? 0;

      List<FlSpot> spots = [];
      if (monthlyCf.isNotEmpty) {
        for (int i = 0; i < monthlyCf.length; i++) {
          final net = (monthlyCf[i]['net_cash_flow'] as num?)?.toDouble() ?? 0;
          spots.add(FlSpot(i.toDouble(), net / 1000000));
        }
      }

      final sr = income > 0 ? ((income - expenses) / income * 100) : 0.0;
      final score = _computeHealthScore(
        income,
        expenses,
        nw['liabilities'] ?? 0,
        nw['netWorth'] ?? 0,
      );

      setState(() {
        _totalIncome = income;
        _totalExpenses = expenses;
        _netWorth = nw['netWorth'] ?? 0;
        _totalAssets = nw['assets'] ?? 0;
        _totalLiabilities = nw['liabilities'] ?? 0;
        _savingsRate = sr;
        _healthScore = score;
        _recentTransactions = recentTx;
        _accounts = accounts;
        _cashFlowSpots = spots.isNotEmpty ? spots : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runReconciliation() async {
    setState(() => _isReconciling = true);
    await EnterpriseReconciliationService.instance.runFullReconciliation();
    await MasterAssetRegistryService.instance.autoRegisterAllAssets();
    if (mounted) {
      setState(() => _isReconciling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Financial data reconciled and synchronized'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  List<FlSpot> _defaultSpots() => [];

  int _computeHealthScore(
    double income,
    double expenses,
    double liabilities,
    double netWorth,
  ) {
    int score = 50;
    if (income > 0) {
      final ratio = expenses / income;
      if (ratio < 0.5) {
        score += 20;
      } else if (ratio < 0.7)
        score += 10;
      else if (ratio > 0.9)
        score -= 10;
    }
    if (netWorth > 0) score += 15;
    if (liabilities < netWorth * 0.3) score += 15;
    return score.clamp(0, 100);
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return 'TSh ${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  Color _healthColor() {
    if (_healthScore >= 75) return AppTheme.success;
    if (_healthScore >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  String _healthLabel() {
    if (_healthScore >= 75) return 'Excellent';
    if (_healthScore >= 50) return 'Good';
    if (_healthScore >= 30) return 'Fair';
    return 'Needs Attention';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty =
        !_isLoading &&
        _totalIncome == 0 &&
        _totalExpenses == 0 &&
        _netWorth == 0 &&
        _accounts.isEmpty &&
        _recentTransactions.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const CnaLoadingState(message: 'Loading financial data...')
            : RefreshIndicator(
                onRefresh: _loadData,
                child: isEmpty
                    ? _buildOnboarding(theme)
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _buildHeader(theme)),
                          SliverToBoxAdapter(child: _buildNetWorthCard(theme)),
                          SliverToBoxAdapter(
                            child: _buildFuturePlanningBanner(theme),
                          ),
                          SliverToBoxAdapter(child: _buildCashFlowCard(theme)),
                          SliverToBoxAdapter(child: _buildHealthScore(theme)),
                          SliverToBoxAdapter(
                            child: _buildAccountsSummary(theme),
                          ),
                          SliverToBoxAdapter(child: _buildQuickModules(theme)),
                          SliverToBoxAdapter(
                            child: _buildRecentTransactions(theme),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ),
              ),
      ),
      floatingActionButton: isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.transactionHistoryScreen),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance Center',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.onSurfaceLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your financial intelligence hub',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isReconciling ? null : _runReconciliation,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Center(
                child: _isReconciling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : const CustomIconWidget(
                        iconName: 'sync',
                        color: AppTheme.primary,
                        size: 20,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'refresh',
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturePlanningBanner(ThemeData theme) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.futurePlanningScreen),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A3344), Color(0xFF1A5F7A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.timeline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash Flow Intelligence Engine',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Forecast, simulate & plan your financial future',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5F7A), Color(0xFF0A3344)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Worth',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
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
                  child: Row(
                    children: [
                      const CustomIconWidget(
                        iconName: 'trending_up',
                        color: Color(0xFF4ADE80),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+2.4%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatAmount(_netWorth),
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNWMetric(
                    theme,
                    'Total Assets',
                    _totalAssets,
                    const Color(0xFF4ADE80),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: _buildNWMetric(
                    theme,
                    'Liabilities',
                    _totalLiabilities,
                    const Color(0xFFFCA5A5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNWMetric(
    ThemeData theme,
    String label,
    double value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAmount(value),
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(ThemeData theme) {
    final netFlow = _totalIncome - _totalExpenses;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash Flow',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'This Month',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFlowTile(
                  theme,
                  'Income',
                  _totalIncome,
                  AppTheme.success,
                  'arrow_downward',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFlowTile(
                  theme,
                  'Expenses',
                  _totalExpenses,
                  AppTheme.error,
                  'arrow_upward',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFlowTile(
                  theme,
                  'Net Flow',
                  netFlow,
                  netFlow >= 0 ? AppTheme.success : AppTheme.error,
                  'account_balance_wallet',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings Rate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
              Text(
                '${_savingsRate.toStringAsFixed(1)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_savingsRate / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.outlineLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                _savingsRate >= 20 ? AppTheme.success : AppTheme.warning,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _cashFlowSpots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withAlpha(30),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Net worth trend (6 months)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowTile(
    ThemeData theme,
    String label,
    double value,
    Color color,
    String icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _formatAmount(value.abs()),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore(ThemeData theme) {
    final color = _healthColor();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Health Score',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _healthScore / 100,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.outlineLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '$_healthScore',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _healthLabel(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _healthScore >= 75
                          ? 'Your finances are in great shape. Keep up the excellent work!'
                          : _healthScore >= 50
                          ? 'Good progress. Focus on reducing expenses and growing savings.'
                          : 'Review your spending patterns and increase your savings rate.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHealthMetric(theme, 'Income Stability', 85, AppTheme.success),
          const SizedBox(height: 8),
          _buildHealthMetric(
            theme,
            'Expense Control',
            _totalIncome > 0
                ? (100 - (_totalExpenses / _totalIncome * 100)).clamp(0, 100)
                : 50,
            AppTheme.warning,
          ),
          const SizedBox(height: 8),
          _buildHealthMetric(
            theme,
            'Savings Ability',
            _savingsRate.clamp(0, 100),
            AppTheme.primary,
          ),
          const SizedBox(height: 8),
          _buildHealthMetric(theme, 'Asset Growth', 72, AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(
    ThemeData theme,
    String label,
    double value,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.outlineLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${value.toInt()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSummary(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finance Tools',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  theme,
                  'Accounts',
                  'account_balance',
                  AppTheme.primary,
                  AppRoutes.accountsScreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolCard(
                  theme,
                  'Budget',
                  'pie_chart',
                  const Color(0xFF8B5CF6),
                  AppRoutes.budgetPlannerScreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolCard(
                  theme,
                  'Net Worth',
                  'trending_up',
                  AppTheme.success,
                  AppRoutes.netWorthScreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolCard(
                  theme,
                  'Goals',
                  'flag',
                  AppTheme.warning,
                  AppRoutes.financialGoalsScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  theme,
                  'Loans',
                  'account_balance_wallet',
                  const Color(0xFF1A5F7A),
                  AppRoutes.loanDashboardScreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolCard(
                  theme,
                  'AI Advisor',
                  'psychology',
                  const Color(0xFF8B5CF6),
                  AppRoutes.aiDebtAdvisorScreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolCard(
                  theme,
                  'Simulator',
                  'calculate',
                  AppTheme.appreciatingColor,
                  AppRoutes.loanSimulatorScreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolCard(
                  theme,
                  'Calendar',
                  'calendar_month',
                  AppTheme.depreciatingColor,
                  AppRoutes.loanRepaymentCalendarScreen,
                ),
              ),
            ],
          ),
          if (_accounts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accounts',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.accountsScreen),
                  child: Text(
                    'View All',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Total: ${_formatAmount(_accounts.fold<double>(0, (s, a) => s + (a['balance'] as num).toDouble()))}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedLight,
              ),
            ),
            const SizedBox(height: 12),
            ..._accounts.take(3).map((acc) => _buildAccountTile(theme, acc)),
          ],
        ],
      ),
    );
  }

  Widget _buildToolCard(
    ThemeData theme,
    String label,
    String icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            CustomIconWidget(iconName: icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(ThemeData theme, Map<String, dynamic> acc) {
    final color = Color(
      int.tryParse(
            (acc['color'] as String? ?? '#1A5F7A').replaceFirst('#', '0xFF'),
          ) ??
          0xFF1A5F7A,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: acc['icon'] as String? ?? 'account_balance',
                color: color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc['account_name'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  acc['provider'] as String? ??
                      acc['account_category'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatAmount((acc['balance'] as num).toDouble()),
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme) {
    if (_recentTransactions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.transactionHistoryScreen),
                child: Text(
                  'View All',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recentTransactions.map((tx) => _buildTxTile(theme, tx)),
        ],
      ),
    );
  }

  Widget _buildTxTile(ThemeData theme, Map<String, dynamic> tx) {
    final isIncome = tx['transaction_type'] == 'income';
    final color = isIncome ? AppTheme.success : AppTheme.error;
    final amount = (tx['amount'] as num).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: isIncome ? 'arrow_downward' : 'arrow_upward',
                color: color,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] as String? ?? 'Transaction',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  tx['category'] as String? ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboarding(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'account_balance_wallet',
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Finance Center',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your unified financial intelligence hub. Start by adding your accounts, income, and expenses to unlock real-time insights.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildOnboardingAction(
            theme,
            'Add Your First Account',
            'Set up cash, bank, or mobile money accounts',
            'account_balance',
            AppTheme.primary,
            () => context.push(AppRoutes.accountsScreen),
          ),
          const SizedBox(height: 12),
          _buildOnboardingAction(
            theme,
            'Record Income',
            'Log salary, business revenue, or other income',
            'arrow_downward',
            AppTheme.success,
            () => context.push(AppRoutes.transactionHistoryScreen),
          ),
          const SizedBox(height: 12),
          _buildOnboardingAction(
            theme,
            'Track Expenses',
            'Record your spending to understand cash flow',
            'arrow_upward',
            AppTheme.error,
            () => context.push(AppRoutes.transactionHistoryScreen),
          ),
          const SizedBox(height: 12),
          _buildOnboardingAction(
            theme,
            'Set Financial Goals',
            'Define savings targets and track progress',
            'flag',
            AppTheme.warning,
            () => context.push(AppRoutes.financialGoalsScreen),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOnboardingAction(
    ThemeData theme,
    String title,
    String subtitle,
    String icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: CustomIconWidget(iconName: icon, color: color, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
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
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickModules(ThemeData theme) {
    final modules = [
      {
        'label': 'Savings',
        'icon': 'savings',
        'route': AppRoutes.savingsCentreScreen,
        'color': AppTheme.success,
      },
      {
        'label': 'Closing',
        'icon': 'assessment',
        'route': AppRoutes.financialClosingScreen,
        'color': AppTheme.primary,
      },
      {
        'label': 'Asset Registry',
        'icon': 'inventory_2',
        'route': AppRoutes.masterAssetRegistryScreen,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'label': 'Goals',
        'icon': 'flag',
        'route': AppRoutes.financialGoalsScreen,
        'color': AppTheme.warning,
      },
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: modules.map((m) {
              final color = m['color'] as Color;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.push(m['route'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: color.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withAlpha(40)),
                    ),
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: m['icon'] as String,
                          color: color,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m['label'] as String,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
