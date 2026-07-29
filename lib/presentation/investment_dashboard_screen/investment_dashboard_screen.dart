import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class InvestmentDashboardScreen extends StatefulWidget {
  const InvestmentDashboardScreen({super.key});

  @override
  State<InvestmentDashboardScreen> createState() =>
      _InvestmentDashboardScreenState();
}

class _InvestmentDashboardScreenState extends State<InvestmentDashboardScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;

  List<Map<String, dynamic>> _portfolios = [];
  List<Map<String, dynamic>> _investments = [];
  Map<String, dynamic>? _selectedPortfolio;

  double _totalInvested = 0;
  double _currentValue = 0;
  double _totalProfit = 0;
  double _overallRoi = 0;

  final Map<String, Color> _categoryColors = {
    'real_estate': const Color(0xFF1A5F7A),
    'business': const Color(0xFF2D9CDB),
    'stocks': const Color(0xFF27AE60),
    'agriculture': const Color(0xFFF2994A),
    'digital': const Color(0xFF9B51E0),
    'other': const Color(0xFF828282),
  };

  final Map<String, String> _categoryLabels = {
    'real_estate': 'Real Estate',
    'business': 'Business',
    'stocks': 'Stocks & Bonds',
    'agriculture': 'Agriculture',
    'digital': 'Digital Assets',
    'other': 'Other',
  };

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

      // Run queries independently so one failure doesn't block the other
      List<dynamic> portfolios = [];
      List<dynamic> investments = [];

      try {
        portfolios = await _client
            .from('investment_portfolios')
            .select()
            .eq('owner_id', userId)
            .eq('is_active', true)
            .order('created_at', ascending: false);
      } catch (_) {}

      try {
        investments = await _client
            .from('investments')
            .select()
            .eq('owner_id', userId)
            .eq('is_active', true)
            .eq('status', 'active')
            .order('current_value', ascending: false);
      } catch (_) {}

      double totalInv = 0, curVal = 0;
      for (final inv in investments) {
        totalInv += (inv['initial_value'] as num?)?.toDouble() ?? 0;
        curVal += (inv['current_value'] as num?)?.toDouble() ?? 0;
      }

      setState(() {
        _portfolios = List<Map<String, dynamic>>.from(portfolios);
        _investments = List<Map<String, dynamic>>.from(investments);
        _selectedPortfolio = _portfolios.isNotEmpty ? _portfolios.first : null;
        _totalInvested = totalInv;
        _currentValue = curVal;
        _totalProfit = curVal - totalInv;
        _overallRoi = totalInv > 0 ? (_totalProfit / totalInv) * 100 : 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, double> _getCategoryAllocation() {
    final Map<String, double> allocation = {};
    for (final inv in _investments) {
      final cat = inv['category'] as String? ?? 'other';
      final val = (inv['current_value'] as num?)?.toDouble() ?? 0;
      allocation[cat] = (allocation[cat] ?? 0) + val;
    }
    return allocation;
  }

  List<Map<String, dynamic>> _getTopInvestments() {
    final sorted = List<Map<String, dynamic>>.from(_investments);
    sorted.sort((a, b) {
      final aRoi = _calcRoi(a);
      final bRoi = _calcRoi(b);
      return bRoi.compareTo(aRoi);
    });
    return sorted.take(5).toList();
  }

  double _calcRoi(Map<String, dynamic> inv) {
    final initial = (inv['initial_value'] as num?)?.toDouble() ?? 0;
    final current = (inv['current_value'] as num?)?.toDouble() ?? 0;
    if (initial == 0) return 0;
    return ((current - initial) / initial) * 100;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return 'TSh ${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return 'TSh ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'TSh ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading investment data...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(theme),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPortfolioSummaryCard(theme),
                          const SizedBox(height: 20),
                          _buildMetricsRow(theme),
                          const SizedBox(height: 20),
                          _buildAllocationSection(theme),
                          const SizedBox(height: 20),
                          _buildPerformanceRanking(theme),
                          const SizedBox(height: 20),
                          _buildAiInsights(theme),
                          const SizedBox(height: 20),
                          _buildQuickActions(theme),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addInvestmentScreen),
        backgroundColor: const Color(0xFF1A5F7A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Investment',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Investments',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: CustomIconWidget(
            iconName: 'analytics',
            color: theme.colorScheme.onSurface,
            size: 22,
          ),
          onPressed: () =>
              context.push(AppRoutes.investmentPortfolioAnalysisScreen),
        ),
        IconButton(
          icon: CustomIconWidget(
            iconName: 'psychology',
            color: const Color(0xFF1A5F7A),
            size: 22,
          ),
          onPressed: () => context.push(AppRoutes.aiInvestmentAdvisorScreen),
        ),
      ],
    );
  }

  Widget _buildPortfolioSummaryCard(ThemeData theme) {
    final isProfit = _totalProfit >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3B4F), Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5F7A).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Portfolio Value',
                style: GoogleFonts.manrope(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_investments.length} investments',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(_currentValue),
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryChip(
                'Invested',
                _formatCurrency(_totalInvested),
                Colors.white60,
              ),
              const SizedBox(width: 16),
              _buildSummaryChip(
                isProfit ? 'Profit' : 'Loss',
                _formatCurrency(_totalProfit.abs()),
                isProfit ? const Color(0xFF6FCF97) : const Color(0xFFEB5757),
              ),
              const SizedBox(width: 16),
              _buildSummaryChip(
                'ROI',
                '${_overallRoi.toStringAsFixed(1)}%',
                isProfit ? const Color(0xFF6FCF97) : const Color(0xFFEB5757),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(ThemeData theme) {
    final portfolioCount = _portfolios.length;
    final activeCount = _investments
        .where((i) => i['status'] == 'active')
        .length;
    final avgRoi = _investments.isNotEmpty
        ? _investments.fold<double>(0, (s, i) => s + _calcRoi(i)) /
              _investments.length
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            'Portfolios',
            '$portfolioCount',
            'account_balance_wallet',
            const Color(0xFF1A5F7A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            theme,
            'Active',
            '$activeCount',
            'trending_up',
            const Color(0xFF27AE60),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            theme,
            'Avg ROI',
            '${avgRoi.toStringAsFixed(1)}%',
            'percent',
            const Color(0xFFF2994A),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    String icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationSection(ThemeData theme) {
    final allocation = _getCategoryAllocation();
    if (allocation.isEmpty) return const SizedBox.shrink();

    final total = allocation.values.fold<double>(0, (s, v) => s + v);
    final sections = allocation.entries.map((e) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;
      return PieChartSectionData(
        value: e.value,
        color: _categoryColors[e.key] ?? const Color(0xFF828282),
        title: '${pct.toStringAsFixed(0)}%',
        radius: 55,
        titleStyle: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asset Allocation',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: allocation.entries.map((e) {
                    final pct = total > 0 ? (e.value / total) * 100 : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color:
                                  _categoryColors[e.key] ??
                                  const Color(0xFF828282),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _categoryLabels[e.key] ?? e.key,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRanking(ThemeData theme) {
    final top = _getTopInvestments();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance Ranking',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.push(AppRoutes.investmentPortfolioAnalysisScreen),
              child: Text(
                'View All',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: const Color(0xFF1A5F7A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...top.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final inv = entry.value;
          final roi = _calcRoi(inv);
          final isPositive = roi >= 0;
          final cat = inv['category'] as String? ?? 'other';
          return GestureDetector(
            onTap: () =>
                context.push(AppRoutes.investmentDetailsScreen, extra: inv),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFF2C94C).withAlpha(30)
                          : theme.colorScheme.outline.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: rank == 1
                              ? const Color(0xFFF2C94C)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _categoryColors[cat] ?? const Color(0xFF828282),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv['name'] as String? ?? '',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _categoryLabels[cat] ?? cat,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(
                          (inv['current_value'] as num?)?.toDouble() ?? 0,
                        ),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xFF27AE60).withAlpha(20)
                              : const Color(0xFFEB5757).withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${roi.toStringAsFixed(1)}%',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isPositive
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFEB5757),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAiInsights(ThemeData theme) {
    final concentration = _getCategoryAllocation();
    final total = concentration.values.fold<double>(0, (s, v) => s + v);
    String topCat = '';
    double topPct = 0;
    for (final e in concentration.entries) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;
      if (pct > topPct) {
        topPct = pct;
        topCat = _categoryLabels[e.key] ?? e.key;
      }
    }

    final insights = [
      if (topPct > 60)
        '⚠️ ${topPct.toStringAsFixed(0)}% of your portfolio is in $topCat. Consider diversifying to reduce concentration risk.',
      if (_overallRoi > 20)
        '🚀 Excellent! Your portfolio ROI of ${_overallRoi.toStringAsFixed(1)}% significantly outperforms the market average.',
      if (_investments.any((i) => _calcRoi(i) < 0))
        '📉 ${_investments.where((i) => _calcRoi(i) < 0).length} investment(s) are currently in loss. Review exit strategy.',
      '💡 Your total wealth from investments is ${_formatCurrency(_currentValue)}. Keep compounding for long-term growth.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A5F7A).withAlpha(15),
            const Color(0xFF2D9CDB).withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A5F7A).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF1A5F7A), size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Investment Insights',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A5F7A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                insight,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => context.push(AppRoutes.aiInvestmentAdvisorScreen),
            child: Text(
              'Ask AI Advisor →',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A5F7A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    final actions = [
      {
        'label': 'Add Investment',
        'icon': 'add_circle_outline',
        'route': AppRoutes.addInvestmentScreen,
        'color': const Color(0xFF1A5F7A),
      },
      {
        'label': 'Portfolio Analysis',
        'icon': 'pie_chart',
        'route': AppRoutes.investmentPortfolioAnalysisScreen,
        'color': const Color(0xFF2D9CDB),
      },
      {
        'label': 'Simulator',
        'icon': 'calculate',
        'route': AppRoutes.investmentSimulatorScreen,
        'color': const Color(0xFFF2994A),
      },
      {
        'label': 'AI Advisor',
        'icon': 'psychology',
        'route': AppRoutes.aiInvestmentAdvisorScreen,
        'color': const Color(0xFF9B51E0),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            final color = action['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => context.push(action['route'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withAlpha(50)),
                  ),
                  child: Column(
                    children: [
                      CustomIconWidget(
                        iconName: action['icon'] as String,
                        color: color,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action['label'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
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
    );
  }
}