import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AssetDashboardScreen extends StatefulWidget {
  const AssetDashboardScreen({super.key});

  @override
  State<AssetDashboardScreen> createState() => _AssetDashboardScreenState();
}

class _AssetDashboardScreenState extends State<AssetDashboardScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _assets = [];
  int _touchedIndex = -1;

  double get _totalValue =>
      _assets.fold(0.0, (s, a) => s + (a['current_value'] as num).toDouble());
  double get _totalIncome =>
      _assets.fold(0.0, (s, a) => s + (a['monthly_income'] as num).toDouble());
  double get _totalExpenses => _assets.fold(
    0.0,
    (s, a) => s + (a['monthly_expenses'] as num).toDouble(),
  );
  double get _netIncome => _totalIncome - _totalExpenses;

  @override
  void initState() {
    super.initState();
    _loadAssets();
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, double> get _categoryTotals {
    final map = <String, double>{};
    for (final a in _assets) {
      final cat = a['asset_category'] as String? ?? 'other';
      map[cat] = (map[cat] ?? 0) + (a['current_value'] as num).toDouble();
    }
    return map;
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'fixed':
        return AppTheme.fixedAssetColor;
      case 'current':
        return AppTheme.currentAssetColor;
      case 'permanent_strategic':
        return AppTheme.appreciatingColor;
      case 'temporary':
        return AppTheme.depreciatingColor;
      default:
        return AppTheme.intangibleColor;
    }
  }

  String _catLabel(String cat) {
    switch (cat) {
      case 'fixed':
        return 'Fixed';
      case 'current':
        return 'Current';
      case 'permanent_strategic':
        return 'Strategic';
      case 'temporary':
        return 'Temporary';
      default:
        return cat;
    }
  }

  String _fmtTZS(double v) {
    if (v >= 1000000000) return 'TSh ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  String _assetIcon(String type) {
    switch (type) {
      case 'land':
        return 'landscape';
      case 'building':
        return 'apartment';
      case 'vehicle':
        return 'directions_bus';
      case 'business':
        return 'business';
      case 'investment':
        return 'trending_up';
      case 'equipment':
        return 'computer';
      default:
        return 'real_estate_agent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadAssets,
                color: AppTheme.primary,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(theme)),
                    SliverToBoxAdapter(child: _buildTotalCard(theme)),
                    SliverToBoxAdapter(child: _buildIncomeRow(theme)),
                    SliverToBoxAdapter(child: _buildDistributionChart(theme)),
                    SliverToBoxAdapter(child: _buildQuickActions(theme)),
                    SliverToBoxAdapter(child: _buildTopAssets(theme)),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addAssetScreen),
        backgroundColor: AppTheme.primary,
        icon: const CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'Add Asset',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asset Intelligence',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.onSurfaceLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_assets.length} assets tracked',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.aiAssetAdvisorScreen),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'psychology',
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loadAssets,
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
                  iconName: 'refresh',
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5F7A), Color(0xFF0A3344)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomIconWidget(
                iconName: 'account_balance_wallet',
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'TOTAL ASSET VALUE',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmtTZS(_totalValue),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_assets.length} active assets in portfolio',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              label: 'Monthly Income',
              value: _fmtTZS(_totalIncome),
              icon: 'trending_up',
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricTile(
              label: 'Monthly Costs',
              value: _fmtTZS(_totalExpenses),
              icon: 'trending_down',
              color: AppTheme.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricTile(
              label: 'Net Profit',
              value: _fmtTZS(_netIncome),
              icon: 'account_balance',
              color: _netIncome >= 0 ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(ThemeData theme) {
    final totals = _categoryTotals;
    if (totals.isEmpty) return const SizedBox.shrink();

    final sections = totals.entries.toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Distribution',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          _touchedIndex =
                              response?.touchedSection?.touchedSectionIndex ??
                              -1;
                        });
                      },
                    ),
                    sections: List.generate(sections.length, (i) {
                      final e = sections[i];
                      final pct = _totalValue > 0
                          ? (e.value / _totalValue * 100)
                          : 0.0;
                      final isTouched = i == _touchedIndex;
                      return PieChartSectionData(
                        value: e.value,
                        color: _catColor(e.key),
                        radius: isTouched ? 52 : 44,
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: GoogleFonts.plusJakartaSans(
                          fontSize: isTouched ? 12 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }),
                    centerSpaceRadius: 28,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((e) {
                    final pct = _totalValue > 0
                        ? (e.value / _totalValue * 100)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _catColor(e.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _catLabel(e.key),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedLight,
                              fontWeight: FontWeight.w600,
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

  Widget _buildQuickActions(ThemeData theme) {
    final actions = [
      {
        'label': 'All Assets',
        'icon': 'list_alt',
        'color': AppTheme.primary,
        'route': AppRoutes.assetPortfolioScreen,
      },
      {
        'label': 'AI Advisor',
        'icon': 'psychology',
        'color': const Color(0xFF8B5CF6),
        'route': AppRoutes.aiAssetAdvisorScreen,
      },
      {
        'label': 'Add Asset',
        'icon': 'add_circle',
        'color': AppTheme.success,
        'route': AppRoutes.addAssetScreen,
      },
      {
        'label': 'Compare',
        'icon': 'compare_arrows',
        'color': AppTheme.warning,
        'route': AppRoutes.aiAssetAdvisorScreen,
      },
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: GestureDetector(
              onTap: () => context.push(a['route'] as String),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineLight),
                ),
                child: Column(
                  children: [
                    CustomIconWidget(
                      iconName: a['icon'] as String,
                      color: a['color'] as Color,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopAssets(ThemeData theme) {
    final top = _assets.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Assets',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurfaceLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.assetPortfolioScreen),
                child: Text(
                  'View All',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...top.map(
            (a) => _AssetRow(
              asset: a,
              fmtTZS: _fmtTZS,
              assetIcon: _assetIcon,
              catColor: _catColor,
              onTap: () => context.push(AppRoutes.assetDetailsScreen, extra: a),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppTheme.mutedLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  final Map<String, dynamic> asset;
  final String Function(double) fmtTZS;
  final String Function(String) assetIcon;
  final Color Function(String) catColor;
  final VoidCallback onTap;

  const _AssetRow({
    required this.asset,
    required this.fmtTZS,
    required this.assetIcon,
    required this.catColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = asset['asset_category'] as String? ?? 'fixed';
    final type = asset['asset_type'] as String? ?? 'other';
    final cv = (asset['current_value'] as num).toDouble();
    final pv = (asset['purchase_price'] as num).toDouble();
    final gain = cv - pv;
    final isUp = gain >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: catColor(cat), width: 3),
            top: BorderSide(color: AppTheme.outlineLight),
            right: BorderSide(color: AppTheme.outlineLight),
            bottom: BorderSide(color: AppTheme.outlineLight),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor(cat).withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: assetIcon(type),
                  color: catColor(cat),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset['asset_name'] as String? ?? '',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.onSurfaceLight,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    asset['region'] as String? ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmtTZS(cv),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.onSurfaceLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pv > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isUp
                          ? AppTheme.successContainer
                          : AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${isUp ? '+' : ''}${fmtTZS(gain)}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isUp ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}