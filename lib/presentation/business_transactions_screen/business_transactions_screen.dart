import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class BusinessTransactionsScreen extends StatefulWidget {
  final Map<String, dynamic>? business;
  const BusinessTransactionsScreen({super.key, this.business});

  @override
  State<BusinessTransactionsScreen> createState() =>
      _BusinessTransactionsScreenState();
}

class _BusinessTransactionsScreenState
    extends State<BusinessTransactionsScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _branches = [];
  String _filterType = 'all';
  Map<String, dynamic>? _activeBusiness;

  @override
  void initState() {
    super.initState();
    _activeBusiness = widget.business;
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

      if (_activeBusiness == null) {
        final biz = await _client
            .from('businesses')
            .select()
            .eq('owner_id', userId)
            .eq('is_active', true)
            .limit(1)
            .maybeSingle();
        _activeBusiness = biz;
      }
      if (_activeBusiness == null) {
        setState(() => _isLoading = false);
        return;
      }

      final bizId = _activeBusiness!['id'] as String;
      final results = await Future.wait(<Future<dynamic>>[
        _client
            .from('business_transactions')
            .select()
            .eq('business_id', bizId)
            .order('transaction_date', ascending: false)
            .limit(100),
        _client.from('business_branches').select().eq('business_id', bizId),
      ]);

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(results[0]);
        _branches = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterType == 'all') return _transactions;
    return _transactions
        .where((t) => t['transaction_type'] == _filterType)
        .toList();
  }

  double get _totalRevenue => _transactions
      .where((t) => t['transaction_type'] == 'revenue')
      .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
  double get _totalExpenses => _transactions
      .where((t) => t['transaction_type'] == 'expense')
      .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

  String _fmt(double v) {
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  String? _branchName(String? id) => id == null
      ? null
      : _branches.firstWhere((b) => b['id'] == id, orElse: () => {})['name']
            as String?;

  void _showAddTransactionSheet() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final customerCtrl = TextEditingController();
    String txType = 'revenue';
    String? selectedBranch;
    DateTime selectedDate = DateTime.now();

    final revenueCategories = [
      'Passenger Fares',
      'Cargo Transport',
      'Rental Income',
      'Sales',
      'Services',
      'Contracts',
      'Investments',
      'Charter Services',
      'Other Income',
    ];
    final expenseCategories = [
      'Fuel',
      'Salaries',
      'Maintenance',
      'Rent',
      'Utilities',
      'Insurance',
      'Marketing',
      'Supplies',
      'Taxes',
      'Loan Payment',
      'Other Expense',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cats = txType == 'revenue'
              ? revenueCategories
              : expenseCategories;
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
            child: SingleChildScrollView(
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
                    'Add Transaction',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Type selector
                  Row(
                    children: ['revenue', 'expense'].map((t) {
                      final isSelected = txType == t;
                      final color = t == 'revenue'
                          ? AppTheme.success
                          : AppTheme.error;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              txType = t;
                              categoryCtrl.clear();
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                              right: t == 'revenue' ? 6 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : AppTheme.outlineLight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                t.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.mutedLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  _sheetField(
                    'Amount (TZS) *',
                    amountCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cats.map((c) {
                      final isSelected = categoryCtrl.text == c;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => categoryCtrl.text = c);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.outlineLight,
                            ),
                          ),
                          child: Text(
                            c,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  _sheetField('Description', descCtrl),
                  const SizedBox(height: 10),
                  _sheetField('Customer / Client', customerCtrl),
                  const SizedBox(height: 10),
                  if (_branches.isNotEmpty) ...[
                    Text(
                      'Branch',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBranch,
                      decoration: InputDecoration(
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
                      ),
                      hint: Text(
                        'Select branch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No specific branch'),
                        ),
                        ..._branches.map(
                          (b) => DropdownMenuItem(
                            value: b['id'] as String,
                            child: Text(b['name'] as String),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => selectedBranch = v),
                    ),
                    const SizedBox(height: 10),
                  ],
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.outlineLight),
                      ),
                      child: Row(
                        children: [
                          const CustomIconWidget(
                            iconName: 'calendar_today',
                            color: AppTheme.mutedLight,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amt = double.tryParse(amountCtrl.text);
                        if (amt == null || amt <= 0) return;
                        final category = categoryCtrl.text.isEmpty
                            ? (txType == 'revenue'
                                  ? 'Other Income'
                                  : 'Other Expense')
                            : categoryCtrl.text;
                        try {
                          await _client.from('business_transactions').insert({
                            'business_id': _activeBusiness!['id'],
                            'branch_id': selectedBranch,
                            'transaction_type': txType,
                            'category': category,
                            'amount': amt,
                            'description': descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            'customer_client': customerCtrl.text.trim().isEmpty
                                ? null
                                : customerCtrl.text.trim(),
                            'transaction_date':
                                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
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
                        backgroundColor: txType == 'revenue'
                            ? AppTheme.success
                            : AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Record ${txType == 'revenue' ? 'Revenue' : 'Expense'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
  }) {
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
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
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
    final filtered = _filtered;
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
              'Business Transactions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            if (_activeBusiness != null)
              Text(
                _activeBusiness!['name'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.mutedLight,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showAddTransactionSheet,
            icon: const Icon(Icons.add, color: AppTheme.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading transactions...')
          : Column(
              children: [
                _buildSummary(),
                _buildFilter(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CustomIconWidget(
                                  iconName: 'receipt_long',
                                  color: AppTheme.mutedLight,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions yet',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showAddTransactionSheet,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: Text(
                                    'Add Transaction',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) =>
                                _buildTxCard(filtered[i]),
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummary() {
    final profit = _totalRevenue - _totalExpenses;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surfaceLight,
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              'Revenue',
              _fmt(_totalRevenue),
              AppTheme.success,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.outlineLight),
          Expanded(
            child: _summaryItem(
              'Expenses',
              _fmt(_totalExpenses),
              AppTheme.error,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.outlineLight),
          Expanded(
            child: _summaryItem(
              'Net Profit',
              _fmt(profit),
              profit >= 0 ? AppTheme.primary : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
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
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['all', 'revenue', 'expense', 'investment', 'loan_payment']
              .map((t) {
                final isSelected = _filterType == t;
                return GestureDetector(
                  onTap: () => setState(() => _filterType = t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.outlineLight,
                      ),
                    ),
                    child: Text(
                      t == 'all' ? 'All' : t.replaceAll('_', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.mutedLight,
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTxCard(Map<String, dynamic> tx) {
    final isRevenue = tx['transaction_type'] == 'revenue';
    final amt = (tx['amount'] as num).toDouble();
    final branch = _branchName(tx['branch_id'] as String?);
    final date = tx['transaction_date'] as String;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (isRevenue ? AppTheme.success : AppTheme.error).withAlpha(
                15,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: isRevenue ? 'arrow_downward' : 'arrow_upward',
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
                  tx['category'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                if (tx['description'] != null)
                  Text(
                    tx['description'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppTheme.mutedLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    if (branch != null) ...[
                      Text(
                        ' • ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      Text(
                        branch,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.mutedLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isRevenue ? '+' : '-'}${_fmt(amt)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isRevenue ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }
}