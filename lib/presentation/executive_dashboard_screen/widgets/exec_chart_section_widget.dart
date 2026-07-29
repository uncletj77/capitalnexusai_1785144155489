import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/finance_service.dart';

class ExecChartSectionWidget extends StatefulWidget {
  final int period;
  final Map<String, dynamic> analyticsData;

  const ExecChartSectionWidget({
    required this.period,
    required this.analyticsData,
    super.key,
  });

  @override
  State<ExecChartSectionWidget> createState() => _ExecChartSectionWidgetState();
}

class _ExecChartSectionWidgetState extends State<ExecChartSectionWidget> {
  int _activeChart = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _trends = [];
  List<FlSpot> _incomeSpots = [];
  List<FlSpot> _expenseSpots = [];
  List<PieChartSectionData> _assetSections = [];

  final List<String> _chartTabs = [
    'Cash Flow',
    'Net Worth',
    'Income Sources',
    'Asset Allocation',
  ];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void didUpdateWidget(ExecChartSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    try {
      final trends = await FinanceService.instance.getMonthlyTrends(months: 6);
      final incomeSpots = <FlSpot>[];
      final expenseSpots = <FlSpot>[];
      for (int i = 0; i < trends.length; i++) {
        final t = trends[i];
        incomeSpots.add(
          FlSpot(
            i.toDouble(),
            ((t['income'] as num?)?.toDouble() ?? 0) / 1000000,
          ),
        );
        expenseSpots.add(
          FlSpot(
            i.toDouble(),
            ((t['expenses'] as num?)?.toDouble() ?? 0) / 1000000,
          ),
        );
      }
      if (mounted) {
        setState(() {
          _trends = trends;
          _incomeSpots = incomeSpots.isEmpty
              ? [const FlSpot(0, 0), const FlSpot(1, 0)]
              : incomeSpots;
          _expenseSpots = expenseSpots.isEmpty
              ? [const FlSpot(0, 0), const FlSpot(1, 0)]
              : expenseSpots;
          _assetSections = _buildAssetSections();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _incomeSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
          _expenseSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
          _assetSections = _buildAssetSections();
          _isLoading = false;
        });
      }
    }
  }

