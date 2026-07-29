import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../services/finance_service.dart';

/// Executive Financial Metrics — live data from Finance Engine
class ExecutiveMetricsWidget extends StatefulWidget {
  final Map<String, dynamic> data;

  const ExecutiveMetricsWidget({required this.data, super.key});

  @override
  State<ExecutiveMetricsWidget> createState() => _ExecutiveMetricsWidgetState();
}

class _ExecutiveMetricsWidgetState extends State<ExecutiveMetricsWidget> {
  double _loanReceivableTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadReceivables();
  }

  Future<void> _loadReceivables() async {
    try {
      final receivables = await FinanceService.instance.getLoansReceivable();
      double total = 0;
      for (final r in receivables) {
        if ([
          'active',
          'partially_paid',
          'overdue',
        ].contains(r['loan_status'])) {
          total += (r['remaining_balance'] as num?)?.toDouble() ?? 0;
        }
      }
      if (mounted) setState(() => _loanReceivableTotal = total);
    } catch (_) {}
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
    final income = (widget.data['monthlyIncome'] as double?) ?? 0;
    final expenses = (widget.data['monthlyExpenses'] as double?) ?? 0;
    final netProfit = income - expenses;
    final cash = (widget.data['availableCash'] as double?) ?? 0;
    final netWorth = (widget.data['netWorth'] as double?) ?? 0;
    final totalAssets = (widget.data['totalAssets'] as double?) ?? 0;
    final totalLiabilities = (widget.data['totalLiabilities'] as double?) ?? 0;
    final savings = (widget.data['save'] as double?) ?? 0;
    final investments = (widget.data['invest'] as double?) ?? 0;
    final bizValue = (widget.data['totalBusinessValue'] as double?) ?? 0;

    final metrics = [
      _ExecMetric(
        'Revenue',
        _fmt(income),
        'trending_up',
        const Color(0xFF27AE60),
        AppRoutes.transactionHistoryScreen,
      ),
      _ExecMetric(
        'Expenses',
        _fmt(expenses),
        'trending_down',
        const Color(0xFFE53E3E),
        AppRoutes.transactionHistoryScreen,
      ),
      _ExecMetric(
        'Net Profit',
        _fmt(netProfit),
        netProfit >= 0 ? 'arrow_upward' : 'arrow_downward',
        netProfit >= 0 ? const Color(0xFF27AE60) : const Color(0xFFE53E3E),
        AppRoutes.financeDashboardScreen,
      ),
      _ExecMetric(
        'Cash Available',
        _fmt(cash),
        'account_balance_wallet',
        const Color(0xFF1A5F7A),
        AppRoutes.accountsScreen,
      ),
      _ExecMetric(
        'Net Worth',
        _fmt(netWorth),
        'bar_chart',
        const Color(0xFF2D9CDB),
        AppRoutes.netWorthScreen,
      ),
      _ExecMetric(
        'Total Assets',
        _fmt(totalAssets),
        'real_estate_agent',
        const Color(0xFF4BB8A0),
        AppRoutes.assetDashboardScreen,
      ),
      _ExecMetric(
        'Liabilities',
        _fmt(totalLiabilities),
        'credit_card_off',
        const Color(0xFFF2994A),
        AppRoutes.loanDashboardScreen,
      ),
      _ExecMetric(
        'Savings',
        _fmt(savings),
        'savings',
        const Color(0xFF27AE60),
        AppRoutes.accountsScreen,
      ),
      _ExecMetric(
        'Investments',
        _fmt(investments),
        'show_chart',
        const Color(0xFF1A5F7A),
        AppRoutes.investmentDashboardScreen,
      ),
      _ExecMetric(
        'Loan Receivables',
        _fmt(_loanReceivableTotal),
        'payments',
        const Color(0xFF9B59B6),
        AppRoutes.loansReceivableScreen,
      ),
      _ExecMetric(
        'Loans Payable',
        _fmt(totalLiabilities),
        'account_balance',
        const Color(0xFFE74C3C),
        AppRoutes.loanDashboardScreen,
      ),
      _ExecMetric(
        'Business Value',
        _fmt(bizValue),
        'business_center',
        const Color(0xFF2980B9),
        AppRoutes.businessDashboardScreen,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Executive Metrics',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: metrics.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _ExecMetricCard(metric: metrics[i]),
          ),
        ),
      ],
    );
  }
}

class _ExecMetric {
  final String label;
  final String value;
  final String icon;
  final Color color;
  final String route;
  const _ExecMetric(this.label, this.value, this.icon, this.color, this.route);
}

class _ExecMetricCard extends StatelessWidget {
  final _ExecMetric metric;

  const _ExecMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.go(metric.route),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: metric.color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: metric.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: metric.icon,
                      color: metric.color,
                      size: 12,
                    ),
                  ),
                ),
                const Spacer(),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: metric.color.withAlpha(120),
                  size: 12,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceLight,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  metric.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.mutedLight,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
