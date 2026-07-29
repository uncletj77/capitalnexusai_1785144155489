import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';

/// Interactive drill-down graph widget.
/// Supports daily/weekly/monthly/quarterly/yearly filtering.
/// Selecting any bar/point reveals the underlying transactions.
class InteractiveDrillDownGraph extends StatefulWidget {
  final String
  graphType; // 'cash_flow' | 'net_worth' | 'income_expense' | 'investment_performance'
  final Map<String, dynamic> graphData;
  final String title;
  final bool isLoading;
  final Function(String period)? onPeriodChanged;
  final Function(Map<String, dynamic> dataPoint)? onDrillDown;

  const InteractiveDrillDownGraph({
    super.key,
    required this.graphType,
    required this.graphData,
    required this.title,
    this.isLoading = false,
    this.onPeriodChanged,
    this.onDrillDown,
  });

  @override
  State<InteractiveDrillDownGraph> createState() =>
      _InteractiveDrillDownGraphState();
}

class _InteractiveDrillDownGraphState extends State<InteractiveDrillDownGraph>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'monthly';
  int? _touchedIndex;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, String>> _periods = [
    {'key': 'daily', 'label': 'Daily'},
    {'key': 'weekly', 'label': 'Weekly'},
    {'key': 'monthly', 'label': 'Monthly'},
    {'key': 'quarterly', 'label': 'Quarterly'},
    {'key': 'yearly', 'label': 'Yearly'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InteractiveDrillDownGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graphData != widget.graphData) {
      _animController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final textColor = isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.graphData['record_count'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.graphData['record_count']} records',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Period Filter
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _periods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final p = _periods[i];
                final isSelected = _selectedPeriod == p['key'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = p['key']!;
                      _touchedIndex = null;
                    });
                    widget.onPeriodChanged?.call(p['key']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.outlineLight,
                      ),
                    ),
                    child: Text(
                      p['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : mutedColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Chart
          widget.isLoading
              ? _buildLoadingState()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildChart(isDark, textColor, mutedColor),
                ),

          // Drill-down hint
          if (_touchedIndex != null) _buildDrillDownHint(textColor, mutedColor),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark, Color textColor, Color mutedColor) {
    final dataPoints = widget.graphData['data_points'] as List? ?? [];
    if (dataPoints.isEmpty) return _buildEmptyState(mutedColor);

    switch (widget.graphType) {
      case 'cash_flow':
      case 'income_expense':
        return _buildBarChart(dataPoints, isDark, textColor, mutedColor);
      case 'net_worth':
        return _buildLineChart(dataPoints, isDark, textColor, mutedColor);
      case 'investment_performance':
        return _buildInvestmentChart(dataPoints, isDark, textColor, mutedColor);
      default:
        return _buildBarChart(dataPoints, isDark, textColor, mutedColor);
    }
  }

  Widget _buildBarChart(
    List dataPoints,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    final maxVal = dataPoints.fold<double>(0, (max, d) {
      final income = (d['income'] as num?)?.toDouble() ?? 0;
      final expense = (d['expense'] as num?)?.toDouble() ?? 0;
      return [max, income, expense].reduce((a, b) => a > b ? a : b);
    });

    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.2,
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: (event, response) {
                if (event is FlTapUpEvent && response?.spot != null) {
                  final idx = response!.spot!.touchedBarGroupIndex;
                  setState(() => _touchedIndex = idx);
                  if (idx < dataPoints.length) {
                    widget.onDrillDown?.call(
                      Map<String, dynamic>.from(dataPoints[idx] as Map),
                    );
                  }
                }
              },
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: AppTheme.primary.withAlpha(230),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex >= dataPoints.length) return null;
                  final d = dataPoints[groupIndex] as Map;
                  final label = d['label'] as String? ?? '';
                  final income = (d['income'] as num?)?.toDouble() ?? 0;
                  final expense = (d['expense'] as num?)?.toDouble() ?? 0;
                  return BarTooltipItem(
                    '$label\nIncome: ${_fmt(income)}\nExpense: ${_fmt(expense)}',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) => Text(
                    _fmtShort(value),
                    style: GoogleFonts.inter(fontSize: 9, color: mutedColor),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= dataPoints.length) {
                      return const SizedBox.shrink();
                    }
                    final label =
                        (dataPoints[idx] as Map)['label'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _shortLabel(label),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: mutedColor,
                        ),
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
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.outlineLight.withAlpha(128),
                strokeWidth: 0.8,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(dataPoints.length, (i) {
              final d = dataPoints[i] as Map;
              final income = (d['income'] as num?)?.toDouble() ?? 0;
              final expense = (d['expense'] as num?)?.toDouble() ?? 0;
              final isTouched = _touchedIndex == i;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: income,
                    color: AppTheme.successLight.withOpacity(
                      isTouched ? 1.0 : 0.8,
                    ),
                    width: 8,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  BarChartRodData(
                    toY: expense,
                    color: AppTheme.dangerLight.withOpacity(
                      isTouched ? 1.0 : 0.8,
                    ),
                    width: 8,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(
    List dataPoints,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    if (dataPoints.isEmpty) return _buildEmptyState(mutedColor);

    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final d = dataPoints[i] as Map;
      final val = (d['net_worth'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), val));
    }

    final maxY = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m) * 1.2;
    final minY =
        spots.fold<double>(double.infinity, (m, s) => s.y < m ? s.y : m) * 0.8;

    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LineChart(
          LineChartData(
            minY: minY < 0 ? minY : 0,
            maxY: maxY,
            lineTouchData: LineTouchData(
              enabled: true,
              touchCallback: (event, response) {
                if (event is FlTapUpEvent && response?.lineBarSpots != null) {
                  final idx = response!.lineBarSpots!.first.spotIndex;
                  setState(() => _touchedIndex = idx);
                  if (idx < dataPoints.length) {
                    widget.onDrillDown?.call(
                      Map<String, dynamic>.from(dataPoints[idx] as Map),
                    );
                  }
                }
              },
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: AppTheme.primary.withAlpha(230),
                getTooltipItems: (spots) => spots.map((s) {
                  final idx = s.spotIndex;
                  if (idx >= dataPoints.length) return null;
                  final d = dataPoints[idx] as Map;
                  return LineTooltipItem(
                    '${d['label']}\n${_fmt(s.y)}',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) => Text(
                    _fmtShort(value),
                    style: GoogleFonts.inter(fontSize: 9, color: mutedColor),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= dataPoints.length) {
                      return const SizedBox.shrink();
                    }
                    final label =
                        (dataPoints[idx] as Map)['label'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _shortLabel(label),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: mutedColor,
                        ),
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
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.outlineLight.withAlpha(128),
                strokeWidth: 0.8,
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.primary,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: _touchedIndex == index ? 5 : 3,
                        color: AppTheme.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primary.withAlpha(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentChart(
    List dataPoints,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    if (dataPoints.isEmpty) return _buildEmptyState(mutedColor);

    final sections = <PieChartSectionData>[];
    final colors = [
      AppTheme.primary,
      AppTheme.primaryLight,
      AppTheme.successLight,
      AppTheme.warningLight,
      AppTheme.dangerLight,
      const Color(0xFF8B5CF6),
    ];

    double total = dataPoints.fold<double>(
      0,
      (s, d) => s + ((d['current_value'] as num?)?.toDouble() ?? 0),
    );

    for (int i = 0; i < dataPoints.length; i++) {
      final d = dataPoints[i] as Map;
      final val = (d['current_value'] as num?)?.toDouble() ?? 0;
      final pct = total > 0 ? val / total * 100 : 0.0;
      final isTouched = _touchedIndex == i;

      sections.add(
        PieChartSectionData(
          value: val,
          color: colors[i % colors.length],
          radius: isTouched ? 60 : 50,
          title: '${pct.toStringAsFixed(0)}%',
          titleStyle: GoogleFonts.inter(
            fontSize: isTouched ? 12 : 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response?.touchedSection != null) {
                      final idx = response!.touchedSection!.touchedSectionIndex;
                      setState(() => _touchedIndex = idx);
                      if (idx >= 0 && idx < dataPoints.length) {
                        widget.onDrillDown?.call(
                          Map<String, dynamic>.from(dataPoints[idx] as Map),
                        );
                      }
                    }
                  },
                ),
                centerSpaceRadius: 35,
                sectionsSpace: 2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(dataPoints.length.clamp(0, 5), (i) {
                final d = dataPoints[i] as Map;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _truncate(d['label'] as String? ?? '', 12),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillDownHint(Color textColor, Color mutedColor) {
    final dataPoints = widget.graphData['data_points'] as List? ?? [];
    if (_touchedIndex == null || _touchedIndex! >= dataPoints.length) {
      return const SizedBox.shrink();
    }

    final d = dataPoints[_touchedIndex!] as Map;
    final transactions = d['transactions'] as List? ?? [];
    final label = d['label'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomIconWidget(
                iconName: 'info',
                color: AppTheme.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Drill-down: $label',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _touchedIndex = null),
                child: const CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.primary,
                  size: 14,
                ),
              ),
            ],
          ),
          if (transactions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${transactions.length} transaction(s) in this period:',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primary),
            ),
            const SizedBox(height: 4),
            ...transactions.take(3).map((t) {
              final txn = t as Map;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        txn['description'] as String? ??
                            txn['category'] as String? ??
                            'Transaction',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _fmt((txn['amount'] as num?)?.toDouble() ?? 0),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: txn['type'] == 'expense'
                            ? AppTheme.danger
                            : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (transactions.length > 3)
              Text(
                '+ ${transactions.length - 3} more',
                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.primary),
              ),
          ] else if (d['income'] != null || d['net_worth'] != null) ...[
            const SizedBox(height: 6),
            if (d['income'] != null)
              _drillRow(
                'Income',
                _fmt((d['income'] as num?)?.toDouble() ?? 0),
                AppTheme.success,
              ),
            if (d['expense'] != null)
              _drillRow(
                'Expense',
                _fmt((d['expense'] as num?)?.toDouble() ?? 0),
                AppTheme.danger,
              ),
            if (d['net'] != null)
              _drillRow(
                'Net',
                _fmt((d['net'] as num?)?.toDouble() ?? 0),
                AppTheme.primary,
              ),
            if (d['net_worth'] != null)
              _drillRow(
                'Net Worth',
                _fmt((d['net_worth'] as num?)?.toDouble() ?? 0),
                AppTheme.primary,
              ),
          ],
        ],
      ),
    );
  }

  Widget _drillRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primary),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 180,
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color mutedColor) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'bar_chart',
              color: mutedColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No data available for this period',
              style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Add transactions to see your analytics',
              style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
            ),
          ],
        ),
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

  String _fmtShort(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(0)}B';
    }
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  String _shortLabel(String label) {
    if (label.length <= 7) return label;
    // For monthly: "2025-01" → "Jan"
    if (label.contains('-') && label.length == 7) {
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
      final parts = label.split('-');
      if (parts.length == 2) {
        final m = int.tryParse(parts[1]);
        if (m != null && m >= 1 && m <= 12) return months[m - 1];
      }
    }
    return label.substring(0, 6);
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;
}
