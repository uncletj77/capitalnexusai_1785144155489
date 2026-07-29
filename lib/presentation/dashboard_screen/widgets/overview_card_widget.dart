import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/finance_service.dart';
import '../../../widgets/cna_shared_components.dart';

class OverviewCardWidget extends StatefulWidget {
  final int selectedPeriod;

  const OverviewCardWidget({required this.selectedPeriod, super.key});

  @override
  State<OverviewCardWidget> createState() => _OverviewCardWidgetState();
}

class _OverviewCardWidgetState extends State<OverviewCardWidget> {
  int? _touchedIndex;
  bool _isLoading = true;
  String _selectedMetric = 'Cash Flow';
  List<Map<String, dynamic>> _chartData = [];
  double _maxY = 10;

  final List<String> _metrics = [
    'Cash Flow',
    'Revenue',
    'Expenses',
    'Net Worth',
    'Savings',
    'Investments',
    'Debt',
    'Profit',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(OverviewCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadData();
    }
  }

  int get _monthsForPeriod {
    switch (widget.selectedPeriod) {
      case 0:
        return 1; // Daily → 1 month
      case 1:
        return 1; // Weekly → 1 month
      case 2:
        return 3; // Monthly → 3 months
      case 3:
        return 6; // Quarterly → 6 months
      case 4:
        return 12; // Annual → 12 months
      default:
        return 6;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final months = _monthsForPeriod;
      final cashFlow = await FinanceService.instance.getMonthlyCashFlow(
        months: months,
      );
      if (!mounted) return;

      if (cashFlow.isEmpty) {
        setState(() {
          _chartData = [];
          _isLoading = false;
        });
        return;
      }

      double maxVal = 0;
      final processed = cashFlow.map((m) {
        final income = (m['total_income'] as num?)?.toDouble() ?? 0;
        final expenses = (m['total_expenses'] as num?)?.toDouble() ?? 0;
        final net = (m['net_cash_flow'] as num?)?.toDouble() ?? 0;
        final label = m['month_year'] as String? ?? '';
        if (income > maxVal) maxVal = income;
        if (expenses > maxVal) maxVal = expenses;
        return {
          'label': label.length > 6 ? label.substring(0, 6) : label,
          'income': income,
          'expense': expenses,
          'net': net,
          'savings': net > 0 ? net : 0.0,
        };
      }).toList();

      setState(() {
        _chartData = processed;
        _maxY = maxVal > 0 ? maxVal * 1.2 : 10;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _getBarValue(Map<String, dynamic> d, int rodIndex) {
    switch (_selectedMetric) {
      case 'Revenue':
        return rodIndex == 0 ? (d['income'] as double) : 0;
      case 'Expenses':
        return rodIndex == 0 ? (d['expense'] as double) : 0;
      case 'Savings':
        return rodIndex == 0 ? (d['savings'] as double) : 0;
      case 'Profit':
        return rodIndex == 0
            ? (d['net'] as double).clamp(0, double.infinity)
            : 0;
      default:
        return rodIndex == 0
            ? (d['income'] as double)
            : (d['expense'] as double);
    }
  }

  bool get _isSingleBar =>
      ['Revenue', 'Expenses', 'Savings', 'Profit'].contains(_selectedMetric);

  String _formatTZS(double v) {
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
  }

  String get _periodLabel {
    final now = DateTime.now();
    switch (widget.selectedPeriod) {
      case 0:
        return 'Today';
      case 1:
        return 'This Week';
      case 2:
        return 'Last 3 Months';
      case 3:
        return 'Last 6 Months';
      case 4:
        return '${now.year}';
      default:
        return 'Custom Period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.onSurfaceLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _periodLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed('/transaction-history'),
                child: Text(
                  'VIEW ALL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metric selector
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _metrics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final selected = _metrics[i] == _selectedMetric;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMetric = _metrics[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _metrics[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (!_isSingleBar)
            Row(
              children: [
                _LegendItem(color: AppTheme.primary, label: 'Income'),
                const SizedBox(width: 16),
                _LegendItem(
                  color: AppTheme.error.withAlpha(180),
                  label: 'Expenses',
                ),
              ],
            ),
          if (!_isSingleBar) const SizedBox(height: 12),
          if (_isLoading)
            const SizedBox(
              height: 160,
              child: Center(
                child: CnaLoadingState(message: 'Loading chart...'),
              ),
            )
          else if (_chartData.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, color: AppTheme.mutedLight, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'No financial data yet',
                      style: TextStyle(
                        color: AppTheme.mutedLight,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Add transactions to see your overview',
                      style: TextStyle(
                        color: AppTheme.mutedLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex >= _chartData.length) return null;
                        final d = _chartData[groupIndex];
                        final label = _isSingleBar
                            ? _selectedMetric
                            : (rodIndex == 0 ? 'Income' : 'Expense');
                        final value = _getBarValue(d, rodIndex);
                        return BarTooltipItem(
                          '$label\n${_formatTZS(value)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex = response?.spot?.touchedBarGroupIndex;
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= _chartData.length) {
                            return const SizedBox.shrink();
                          }
                          if (i == 0 || i == _chartData.length - 1) {
                            return Text(
                              _chartData[i]['label'] as String,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.mutedLight,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 20,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.outlineLight,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(_chartData.length, (i) {
                    final d = _chartData[i];
                    final isTouched = i == _touchedIndex;
                    if (_isSingleBar) {
                      final val = _getBarValue(d, 0);
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: val.clamp(0, _maxY),
                            color: isTouched
                                ? AppTheme.primary
                                : AppTheme.primary.withAlpha(200),
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (_getBarValue(d, 0)).clamp(0, _maxY),
                          color: isTouched
                              ? AppTheme.primary
                              : AppTheme.primary.withAlpha(217),
                          width: 6,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: (_getBarValue(d, 1)).clamp(0, _maxY),
                          color: AppTheme.error.withAlpha(150),
                          width: 6,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                      barsSpace: 3,
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.mutedLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
