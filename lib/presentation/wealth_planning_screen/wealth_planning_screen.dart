import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../services/wealth_intelligence_service.dart';
import '../../widgets/cna_shared_components.dart';
import '../../widgets/interactive_drill_down_graph.dart';

class WealthPlanningScreen extends StatefulWidget {
  const WealthPlanningScreen({super.key});

  @override
  State<WealthPlanningScreen> createState() => _WealthPlanningScreenState();
}

class _WealthPlanningScreenState extends State<WealthPlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = WealthIntelligenceService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _position = {};
  List<Map<String, dynamic>> _projections = [];
  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _risks = [];
  List<Map<String, dynamic>> _scenarios = [];
  Map<String, dynamic> _cashFlowGraph = {};
  Map<String, dynamic> _netWorthGraph = {};
  bool _graphLoading = false;
  String _graphPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getLiveFinancialPosition(),
        _service.getWealthProjections(),
        _service.getGoalProgress(),
        _service.generateRecommendations(),
        _service.getRiskFactors(),
        _service.compareScenarios(),
        _service.getGraphData(graphType: 'cash_flow', period: _graphPeriod),
        _service.getGraphData(graphType: 'net_worth', period: _graphPeriod),
      ]);

      if (mounted) {
        setState(() {
          _position = results[0] as Map<String, dynamic>;
          _projections = results[1] as List<Map<String, dynamic>>;
          _goals = results[2] as List<Map<String, dynamic>>;
          _recommendations = results[3] as List<Map<String, dynamic>>;
          _risks = results[4] as List<Map<String, dynamic>>;
          _scenarios = results[5] as List<Map<String, dynamic>>;
          _cashFlowGraph = results[6] as Map<String, dynamic>;
          _netWorthGraph = results[7] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reloadGraphs(String period) async {
    setState(() {
      _graphPeriod = period;
      _graphLoading = true;
    });
    try {
      final results = await Future.wait([
        _service.getGraphData(graphType: 'cash_flow', period: period),
        _service.getGraphData(graphType: 'net_worth', period: period),
      ]);
      if (mounted) {
        setState(() {
          _cashFlowGraph = results[0];
          _netWorthGraph = results[1];
          _graphLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _graphLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final textColor = isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const CustomIconWidget(iconName: 'arrow_back', size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Wealth Planning Intelligence',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.primary,
              size: 22,
            ),
            onPressed: _loadAll,
            tooltip: 'Refresh live data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: mutedColor,
          indicatorColor: AppTheme.primary,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Projections'),
            Tab(text: 'Goals'),
            Tab(text: 'Insights'),
            Tab(text: 'Graphs'),
          ],
        ),
      ),
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading live financial data...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isDark, surface, textColor, mutedColor),
                _buildProjectionsTab(isDark, surface, textColor, mutedColor),
                _buildGoalsTab(isDark, surface, textColor, mutedColor),
                _buildInsightsTab(isDark, surface, textColor, mutedColor),
                _buildGraphsTab(isDark, surface, textColor, mutedColor),
              ],
            ),
    );
  }

  // ─── OVERVIEW TAB ─────────────────────────────────────────────────────────

  Widget _buildOverviewTab(
    bool isDark,
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    if (_position.isEmpty) {
      return _buildNoDataState(mutedColor);
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDataSourceBadge(mutedColor),
          const SizedBox(height: 12),
          _buildNetWorthCard(surface, textColor, mutedColor),
          const SizedBox(height: 12),
          _buildFinancialHealthGrid(surface, textColor, mutedColor),
          const SizedBox(height: 12),
          _buildRiskSummary(surface, textColor, mutedColor),
          const SizedBox(height: 12),
          _buildScenarioComparison(surface, textColor, mutedColor),
        ],
      ),
    );
  }

  Widget _buildDataSourceBadge(Color mutedColor) {
    final sources = _position['data_sources'] as Map<String, dynamic>? ?? {};
    final activeCount = sources.values.where((v) => v == true).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.successContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CustomIconWidget(
            iconName: 'verified',
            color: AppTheme.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Live data from $activeCount financial modules — no demo data',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard(Color surface, Color textColor, Color mutedColor) {
    final netWorth = ((_position['net_worth'] as num?)?.toDouble() ?? 0);
    final assets = ((_position['total_assets'] as num?)?.toDouble() ?? 0);
    final liabilities =
        ((_position['total_liabilities'] as num?)?.toDouble() ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Net Worth',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(netWorth),
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _netWorthMetric(
                  'Total Assets',
                  _fmt(assets),
                  Colors.white,
                ),
              ),
              Expanded(
                child: _netWorthMetric(
                  'Total Liabilities',
                  _fmt(liabilities),
                  Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _netWorthMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHealthGrid(
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    final savingsRate = ((_position['savings_rate'] as num?)?.toDouble() ?? 0);
    final emergencyMonths =
        ((_position['emergency_fund_months'] as num?)?.toDouble() ?? 0);
    final debtToIncome =
        ((_position['debt_to_income_ratio'] as num?)?.toDouble() ?? 0);
    final monthlySavings =
        ((_position['monthly_savings'] as num?)?.toDouble() ?? 0);

    final metrics = [
      {
        'label': 'Savings Rate',
        'value': '${savingsRate.toStringAsFixed(1)}%',
        'icon': 'savings',
        'color': savingsRate >= 20
            ? AppTheme.success
            : savingsRate >= 10
            ? AppTheme.warning
            : AppTheme.danger,
        'status': savingsRate >= 20
            ? 'Excellent'
            : savingsRate >= 10
            ? 'Fair'
            : 'Low',
      },
      {
        'label': 'Emergency Fund',
        'value': '${emergencyMonths.toStringAsFixed(1)} mo',
        'icon': 'shield',
        'color': emergencyMonths >= 3
            ? AppTheme.success
            : emergencyMonths >= 1
            ? AppTheme.warning
            : AppTheme.danger,
        'status': emergencyMonths >= 3
            ? 'Secure'
            : emergencyMonths >= 1
            ? 'Building'
            : 'Critical',
      },
      {
        'label': 'Debt/Income',
        'value': '${debtToIncome.toStringAsFixed(1)}%',
        'icon': 'account_balance',
        'color': debtToIncome <= 30
            ? AppTheme.success
            : debtToIncome <= 50
            ? AppTheme.warning
            : AppTheme.danger,
        'status': debtToIncome <= 30
            ? 'Healthy'
            : debtToIncome <= 50
            ? 'Moderate'
            : 'High',
      },
      {
        'label': 'Monthly Savings',
        'value': _fmt(monthlySavings),
        'icon': 'trending_up',
        'color': monthlySavings > 0 ? AppTheme.success : AppTheme.danger,
        'status': monthlySavings > 0 ? 'Positive' : 'Negative',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) {
        final m = metrics[i];
        final color = m['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: m['icon'] as String,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      m['label'] as String,
                      style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                m['value'] as String,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  m['status'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskSummary(Color surface, Color textColor, Color mutedColor) {
    if (_risks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No critical risk factors detected based on your current financial data.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.success),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomIconWidget(
                iconName: 'warning',
                color: AppTheme.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Risk Factors (${_risks.length})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._risks.map((r) => _buildRiskItem(r, mutedColor)),
        ],
      ),
    );
  }

  Widget _buildRiskItem(Map<String, dynamic> risk, Color mutedColor) {
    final severity = risk['severity'] as String? ?? 'medium';
    final color = severity == 'high' ? AppTheme.danger : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  risk['title'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            risk['description'] as String? ?? '',
            style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
          ),
          const SizedBox(height: 4),
          Text(
            '→ ${risk['action']}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioComparison(
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    if (_scenarios.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scenario Comparison',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on your actual financial data',
            style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
          ),
          const SizedBox(height: 12),
          ..._scenarios.map(
            (s) => _buildScenarioItem(s, textColor, mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioItem(
    Map<String, dynamic> s,
    Color textColor,
    Color mutedColor,
  ) {
    final isFirst = s['id'] == 'current';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFirst ? AppTheme.primaryContainer : AppTheme.neutralContainer,
        borderRadius: BorderRadius.circular(10),
        border: isFirst
            ? Border.all(color: AppTheme.primary.withAlpha(77))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s['name'] as String? ?? '',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isFirst ? AppTheme.primary : textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s['description'] as String? ?? '',
            style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _scenarioMetric(
                  '5-Year',
                  _fmt((s['net_worth_5y'] as num?)?.toDouble() ?? 0),
                  isFirst,
                ),
              ),
              Expanded(
                child: _scenarioMetric(
                  '10-Year',
                  _fmt((s['net_worth_10y'] as num?)?.toDouble() ?? 0),
                  isFirst,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scenarioMetric(String label, String value, bool isPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedLight),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isPrimary ? AppTheme.primary : AppTheme.onSurfaceLight,
          ),
        ),
      ],
    );
  }

  // ─── PROJECTIONS TAB ──────────────────────────────────────────────────────

  Widget _buildProjectionsTab(
    bool isDark,
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    if (_projections.isEmpty) return _buildNoDataState(mutedColor);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.infoContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Projections are calculated using your actual savings rate, investment returns, and current net worth — not templates.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.info),
          ),
        ),
        const SizedBox(height: 16),
        ..._projections.map(
          (p) => _buildProjectionCard(p, surface, textColor, mutedColor),
        ),
      ],
    );
  }

  Widget _buildProjectionCard(
    Map<String, dynamic> p,
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    final year = p['year'] as int? ?? 0;
    final netWorth = (p['projected_net_worth'] as num?)?.toDouble() ?? 0;
    final investments = (p['projected_investments'] as num?)?.toDouble() ?? 0;
    final savings = (p['cumulative_savings'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Y$year',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['year_label'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Net Worth: ${_fmt(netWorth)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Investments: ${_fmt(investments)} · Savings: ${_fmt(savings)}',
                  style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── GOALS TAB ────────────────────────────────────────────────────────────

  Widget _buildGoalsTab(
    bool isDark,
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomIconWidget(
              iconName: 'flag',
              color: AppTheme.mutedLight,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No financial goals set',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add goals in the Financial Goals module',
              style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _goals
          .map((g) => _buildGoalCard(g, surface, textColor, mutedColor))
          .toList(),
    );
  }

  Widget _buildGoalCard(
    Map<String, dynamic> g,
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    final progress = (g['progress_percent'] as num?)?.toDouble() ?? 0;
    final status = g['completion_status'] as String? ?? 'unknown';
    final statusColor = status == 'on_track'
        ? AppTheme.success
        : status == 'delayed'
        ? AppTheme.danger
        : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  g['name'] as String? ?? 'Goal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status == 'on_track'
                      ? 'On Track'
                      : status == 'delayed'
                      ? 'Delayed'
                      : 'Tracking',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt((g['current_amount'] as num?)?.toDouble() ?? 0),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                'of ${_fmt((g['target_amount'] as num?)?.toDouble() ?? 0)}',
                style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.outlineLight,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.toStringAsFixed(1)}% complete',
                style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
              ),
              if (g['estimated_completion'] != null)
                Text(
                  'Est: ${g['estimated_completion']}',
                  style: GoogleFonts.inter(fontSize: 11, color: statusColor),
                ),
            ],
          ),
          if (g['target_date'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Target: ${g['target_date']}',
              style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
            ),
          ],
        ],
      ),
    );
  }

  // ─── INSIGHTS TAB ─────────────────────────────────────────────────────────

  Widget _buildInsightsTab(
    bool isDark,
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    if (_recommendations.isEmpty) {
      return Center(
        child: Text(
          'Add financial data to generate insights',
          style: GoogleFonts.inter(fontSize: 14, color: mutedColor),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'AI Recommendations',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Every recommendation is based on your actual financial data',
          style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
        ),
        const SizedBox(height: 16),
        ..._recommendations.map(
          (r) => _buildRecommendationCard(r, surface, textColor, mutedColor),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    Map<String, dynamic> r,
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    final priority = r['priority'] as String? ?? 'normal';
    final confidence = (r['confidence'] as num?)?.toDouble() ?? 0;
    final color = priority == 'high'
        ? AppTheme.danger
        : priority == 'low'
        ? AppTheme.success
        : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(51)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r['title'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                '${confidence.toStringAsFixed(0)}% confidence',
                style: GoogleFonts.inter(fontSize: 10, color: mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r['description'] as String? ?? '',
            style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
          ),
          const SizedBox(height: 10),
          _infoRow('Data Used', r['data_used'] as String? ?? '', mutedColor),
          _infoRow('Reasoning', r['reasoning'] as String? ?? '', mutedColor),
          _infoRow(
            'Expected Benefit',
            r['expected_benefit'] as String? ?? '',
            AppTheme.success,
          ),
          _infoRow(
            'Potential Risk',
            r['potential_risk'] as String? ?? '',
            AppTheme.warning,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'arrow_forward',
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r['action'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.mutedLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 11, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  // ─── GRAPHS TAB ───────────────────────────────────────────────────────────

  Widget _buildGraphsTab(
    bool isDark,
    Color surface,
    Color textColor,
    Color mutedColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Interactive Financial Graphs',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap any bar or point to see the underlying transactions',
          style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
        ),
        const SizedBox(height: 16),
        InteractiveDrillDownGraph(
          graphType: 'cash_flow',
          graphData: _cashFlowGraph,
          title: 'Cash Flow — Income vs Expense',
          isLoading: _graphLoading,
          onPeriodChanged: _reloadGraphs,
          onDrillDown: (data) => _showDrillDownSheet(data),
        ),
        const SizedBox(height: 16),
        InteractiveDrillDownGraph(
          graphType: 'net_worth',
          graphData: _netWorthGraph,
          title: 'Net Worth Trend',
          isLoading: _graphLoading,
          onPeriodChanged: _reloadGraphs,
          onDrillDown: (data) => _showDrillDownSheet(data),
        ),
        const SizedBox(height: 16),
        _buildLegend(mutedColor),
      ],
    );
  }

  Widget _buildLegend(Color mutedColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutralContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Graph Legend',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendItem('Income', AppTheme.successLight),
              const SizedBox(width: 16),
              _legendItem('Expense', AppTheme.dangerLight),
              const SizedBox(width: 16),
              _legendItem('Net Worth', AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedLight),
        ),
      ],
    );
  }

  void _showDrillDownSheet(Map<String, dynamic> data) {
    final transactions = data['transactions'] as List? ?? [];
    if (transactions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
        final textColor = isDark
            ? AppTheme.onSurfaceDark
            : AppTheme.onSurfaceLight;
        final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Transactions: ${data['label'] ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${transactions.length} records',
                      style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: AppTheme.outlineLight, height: 1),
                  itemBuilder: (ctx, i) {
                    final t = transactions[i] as Map;
                    final isExpense = t['type'] == 'expense';
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      title: Text(
                        t['description'] as String? ??
                            t['category'] as String? ??
                            'Transaction',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${t['date'] ?? ''} · ${t['category'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                      trailing: Text(
                        _fmt((t['amount'] as num?)?.toDouble() ?? 0),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isExpense ? AppTheme.danger : AppTheme.success,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoDataState(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomIconWidget(
            iconName: 'account_balance_wallet',
            color: AppTheme.mutedLight,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'No financial data yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add transactions, assets, or investments\nto generate your wealth plan',
            style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _fmt(double value) {
    if (value >= 1000000000) {
      return 'TSh ${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return 'TSh ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'TSh ${(value / 1000).toStringAsFixed(0)}K';
    return 'TSh ${value.toStringAsFixed(0)}';
  }
}
