import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class BranchManagementScreen extends StatefulWidget {
  final Map<String, dynamic>? business;
  const BranchManagementScreen({super.key, this.business});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.business == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final bizId = widget.business!['id'] as String;
      final results = await Future.wait(<Future<dynamic>>[
        _client
            .from('business_branches')
            .select()
            .eq('business_id', bizId)
            .order('created_at'),
        _client
            .from('business_transactions')
            .select()
            .eq('business_id', bizId)
            .gte(
              'transaction_date',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String()
                  .split('T')[0],
            ),
        _client
            .from('business_employees')
            .select()
            .eq('business_id', bizId)
            .eq('emp_status', 'active'),
      ]);
      setState(() {
        _branches = List<Map<String, dynamic>>.from(results[0]);
        _transactions = List<Map<String, dynamic>>.from(results[1]);
        _employees = List<Map<String, dynamic>>.from(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _branchRevenue(String branchId) => _transactions
      .where(
        (t) => t['branch_id'] == branchId && t['transaction_type'] == 'revenue',
      )
      .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
  double _branchExpenses(String branchId) => _transactions
      .where(
        (t) => t['branch_id'] == branchId && t['transaction_type'] == 'expense',
      )
      .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
  int _branchEmployees(String branchId) =>
      _employees.where((e) => e['branch_id'] == branchId).length;

  String _fmt(double v) {
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  void _showAddBranchSheet() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final regionCtrl = TextEditingController();
    final managerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add Branch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 16),
                _sheetField(
                  'Branch Name *',
                  nameCtrl,
                  hint: 'e.g. Mwanza Branch',
                ),
                const SizedBox(height: 12),
                _sheetField('Location', locationCtrl, hint: 'City or area'),
                const SizedBox(height: 12),
                _sheetField('Region', regionCtrl, hint: 'e.g. Mwanza'),
                const SizedBox(height: 12),
                _sheetField(
                  'Manager Name',
                  managerCtrl,
                  hint: 'Branch manager',
                ),
                const SizedBox(height: 12),
                _sheetField('Phone', phoneCtrl, hint: '+255 XXX XXX XXX'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      try {
                        await _client.from('business_branches').insert({
                          'business_id': widget.business!['id'],
                          'name': nameCtrl.text.trim(),
                          'location': locationCtrl.text.trim().isEmpty
                              ? null
                              : locationCtrl.text.trim(),
                          'region': regionCtrl.text.trim().isEmpty
                              ? null
                              : regionCtrl.text.trim(),
                          'manager': managerCtrl.text.trim().isEmpty
                              ? null
                              : managerCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim().isEmpty
                              ? null
                              : phoneCtrl.text.trim(),
                          'is_active': true,
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Branch',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedLight,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.mutedLight.withAlpha(120),
            ),
            filled: true,
            fillColor: AppTheme.backgroundLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort branches by revenue descending
    final sorted = List<Map<String, dynamic>>.from(_branches);
    sorted.sort(
      (a, b) => _branchRevenue(
        b['id'] as String,
      ).compareTo(_branchRevenue(a['id'] as String)),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Branch Management',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            if (widget.business != null)
              Text(
                widget.business!['name'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.mutedLight,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showAddBranchSheet,
            icon: const Icon(Icons.add, color: AppTheme.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading branch data...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(),
                    const SizedBox(height: 16),
                    Text(
                      'Branch Rankings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (sorted.isEmpty)
                      _buildEmptyBranches()
                    else
                      ...sorted.asMap().entries.map(
                        (e) => _buildBranchCard(e.value, e.key + 1),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow() {
    final totalRev = _branches.fold(
      0.0,
      (s, b) => s + _branchRevenue(b['id'] as String),
    );
    final totalExp = _branches.fold(
      0.0,
      (s, b) => s + _branchExpenses(b['id'] as String),
    );
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Total Revenue',
            _fmt(totalRev),
            'trending_up',
            AppTheme.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Total Expenses',
            _fmt(totalExp),
            'trending_down',
            AppTheme.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Branches',
            '${_branches.length}',
            'store',
            AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch, int rank) {
    final branchId = branch['id'] as String;
    final rev = _branchRevenue(branchId);
    final exp = _branchExpenses(branchId);
    final profit = rev - exp;
    final empCount = _branchEmployees(branchId);
    final totalRev = _branches.fold(
      0.0,
      (s, b) => s + _branchRevenue(b['id'] as String),
    );
    final pct = totalRev > 0 ? (rev / totalRev).clamp(0.0, 1.0) : 0.0;

    final rankColors = [
      AppTheme.warning,
      AppTheme.mutedLight,
      const Color(0xFFCD7F32),
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : AppTheme.outlineLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank == 1
              ? AppTheme.warning.withAlpha(60)
              : AppTheme.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: rankColor.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(color: rankColor.withAlpha(60)),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: rankColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      '${branch['location'] ?? ''} ${branch['region'] != null ? '• ${branch['region']}' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (profit >= 0 ? AppTheme.success : AppTheme.error)
                      .withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _fmt(profit),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: profit >= 0 ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricPill('Revenue', _fmt(rev), AppTheme.success),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricPill('Expenses', _fmt(exp), AppTheme.error),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricPill(
                  'Staff',
                  '$empCount',
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).toStringAsFixed(1)}% of total revenue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppTheme.mutedLight,
                ),
              ),
              if (branch['manager'] != null)
                Text(
                  'Manager: ${branch['manager']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.mutedLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.outlineLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBranches() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CustomIconWidget(
              iconName: 'store',
              color: AppTheme.mutedLight,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No branches yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add branches to track performance by location',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.mutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddBranchSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Add Branch',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
