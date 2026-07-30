import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class InvestmentPortfolioAnalysisScreen extends StatefulWidget {
  const InvestmentPortfolioAnalysisScreen({super.key});

  @override
  State<InvestmentPortfolioAnalysisScreen> createState() =>
      _InvestmentPortfolioAnalysisScreenState();
}

class _InvestmentPortfolioAnalysisScreenState
    extends State<InvestmentPortfolioAnalysisScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _investments = [];
  List<Map<String, dynamic>> _riskAnalyses = [];

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
      if (userId == null) return;

      final results = await Future.wait(<Future<dynamic>>[
        _client
            .from('investments')
            .select()
            .eq('owner_id', userId)
            .eq('is_active', true)
            .order('current_value', ascending: false),
        _client
            .from('investment_risk_analysis')
            .select('*, investments!inner(owner_id)')
            .eq('investments.owner_id', userId),
      ]);

      setState(() {
        _investments = List<Map<String, dynamic>>.from(results[0]);
        _riskAnalyses = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _calcRoi(Map<String, dynamic> inv) {
    final initial = (inv['initial_value'] as num?)?.toDouble() ?? 0;
    final current = (inv['current_value'] as num?)?.toDouble() ?? 0;
    if (initial == 0) return 0;
    return ((current - initial) / initial) * 100;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'TSh ${(value / 1000000).toStringAsFixed(1)}M';
    }
    return 'TSh ${value.toStringAsFixed(0)}';
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

  double _getConcentrationRisk() {
    final allocation = _getCategoryAllocation();
    final total = allocation.values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return 0;
    double maxPct = 0;
    for (final v in allocation.values) {
      final pct = (v / total) * 100;
      if (pct > maxPct) maxPct = pct;
    }
    return maxPct;
  }

  double _getAvgRiskScore() {
    if (_riskAnalyses.isEmpty) return 50;
    final sum = _riskAnalyses.fold<double>(
      0,
      (s, r) => s + ((r['risk_score'] as num?)?.toDouble() ?? 50),
    );
    return sum / _riskAnalyses.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Portfolio Analysis',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildRiskOverview(theme),
                  const SizedBox(height: 20),
                  _buildAllocationChart(theme),
                  const SizedBox(height: 20),
                  _buildRiskBreakdown(theme),
                  const SizedBox(height: 20),
                  _buildInvestmentComparison(theme),
                  const SizedBox(height: 20),
                  _buildRecommendations(theme),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildRiskOverview(ThemeData theme) {
    final avgRisk = _getAvgRiskScore();
    final concentration = _getConcentrationRisk();
    final totalInvested = _investments.fold<double>(
      0,
      (s, i) => s + ((i['initial_value'] as num?)?.toDouble() ?? 0),
    );
    final currentValue = _investments.fold<double>(
      0,
      (s, i) => s + ((i['current_value'] as num?)?.toDouble() ?? 0),
    );
    final overallRoi = totalInvested > 0
        ? ((currentValue - totalInvested) / totalInvested) * 100
        : 0.0;

    Color riskColor;
    String riskLabel;
    if (avgRisk < 30) {
      riskColor = const Color(0xFF27AE60);
      riskLabel = 'Low Risk';
    } else if (avgRisk < 55) {
      riskColor = const Color(0xFFF2994A);
      riskLabel = 'Moderate Risk';
    } else if (avgRisk < 75) {
      riskColor = const Color(0xFFEB5757);
      riskLabel = 'High Risk';
    } else {
      riskColor = const Color(0xFF9B51E0);
      riskLabel = 'Very High Risk';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B4F), Color(0xFF1A5F7A)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Health',
                      style: GoogleFonts.manrope(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      riskLabel,
                      style: GoogleFonts.manrope(
                        color: riskColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
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
                      value: avgRisk / 100,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      strokeWidth: 8,
                    ),
                    Text(
                      avgRisk.toStringAsFixed(0),
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _overviewStat('Total Invested', _formatCurrency(totalInvested)),
              _overviewStat('Current Value', _formatCurrency(currentValue)),
              _overviewStat('Overall ROI', '${overallRoi.toStringAsFixed(1)}%'),
              _overviewStat(
                'Concentration',
                '${concentration.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationChart(ThemeData theme) {
    final allocation = _getCategoryAllocation();
    if (allocation.isEmpty) return const SizedBox.shrink();
    final total = allocation.values.fold<double>(0, (s, v) => s + v);

    final sections = allocation.entries.map((e) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;
      return PieChartSectionData(
        value: e.value,
        color: _categoryColors[e.key] ?? const Color(0xFF828282),
        title: '${pct.toStringAsFixed(0)}%',
        radius: 65,
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
                    centerSpaceRadius: 35,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: allocation.entries.map((e) {
                    final pct = total > 0 ? (e.value / total) * 100 : 0.0;
                    final isHighConcentration = pct > 60;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
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
                              style: GoogleFonts.manrope(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHighConcentration)
                            const Icon(
                              Icons.warning_amber,
                              size: 14,
                              color: Color(0xFFF2994A),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isHighConcentration
                                  ? const Color(0xFFF2994A)
                                  : theme.colorScheme.onSurface,
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

  Widget _buildRiskBreakdown(ThemeData theme) {
    if (_riskAnalyses.isEmpty) return const SizedBox.shrink();

    final avgMarket =
        _riskAnalyses.fold<double>(
          0,
          (s, r) => s + ((r['market_risk'] as num?)?.toDouble() ?? 50),
        ) /
        _riskAnalyses.length;
    final avgLiquidity =
        _riskAnalyses.fold<double>(
          0,
          (s, r) => s + ((r['liquidity_risk'] as num?)?.toDouble() ?? 50),
        ) /
        _riskAnalyses.length;
    final avgOperational =
        _riskAnalyses.fold<double>(
          0,
          (s, r) => s + ((r['operational_risk'] as num?)?.toDouble() ?? 50),
        ) /
        _riskAnalyses.length;
    final avgConcentration =
        _riskAnalyses.fold<double>(
          0,
          (s, r) => s + ((r['concentration_risk'] as num?)?.toDouble() ?? 50),
        ) /
        _riskAnalyses.length;

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
            'Risk Breakdown',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _riskBar(theme, 'Market Risk', avgMarket),
          _riskBar(theme, 'Liquidity Risk', avgLiquidity),
          _riskBar(theme, 'Operational Risk', avgOperational),
          _riskBar(theme, 'Concentration Risk', avgConcentration),
        ],
      ),
    );
  }

  Widget _riskBar(ThemeData theme, String label, double score) {
    Color barColor;
    if (score < 30) {
      barColor = const Color(0xFF27AE60);
    } else if (score < 55) {
      barColor = const Color(0xFFF2994A);
    } else {
      barColor = const Color(0xFFEB5757);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                '${score.toStringAsFixed(0)}/100',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: theme.colorScheme.outline.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentComparison(ThemeData theme) {
    if (_investments.length < 2) return const SizedBox.shrink();

    final sorted = List<Map<String, dynamic>>.from(_investments);
    sorted.sort((a, b) => _calcRoi(b).compareTo(_calcRoi(a)));

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
            'Investment Comparison',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final inv = entry.value;
            final roi = _calcRoi(inv);
            final isPositive = roi >= 0;
            final cat = inv['category'] as String? ?? 'other';
            final catColor = _categoryColors[cat] ?? const Color(0xFF828282);
            final maxRoi = _calcRoi(sorted.first).abs();
            final barWidth = maxRoi > 0 ? roi.abs() / maxRoi : 0.0;

            return GestureDetector(
              onTap: () =>
                  context.push(AppRoutes.investmentDetailsScreen, extra: inv),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$rank',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: rank == 1
                                ? const Color(0xFFF2C94C)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            inv['name'] as String? ?? '',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${isPositive ? '+' : ''}${roi.toStringAsFixed(1)}%',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isPositive
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFEB5757),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: barWidth.clamp(0.0, 1.0),
                        backgroundColor: theme.colorScheme.outline.withAlpha(
                          20,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPositive
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFEB5757),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendations(ThemeData theme) {
    final concentration = _getConcentrationRisk();
    final avgRisk = _getAvgRiskScore();
    final allocation = _getCategoryAllocation();
    final total = allocation.values.fold<double>(0, (s, v) => s + v);
    String topCat = '';
    double topPct = 0;
    for (final e in allocation.entries) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;
      if (pct > topPct) {
        topPct = pct;
        topCat = _categoryLabels[e.key] ?? e.key;
      }
    }

    final recs = <Map<String, dynamic>>[];
    if (concentration > 60) {
      recs.add({
        'icon': 'warning_amber',
        'color': const Color(0xFFF2994A),
        'title': 'High Concentration Risk',
        'body':
            '${topPct.toStringAsFixed(0)}% of your portfolio is in $topCat. Diversify into other asset classes to reduce risk.',
        'priority': 'High',
      });
    }
    if (avgRisk > 65) {
      recs.add({
        'icon': 'shield',
        'color': const Color(0xFFEB5757),
        'title': 'Portfolio Risk Too High',
        'body':
            'Average risk score is ${avgRisk.toStringAsFixed(0)}/100. Consider adding low-risk assets like real estate or bonds.',
        'priority': 'High',
      });
    }
    if (!allocation.containsKey('real_estate') ||
        (allocation['real_estate'] ?? 0) / total < 0.2) {
      recs.add({
        'icon': 'home_work',
        'color': const Color(0xFF1A5F7A),
        'title': 'Add Real Estate Exposure',
        'body':
            'Real estate provides stable returns and inflation protection. Consider allocating 20–30% to property.',
        'priority': 'Medium',
      });
    }
    recs.add({
      'icon': 'trending_up',
      'color': const Color(0xFF27AE60),
      'title': 'Keep Compounding',
      'body':
          'Reinvest distributions and dividends to maximize compound growth over time.',
      'priority': 'Low',
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Recommendations',
          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...recs.map((rec) {
          final color = rec['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: rec['icon'] as String,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rec['title'] as String,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
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
                              rec['priority'] as String,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec['body'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
