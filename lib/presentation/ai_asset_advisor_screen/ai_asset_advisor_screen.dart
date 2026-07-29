import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AiAssetAdvisorScreen extends StatefulWidget {
  const AiAssetAdvisorScreen({super.key});

  @override
  State<AiAssetAdvisorScreen> createState() => _AiAssetAdvisorScreenState();
}

class _AiAssetAdvisorScreenState extends State<AiAssetAdvisorScreen>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.client;
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _assets = [];

  // Comparison
  Map<String, dynamic>? _assetA;
  Map<String, dynamic>? _assetB;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAssets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final res = await _client
          .from('assets')
          .select()
          .eq('user_id', userId)
          .neq('asset_status', 'disposed')
          .order('current_value', ascending: false);
      setState(() {
        _assets = List<Map<String, dynamic>>.from(res);
        if (_assets.length >= 2) {
          _assetA = _assets[0];
          _assetB = _assets[1];
        } else if (_assets.length == 1) {
          _assetA = _assets[0];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _fmtTZS(double v) {
    if (v >= 1000000000) return 'TSh ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  // AI insight generation from real data
  List<Map<String, dynamic>> _generateInsights() {
    if (_assets.isEmpty) return [];
    final insights = <Map<String, dynamic>>[];

    // Best performer
    final byProfit = List<Map<String, dynamic>>.from(_assets)
      ..sort((a, b) {
        final profitA =
            (a['monthly_income'] as num).toDouble() -
            (a['monthly_expenses'] as num).toDouble();
        final profitB =
            (b['monthly_income'] as num).toDouble() -
            (b['monthly_expenses'] as num).toDouble();
        return profitB.compareTo(profitA);
      });

    if (byProfit.isNotEmpty) {
      final best = byProfit.first;
      final profit =
          (best['monthly_income'] as num).toDouble() -
          (best['monthly_expenses'] as num).toDouble();
      if (profit > 0) {
        insights.add({
          'type': 'positive',
          'icon': 'emoji_events',
          'color': AppTheme.success,
          'title': 'Top Performer',
          'message':
              '"${best['asset_name']}" generates ${_fmtTZS(profit)}/month net profit — your highest-earning asset.',
        });
      }
    }

    // Losing money
    final losing = _assets.where((a) {
      final income = (a['monthly_income'] as num).toDouble();
      final expenses = (a['monthly_expenses'] as num).toDouble();
      return expenses > income && expenses > 0;
    }).toList();

    if (losing.isNotEmpty) {
      final worst = losing.first;
      final loss =
          (worst['monthly_expenses'] as num).toDouble() -
          (worst['monthly_income'] as num).toDouble();
      insights.add({
        'type': 'warning',
        'icon': 'warning_amber',
        'color': AppTheme.warning,
        'title': 'Cost Alert',
        'message':
            '"${worst['asset_name']}" costs ${_fmtTZS(loss)}/month more than it earns. Review or dispose.',
      });
    }

    // Appreciation analysis
    final appreciating = _assets.where((a) {
      final cv = (a['current_value'] as num).toDouble();
      final pv = (a['purchase_price'] as num).toDouble();
      return pv > 0 && cv > pv;
    }).toList();

    if (appreciating.isNotEmpty) {
      final totalGain = appreciating.fold(0.0, (s, a) {
        return s +
            (a['current_value'] as num).toDouble() -
            (a['purchase_price'] as num).toDouble();
      });
      insights.add({
        'type': 'positive',
        'icon': 'trending_up',
        'color': AppTheme.primary,
        'title': 'Wealth Growth',
        'message':
            '${appreciating.length} assets have appreciated by a total of ${_fmtTZS(totalGain)} since purchase.',
      });
    }

    // Depreciation warning
    final depreciating = _assets.where((a) {
      final cv = (a['current_value'] as num).toDouble();
      final pv = (a['purchase_price'] as num).toDouble();
      final rate = (a['depreciation_rate'] as num?)?.toDouble() ?? 0;
      return pv > 0 && cv < pv && rate > 15;
    }).toList();

    if (depreciating.isNotEmpty) {
      insights.add({
        'type': 'negative',
        'icon': 'trending_down',
        'color': AppTheme.error,
        'title': 'Rapid Depreciation',
        'message':
            '${depreciating.length} asset(s) depreciating at >15%/year. Consider replacement planning.',
      });
    }

    // Total portfolio value
    final totalValue = _assets.fold(
      0.0,
      (s, a) => s + (a['current_value'] as num).toDouble(),
    );
    final totalIncome = _assets.fold(
      0.0,
      (s, a) => s + (a['monthly_income'] as num).toDouble(),
    );
    if (totalValue > 0) {
      final roi = totalIncome / totalValue * 100 * 12;
      insights.add({
        'type': 'info',
        'icon': 'analytics',
        'color': AppTheme.primary,
        'title': 'Portfolio ROI',
        'message':
            'Your asset portfolio generates an estimated ${roi.toStringAsFixed(1)}% annual return on ${_fmtTZS(totalValue)} total value.',
      });
    }

    return insights;
  }

  List<Map<String, dynamic>> _generateRecommendations() {
    final recs = <Map<String, dynamic>>[];
    if (_assets.isEmpty) return recs;

    final totalValue = _assets.fold(
      0.0,
      (s, a) => s + (a['current_value'] as num).toDouble(),
    );
    final totalIncome = _assets.fold(
      0.0,
      (s, a) => s + (a['monthly_income'] as num).toDouble(),
    );

    // Diversification
    final cats = _assets.map((a) => a['asset_category']).toSet();
    if (cats.length < 3) {
      recs.add({
        'priority': 'high',
        'icon': 'pie_chart',
        'title': 'Diversify Portfolio',
        'action': 'Add assets in different categories to reduce risk.',
      });
    }

    // Income-generating assets
    final incomeAssets = _assets
        .where((a) => (a['monthly_income'] as num).toDouble() > 0)
        .length;
    if (incomeAssets < _assets.length ~/ 2) {
      recs.add({
        'priority': 'medium',
        'icon': 'attach_money',
        'title': 'Increase Income Assets',
        'action':
            'Only $incomeAssets of ${_assets.length} assets generate income. Consider converting idle assets.',
      });
    }

    // High value non-income
    final highValueIdle = _assets.where((a) {
      final cv = (a['current_value'] as num).toDouble();
      final income = (a['monthly_income'] as num).toDouble();
      return cv > 50000000 && income == 0;
    }).toList();

    if (highValueIdle.isNotEmpty) {
      recs.add({
        'priority': 'medium',
        'icon': 'lightbulb',
        'title': 'Activate Idle Assets',
        'action':
            '"${highValueIdle.first['asset_name']}" is worth ${_fmtTZS((highValueIdle.first['current_value'] as num).toDouble())} but generates no income. Consider renting or leasing.',
      });
    }

    recs.add({
      'priority': 'low',
      'icon': 'update',
      'title': 'Regular Valuation',
      'action':
          'Update asset valuations quarterly to maintain accurate net worth calculations.',
    });

    return recs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.onSurfaceLight,
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'psychology',
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Asset Advisor',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurfaceLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.mutedLight,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Insights'),
            Tab(text: 'Compare'),
            Tab(text: 'Advice'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInsightsTab(theme),
                _buildCompareTab(theme),
                _buildAdviceTab(theme),
              ],
            ),
    );
  }

  Widget _buildInsightsTab(ThemeData theme) {
    final insights = _generateInsights();
    return RefreshIndicator(
      onRefresh: _loadAssets,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // AI header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF0A3344)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CustomIconWidget(
                  iconName: 'psychology',
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CNA AI Analysis',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Based on ${_assets.length} assets in your portfolio',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (insights.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'Add assets to get AI insights',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                ),
              ),
            )
          else
            ...insights.map((insight) => _InsightCard(insight: insight)),
        ],
      ),
    );
  }

  Widget _buildCompareTab(ThemeData theme) {
    if (_assets.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CustomIconWidget(
                iconName: 'compare_arrows',
                color: AppTheme.mutedLight,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Add at least 2 assets to compare',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare Assets',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // Asset A selector
          Row(
            children: [
              Expanded(
                child: _AssetSelector(
                  label: 'Asset A',
                  selected: _assetA,
                  assets: _assets,
                  onChanged: (a) => setState(() => _assetA = a),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const CustomIconWidget(
                  iconName: 'compare_arrows',
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              Expanded(
                child: _AssetSelector(
                  label: 'Asset B',
                  selected: _assetB,
                  assets: _assets,
                  onChanged: (a) => setState(() => _assetB = a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_assetA != null && _assetB != null) ...[
            _buildComparisonTable(theme),
            const SizedBox(height: 16),
            _buildAiVerdict(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonTable(ThemeData theme) {
    final a = _assetA!;
    final b = _assetB!;

    final aIncome = (a['monthly_income'] as num).toDouble();
    final bIncome = (b['monthly_income'] as num).toDouble();
    final aExpenses = (a['monthly_expenses'] as num).toDouble();
    final bExpenses = (b['monthly_expenses'] as num).toDouble();
    final aProfit = aIncome - aExpenses;
    final bProfit = bIncome - bExpenses;
    final aValue = (a['current_value'] as num).toDouble();
    final bValue = (b['current_value'] as num).toDouble();
    final aGain = aValue - (a['purchase_price'] as num).toDouble();
    final bGain = bValue - (b['purchase_price'] as num).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: [
          _CompRow(
            metric: 'Current Value',
            aVal: _fmtTZS(aValue),
            bVal: _fmtTZS(bValue),
            aWins: aValue >= bValue,
          ),
          _CompRow(
            metric: 'Monthly Income',
            aVal: _fmtTZS(aIncome),
            bVal: _fmtTZS(bIncome),
            aWins: aIncome >= bIncome,
          ),
          _CompRow(
            metric: 'Monthly Costs',
            aVal: _fmtTZS(aExpenses),
            bVal: _fmtTZS(bExpenses),
            aWins: aExpenses <= bExpenses,
          ),
          _CompRow(
            metric: 'Net Profit/mo',
            aVal: _fmtTZS(aProfit),
            bVal: _fmtTZS(bProfit),
            aWins: aProfit >= bProfit,
          ),
          _CompRow(
            metric: 'Total Gain',
            aVal: '${aGain >= 0 ? '+' : ''}${_fmtTZS(aGain)}',
            bVal: '${bGain >= 0 ? '+' : ''}${_fmtTZS(bGain)}',
            aWins: aGain >= bGain,
          ),
          _CompRow(
            metric: 'Condition',
            aVal: a['asset_condition'] as String? ?? '',
            bVal: b['asset_condition'] as String? ?? '',
            aWins: true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAiVerdict(ThemeData theme) {
    final a = _assetA!;
    final b = _assetB!;
    final aProfit =
        (a['monthly_income'] as num).toDouble() -
        (a['monthly_expenses'] as num).toDouble();
    final bProfit =
        (b['monthly_income'] as num).toDouble() -
        (b['monthly_expenses'] as num).toDouble();
    final aValue = (a['current_value'] as num).toDouble();
    final bValue = (b['current_value'] as num).toDouble();

    final aScore = aProfit + (aValue / 1000000);
    final bScore = bProfit + (bValue / 1000000);
    final winner = aScore >= bScore ? a : b;
    final loser = aScore >= bScore ? b : a;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
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
                'AI Verdict',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${winner['asset_name']}" outperforms "${loser['asset_name']}" with ${_fmtTZS(aScore >= bScore ? aProfit : bProfit)}/month net profit and ${_fmtTZS(aScore >= bScore ? aValue : bValue)} current value. '
            'Focus resources on "${winner['asset_name']}" for maximum wealth growth.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceTab(ThemeData theme) {
    final recs = _generateRecommendations();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Strategic Recommendations',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.onSurfaceLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your current asset portfolio',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedLight,
          ),
        ),
        const SizedBox(height: 16),
        ...recs.map((r) => _RecommendationCard(rec: r)),
        const SizedBox(height: 20),
        // Quick stats
        Text(
          'Portfolio Health',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.onSurfaceLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildPortfolioHealth(theme),
      ],
    );
  }

  Widget _buildPortfolioHealth(ThemeData theme) {
    final totalValue = _assets.fold(
      0.0,
      (s, a) => s + (a['current_value'] as num).toDouble(),
    );
    final totalIncome = _assets.fold(
      0.0,
      (s, a) => s + (a['monthly_income'] as num).toDouble(),
    );
    final totalExpenses = _assets.fold(
      0.0,
      (s, a) => s + (a['monthly_expenses'] as num).toDouble(),
    );
    final incomeAssets = _assets
        .where((a) => (a['monthly_income'] as num) > 0)
        .length;
    final appreciating = _assets.where((a) {
      final cv = (a['current_value'] as num).toDouble();
      final pv = (a['purchase_price'] as num).toDouble();
      return pv > 0 && cv > pv;
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: [
          _HealthRow(
            'Total Portfolio Value',
            _fmtTZS(totalValue),
            AppTheme.primary,
          ),
          _HealthRow(
            'Monthly Income Generated',
            _fmtTZS(totalIncome),
            AppTheme.success,
          ),
          _HealthRow(
            'Monthly Operating Costs',
            _fmtTZS(totalExpenses),
            AppTheme.error,
          ),
          _HealthRow(
            'Net Monthly Cash Flow',
            _fmtTZS(totalIncome - totalExpenses),
            totalIncome >= totalExpenses ? AppTheme.success : AppTheme.error,
          ),
          _HealthRow(
            'Income-Generating Assets',
            '$incomeAssets / ${_assets.length}',
            AppTheme.primary,
          ),
          _HealthRow(
            'Appreciating Assets',
            '$appreciating / ${_assets.length}',
            AppTheme.success,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = insight['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: insight['icon'] as String,
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
                  insight['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['message'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.mutedLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  const _RecommendationCard({required this.rec});

  Color _priorityColor() {
    switch (rec['priority']) {
      case 'high':
        return AppTheme.error;
      case 'medium':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(26),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        (rec['priority'] as String).toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rec['action'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.mutedLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSelector extends StatelessWidget {
  final String label;
  final Map<String, dynamic>? selected;
  final List<Map<String, dynamic>> assets;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _AssetSelector({
    required this.label,
    required this.selected,
    required this.assets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: selected,
          isExpanded: true,
          hint: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.mutedLight,
            ),
          ),
          icon: const CustomIconWidget(
            iconName: 'expand_more',
            color: AppTheme.mutedLight,
            size: 18,
          ),
          items: assets
              .map(
                (a) => DropdownMenuItem(
                  value: a,
                  child: Text(
                    a['asset_name'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.onSurfaceLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _CompRow extends StatelessWidget {
  final String metric;
  final String aVal;
  final String bVal;
  final bool aWins;
  final bool isLast;

  const _CompRow({
    required this.metric,
    required this.aVal,
    required this.bVal,
    required this.aWins,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: aWins ? AppTheme.successContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                aVal,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: aWins ? AppTheme.success : AppTheme.mutedLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              metric,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.mutedLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: !aWins ? AppTheme.successContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bVal,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: !aWins ? AppTheme.success : AppTheme.mutedLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HealthRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.mutedLight,
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
}