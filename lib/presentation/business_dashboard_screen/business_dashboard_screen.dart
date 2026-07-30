import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/master_asset_registry_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;

  List<Map<String, dynamic>> _businesses = [];
  Map<String, dynamic>? _selectedBusiness;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _kpis = [];

  double _totalRevenue = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;
  double _grossProfit = 0;
  int _healthScore = 0;
  List<BarChartGroupData> _barGroups = [];

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final bizRes = await _client
          .from('businesses')
          .select()
          .eq('owner_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if ((bizRes as List).isNotEmpty) {
        setState(() {
          _businesses = List<Map<String, dynamic>>.from(bizRes);
          _selectedBusiness ??= _businesses.first;
        });
        await _loadBusinessData(_selectedBusiness!['id'] as String);
      } else {
        setState(() {
          _businesses = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBusinessData(String businessId) async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final monthStart = DateTime(
        now.year,
        now.month,
        1,
      ).toIso8601String().split('T')[0];
      final sixMonthsAgo = DateTime(
        now.year,
        now.month - 5,
        1,
      ).toIso8601String().split('T')[0];

      // Run queries in parallel; each wrapped in try-catch to prevent one failure blocking all
      final results = await Future.wait(<Future<dynamic>>[
        _client
            .from('business_transactions')
            .select()
            .eq('business_id', businessId)
            .gte('transaction_date', monthStart)
            .order('transaction_date', ascending: false)
            .then((r) => r)
            .catchError((_) => <dynamic>[]),
        _client
            .from('business_branches')
            .select()
            .eq('business_id', businessId)
            .eq('is_active', true)
            .then((r) => r)
            .catchError((_) => <dynamic>[]),
        _client
            .from('business_employees')
            .select()
            .eq('business_id', businessId)
            .eq('emp_status', 'active')
            .then((r) => r)
            .catchError((_) => <dynamic>[]),
        _client
            .from('business_kpis')
            .select()
            .eq('business_id', businessId)
            .order('kpi_date', ascending: false)
            .limit(20)
            .then((r) => r)
            .catchError((_) => <dynamic>[]),
        _client
            .from('business_transactions')
            .select()
            .eq('business_id', businessId)
            .gte('transaction_date', sixMonthsAgo)
            .order('transaction_date', ascending: true)
            .then((r) => r)
            .catchError((_) => <dynamic>[]),
      ]);

      final txList = List<Map<String, dynamic>>.from(results[0] as List);
      final branchList = List<Map<String, dynamic>>.from(results[1] as List);
      final empList = List<Map<String, dynamic>>.from(results[2] as List);
      final kpiList = List<Map<String, dynamic>>.from(results[3] as List);
      final allTx = List<Map<String, dynamic>>.from(results[4] as List);

      double rev = 0, exp = 0;
      for (final t in txList) {
        final amt = (t['amount'] as num).toDouble();
        if (t['transaction_type'] == 'revenue') rev += amt;
        if (t['transaction_type'] == 'expense') exp += amt;
      }

      // Build 6-month bar chart
      final Map<int, double> monthRevenue = {};
      final Map<int, double> monthExpense = {};
      for (final t in allTx) {
        final date = DateTime.parse(t['transaction_date'] as String);
        final monthIdx =
            (date.year * 12 + date.month) - (now.year * 12 + now.month - 5);
        if (monthIdx < 0 || monthIdx > 5) continue;
        final amt = (t['amount'] as num).toDouble() / 1000000;
        if (t['transaction_type'] == 'revenue') {
          monthRevenue[monthIdx] = (monthRevenue[monthIdx] ?? 0) + amt;
        } else if (t['transaction_type'] == 'expense') {
          monthExpense[monthIdx] = (monthExpense[monthIdx] ?? 0) + amt;
        }
      }

      final barGroups = List.generate(6, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthRevenue[i] ?? 0,
              color: AppTheme.success,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: monthExpense[i] ?? 0,
              color: AppTheme.error,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      });

      int score = 0;
      for (final k in kpiList) {
        if (k['metric'] == 'health_score') {
          score = (k['value'] as num).toInt();
          break;
        }
      }
      if (score == 0 && rev > 0) {
        final margin = (rev - exp) / rev;
        score = (margin * 100).clamp(0, 100).toInt();
      }

      setState(() {
        _transactions = txList;
        _branches = branchList;
        _employees = empList;
        _kpis = kpiList;
        _totalRevenue = rev;
        _totalExpenses = exp;
        _netProfit = rev - exp;
        _grossProfit = rev * 0.65;
        _healthScore = score;
        _barGroups = barGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return 'TSh ${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  Color _healthColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  String _healthLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }

  String _industryIcon(String? industry) {
    switch (industry) {
      case 'transport':
        return 'directions_bus';
      case 'agriculture':
        return 'agriculture';
      case 'real_estate':
        return 'apartment';
      case 'healthcare':
        return 'local_hospital';
      case 'retail':
        return 'storefront';
      case 'technology':
        return 'computer';
      case 'manufacturing':
        return 'factory';
      case 'hospitality':
        return 'hotel';
      case 'education':
        return 'school';
      default:
        return 'business';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _businesses.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () =>
                          _loadBusinessData(_selectedBusiness!['id'] as String),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            _buildBusinessSelector(),
                            _buildHealthScore(),
                            _buildKpiGrid(),
                            _buildRevenueChart(),
                            _buildBranchPerformance(),
                            _buildAiInsights(),
                            _buildQuickActions(),
                            _buildRecentTransactions(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/add-business').then((_) => _loadBusinesses()),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Business',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
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
            child: const Center(
              child: CustomIconWidget(
                iconName: 'business_center',
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Intelligence',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  '${_businesses.length} business${_businesses.length != 1 ? 'es' : ''} managed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                context.push('/business-reports', extra: _selectedBusiness),
            icon: const CustomIconWidget(
              iconName: 'assessment',
              color: AppTheme.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSelector() {
    if (_businesses.length <= 1 && _selectedBusiness != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: _buildSelectedBusinessCard(),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Businesses',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _businesses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final biz = _businesses[i];
                final isSelected = _selectedBusiness?['id'] == biz['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedBusiness = biz);
                    _loadBusinessData(biz['id'] as String);
                  },
                  onLongPress: () => _showEditBusinessSheet(biz),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.outlineLight,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(40),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: _industryIcon(biz['industry'] as String?),
                          color: isSelected ? Colors.white : AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          biz['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.onSurfaceLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          (biz['status'] as String)
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: isSelected
                                ? Colors.white70
                                : AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBusinessCard() {
    if (_selectedBusiness == null) return const SizedBox.shrink();
    final biz = _selectedBusiness!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: _industryIcon(biz['industry'] as String?),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biz['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${(biz['industry'] as String).replaceAll('_', ' ')} • ${(biz['status'] as String).replaceAll('_', ' ')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Options button — always visible
          GestureDetector(
            onTap: () => _showEditBusinessSheet(biz),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => context
                .push('/business-profile', extra: biz)
                .then((_) => _loadBusinesses()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'View',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _healthScore / 100,
                    strokeWidth: 7,
                    backgroundColor: AppTheme.outlineLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _healthColor(_healthScore),
                    ),
                  ),
                  Text(
                    '$_healthScore',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _healthColor(_healthScore),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Health Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _healthColor(_healthScore).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _healthLabel(_healthScore),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _healthColor(_healthScore),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _healthScore >= 80
                        ? 'Strong performance across all metrics'
                        : _healthScore >= 60
                        ? 'Good performance with room to improve'
                        : 'Attention needed in key areas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    final items = [
      {
        'label': 'Revenue',
        'value': _formatAmount(_totalRevenue),
        'icon': 'trending_up',
        'color': AppTheme.success,
      },
      {
        'label': 'Expenses',
        'value': _formatAmount(_totalExpenses),
        'icon': 'trending_down',
        'color': AppTheme.error,
      },
      {
        'label': 'Net Profit',
        'value': _formatAmount(_netProfit),
        'icon': 'account_balance_wallet',
        'color': _netProfit >= 0 ? AppTheme.primary : AppTheme.error,
      },
      {
        'label': 'Employees',
        'value': '${_employees.length}',
        'icon': 'people',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'label': 'Branches',
        'value': '${_branches.length}',
        'icon': 'store',
        'color': const Color(0xFFF59E0B),
      },
      {
        'label': 'Margin',
        'value': _totalRevenue > 0
            ? '${((_netProfit / _totalRevenue) * 100).toStringAsFixed(1)}%'
            : '0%',
        'icon': 'pie_chart',
        'color': AppTheme.primaryLight,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final color = item['color'] as Color;
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomIconWidget(
                  iconName: item['icon'] as String,
                  color: color,
                  size: 18,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['value'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue vs Expenses',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Row(
                  children: [
                    _legendDot(AppTheme.success, 'Revenue'),
                    const SizedBox(width: 8),
                    _legendDot(AppTheme.error, 'Expenses'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: _barGroups.isEmpty
                  ? Center(
                      child: Text(
                        'No data yet',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        barGroups: _barGroups,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: AppTheme.outlineLight,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (v, _) => Text(
                                '${v.toInt()}M',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: AppTheme.mutedLight,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final now = DateTime.now();
                                final month = DateTime(
                                  now.year,
                                  now.month - 5 + v.toInt(),
                                );
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
                                return Text(
                                  months[month.month - 1],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: AppTheme.mutedLight,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barTouchData: BarTouchData(enabled: true),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppTheme.mutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBranchPerformance() {
    if (_branches.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Branch Performance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    '/branch-management',
                    extra: _selectedBusiness,
                  ),
                  child: Text(
                    'Manage',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._branches.asMap().entries.map((entry) {
              final branch = entry.value;
              final branchRevenue = _transactions
                  .where(
                    (t) =>
                        t['branch_id'] == branch['id'] &&
                        t['transaction_type'] == 'revenue',
                  )
                  .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
              final totalRev = _totalRevenue > 0 ? _totalRevenue : 1;
              final pct = (branchRevenue / totalRev).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            branch['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatAmount(branchRevenue),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppTheme.outlineLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}% of total revenue',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsights() {
    final insights = _generateInsights();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A5F7A).withAlpha(10),
              const Color(0xFF2D9CDB).withAlpha(10),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CustomIconWidget(
                  iconName: 'psychology',
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Business Insights',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push(
                    '/ai-business-advisor',
                    extra: _selectedBusiness,
                  ),
                  child: Text(
                    'Ask AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.onSurfaceLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _generateInsights() {
    final insights = <String>[];
    if (_selectedBusiness == null) {
      return ['Add your first business to get AI insights.'];
    }

    final margin = _totalRevenue > 0 ? (_netProfit / _totalRevenue) * 100 : 0;
    if (_netProfit > 0) {
      insights.add(
        'Net profit margin is ${margin.toStringAsFixed(1)}%. ${margin > 20 ? 'Strong profitability — consider reinvesting in growth.' : 'Margin is moderate — review expense categories for optimization.'}',
      );
    } else {
      insights.add(
        'Business is currently operating at a loss. Immediate review of expense categories recommended.',
      );
    }

    if (_branches.isNotEmpty) {
      final topBranch = _branches.first;
      insights.add(
        '${topBranch['name']} is your primary branch. Monitor performance across all ${_branches.length} locations for balanced growth.',
      );
    }

    if (_employees.isNotEmpty) {
      final totalSalary = _employees.fold(
        0.0,
        (sum, e) => sum + (e['salary'] as num? ?? 0).toDouble(),
      );
      final salaryRatio = _totalRevenue > 0
          ? (totalSalary / _totalRevenue) * 100
          : 0;
      insights.add(
        'Payroll represents ${salaryRatio.toStringAsFixed(1)}% of revenue across ${_employees.length} employees. ${salaryRatio < 30 ? 'Healthy ratio.' : 'Consider productivity improvements.'}',
      );
    }

    if (_totalExpenses > 0) {
      insights.add(
        'Total expenses this month: ${_formatAmount(_totalExpenses)}. Track expense trends monthly to identify cost-saving opportunities.',
      );
    }

    return insights.take(3).toList();
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Add Revenue',
        'icon': 'add_circle',
        'color': AppTheme.success,
        'route': '/add-business-transaction',
      },
      {
        'label': 'Add Expense',
        'icon': 'remove_circle',
        'color': AppTheme.error,
        'route': '/add-business-transaction',
      },
      {
        'label': 'Employees',
        'icon': 'people',
        'color': const Color(0xFF8B5CF6),
        'route': '/employee-management',
      },
      {
        'label': 'Inventory',
        'icon': 'inventory',
        'color': const Color(0xFFF59E0B),
        'route': '/business-inventory',
      },
      {
        'label': 'Simulate',
        'icon': 'science',
        'color': AppTheme.primaryLight,
        'route': '/business-simulator',
      },
      {
        'label': 'Reports',
        'icon': 'assessment',
        'color': AppTheme.primary,
        'route': '/business-reports',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((a) {
              final color = a['color'] as Color;
              return GestureDetector(
                onTap: () => context.push(
                  a['route'] as String,
                  extra: _selectedBusiness,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withAlpha(18),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: color.withAlpha(40)),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: a['icon'] as String,
                          color: color,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      a['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recent = _transactions.take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    '/business-transactions',
                    extra: _selectedBusiness,
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recent.map((t) {
              final isRevenue = t['transaction_type'] == 'revenue';
              final amt = (t['amount'] as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (isRevenue ? AppTheme.success : AppTheme.error)
                            .withAlpha(18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: isRevenue
                              ? 'arrow_downward'
                              : 'arrow_upward',
                          color: isRevenue ? AppTheme.success : AppTheme.error,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['category'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            t['description'] as String? ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.mutedLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isRevenue ? '+' : '-'}${_formatAmount(amt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isRevenue ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'business_center',
                  color: AppTheme.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Businesses Yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Register your first business to start tracking revenue, expenses, employees, and growth.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.mutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push('/add-business').then((_) => _loadBusinesses()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                'Add Business',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBusinessSheet(Map<String, dynamic> biz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Business Options',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                biz['name'] as String? ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.mutedLight,
                ),
              ),
              const SizedBox(height: 16),
              _businessActionTile(
                Icons.edit,
                'Edit Business',
                AppTheme.primary,
                () {
                  Navigator.pop(context);
                  context
                      .push('/add-business', extra: biz)
                      .then((_) => _loadBusinesses());
                },
              ),
              _businessActionTile(
                Icons.receipt_long,
                'View Transactions',
                AppTheme.warning,
                () {
                  Navigator.pop(context);
                  context.push('/business-transactions', extra: biz);
                },
              ),
              _businessActionTile(
                Icons.sync,
                'Register in Asset Intelligence',
                const Color(0xFF8B5CF6),
                () async {
                  Navigator.pop(context);
                  await MasterAssetRegistryService.instance
                      .autoRegisterAllAssets();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Business registered in Asset Intelligence',
                        ),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              _businessActionTile(
                Icons.archive,
                'Archive Business',
                AppTheme.mutedLight,
                () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Archive Business'),
                      content: const Text(
                        'This business will be archived. All records will be preserved.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            'Archive',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await _client
                        .from('businesses')
                        .update({'is_active': false})
                        .eq('id', biz['id'] as String);
                    _loadBusinesses();
                  }
                },
              ),
              _businessActionTile(
                Icons.delete,
                'Delete Business',
                AppTheme.error,
                () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Business'),
                      content: const Text(
                        'This will permanently delete the business. Transaction history will be preserved.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await _client
                        .from('businesses')
                        .update({'is_active': false, 'is_deleted': true})
                        .eq('id', biz['id'] as String);
                    _loadBusinesses();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _businessActionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
