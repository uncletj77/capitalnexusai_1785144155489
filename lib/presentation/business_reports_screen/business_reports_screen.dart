import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/enterprise_transaction_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';

/// Business Reports Screen — AI-powered financial reports for a specific business.
/// Shows P&L, revenue trends, expense breakdown, KPIs, and AI-generated insights.
class BusinessReportsScreen extends StatefulWidget {
  final Map<String, dynamic>? business;
  const BusinessReportsScreen({super.key, this.business});

  @override
  State<BusinessReportsScreen> createState() => _BusinessReportsScreenState();
}

class _BusinessReportsScreenState extends State<BusinessReportsScreen>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  bool _isGeneratingAI = false;
  late TabController _tabController;

  Map<String, dynamic>? _business;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _aiInsights = [];
  String _selectedPeriod = 'this_month';

  double _totalRevenue = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;
  double _grossMargin = 0;
  Map<String, double> _expenseBreakdown = {};
  Map<String, double> _revenueBreakdown = {};
  List<Map<String, dynamic>> _monthlyTrend = [];

  final List<Map<String, String>> _periods = [
    {'key': 'this_month', 'label': 'This Month'},
    {'key': 'last_month', 'label': 'Last Month'},
    {'key': 'this_quarter', 'label': 'This Quarter'},
    {'key': 'this_year', 'label': 'This Year'},
    {'key': 'all_time', 'label': 'All Time'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _business = widget.business;
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTimeRange _getPeriodRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'last_month':
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: start, end: end);
      case 'this_quarter':
        final qStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        return DateTimeRange(start: qStart, end: now);
      case 'this_year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case 'all_time':
        return DateTimeRange(start: DateTime(2020, 1, 1), end: now);
      default: // this_month
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      if (_business == null) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          final biz = await _client
              .from('businesses')
              .select()
              .eq('owner_id', userId)
              .eq('is_active', true)
              .limit(1)
              .maybeSingle();
          _business = biz;
        }
      }
      if (_business == null) {
        setState(() => _isLoading = false);
        return;
      }

      final range = _getPeriodRange();
      final bizId = _business!['id'] as String;

      // Load business transactions for the period
      final txRes = await _client
          .from('business_transactions')
          .select()
          .eq('business_id', bizId)
          .gte('transaction_date', range.start.toIso8601String().split('T')[0])
          .lte('transaction_date', range.end.toIso8601String().split('T')[0])
          .order('transaction_date', ascending: false)
          .catchError((_) => <dynamic>[]);

      final txList = List<Map<String, dynamic>>.from(txRes as List);

      // Also load from financial_transactions linked to this business
      final ftRes = await _client
          .from('financial_transactions')
          .select()
          .eq('related_business_id', bizId)
          .gte('transaction_date', range.start.toIso8601String().split('T')[0])
          .lte('transaction_date', range.end.toIso8601String().split('T')[0])
          .order('transaction_date', ascending: false)
          .catchError((_) => <dynamic>[]);

      // Merge both sources, deduplicate by financial_transaction_id
      final seenIds = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final t in txList) {
        final ftId = t['financial_transaction_id'] as String?;
        if (ftId != null) seenIds.add(ftId);
        merged.add({...t, '_source': 'business'});
      }
      for (final t in (ftRes as List)) {
        final id = t['id'] as String;
        if (!seenIds.contains(id)) {
          merged.add({...Map<String, dynamic>.from(t), '_source': 'financial'});
        }
      }

      // Calculate KPIs
      double rev = 0, exp = 0;
      final expBreak = <String, double>{};
      final revBreak = <String, double>{};

      for (final t in merged) {
        final amt = (t['amount'] as num).toDouble();
        final type = t['transaction_type'] as String? ?? '';
        final cat = t['category'] as String? ?? 'Other';

        final isRevenue =
            type == 'revenue' || type == 'business_income' || type == 'income';
        final isExpense = type == 'expense' || type == 'business_expense';

        if (isRevenue) {
          rev += amt;
          revBreak[cat] = (revBreak[cat] ?? 0) + amt;
        } else if (isExpense) {
          exp += amt;
          expBreak[cat] = (expBreak[cat] ?? 0) + amt;
        }
      }

      // Build monthly trend (last 6 months)
      final now = DateTime.now();
      final trend = <Map<String, dynamic>>[];
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);
        double mRev = 0, mExp = 0;
        for (final t in merged) {
          final dateStr = t['transaction_date'] as String?;
          if (dateStr == null) continue;
          final date = DateTime.tryParse(dateStr);
          if (date == null) continue;
          if (date.isBefore(month) || date.isAfter(monthEnd)) continue;
          final amt = (t['amount'] as num).toDouble();
          final type = t['transaction_type'] as String? ?? '';
          if (type == 'revenue' ||
              type == 'business_income' ||
              type == 'income')
            mRev += amt;
          if (type == 'expense' || type == 'business_expense') mExp += amt;
        }
        const monthNames = [
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
        trend.add({
          'month': monthNames[month.month - 1],
          'revenue': mRev,
          'expense': mExp,
          'profit': mRev - mExp,
        });
      }

      // Load AI insights from database
      final aiRes = await _client
          .from('ai_insights')
          .select()
          .eq('entity_type', 'business')
          .eq('entity_id', bizId)
          .order('created_at', ascending: false)
          .limit(10)
          .catchError((_) => <dynamic>[]);

      setState(() {
        _transactions = merged;
        _totalRevenue = rev;
        _totalExpenses = exp;
        _netProfit = rev - exp;
        _grossMargin = rev > 0 ? ((rev - exp) / rev) * 100 : 0;
        _expenseBreakdown = expBreak;
        _revenueBreakdown = revBreak;
        _monthlyTrend = trend;
        _aiInsights = List<Map<String, dynamic>>.from(aiRes as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAIReport() async {
    setState(() => _isGeneratingAI = true);
    try {
      final bizName = _business?['name'] as String? ?? 'Business';
      final margin = _grossMargin.toStringAsFixed(1);
      final profitStr = _netProfit >= 0
          ? 'profit of ${_fmt(_netProfit)}'
          : 'loss of ${_fmt(_netProfit.abs())}';

      // Generate structured AI insights based on financial data
      final insights = <Map<String, dynamic>>[];

      // Profitability insight
      insights.add({
        'title': 'Profitability Analysis',
        'icon': 'trending_up',
        'color': _netProfit >= 0 ? 'success' : 'error',
        'insight': _netProfit >= 0
            ? '$bizName achieved a $profitStr with a gross margin of $margin%. ${double.parse(margin) > 20 ? 'This is a strong margin — consider reinvesting in growth initiatives.' : 'Margin is moderate — review expense categories for optimization opportunities.'}'
            : '$bizName recorded a $profitStr this period. Immediate review of expense categories is recommended to restore profitability.',
        'action': _netProfit >= 0
            ? 'Explore growth investment options'
            : 'Review and reduce top expense categories',
      });

      // Revenue insight
      if (_revenueBreakdown.isNotEmpty) {
        final topRevCat = _revenueBreakdown.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        insights.add({
          'title': 'Revenue Intelligence',
          'icon': 'attach_money',
          'color': 'primary',
          'insight':
              'Top revenue source is "${topRevCat.key}" contributing ${_totalRevenue > 0 ? ((topRevCat.value / _totalRevenue) * 100).toStringAsFixed(1) : 0}% of total revenue (${_fmt(topRevCat.value)}). Diversifying revenue streams can reduce dependency risk.',
          'action': 'Identify and develop secondary revenue streams',
        });
      }

      // Expense insight
      if (_expenseBreakdown.isNotEmpty) {
        final topExpCat = _expenseBreakdown.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        insights.add({
          'title': 'Cost Management',
          'icon': 'savings',
          'color': 'warning',
          'insight':
              'Largest expense category is "${topExpCat.key}" at ${_fmt(topExpCat.value)} (${_totalExpenses > 0 ? ((topExpCat.value / _totalExpenses) * 100).toStringAsFixed(1) : 0}% of total costs). Monitoring this category closely can yield significant savings.',
          'action': 'Set budget limits for top expense categories',
        });
      }

      // Trend insight
      if (_monthlyTrend.length >= 3) {
        final recent = _monthlyTrend.last;
        final prev = _monthlyTrend[_monthlyTrend.length - 2];
        final revChange = (prev['revenue'] as double) > 0
            ? (((recent['revenue'] as double) - (prev['revenue'] as double)) /
                      (prev['revenue'] as double)) *
                  100
            : 0.0;
        insights.add({
          'title': 'Growth Trend',
          'icon': 'show_chart',
          'color': revChange >= 0 ? 'success' : 'error',
          'insight':
              'Revenue ${revChange >= 0 ? 'grew' : 'declined'} by ${revChange.abs().toStringAsFixed(1)}% compared to last month. ${revChange >= 10
                  ? 'Excellent growth momentum — maintain current strategies.'
                  : revChange >= 0
                  ? 'Steady growth — look for acceleration opportunities.'
                  : 'Revenue decline detected — investigate root causes immediately.'}',
          'action': revChange >= 0
              ? 'Maintain growth momentum'
              : 'Investigate revenue decline causes',
        });
      }

      // Cash flow insight
      insights.add({
        'title': 'Cash Flow Forecast',
        'icon': 'account_balance_wallet',
        'color': 'primary',
        'insight':
            'Based on current revenue of ${_fmt(_totalRevenue)} and expenses of ${_fmt(_totalExpenses)}, the business ${_netProfit >= 0 ? 'is generating positive cash flow' : 'has negative cash flow'}. ${_netProfit >= 0 ? 'Maintain a cash reserve of at least 3 months of operating expenses.' : 'Urgent action required to improve cash position.'}',
        'action': _netProfit >= 0
            ? 'Build emergency cash reserve'
            : 'Secure additional funding or reduce costs',
      });

      setState(() {
        _aiInsights = insights;
        _isGeneratingAI = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI report generated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingAI = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _fmt(double v) {
    if (v >= 1000000000) return 'TSh ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  Color _insightColor(String? colorKey) {
    switch (colorKey) {
      case 'success':
        return AppTheme.success;
      case 'error':
        return AppTheme.error;
      case 'warning':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bizName = _business?['name'] as String? ?? 'Business';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Reports',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              bizName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isGeneratingAI
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology, color: AppTheme.primary),
            onPressed: _isGeneratingAI ? null : _generateAIReport,
            tooltip: 'Generate AI Report',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.mutedLight,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'AI Insights'),
            Tab(text: 'Breakdown'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Period selector
                Container(
                  height: 44,
                  color: AppTheme.surfaceLight,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    children: _periods.map((p) {
                      final isSelected = _selectedPeriod == p['key'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedPeriod = p['key']!);
                          _loadReports();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surfaceVariantLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.outlineLight,
                            ),
                          ),
                          child: Text(
                            p['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(theme),
                      _buildAIInsightsTab(theme),
                      _buildBreakdownTab(theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // P&L Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profit & Loss Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _netProfit >= 0 ? '+${_fmt(_netProfit)}' : _fmt(_netProfit),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Net ${_netProfit >= 0 ? 'Profit' : 'Loss'} • Margin: ${_grossMargin.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _plChip(
                        theme,
                        'Revenue',
                        _fmt(_totalRevenue),
                        AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _plChip(
                        theme,
                        'Expenses',
                        _fmt(_totalExpenses),
                        AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // KPI Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _kpiCard(
                theme,
                'Transactions',
                '${_transactions.length}',
                Icons.receipt_long,
                AppTheme.primary,
              ),
              _kpiCard(
                theme,
                'Gross Margin',
                '${_grossMargin.toStringAsFixed(1)}%',
                Icons.pie_chart,
                _grossMargin >= 20 ? AppTheme.success : AppTheme.warning,
              ),
              _kpiCard(
                theme,
                'Avg Transaction',
                _fmt(
                  _transactions.isEmpty
                      ? 0
                      : (_totalRevenue + _totalExpenses) / _transactions.length,
                ),
                Icons.analytics,
                AppTheme.primaryLight,
              ),
              _kpiCard(
                theme,
                'Expense Ratio',
                _totalRevenue > 0
                    ? '${((_totalExpenses / _totalRevenue) * 100).toStringAsFixed(1)}%'
                    : '0%',
                Icons.trending_down,
                AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Monthly Trend
          if (_monthlyTrend.isNotEmpty) ...[
            Text(
              'Monthly Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                children: _monthlyTrend.map((m) {
                  final rev = m['revenue'] as double;
                  final exp = m['expense'] as double;
                  final profit = m['profit'] as double;
                  final maxVal = _monthlyTrend.fold(0.0, (max, t) {
                    final v =
                        (t['revenue'] as double) + (t['expense'] as double);
                    return v > max ? v : max;
                  });
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            m['month'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: maxVal > 0
                                      ? (rev / maxVal).clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.outlineLight,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppTheme.success,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: maxVal > 0
                                      ? (exp / maxVal).clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.outlineLight,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppTheme.error,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            profit >= 0 ? '+${_fmt(profit)}' : _fmt(profit),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: profit >= 0
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _plChip(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generate AI Report button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withAlpha(15),
                  AppTheme.primaryLight.withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Business Intelligence',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        'Generate AI-powered insights from your financial data',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isGeneratingAI ? null : _generateAIReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isGeneratingAI
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Generate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_aiInsights.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: AppTheme.mutedLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No AI insights yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Generate" to create AI-powered business insights',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._aiInsights.map((insight) {
              final color = _insightColor(insight['color'] as String?);
              final title = insight['title'] as String? ?? 'Insight';
              final text = insight['insight'] as String? ?? '';
              final action = insight['action'] as String?;
              final iconName = insight['icon'] as String? ?? 'lightbulb';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomIconWidget(
                            iconName: iconName,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceLight,
                        height: 1.5,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_forward, size: 12, color: color),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                action,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBreakdownTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_revenueBreakdown.isNotEmpty) ...[
            Text(
              'Revenue by Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildBreakdownList(
              theme,
              _revenueBreakdown,
              _totalRevenue,
              AppTheme.success,
            ),
            const SizedBox(height: 20),
          ],
          if (_expenseBreakdown.isNotEmpty) ...[
            Text(
              'Expenses by Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildBreakdownList(
              theme,
              _expenseBreakdown,
              _totalExpenses,
              AppTheme.error,
            ),
            const SizedBox(height: 20),
          ],
          if (_revenueBreakdown.isEmpty && _expenseBreakdown.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: AppTheme.mutedLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions in this period',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownList(
    ThemeData theme,
    Map<String, double> data,
    double total,
    Color color,
  ) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: sorted.map((entry) {
          final pct = total > 0 ? (entry.value / total) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _fmt(entry.value),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.toDouble(),
                    minHeight: 6,
                    backgroundColor: AppTheme.outlineLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