  List<PieChartSectionData> _buildAssetSections() {
    final data = widget.analyticsData;
    final fixed = (data['fixedAssets'] as num?)?.toDouble() ?? 30;
    final current = (data['currentAssets'] as num?)?.toDouble() ?? 20;
    final financial = (data['financialAssets'] as num?)?.toDouble() ?? 25;
    final digital = (data['digitalAssets'] as num?)?.toDouble() ?? 15;
    final other = (data['otherAssets'] as num?)?.toDouble() ?? 10;
    final total = fixed + current + financial + digital + other;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: AppTheme.neutral.withAlpha(60),
          title: '',
        ),
      ];
    }
    return [
      PieChartSectionData(
        value: fixed / total * 100,
        color: AppTheme.fixedAssetColor,
        title: '${(fixed / total * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        radius: 55,
      ),
      PieChartSectionData(
        value: current / total * 100,
        color: AppTheme.currentAssetColor,
        title: '${(current / total * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        radius: 55,
      ),
      PieChartSectionData(
        value: financial / total * 100,
        color: AppTheme.appreciatingColor,
        title: '${(financial / total * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        radius: 55,
      ),
      PieChartSectionData(
        value: digital / total * 100,
        color: AppTheme.intangibleColor,
        title: '${(digital / total * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        radius: 55,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart Tab Selector
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _chartTabs.length,
            itemBuilder: (ctx, i) {
              final selected = i == _activeChart;
              return GestureDetector(
                onTap: () => setState(() => _activeChart = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
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
                    _chartTabs[i],
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
            },
          ),
        ),
        const SizedBox(height: 12),
        // Chart Container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(80),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _buildActiveChart(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChart(BuildContext context) {
    switch (_activeChart) {
      case 0:
        return _buildCashFlowChart(context);
      case 1:
        return _buildNetWorthChart(context);
      case 2:
        return _buildIncomeSourcesChart(context);
      case 3:
        return _buildAssetAllocationChart(context);
      default:
        return _buildCashFlowChart(context);
    }
  }

  Widget _buildCashFlowChart(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Flow Analysis',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Income vs Expenses (TZS Millions)',
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: theme.colorScheme.outline.withAlpha(40),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, m) => Text(
                      '${v.toStringAsFixed(0)}M',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                      final idx = v.toInt();
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox();
                      }
                      return Text(
                        months[idx],
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _incomeSpots,
                  isCurved: true,
                  color: AppTheme.success,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.success.withAlpha(30),
                  ),
                ),
                LineChartBarData(
                  spots: _expenseSpots,
                  isCurved: true,
                  color: AppTheme.danger,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.danger.withAlpha(20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _legend(context, 'Income', AppTheme.success),
            const SizedBox(width: 16),
            _legend(context, 'Expenses', AppTheme.danger),
          ],
        ),
      ],
    );
  }

  Widget _buildNetWorthChart(BuildContext context) {
    final theme = Theme.of(context);
    // Build net worth trend from income - expenses cumulative
    final spots = <FlSpot>[];
    double cumulative = 0;
    for (int i = 0; i < _incomeSpots.length; i++) {
      final inc = i < _incomeSpots.length ? _incomeSpots[i].y : 0;
      final exp = i < _expenseSpots.length ? _expenseSpots[i].y : 0;
      cumulative += (inc - exp);
      spots.add(FlSpot(i.toDouble(), cumulative));
    }
    if (spots.isEmpty) spots.addAll([const FlSpot(0, 0), const FlSpot(1, 0)]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Net Worth Growth',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cumulative wealth trend (TZS Millions)',
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: theme.colorScheme.outline.withAlpha(40),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, m) => Text(
                      '${v.toStringAsFixed(0)}M',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                      final idx = v.toInt();
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox();
                      }
                      return Text(
                        months[idx],
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withAlpha(60),
                        AppTheme.primary.withAlpha(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeSourcesChart(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.analyticsData;
    final business = (data['businessIncome'] as num?)?.toDouble() ?? 40;
    final investment = (data['investmentIncome'] as num?)?.toDouble() ?? 25;
    final employment = (data['employmentIncome'] as num?)?.toDouble() ?? 20;
    final other = (data['otherIncome'] as num?)?.toDouble() ?? 15;
    final total = business + investment + employment + other;

    final sections = total == 0
        ? [
            PieChartSectionData(
              value: 1,
              color: AppTheme.neutral.withAlpha(60),
              title: '',
            ),
          ]
        : [
            PieChartSectionData(
              value: business,
              color: AppTheme.primary,
              title: '${(business / total * 100).toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              radius: 55,
            ),
            PieChartSectionData(
              value: investment,
              color: const Color(0xFF6366F1),
              title: '${(investment / total * 100).toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              radius: 55,
            ),
            PieChartSectionData(
              value: employment,
              color: AppTheme.success,
              title: '${(employment / total * 100).toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              radius: 55,
            ),
            PieChartSectionData(
              value: other,
              color: AppTheme.warning,
              title: '${(other / total * 100).toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              radius: 55,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Income Sources',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 160,
              width: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pieLegend(context, 'Business', AppTheme.primary),
                  const SizedBox(height: 8),
                  _pieLegend(context, 'Investments', const Color(0xFF6366F1)),
                  const SizedBox(height: 8),
                  _pieLegend(context, 'Employment', AppTheme.success),
                  const SizedBox(height: 8),
                  _pieLegend(context, 'Other', AppTheme.warning),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssetAllocationChart(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asset Allocation',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 160,
              width: 160,
              child: PieChart(
                PieChartData(
                  sections: _assetSections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pieLegend(context, 'Fixed Assets', AppTheme.fixedAssetColor),
                  const SizedBox(height: 8),
                  _pieLegend(
                    context,
                    'Current Assets',
                    AppTheme.currentAssetColor,
                  ),
                  const SizedBox(height: 8),
                  _pieLegend(
                    context,
                    'Financial Assets',
                    AppTheme.appreciatingColor,
                  ),
                  const SizedBox(height: 8),
                  _pieLegend(
                    context,
                    'Digital Assets',
                    AppTheme.intangibleColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legend(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _pieLegend(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
