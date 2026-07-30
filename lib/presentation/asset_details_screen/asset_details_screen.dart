import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AssetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  const AssetDetailsScreen({super.key, required this.asset});

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.client;
  late TabController _tabController;
  late Map<String, dynamic> _asset;
  List<Map<String, dynamic>> _valuations = [];
  List<Map<String, dynamic>> _maintenance = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _asset = Map<String, dynamic>.from(widget.asset);
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final assetId = _asset['id'] as String;
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait(<Future<dynamic>>[
        _client
            .from('asset_valuations')
            .select()
            .eq('asset_id', assetId)
            .order('valuation_date', ascending: false)
            .limit(10),
        _client
            .from('asset_maintenance')
            .select()
            .eq('asset_id', assetId)
            .order('service_date', ascending: false)
            .limit(10),
        _client
            .from('asset_transactions')
            .select()
            .eq('asset_id', assetId)
            .order('transaction_date', ascending: false)
            .limit(20),
        _client.from('assets').select().eq('id', assetId).single(),
      ]);

      setState(() {
        _valuations = List<Map<String, dynamic>>.from(results[0] as List);
        _maintenance = List<Map<String, dynamic>>.from(results[1] as List);
        _transactions = List<Map<String, dynamic>>.from(results[2] as List);
        _asset = Map<String, dynamic>.from(results[3] as Map);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAsset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text(
          'Are you sure you want to delete "${_asset['asset_name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _client.from('assets').delete().eq('id', _asset['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asset deleted'),
            backgroundColor: AppTheme.error,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  String _fmtTZS(double v) {
    if (v >= 1000000000) return 'TSh ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  Color _catColor() {
    switch (_asset['asset_category'] as String? ?? 'fixed') {
      case 'fixed':
        return AppTheme.fixedAssetColor;
      case 'current':
        return AppTheme.currentAssetColor;
      case 'permanent_strategic':
        return AppTheme.appreciatingColor;
      case 'temporary':
        return AppTheme.depreciatingColor;
      default:
        return AppTheme.primary;
    }
  }

  double get _monthlyIncome =>
      (_asset['monthly_income'] as num?)?.toDouble() ?? 0;
  double get _monthlyExpenses =>
      (_asset['monthly_expenses'] as num?)?.toDouble() ?? 0;
  double get _netMonthly => _monthlyIncome - _monthlyExpenses;
  double get _currentValue =>
      (_asset['current_value'] as num?)?.toDouble() ?? 0;
  double get _purchasePrice =>
      (_asset['purchase_price'] as num?)?.toDouble() ?? 0;
  double get _totalGain => _currentValue - _purchasePrice;
  double get _gainPct =>
      _purchasePrice > 0 ? (_totalGain / _purchasePrice * 100) : 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _catColor();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: catColor,
            leading: IconButton(
              icon: const CustomIconWidget(
                iconName: 'arrow_back',
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const CustomIconWidget(
                  iconName: 'edit',
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () async {
                  await context.push(AppRoutes.addAssetScreen, extra: _asset);
                  _loadDetails();
                },
              ),
              IconButton(
                icon: const CustomIconWidget(
                  iconName: 'delete_outline',
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _deleteAsset,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catColor, catColor.withAlpha(180)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _asset['asset_name'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Chip(
                              label: (_asset['asset_category'] as String? ?? '')
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label:
                                  (_asset['asset_condition'] as String? ?? '')
                                      .toUpperCase(),
                              color: Colors.white70,
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
              labelStyle: GoogleFonts.plusJakartaSans(
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
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(theme),
                  _buildPerformanceTab(theme),
                  _buildHistoryTab(theme),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMaintenanceSheet(context),
        backgroundColor: catColor,
        icon: const CustomIconWidget(
          iconName: 'build',
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          'Log Maintenance',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value cards
          Row(
            children: [
              Expanded(
                child: _ValueCard(
                  label: 'Purchase Price',
                  value: _fmtTZS(_purchasePrice),
                  icon: 'payments',
                  color: AppTheme.mutedLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ValueCard(
                  label: 'Current Value',
                  value: _fmtTZS(_currentValue),
                  icon: 'trending_up',
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ValueCard(
                  label: 'Total Gain/Loss',
                  value: '${_totalGain >= 0 ? '+' : ''}${_fmtTZS(_totalGain)}',
                  icon: _totalGain >= 0 ? 'arrow_upward' : 'arrow_downward',
                  color: _totalGain >= 0 ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ValueCard(
                  label: 'Return %',
                  value:
                      '${_gainPct >= 0 ? '+' : ''}${_gainPct.toStringAsFixed(1)}%',
                  icon: 'percent',
                  color: _gainPct >= 0 ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader('Asset Details'),
          const SizedBox(height: 12),
          _DetailCard(
            children: [
              _DetailRow(
                'Category',
                (_asset['asset_category'] as String? ?? '').replaceAll(
                  '_',
                  ' ',
                ),
              ),
              _DetailRow(
                'Type',
                (_asset['asset_type'] as String? ?? '').replaceAll('_', ' '),
              ),
              _DetailRow(
                'Condition',
                _asset['asset_condition'] as String? ?? '',
              ),
              _DetailRow('Status', _asset['asset_status'] as String? ?? ''),
              _DetailRow(
                'Lifecycle',
                (_asset['lifecycle_stage'] as String? ?? '').replaceAll(
                  '_',
                  ' ',
                ),
              ),
              _DetailRow(
                'Funding Source',
                (_asset['funding_source'] as String? ?? '').replaceAll(
                  '_',
                  ' ',
                ),
              ),
              _DetailRow(
                'Ownership',
                _asset['ownership_type'] as String? ?? '',
              ),
              _DetailRow('Owner', _asset['owner_name'] as String? ?? ''),
              _DetailRow(
                'Purchase Date',
                _asset['purchase_date'] as String? ?? '—',
              ),
              _DetailRow(
                'Location',
                '${_asset['region'] ?? ''} ${_asset['address'] ?? ''}'.trim(),
              ),
              _DetailRow(
                'Useful Life',
                '${_asset['useful_life_years'] ?? 0} years',
              ),
              _DetailRow(
                'Depreciation Rate',
                '${_asset['depreciation_rate'] ?? 0}%/year',
              ),
            ],
          ),
          if ((_asset['notes'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader('Notes'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Text(
                _asset['notes'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(ThemeData theme) {
    final totalIncome = _transactions
        .where((t) => t['transaction_type'] == 'income')
        .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
    final totalExpenses = _transactions
        .where((t) => t['transaction_type'] == 'expense')
        .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
    final totalMaintCost = _maintenance.fold(
      0.0,
      (s, m) => s + (m['cost'] as num).toDouble(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly performance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF0A3344)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Performance',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PerfTile(
                        label: 'Income',
                        value: _fmtTZS(_monthlyIncome),
                        color: AppTheme.success,
                      ),
                    ),
                    Expanded(
                      child: _PerfTile(
                        label: 'Costs',
                        value: _fmtTZS(_monthlyExpenses),
                        color: AppTheme.error,
                      ),
                    ),
                    Expanded(
                      child: _PerfTile(
                        label: 'Net',
                        value: _fmtTZS(_netMonthly),
                        color: _netMonthly >= 0
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Income vs Expense bar chart
          if (_monthlyIncome > 0 || _monthlyExpenses > 0) ...[
            _SectionHeader('Income vs Expenses'),
            const SizedBox(height: 12),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (_monthlyIncome > _monthlyExpenses
                          ? _monthlyIncome
                          : _monthlyExpenses) *
                      1.3 /
                      1000000,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: _monthlyIncome / 1000000,
                          color: AppTheme.success,
                          width: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: _monthlyExpenses / 1000000,
                          color: AppTheme.error,
                          width: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: _netMonthly.abs() / 1000000,
                          color: _netMonthly >= 0
                              ? AppTheme.primary
                              : AppTheme.warning,
                          width: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final labels = ['Income', 'Costs', 'Net'];
                          return Text(
                            labels[v.toInt()],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.mutedLight,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SectionHeader('Lifetime Summary'),
          const SizedBox(height: 12),
          _DetailCard(
            children: [
              _DetailRow('Total Income Recorded', _fmtTZS(totalIncome)),
              _DetailRow('Total Expenses Recorded', _fmtTZS(totalExpenses)),
              _DetailRow('Total Maintenance Cost', _fmtTZS(totalMaintCost)),
              _DetailRow(
                'Net Lifetime Profit',
                _fmtTZS(totalIncome - totalExpenses - totalMaintCost),
              ),
              _DetailRow('Transactions Recorded', '${_transactions.length}'),
              _DetailRow('Maintenance Records', '${_maintenance.length}'),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Valuation History'),
          const SizedBox(height: 12),
          if (_valuations.isEmpty)
            _EmptyState('No valuation records yet')
          else
            ..._valuations.map(
              (v) => _HistoryTile(
                icon: 'trending_up',
                title:
                    'Value updated to ${_fmtTZS((v['new_value'] as num).toDouble())}',
                subtitle:
                    'From ${_fmtTZS((v['previous_value'] as num).toDouble())} • ${v['valuation_method'] ?? ''}',
                date: v['valuation_date'] as String? ?? '',
                color: AppTheme.primary,
              ),
            ),
          const SizedBox(height: 20),
          _SectionHeader('Maintenance Records'),
          const SizedBox(height: 12),
          if (_maintenance.isEmpty)
            _EmptyState('No maintenance records yet')
          else
            ..._maintenance.map(
              (m) => _HistoryTile(
                icon: 'build',
                title: m['service_description'] as String? ?? '',
                subtitle:
                    '${m['maintenance_type'] ?? ''} • ${_fmtTZS((m['cost'] as num).toDouble())}',
                date: m['service_date'] as String? ?? '',
                color: AppTheme.warning,
              ),
            ),
          const SizedBox(height: 20),
          _SectionHeader('Asset Transactions'),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            _EmptyState('No transactions recorded yet')
          else
            ..._transactions.map((t) {
              final isIncome = t['transaction_type'] == 'income';
              return _HistoryTile(
                icon: isIncome ? 'add_circle' : 'remove_circle',
                title:
                    t['description'] as String? ??
                    t['transaction_type'] as String? ??
                    '',
                subtitle: _fmtTZS((t['amount'] as num).toDouble()),
                date: t['transaction_date'] as String? ?? '',
                color: isIncome ? AppTheme.success : AppTheme.error,
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showAddMaintenanceSheet(BuildContext context) {
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String maintenanceType = 'routine';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Maintenance',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Service Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cost (TZS)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final userId = _client.auth.currentUser?.id;
                      if (userId == null) return;
                      await _client.from('asset_maintenance').insert({
                        'asset_id': _asset['id'],
                        'user_id': userId,
                        'maintenance_type': maintenanceType,
                        'service_description': descCtrl.text.trim(),
                        'cost': double.tryParse(costCtrl.text) ?? 0,
                        'service_date': DateTime.now().toIso8601String().split(
                          'T',
                        )[0],
                      });
                      Navigator.pop(ctx);
                      _loadDetails();
                    } catch (e) {
                      // ignore
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Record',
                    style: GoogleFonts.plusJakartaSans(
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
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;
  const _ValueCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceLight,
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

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
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceLight,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PerfTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String date;
  final Color color;
  const _HistoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(iconName: icon, color: color, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.mutedLight,
          ),
        ),
      ),
    );
  }
}
