import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class InvestmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> investment;
  const InvestmentDetailsScreen({super.key, required this.investment});

  @override
  State<InvestmentDetailsScreen> createState() =>
      _InvestmentDetailsScreenState();
}

class _InvestmentDetailsScreenState extends State<InvestmentDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.client;
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _returnsHistory = [];
  Map<String, dynamic>? _riskAnalysis;
  late Map<String, dynamic> _inv;

  @override
  void initState() {
    super.initState();
    _inv = Map<String, dynamic>.from(widget.investment);
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final invId = _inv['id'] as String;
      final results = await Future.wait(<Future<dynamic>>[
        _client
            .from('investment_transactions')
            .select()
            .eq('investment_id', invId)
            .order('transaction_date', ascending: false),
        _client
            .from('investment_returns_history')
            .select()
            .eq('investment_id', invId)
            .order('snapshot_date', ascending: true),
        _client
            .from('investment_risk_analysis')
            .select()
            .eq('investment_id', invId)
            .order('analysis_date', ascending: false)
            .limit(1),
      ]);

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(results[0]);
        _returnsHistory = List<Map<String, dynamic>>.from(results[1]);
        _riskAnalysis = (results[2] as List).isNotEmpty ? results[2][0] : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _initialValue => (_inv['initial_value'] as num?)?.toDouble() ?? 0;
  double get _currentValue => (_inv['current_value'] as num?)?.toDouble() ?? 0;
  double get _profit => _currentValue - _initialValue;
  double get _roi => _initialValue > 0 ? (_profit / _initialValue) * 100 : 0;

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'TSh ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'TSh ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  Future<void> _recordTransaction() async {
    final amountCtrl = TextEditingController();
    String type = 'distribution';
    final descCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Transaction',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children:
                    [
                      'contribution',
                      'distribution',
                      'dividend',
                      'rental_income',
                    ].map((t) {
                      final labels = {
                        'contribution': 'Contribution',
                        'distribution': 'Distribution',
                        'dividend': 'Dividend',
                        'rental_income': 'Rental Income',
                      };
                      return ChoiceChip(
                        label: Text(labels[t]!),
                        selected: type == t,
                        onSelected: (_) => setS(() => type = t),
                        selectedColor: const Color(0xFF1A5F7A),
                        labelStyle: GoogleFonts.manrope(
                          color: type == t ? Colors.white : null,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (TSh)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    if (amount <= 0) return;
                    try {
                      final userId = _client.auth.currentUser?.id;
                      await _client.from('investment_transactions').insert({
                        'investment_id': _inv['id'],
                        'owner_id': userId,
                        'type': type,
                        'amount': amount,
                        'description': descCtrl.text.trim(),
                        'transaction_date': DateTime.now()
                            .toIso8601String()
                            .split('T')[0],
                      });
                      Navigator.pop(ctx);
                      _loadDetails();
                    } catch (_) {}
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5F7A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Record',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfit = _profit >= 0;
    final cat = _inv['category'] as String? ?? 'other';
    final catColors = {
      'real_estate': const Color(0xFF1A5F7A),
      'business': const Color(0xFF2D9CDB),
      'stocks': const Color(0xFF27AE60),
      'agriculture': const Color(0xFFF2994A),
      'digital': const Color(0xFF9B51E0),
      'other': const Color(0xFF828282),
    };
    final catColor = catColors[cat] ?? const Color(0xFF828282);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading details...')
          : NestedScrollView(
              headerSliverBuilder: (ctx, inner) => [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: catColor,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => context.push(
                        AppRoutes.addInvestmentScreen,
                        extra: _inv,
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [catColor.withAlpha(220), catColor],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _inv['name'] as String? ?? '',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _inv['location'] as String? ?? '',
                                style: GoogleFonts.manrope(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _headerStat(
                                    'Current Value',
                                    _formatCurrency(_currentValue),
                                    Colors.white,
                                  ),
                                  const SizedBox(width: 24),
                                  _headerStat(
                                    isProfit ? 'Profit' : 'Loss',
                                    _formatCurrency(_profit.abs()),
                                    isProfit
                                        ? const Color(0xFF6FCF97)
                                        : const Color(0xFFEB5757),
                                  ),
                                  const SizedBox(width: 24),
                                  _headerStat(
                                    'ROI',
                                    '${_roi.toStringAsFixed(1)}%',
                                    isProfit
                                        ? const Color(0xFF6FCF97)
                                        : const Color(0xFFEB5757),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Performance'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(theme),
                  _buildPerformanceTab(theme),
                  _buildHistoryTab(theme),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recordTransaction,
        backgroundColor: catColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _headerStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(color: Colors.white54, fontSize: 11),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final riskLevel = _inv['risk_level'] as String? ?? 'medium';
    final riskColors = {
      'low': const Color(0xFF27AE60),
      'medium': const Color(0xFFF2994A),
      'high': const Color(0xFFEB5757),
      'very_high': const Color(0xFF9B51E0),
    };
    final riskColor = riskColors[riskLevel] ?? const Color(0xFFF2994A);

    // Annualized return calculation
    final investDate =
        DateTime.tryParse(_inv['investment_date'] ?? '') ??
        DateTime.now().subtract(const Duration(days: 365));
    final years = DateTime.now().difference(investDate).inDays / 365;
    final annualizedRoi = years > 0 && _initialValue > 0
        ? ((_currentValue / _initialValue).toDouble() == 0
              ? 0.0
              : ((_currentValue / _initialValue) - 1) / years * 100)
        : 0.0;

    // Cash returns
    final cashReturns = _transactions
        .where(
          (t) =>
              ['distribution', 'dividend', 'rental_income'].contains(t['type']),
        )
        .fold<double>(
          0,
          (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(theme, 'Investment Details', [
          _infoRow(theme, 'Category', _inv['category'] ?? ''),
          _infoRow(theme, 'Status', _inv['status'] ?? ''),
          _infoRow(
            theme,
            'Ownership',
            '${_inv['ownership_percentage'] ?? 100}%',
          ),
          _infoRow(theme, 'Investment Date', _inv['investment_date'] ?? ''),
          if (_inv['target_exit_date'] != null)
            _infoRow(theme, 'Target Exit', _inv['target_exit_date']),
          if (_inv['location'] != null &&
              (_inv['location'] as String).isNotEmpty)
            _infoRow(theme, 'Location', _inv['location']),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard(theme, 'Financial Summary', [
          _infoRow(theme, 'Initial Capital', _formatCurrency(_initialValue)),
          _infoRow(theme, 'Current Value', _formatCurrency(_currentValue)),
          _infoRow(
            theme,
            'Absolute Profit',
            _formatCurrency(_profit.abs()),
            valueColor: _profit >= 0
                ? const Color(0xFF27AE60)
                : const Color(0xFFEB5757),
          ),
          _infoRow(
            theme,
            'ROI',
            '${_roi.toStringAsFixed(2)}%',
            valueColor: _profit >= 0
                ? const Color(0xFF27AE60)
                : const Color(0xFFEB5757),
          ),
          _infoRow(
            theme,
            'Annualized Return',
            '${annualizedRoi.toStringAsFixed(1)}% p.a.',
          ),
          _infoRow(theme, 'Cash Distributions', _formatCurrency(cashReturns)),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard(theme, 'Risk Profile', [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Risk Level',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  riskLevel.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          if (_riskAnalysis != null) ...[
            const SizedBox(height: 8),
            Text(
              _riskAnalysis!['recommendations'] as String? ?? '',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
        ]),
        if (_inv['notes'] != null && (_inv['notes'] as String).isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoCard(theme, 'Notes', [
            Text(
              _inv['notes'] as String,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ]),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPerformanceTab(ThemeData theme) {
    if (_returnsHistory.isEmpty) {
      return Center(
        child: Text(
          'No performance history yet',
          style: GoogleFonts.manrope(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final spots = _returnsHistory.asMap().entries.map((e) {
      final val = (e.value['value'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), val / 1000000);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Value Growth (TSh M)',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
                        color: theme.colorScheme.outline.withAlpha(30),
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
                            style: GoogleFonts.manrope(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF1A5F7A),
                        barWidth: 2.5,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF1A5F7A).withAlpha(30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Snapshot History',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ..._returnsHistory.reversed.map((r) {
          final val = (r['value'] as num?)?.toDouble() ?? 0;
          final profit = (r['profit'] as num?)?.toDouble() ?? 0;
          final roi = (r['roi_percentage'] as num?)?.toDouble() ?? 0;
          final isPos = profit >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['snapshot_date'] as String? ?? '',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatCurrency(val),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isPos ? '+' : ''}${_formatCurrency(profit.abs())}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPos
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFEB5757),
                      ),
                    ),
                    Text(
                      '${roi.toStringAsFixed(1)}% ROI',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    final typeColors = {
      'contribution': const Color(0xFF2D9CDB),
      'distribution': const Color(0xFF27AE60),
      'dividend': const Color(0xFF27AE60),
      'rental_income': const Color(0xFF27AE60),
      'sale_proceeds': const Color(0xFF9B51E0),
      'other': const Color(0xFF828282),
    };
    final typeIcons = {
      'contribution': 'arrow_downward',
      'distribution': 'arrow_upward',
      'dividend': 'payments',
      'rental_income': 'home',
      'sale_proceeds': 'sell',
      'other': 'swap_horiz',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_transactions.isEmpty)
          Center(
            child: Text(
              'No transactions yet',
              style: GoogleFonts.manrope(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ..._transactions.map((t) {
            final type = t['type'] as String? ?? 'other';
            final amount = (t['amount'] as num?)?.toDouble() ?? 0;
            final color = typeColors[type] ?? const Color(0xFF828282);
            final icon = typeIcons[type] ?? 'swap_horiz';
            final isIncome = [
              'distribution',
              'dividend',
              'rental_income',
              'sale_proceeds',
            ].contains(type);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: icon,
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
                          t['description'] as String? ??
                              type.replaceAll('_', ' '),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t['transaction_date'] as String? ?? '',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'}${_formatCurrency(amount)}',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isIncome
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFEB5757),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}