import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/cna_shared_components.dart';
import './widgets/ai_insight_card_widget.dart';
import './widgets/analytics_chart_widget.dart';
import './widgets/kpi_card_widget.dart';
import './widgets/performance_score_card_widget.dart';
import './widgets/report_viewer_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _analytics = AnalyticsService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _performanceScores = [];
  List<Map<String, dynamic>> _aiInsights = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _monthlyTrends = [];
  Map<String, dynamic> _assetData = {};
  Map<String, double> _investmentData = {};
  bool _isGeneratingReport = false;

  final List<String> _tabs = [
    'Executive',
    'Personal',
    'Business',
    'Assets',
    'Investments',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _analytics.getDashboardData(),
        _analytics.getPerformanceScores(),
        _analytics.getAiInsights(),
        _analytics.getReports(),
        _analytics.getMonthlyTrends(),
        _analytics.calculateAssetPerformance(),
        _analytics.calculateInvestmentReturn(),
      ]);

      if (mounted) {
        setState(() {
          _dashboardData = results[0] as Map<String, dynamic>;
          _performanceScores = results[1] as List<Map<String, dynamic>>;
          _aiInsights = results[2] as List<Map<String, dynamic>>;
          _reports = results[3] as List<Map<String, dynamic>>;
          _monthlyTrends = results[4] as List<Map<String, dynamic>>;
          _assetData = results[5] as Map<String, dynamic>;
          _investmentData = results[6] as Map<String, double>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return 'TSh ${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return 'TSh ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'TSh ${(value / 1000).toStringAsFixed(0)}K';
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  Future<void> _generateReport(String type) async {
    setState(() => _isGeneratingReport = true);
    try {
      await _analytics.generateReport(type);
      final reports = await _analytics.getReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isGeneratingReport = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Analytics Engine',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: theme.colorScheme.primary,
              size: 22,
            ),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading analytics...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExecutiveTab(),
                _buildPersonalTab(),
                _buildBusinessTab(),
                _buildAssetsTab(),
                _buildInvestmentsTab(),
              ],
            ),
    );
  }

  // ─── EXECUTIVE COMMAND CENTER ────────────────────────────────────────────
  Widget _buildExecutiveTab() {
    final nw = _dashboardData['net_worth'] as Map<String, double>? ?? {};
    final cf = _dashboardData['cash_flow'] as Map<String, double>? ?? {};
    final prof = _dashboardData['profitability'] as Map<String, double>? ?? {};
    final growthRate = (_dashboardData['growth_rate'] as double?) ?? 0;
    final debtRatio = (_dashboardData['debt_ratio'] as double?) ?? 0;

    final overallScore = _performanceScores.isNotEmpty
        ? (_performanceScores.fold(0, (s, p) => s + (p['score'] as int? ?? 0)) /
                  _performanceScores.length)
              .round()
        : 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall health banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Health Score',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$overallScore / 100',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _overallHealthLabel(overallScore),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withAlpha(220),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: overallScore / 100,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withAlpha(50),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        Text(
                          '$overallScore',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // KPI Grid
            Text('Key Performance Indicators', style: _sectionTitle()),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                KpiCardWidget(
                  title: 'Net Worth',
                  value: _formatCurrency(nw['net_worth'] ?? 250000000),
                  iconName: 'account_balance_wallet',
                  color: AppTheme.primary,
                  trendPercent: growthRate,
                  subtitle: 'vs last month',
                  status: 'positive',
                ),
                KpiCardWidget(
                  title: 'Monthly Cash Flow',
                  value: _formatCurrency(cf['net'] ?? 4000000),
                  iconName: 'swap_horiz',
                  color: AppTheme.success,
                  trendPercent: 5.2,
                  subtitle: 'net this month',
                  status: (cf['net'] ?? 0) >= 0 ? 'positive' : 'negative',
                ),
                KpiCardWidget(
                  title: 'Business Profit',
                  value: _formatCurrency(prof['profit'] ?? 6000000),
                  iconName: 'business_center',
                  color: const Color(0xFF059669),
                  trendPercent: 15.0,
                  subtitle: 'this month',
                  status: 'positive',
                ),
                KpiCardWidget(
                  title: 'Debt Ratio',
                  value: '${(debtRatio).toStringAsFixed(1)}%',
                  iconName: 'account_balance',
                  color: debtRatio > 50 ? AppTheme.error : AppTheme.warning,
                  subtitle: 'of total assets',
                  status: debtRatio < 30
                      ? 'positive'
                      : debtRatio < 50
                      ? 'neutral'
                      : 'negative',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Performance Scores
            Text('Performance Scores', style: _sectionTitle()),
            const SizedBox(height: 12),
            ..._performanceScores.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PerformanceScoreCardWidget(
                  category: s['category'] as String? ?? '',
                  score: s['score'] as int? ?? 0,
                  explanation: s['explanation'] as String? ?? '',
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Critical Alerts & Opportunities
            Text('AI Alerts & Opportunities', style: _sectionTitle()),
            const SizedBox(height: 12),
            ..._aiInsights
                .take(4)
                .map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AiInsightCardWidget(
                      insightType:
                          insight['insight_type'] as String? ?? 'trend',
                      message: insight['message'] as String? ?? '',
                      severity: insight['severity'] as String? ?? 'neutral',
                      relatedModule: insight['related_module'] as String?,
                    ),
                  ),
                ),
            const SizedBox(height: 20),

            // Reports
            ReportViewerWidget(
              reports: _reports,
              isLoading: _isGeneratingReport,
              onGenerateReport: () => _showReportDialog(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── PERSONAL FINANCIAL DASHBOARD ────────────────────────────────────────
  Widget _buildPersonalTab() {
    final nw = _dashboardData['net_worth'] as Map<String, double>? ?? {};
    final cf = _dashboardData['cash_flow'] as Map<String, double>? ?? {};
    final debtRatio = (_dashboardData['debt_ratio'] as double?) ?? 0;
    final growthRate = (_dashboardData['growth_rate'] as double?) ?? 0;

    final healthScore =
        _performanceScores
            .where((s) => s['category'] == 'financial_health')
            .map((s) => s['score'] as int? ?? 0)
            .firstOrNull ??
        85;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wealth Overview
          Text('Wealth Overview', style: _sectionTitle()),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              KpiCardWidget(
                title: 'Total Assets',
                value: _formatCurrency(nw['total_assets'] ?? 300000000),
                iconName: 'real_estate_agent',
                color: AppTheme.primary,
                status: 'positive',
              ),
              KpiCardWidget(
                title: 'Total Liabilities',
                value: _formatCurrency(nw['total_liabilities'] ?? 50000000),
                iconName: 'account_balance',
                color: AppTheme.error,
                status: 'neutral',
              ),
              KpiCardWidget(
                title: 'Net Worth',
                value: _formatCurrency(nw['net_worth'] ?? 250000000),
                iconName: 'account_balance_wallet',
                color: AppTheme.success,
                trendPercent: growthRate,
                status: 'positive',
              ),
              KpiCardWidget(
                title: 'Cash Available',
                value: _formatCurrency(cf['inflow'] ?? 8000000),
                iconName: 'payments',
                color: const Color(0xFF2D9CDB),
                subtitle: 'monthly inflow',
                status: 'positive',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Income Analysis
          Text('Income Analysis', style: _sectionTitle()),
          const SizedBox(height: 12),
          AnalyticsChartWidget(
            title: 'Monthly Income vs Expenses',
            data: _monthlyTrends
                .map(
                  (m) => {
                    'month': m['month'],
                    'income': m['income'],
                    'secondary': m['expenses'],
                  },
                )
                .toList(),
            chartType: AnalyticsChartType.bar,
            primaryLabel: 'Income',
            secondaryLabel: 'Expenses',
            primaryColor: AppTheme.success,
            secondaryColor: AppTheme.error,
          ),
          const SizedBox(height: 20),

          // Cash Flow Trend
          Text('Cash Flow Trend', style: _sectionTitle()),
          const SizedBox(height: 12),
          AnalyticsChartWidget(
            title: 'Net Cash Flow (6 Months)',
            data: _monthlyTrends
                .map((m) => {'month': m['month'], 'value': m['net']})
                .toList(),
            chartType: AnalyticsChartType.line,
            primaryLabel: 'Net Flow',
            primaryColor: AppTheme.primary,
          ),
          const SizedBox(height: 20),

          // Financial Health Score
          Text('Financial Health Score', style: _sectionTitle()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: healthScore / 100,
                            strokeWidth: 7,
                            backgroundColor: AppTheme.outlineLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _scoreColor(healthScore),
                            ),
                          ),
                          Text(
                            '$healthScore',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _scoreColor(healthScore),
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
                          Text(
                            'Financial Health',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _scoreLabel(healthScore),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _scoreColor(healthScore),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHealthMetricRow('Savings Rate', '50%', AppTheme.success),
                _buildHealthMetricRow(
                  'Debt Ratio',
                  '${debtRatio.toStringAsFixed(1)}%',
                  debtRatio < 30 ? AppTheme.success : AppTheme.warning,
                ),
                _buildHealthMetricRow(
                  'Cash Flow',
                  cf['net'] != null && (cf['net'] ?? 0) > 0
                      ? 'Positive'
                      : 'Negative',
                  (cf['net'] ?? 0) > 0 ? AppTheme.success : AppTheme.error,
                ),
                _buildHealthMetricRow(
                  'Asset Growth',
                  '${growthRate.toStringAsFixed(1)}%',
                  growthRate >= 0 ? AppTheme.success : AppTheme.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── BUSINESS EXECUTIVE DASHBOARD ────────────────────────────────────────
  Widget _buildBusinessTab() {
    final prof = _dashboardData['profitability'] as Map<String, double>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Performance', style: _sectionTitle()),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              KpiCardWidget(
                title: 'Revenue',
                value: _formatCurrency(prof['revenue'] ?? 15000000),
                iconName: 'trending_up',
                color: AppTheme.success,
                trendPercent: 15.0,
                subtitle: 'this month',
                status: 'positive',
              ),
              KpiCardWidget(
                title: 'Expenses',
                value: _formatCurrency(prof['expenses'] ?? 9000000),
                iconName: 'trending_down',
                color: AppTheme.error,
                trendPercent: -3.2,
                subtitle: 'this month',
                status: 'neutral',
              ),
              KpiCardWidget(
                title: 'Net Profit',
                value: _formatCurrency(prof['profit'] ?? 6000000),
                iconName: 'savings',
                color: AppTheme.primary,
                trendPercent: 22.0,
                subtitle: 'this month',
                status: 'positive',
              ),
              KpiCardWidget(
                title: 'Profit Margin',
                value: '${(prof['margin'] ?? 40.0).toStringAsFixed(1)}%',
                iconName: 'percent',
                color: const Color(0xFF8B5CF6),
                subtitle: 'of revenue',
                status: (prof['margin'] ?? 0) > 20 ? 'positive' : 'neutral',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Revenue trend
          Text('Revenue Trend', style: _sectionTitle()),
          const SizedBox(height: 12),
          AnalyticsChartWidget(
            title: 'Monthly Business Revenue',
            data: _monthlyTrends
                .map(
                  (m) => {
                    'month': m['month'],
                    'value': (m['income'] as num).toDouble() * 1.875,
                  },
                )
                .toList(),
            chartType: AnalyticsChartType.line,
            primaryLabel: 'Revenue',
            primaryColor: AppTheme.success,
          ),
          const SizedBox(height: 20),

          // AI Business Summary
          Text('AI Business Intelligence', style: _sectionTitle()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CustomIconWidget(
                      iconName: 'psychology',
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Business Summary',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Revenue increased by 15% this month, driven by transport operations. Operational costs increased at a slower rate of 3.2%, improving overall profitability. Fuel expenses remain the largest variable cost — consider route optimization to further improve margins.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.onSurfaceLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Business health score
          Text('Business Health Score', style: _sectionTitle()),
          const SizedBox(height: 12),
          ..._performanceScores
              .where((s) => s['category'] == 'business_health')
              .map(
                (s) => PerformanceScoreCardWidget(
                  category: s['category'] as String,
                  score: s['score'] as int? ?? 0,
                  explanation: s['explanation'] as String? ?? '',
                ),
              ),
          const SizedBox(height: 20),

          // Business insights
          Text('Business Insights', style: _sectionTitle()),
          const SizedBox(height: 12),
          ..._aiInsights
              .where((i) => i['related_module'] == 'business')
              .map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AiInsightCardWidget(
                    insightType: insight['insight_type'] as String? ?? 'trend',
                    message: insight['message'] as String? ?? '',
                    severity: insight['severity'] as String? ?? 'neutral',
                    relatedModule: insight['related_module'] as String?,
                  ),
                ),
              ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── ASSET ANALYTICS DASHBOARD ───────────────────────────────────────────
  Widget _buildAssetsTab() {
    final totalValue = (_assetData['total_value'] as double?) ?? 300000000;
    final totalIncome = (_assetData['total_income'] as double?) ?? 4500000;
    final productivity = (_assetData['productivity_ratio'] as double?) ?? 18.0;
    final assets =
        (_assetData['assets'] as List<Map<String, dynamic>>?) ?? _demoAssets();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asset Portfolio', style: _sectionTitle()),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              KpiCardWidget(
                title: 'Total Asset Value',
                value: _formatCurrency(totalValue),
                iconName: 'real_estate_agent',
                color: AppTheme.primary,
                status: 'positive',
              ),
              KpiCardWidget(
                title: 'Monthly Income',
                value: _formatCurrency(totalIncome),
                iconName: 'payments',
                color: AppTheme.success,
                subtitle: 'from assets',
                status: 'positive',
              ),
              KpiCardWidget(
                title: 'Productivity Ratio',
                value: '${productivity.toStringAsFixed(1)}%',
                iconName: 'speed',
                color: const Color(0xFF8B5CF6),
                subtitle: 'income/value',
                status: productivity > 10 ? 'positive' : 'neutral',
              ),
              KpiCardWidget(
                title: 'Asset Count',
                value: '${assets.length}',
                iconName: 'inventory_2',
                color: AppTheme.warning,
                subtitle: 'total assets',
                status: 'neutral',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Asset performance list
          Text('Asset Performance', style: _sectionTitle()),
          const SizedBox(height: 12),
          ...assets.take(5).map((asset) => _buildAssetRow(asset)),
          const SizedBox(height: 20),

          // Asset insights
          Text('Asset Intelligence', style: _sectionTitle()),
          const SizedBox(height: 12),
          ..._aiInsights
              .where((i) => i['related_module'] == 'assets')
              .map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AiInsightCardWidget(
                    insightType: insight['insight_type'] as String? ?? 'trend',
                    message: insight['message'] as String? ?? '',
                    severity: insight['severity'] as String? ?? 'neutral',
                    relatedModule: insight['related_module'] as String?,
                  ),
                ),
              ),
          if (_aiInsights.where((i) => i['related_module'] == 'assets').isEmpty)
            AiInsightCardWidget(
              insightType: 'opportunity',
              message:
                  'Asset portfolio productivity ratio is 18% — above industry average of 12%. Consider reinvesting returns.',
              severity: 'positive',
              relatedModule: 'assets',
            ),
          const SizedBox(height: 20),

          // Asset score
          Text('Asset Performance Score', style: _sectionTitle()),
          const SizedBox(height: 12),
          ..._performanceScores
              .where((s) => s['category'] == 'asset_performance')
              .map(
                (s) => PerformanceScoreCardWidget(
                  category: s['category'] as String,
                  score: s['score'] as int? ?? 0,
                  explanation: s['explanation'] as String? ?? '',
                ),
              ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── INVESTMENT ANALYTICS DASHBOARD ──────────────────────────────────────
  Widget _buildInvestmentsTab() {
    final invested = _investmentData['invested'] ?? 50000000;
    final current = _investmentData['current'] ?? 58000000;
    final profit = _investmentData['profit'] ?? 8000000;
    final roi = _investmentData['roi'] ?? 16.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portfolio Performance', style: _sectionTitle()),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              KpiCardWidget(
                title: 'Total Invested',
                value: _formatCurrency(invested),
                iconName: 'savings',
                color: AppTheme.primary,
                status: 'neutral',
              ),
              KpiCardWidget(
                title: 'Current Value',
                value: _formatCurrency(current),
                iconName: 'account_balance_wallet',
                color: AppTheme.success,
                status: 'positive',
              ),
              KpiCardWidget(
                title: 'Total Profit',
                value: _formatCurrency(profit),
                iconName: 'trending_up',
                color: profit >= 0 ? AppTheme.success : AppTheme.error,
                status: profit >= 0 ? 'positive' : 'negative',
              ),
              KpiCardWidget(
                title: 'ROI',
                value: '${roi.toStringAsFixed(1)}%',
                iconName: 'percent',
                color: const Color(0xFF8B5CF6),
                subtitle: 'return on investment',
                status: roi > 10
                    ? 'positive'
                    : roi > 0
                    ? 'neutral'
                    : 'negative',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Portfolio growth chart
          Text('Portfolio Growth', style: _sectionTitle()),
          const SizedBox(height: 12),
          AnalyticsChartWidget(
            title: 'Investment Value Over Time',
            data: _monthlyTrends
                .map(
                  (m) => {
                    'month': m['month'],
                    'value':
                        invested +
                        (profit *
                            (_monthlyTrends.indexOf(m) + 1) /
                            _monthlyTrends.length),
                  },
                )
                .toList(),
            chartType: AnalyticsChartType.line,
            primaryLabel: 'Portfolio Value',
            primaryColor: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 20),

          // Risk Analysis
          Text('Risk Analysis', style: _sectionTitle()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: [
                _buildRiskRow('Concentration Risk', 'Medium', AppTheme.warning),
                _buildRiskRow('Volatility', 'Low', AppTheme.success),
                _buildRiskRow('Market Exposure', 'Moderate', AppTheme.warning),
                _buildRiskRow('Liquidity Risk', 'Low', AppTheme.success),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Investment score
          Text('Investment Performance Score', style: _sectionTitle()),
          const SizedBox(height: 12),
          ..._performanceScores
              .where((s) => s['category'] == 'investment_performance')
              .map(
                (s) => PerformanceScoreCardWidget(
                  category: s['category'] as String,
                  score: s['score'] as int? ?? 0,
                  explanation: s['explanation'] as String? ?? '',
                ),
              ),
          const SizedBox(height: 20),

          // Investment insights
          Text('Investment Insights', style: _sectionTitle()),
          const SizedBox(height: 12),
          ..._aiInsights
              .where((i) => i['related_module'] == 'investments')
              .map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AiInsightCardWidget(
                    insightType: insight['insight_type'] as String? ?? 'trend',
                    message: insight['message'] as String? ?? '',
                    severity: insight['severity'] as String? ?? 'neutral',
                    relatedModule: insight['related_module'] as String?,
                  ),
                ),
              ),
          if (_aiInsights
              .where((i) => i['related_module'] == 'investments')
              .isEmpty)
            AiInsightCardWidget(
              insightType: 'trend',
              message:
                  'Investment portfolio ROI of ${roi.toStringAsFixed(1)}% outperforms market benchmark of 10%. Consider diversifying into bonds.',
              severity: 'positive',
              relatedModule: 'investments',
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ───────────────────────────────────────────────────────

  Widget _buildAssetRow(Map<String, dynamic> asset) {
    final roi = (asset['roi'] as double?) ?? 0;
    final color = roi > 10
        ? AppTheme.success
        : roi > 0
        ? AppTheme.warning
        : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'real_estate_agent',
                color: AppTheme.primary,
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
                  asset['name'] as String? ?? 'Asset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatCurrency((asset['value'] as double?) ?? 0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${roi.toStringAsFixed(1)}% ROI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '${_formatCurrency((asset['income'] as double?) ?? 0)}/mo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.mutedLight,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRow(String label, String level, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.mutedLight,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              level,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionTitle() => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppTheme.onSurfaceLight,
  );

  Color _scoreColor(int s) {
    if (s >= 80) return AppTheme.success;
    if (s >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  String _scoreLabel(int s) {
    if (s >= 80) return 'Excellent Financial Health';
    if (s >= 60) return 'Good Financial Health';
    if (s >= 40) return 'Fair Financial Health';
    return 'Needs Improvement';
  }

  String _overallHealthLabel(int s) {
    if (s >= 80) return 'Your finances are in excellent shape. Keep it up!';
    if (s >= 60) return 'Good overall performance with room to improve.';
    return 'Several areas need attention. Review AI recommendations.';
  }

  List<Map<String, dynamic>> _demoAssets() => [
    {
      'name': 'Transport Bus Fleet',
      'category': 'vehicle',
      'value': 150000000.0,
      'income': 3000000.0,
      'roi': 25.0,
    },
    {
      'name': 'Commercial Property',
      'category': 'real_estate',
      'value': 80000000.0,
      'income': 1200000.0,
      'roi': 18.0,
    },
    {
      'name': 'Office Equipment',
      'category': 'equipment',
      'value': 20000000.0,
      'income': 0.0,
      'roi': 0.0,
    },
    {
      'name': 'Land Plot - Dar es Salaam',
      'category': 'real_estate',
      'value': 50000000.0,
      'income': 0.0,
      'roi': 12.0,
    },
  ];

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Generate Report',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _reportOption(
              ctx,
              'financial',
              'Financial Report',
              'account_balance',
              AppTheme.primary,
            ),
            _reportOption(
              ctx,
              'business',
              'Business Report',
              'business_center',
              AppTheme.success,
            ),
            _reportOption(
              ctx,
              'investment',
              'Investment Report',
              'trending_up',
              const Color(0xFF8B5CF6),
            ),
            _reportOption(
              ctx,
              'executive',
              'Executive Report',
              'dashboard',
              AppTheme.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportOption(
    BuildContext ctx,
    String type,
    String label,
    String icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Center(
          child: CustomIconWidget(iconName: icon, color: color, size: 18),
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(ctx);
        _generateReport(type);
      },
    );
  }
}
