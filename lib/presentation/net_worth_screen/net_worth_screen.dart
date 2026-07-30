import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/finance_service.dart';
import '../../services/supabase_service.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _snapshots = [];
  List<Map<String, dynamic>> _accounts = [];
  double _currentNetWorth = 0;
  double _totalAssets = 0;
  double _totalLiabilities = 0;
  double _monthlyChange = 0;

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

      // Save today's snapshot from real calculated data
      await FinanceService.instance.saveNetWorthSnapshot();

      final snapshotsRes = await _client
          .from('net_worth_snapshots')
          .select()
          .eq('user_id', userId)
          .order('snapshot_date', ascending: true)
          .limit(12);

      final accountsRes = await FinanceService.instance
          .getAccountsWithBalances();

      double netWorth = 0;
      double assets = 0;
      double liabilities = 0;
      double change = 0;

      if (snapshotsRes.isNotEmpty) {
        final last = snapshotsRes.last;
        netWorth = (last['net_worth'] as num).toDouble();
        assets = (last['total_assets'] as num).toDouble();
        liabilities = (last['total_liabilities'] as num).toDouble();
        if (snapshotsRes.length >= 2) {
          final prev = snapshotsRes[snapshotsRes.length - 2];
          change = netWorth - (prev['net_worth'] as num).toDouble();
        }
      } else {
        // No snapshots yet — use live calculation
        final nw = await FinanceService.instance.getNetWorth();
        netWorth = nw['netWorth'] ?? 0;
        assets = nw['assets'] ?? 0;
        liabilities = nw['liabilities'] ?? 0;
      }

      setState(() {
        _snapshots = List<Map<String, dynamic>>.from(snapshotsRes);
        _accounts = accountsRes;
        _currentNetWorth = netWorth;
        _totalAssets = assets;
        _totalLiabilities = liabilities;
        _monthlyChange = change;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return 'TSh ${(amount / 1000000000).toStringAsFixed(2)}B';
    }
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  List<FlSpot> _buildSpots() {
    if (_snapshots.isEmpty) return [const FlSpot(0, 0)];
    return _snapshots.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        (e.value['net_worth'] as num).toDouble() / 1000000,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositiveChange = _monthlyChange >= 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.outlineLight,
                                  ),
                                ),
                                child: const Center(
                                  child: CustomIconWidget(
                                    iconName: 'arrow_back',
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Net Worth',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Your total wealth position',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.mutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _loadData,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.outlineLight,
                                  ),
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
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A5F7A), Color(0xFF0A3344)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Net Worth',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatAmount(_currentNetWorth),
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: isPositiveChange
                                      ? 'trending_up'
                                      : 'trending_down',
                                  color: isPositiveChange
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFFCA5A5),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${isPositiveChange ? '+' : ''}${_formatAmount(_monthlyChange)} this month',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isPositiveChange
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFFFCA5A5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNWMetric(
                                    theme,
                                    'Total Assets',
                                    _totalAssets,
                                    const Color(0xFF4ADE80),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white24,
                                ),
                                Expanded(
                                  child: _buildNWMetric(
                                    theme,
                                    'Liabilities',
                                    _totalLiabilities,
                                    const Color(0xFFFCA5A5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.outlineLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Worth Growth',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '6-month history (TSh Millions)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.mutedLight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 160,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: AppTheme.outlineLight,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, _) {
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
                                          final idx = value.toInt();
                                          if (idx < 0 ||
                                              idx >= _snapshots.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final date =
                                              _snapshots[idx]['snapshot_date']
                                                  as String;
                                          final month =
                                              int.tryParse(
                                                date.split('-')[1],
                                              ) ??
                                              1;
                                          return Text(
                                            months[month - 1],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.mutedLight,
                                            ),
                                          );
                                        },
                                        reservedSize: 24,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _buildSpots(),
                                      isCurved: true,
                                      color: AppTheme.primary,
                                      barWidth: 3,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (_, __, ___, ____) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: AppTheme.primary,
                                              strokeWidth: 2,
                                              strokeColor: Colors.white,
                                            ),
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: AppTheme.primary.withAlpha(25),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'Asset Breakdown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _buildAccountBreakdown(theme, _accounts[i]),
                        ),
                        childCount: _accounts.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          children: [
                            const CustomIconWidget(
                              iconName: 'psychology',
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Insight',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your net worth has grown consistently over the past 6 months. Your debt-to-asset ratio is healthy at ${(_totalLiabilities / (_totalAssets > 0 ? _totalAssets : 1) * 100).toInt()}%. Consider increasing investment allocation to accelerate wealth growth.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNWMetric(
    ThemeData theme,
    String label,
    double value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAmount(value),
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountBreakdown(ThemeData theme, Map<String, dynamic> acc) {
    final color = Color(
      int.tryParse(
            (acc['color'] as String? ?? '#1A5F7A').replaceFirst('#', '0xFF'),
          ) ??
          0xFF1A5F7A,
    );
    final balance = (acc['balance'] as num).toDouble();
    final pct = _totalAssets > 0 ? (balance / _totalAssets * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: acc['icon'] as String? ?? 'account_balance',
                color: color,
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
                  acc['account_name'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.outlineLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(balance),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
