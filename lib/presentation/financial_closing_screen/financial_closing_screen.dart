import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/financial_closing_engine_service.dart';
import '../../widgets/cna_shared_components.dart';

class FinancialClosingScreen extends StatefulWidget {
  const FinancialClosingScreen({super.key});

  @override
  State<FinancialClosingScreen> createState() => _FinancialClosingScreenState();
}

class _FinancialClosingScreenState extends State<FinancialClosingScreen> {
  bool _isLoading = false;
  bool _isGenerating = false;
  String _selectedPeriod = 'monthly';
  Map<String, dynamic>? _currentReport;
  List<Map<String, dynamic>> _reportHistory = [];
  bool _showHistory = false;

  final List<Map<String, dynamic>> _periods = [
    {'key': 'daily', 'label': 'Daily', 'icon': 'today'},
    {'key': 'weekly', 'label': 'Weekly', 'icon': 'date_range'},
    {'key': 'monthly', 'label': 'Monthly', 'icon': 'calendar_month'},
    {'key': 'quarterly', 'label': 'Quarterly', 'icon': 'bar_chart'},
    {'key': 'yearly', 'label': 'Annual', 'icon': 'assessment'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await FinancialClosingEngineService.instance
        .getClosingReports(limit: 10);
    if (mounted) {
      setState(() {
        _reportHistory = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    final report = await FinancialClosingEngineService.instance
        .generateClosingReport(periodType: _selectedPeriod);
    if (mounted) {
      setState(() {
        _currentReport = report;
        _isGenerating = false;
        _showHistory = false;
      });
      _loadHistory();
    }
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

  Color _changeColor(double value) =>
      value >= 0 ? AppTheme.success : AppTheme.error;
  String _changeSign(double value) => value >= 0 ? '+' : '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                          iconName: 'arrow_back',
                          color: AppTheme.primary,
                          size: 20,
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
                          'Financial Closing',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Executive period reviews',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showHistory = !_showHistory),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _showHistory
                            ? AppTheme.primary
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showHistory
                              ? AppTheme.primary
                              : AppTheme.outlineLight,
                        ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'history',
                          color: _showHistory ? Colors.white : AppTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Period selector
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final p = _periods[i];
                  final isSelected = _selectedPeriod == p['key'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPeriod = p['key'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.outlineLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: p['icon'] as String,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.mutedLight,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.mutedLight,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Generate button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateReport,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.play_arrow, color: Colors.white),
                  label: Text(
                    _isGenerating
                        ? 'Generating Report...'
                        : 'Generate ${_periods.firstWhere((p) => p['key'] == _selectedPeriod)['label']} Review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const CnaLoadingState(message: 'Loading reports...')
                  : _showHistory
                  ? _buildHistoryView(theme)
                  : _currentReport != null
                  ? _buildReportView(theme, _currentReport!)
                  : _buildEmptyState(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'assessment',
                  color: AppTheme.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Generate Your First Report',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a period above and tap Generate to create an executive financial review with AI insights.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (_reportHistory.isNotEmpty) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => setState(() => _showHistory = true),
                icon: const Icon(Icons.history, size: 16),
                label: Text('View ${_reportHistory.length} previous report(s)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView(ThemeData theme) {
    if (_reportHistory.isEmpty) {
      return const CnaEmptyState(
        iconName: 'history',
        title: 'No Reports Yet',
        description: 'Generate your first financial closing report.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _reportHistory.length,
      itemBuilder: (ctx, i) {
        final r = _reportHistory[i];
        final income = (r['total_income'] as num?)?.toDouble() ?? 0;
        final expenses = (r['total_expenses'] as num?)?.toDouble() ?? 0;
        final netCashFlow = income - expenses;
        final score = (r['financial_health_score'] as num?)?.toInt() ?? 0;
        final scoreColor = score >= 75
            ? AppTheme.success
            : score >= 50
            ? AppTheme.warning
            : AppTheme.error;

        return GestureDetector(
          onTap: () => setState(() {
            _currentReport = r;
            _showHistory = false;
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: CustomIconWidget(
                      iconName: 'assessment',
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['period_label'] as String? ?? 'Report',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Net: ${_formatAmount(netCashFlow)} • Health: $score/100',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$score',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportView(ThemeData theme, Map<String, dynamic> report) {
    final income = (report['total_income'] as num?)?.toDouble() ?? 0;
    final expenses = (report['total_expenses'] as num?)?.toDouble() ?? 0;
    final netCashFlow = income - expenses;
    final netWorth = (report['closing_net_worth'] as num?)?.toDouble() ?? 0;
    final healthScore =
        (report['financial_health_score'] as num?)?.toInt() ?? 0;
    final scoreColor = healthScore >= 75
        ? AppTheme.success
        : healthScore >= 50
        ? AppTheme.warning
        : AppTheme.error;
    final incomeVsPrior = (report['income_vs_prior'] as num?)?.toDouble() ?? 0;
    final expenseVsPrior =
        (report['expense_vs_prior'] as num?)?.toDouble() ?? 0;
    final bizRevenue = (report['business_revenue'] as num?)?.toDouble() ?? 0;
    final bizProfit = (report['business_profit'] as num?)?.toDouble() ?? 0;
    final portfolioValue = (report['portfolio_value'] as num?)?.toDouble() ?? 0;
    final loanPayables =
        (report['loan_payables_balance'] as num?)?.toDouble() ?? 0;
    final loanReceivables =
        (report['loan_receivables_balance'] as num?)?.toDouble() ?? 0;
    final aiSummary = report['ai_executive_summary'] as String? ?? '';
    final insights =
        (report['ai_key_insights'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final risks =
        (report['ai_risks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final recommendations =
        (report['ai_recommendations'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final milestones =
        (report['milestones_achieved'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final goalsProgress =
        (report['goals_progress'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Report header
        Container(
          padding: const EdgeInsets.all(16),
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
                report['period_label'] as String? ?? 'Report',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Generated ${_formatDateTime(report['generated_at'] as String?)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _reportMetric('Health Score', '$healthScore/100', scoreColor),
                  _reportMetric(
                    'Net Worth',
                    _formatAmount(netWorth),
                    Colors.white,
                  ),
                  _reportMetric(
                    'Cash Flow',
                    _formatAmount(netCashFlow),
                    netCashFlow >= 0 ? AppTheme.success : AppTheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Executive Summary
        if (aiSummary.isNotEmpty) ...[
          _sectionHeader(theme, 'AI Executive Summary', 'psychology'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: Text(
              aiSummary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Income & Expense Analysis
        _sectionHeader(theme, 'Income & Expense Analysis', 'account_balance'),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                theme,
                'Total Income',
                _formatAmount(income),
                '${_changeSign(incomeVsPrior)}${(incomeVsPrior * 100).toStringAsFixed(1)}% vs prior',
                _changeColor(incomeVsPrior),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                theme,
                'Total Expenses',
                _formatAmount(expenses),
                '${_changeSign(expenseVsPrior)}${(expenseVsPrior * 100).toStringAsFixed(1)}% vs prior',
                _changeColor(-expenseVsPrior),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _metricCard(
          theme,
          'Net Cash Flow',
          _formatAmount(netCashFlow),
          netCashFlow >= 0 ? 'Positive cash flow' : 'Negative cash flow',
          _changeColor(netCashFlow),
        ),
        const SizedBox(height: 16),

        // Business & Investment
        if (bizRevenue > 0 || portfolioValue > 0) ...[
          _sectionHeader(theme, 'Business & Investment', 'business_center'),
          Row(
            children: [
              if (bizRevenue > 0)
                Expanded(
                  child: _metricCard(
                    theme,
                    'Business Revenue',
                    _formatAmount(bizRevenue),
                    'Profit: ${_formatAmount(bizProfit)}',
                    bizProfit >= 0 ? AppTheme.success : AppTheme.error,
                  ),
                ),
              if (bizRevenue > 0 && portfolioValue > 0)
                const SizedBox(width: 10),
              if (portfolioValue > 0)
                Expanded(
                  child: _metricCard(
                    theme,
                    'Portfolio Value',
                    _formatAmount(portfolioValue),
                    'Investment assets',
                    AppTheme.primaryLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Loans
        if (loanPayables > 0 || loanReceivables > 0) ...[
          _sectionHeader(theme, 'Loan Summary', 'account_balance_wallet'),
          Row(
            children: [
              if (loanReceivables > 0)
                Expanded(
                  child: _metricCard(
                    theme,
                    'Receivables',
                    _formatAmount(loanReceivables),
                    'Owed to you',
                    AppTheme.success,
                  ),
                ),
              if (loanReceivables > 0 && loanPayables > 0)
                const SizedBox(width: 10),
              if (loanPayables > 0)
                Expanded(
                  child: _metricCard(
                    theme,
                    'Payables',
                    _formatAmount(loanPayables),
                    'You owe',
                    AppTheme.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Goals Progress
        if (goalsProgress.isNotEmpty) ...[
          _sectionHeader(theme, 'Goals Progress', 'flag'),
          ...goalsProgress.take(4).map((g) {
            final progress = (g['progress'] as num?)?.toDouble() ?? 0;
            final status = g['status'] as String? ?? 'behind';
            final statusColor = status == 'completed'
                ? AppTheme.success
                : status == 'on_track'
                ? AppTheme.primaryLight
                : AppTheme.warning;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g['name'] as String? ?? 'Goal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (progress / 100).clamp(0.0, 1.0),
                            backgroundColor: statusColor.withAlpha(30),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Key Insights
        if (insights.isNotEmpty) ...[
          _sectionHeader(theme, 'Key Insights', 'lightbulb'),
          ...insights.map((ins) {
            final type = ins['type'] as String? ?? 'neutral';
            final color = type == 'positive'
                ? AppTheme.success
                : type == 'negative'
                ? AppTheme.error
                : AppTheme.warning;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ins['title'] as String? ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ins['detail'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Risks
        if (risks.isNotEmpty) ...[
          _sectionHeader(theme, 'Risk Analysis', 'warning'),
          ...risks.map((risk) {
            final severity = risk['severity'] as String? ?? 'medium';
            final color = severity == 'high'
                ? AppTheme.error
                : severity == 'medium'
                ? AppTheme.warning
                : AppTheme.primaryLight;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomIconWidget(iconName: 'warning', color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          risk['title'] as String? ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          risk['description'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Recommendations
        if (recommendations.isNotEmpty) ...[
          _sectionHeader(
            theme,
            'Strategic Recommendations',
            'tips_and_updates',
          ),
          ...recommendations.map((rec) {
            final priority = rec['priority'] as String? ?? 'medium';
            final color = priority == 'high'
                ? AppTheme.error
                : priority == 'medium'
                ? AppTheme.warning
                : AppTheme.primaryLight;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['title'] as String? ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          rec['action'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Milestones
        if (milestones.isNotEmpty) ...[
          _sectionHeader(theme, 'Achievements & Milestones', 'emoji_events'),
          ...milestones.map(
            (m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const CustomIconWidget(
                    iconName: 'emoji_events',
                    color: AppTheme.success,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] as String? ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                        Text(
                          m['description'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _reportMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, String icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CustomIconWidget(iconName: icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    ThemeData theme,
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
