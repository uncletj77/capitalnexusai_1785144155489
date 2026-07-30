import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/enterprise_transaction_service.dart';
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
            .eq('is_archived', false)
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
                  Row(
                    children: ['revenue', 'expense'].map((t) {
                      final isSelected = txType == t;
                      final color = t == 'revenue'
                          ? AppTheme.success
                          : AppTheme.error;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() {
                            txType = t;
                            categoryCtrl.clear();
                          }),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: t == 'revenue' ? 6 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : AppTheme.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                t.toUpperCase(),
                                style: TextStyle(
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
                  const SizedBox(height: 12),
                  _sheetField(
                    'Amount (TSh) *',
                    amountCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: cats.contains(categoryCtrl.text)
                        ? categoryCtrl.text
                        : cats.first,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: cats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(
                      () => categoryCtrl.text = v ?? cats.first,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _sheetField('Description', descCtrl),
                  const SizedBox(height: 10),
                  _sheetField('Customer / Client', customerCtrl),
                  if (_branches.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedBranch,
                      decoration: InputDecoration(
                        labelText: 'Branch (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Branch'),
                        ),
                        ..._branches.map(
                          (b) => DropdownMenuItem<String?>(
                            value: b['id'] as String,
                            child: Text(b['name'] as String? ?? 'Branch'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => selectedBranch = v),
                    ),
                  ],
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.outlineLight),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
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
                        final amount = double.tryParse(
                          amountCtrl.text.replaceAll(',', ''),
                        );
                        if (amount == null || amount <= 0) return;
                        final category = categoryCtrl.text.isEmpty
                            ? cats.first
                            : categoryCtrl.text;
                        final bizId = _activeBusiness!['id'] as String;
                        await EnterpriseTransactionService.instance
                            .createBusinessTransaction(
                              businessId: bizId,
                              type: txType,
                              category: category,
                              amount: amount,
                              date: selectedDate,
                              description: descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              branchId: selectedBranch,
                              customerClient: customerCtrl.text.trim().isEmpty
                                  ? null
                                  : customerCtrl.text.trim(),
                            );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
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

  void _showEditTransactionSheet(Map<String, dynamic> tx) {
    final amountCtrl = TextEditingController(
      text: (tx['amount'] as num).toDouble().toStringAsFixed(0),
    );
    final descCtrl = TextEditingController(
      text: tx['description'] as String? ?? '',
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Transaction',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Delete Transaction'),
                                content: const Text(
                                  'This will delete the transaction and update all financial calculations.',
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
                              await EnterpriseTransactionService.instance
                                  .deleteBusinessTransaction(
                                    tx['id'] as String,
                                  );
                              _loadData();
                            }
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: AppTheme.error,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (tx['transaction_type'] == 'revenue'
                                ? AppTheme.success
                                : AppTheme.error)
                            .withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(tx['transaction_type'] as String).toUpperCase()} • ${tx['category'] ?? ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tx['transaction_type'] == 'revenue'
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (TSh)',
                    prefixText: 'TSh ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final amount = double.tryParse(
                              amountCtrl.text.replaceAll(',', ''),
                            );
                            if (amount == null || amount <= 0) return;
                            setSheet(() => isSaving = true);
                            await EnterpriseTransactionService.instance
                                .updateBusinessTransaction(tx['id'] as String, {
                                  'amount': amount,
                                  'description': descCtrl.text.isEmpty
                                      ? null
                                      : descCtrl.text,
                                });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadData();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
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
                                const Icon(
                                  Icons.receipt_long,
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

    return GestureDetector(
      onTap: () => _showEditTransactionSheet(tx),
      child: Container(
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
                color: (isRevenue ? AppTheme.success : AppTheme.error)
                    .withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  isRevenue ? Icons.arrow_downward : Icons.arrow_upward,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isRevenue ? '+' : '-'}${_fmt(amt)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isRevenue ? AppTheme.success : AppTheme.error,
                  ),
                ),
                Text(
                  'Tap to edit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppTheme.mutedLight,
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
