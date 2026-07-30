import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/enterprise_transaction_service.dart';
import '../../services/finance_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cna_shared_components.dart';
import '../../widgets/custom_icon_widget.dart';

class EnterpriseTransactionScreen extends StatefulWidget {
  const EnterpriseTransactionScreen({super.key});

  @override
  State<EnterpriseTransactionScreen> createState() =>
      _EnterpriseTransactionScreenState();
}

class _EnterpriseTransactionScreenState
    extends State<EnterpriseTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _accounts = [];
  String _selectedType = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      EnterpriseTransactionService.instance.getTransactions(
        type: _selectedType == 'all' ? null : _selectedType,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        limit: 200,
      ),
      FinanceService.instance.getAccounts(),
      EnterpriseTransactionService.instance.getTransactionAnalytics(),
    ]);
    if (mounted) {
      setState(() {
        _transactions = results[0] as List<Map<String, dynamic>>;
        _accounts = results[1] as List<Map<String, dynamic>>;
        _analytics = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
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
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _typeColor(String type) {
    if ([
      'income',
      'business_income',
      'interest_received',
      'dividend',
      'salary',
      'refund',
      'savings_withdrawal',
      'asset_sale',
      'investment_withdrawal',
    ].contains(type)) {
      return AppTheme.success;
    }
    if ([
      'expense',
      'business_expense',
      'interest_paid',
      'tax',
      'write_off',
      'asset_purchase',
    ].contains(type)) {
      return AppTheme.error;
    }
    if (type == 'transfer') return AppTheme.primary;
    return AppTheme.warning;
  }

  bool _isCredit(String type) {
    return [
      'income',
      'business_income',
      'interest_received',
      'dividend',
      'salary',
      'refund',
      'savings_withdrawal',
      'asset_sale',
      'investment_withdrawal',
      'loan_repayment',
    ].contains(type);
  }

  void _showAddTransactionSheet() {
    String selectedType = 'income';
    String selectedCategory = 'business';
    String? selectedAccountId = _accounts.isNotEmpty
        ? _accounts.first['id'] as String
        : null;
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    final categories = {
      'income': [
        'business',
        'salary',
        'rental',
        'investment',
        'dividends',
        'consulting',
        'freelance',
        'other_income',
      ],
      'expense': [
        'food',
        'transport',
        'fuel',
        'utilities',
        'housing',
        'healthcare',
        'education',
        'entertainment',
        'salaries',
        'loan_payment',
        'insurance',
        'maintenance',
        'marketing',
        'taxes',
        'other',
      ],
      'transfer': ['transfer_out'],
      'business_income': [
        'sales',
        'services',
        'contracts',
        'cargo',
        'other_income',
      ],
      'business_expense': [
        'fuel',
        'salaries',
        'maintenance',
        'rent',
        'utilities',
        'insurance',
        'marketing',
        'supplies',
        'taxes',
        'other',
      ],
      'investment_deposit': ['contribution', 'top_up'],
      'investment_withdrawal': ['withdrawal', 'profit_taking'],
      'loan_given': ['personal_loan', 'business_loan'],
      'loan_taken': ['personal_loan', 'business_loan', 'mortgage'],
      'loan_repayment': ['principal', 'interest', 'full_repayment'],
      'interest_received': [
        'loan_interest',
        'savings_interest',
        'investment_interest',
      ],
      'interest_paid': ['loan_interest', 'credit_interest'],
      'savings_deposit': ['regular_savings', 'goal_savings'],
      'savings_withdrawal': ['goal_withdrawal', 'emergency'],
      'asset_purchase': ['vehicle', 'property', 'equipment', 'digital'],
      'asset_sale': ['vehicle', 'property', 'equipment', 'digital'],
      'dividend': ['stock_dividend', 'business_dividend'],
      'salary': ['monthly_salary', 'bonus', 'commission'],
      'tax': ['income_tax', 'vat', 'corporate_tax'],
      'adjustment': ['correction', 'reconciliation'],
      'refund': ['product_refund', 'service_refund'],
      'write_off': ['bad_debt', 'asset_write_off'],
      'other': ['miscellaneous'],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final cats = categories[selectedType] ?? ['other'];
          if (!cats.contains(selectedCategory)) selectedCategory = cats.first;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Transaction',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Transaction Type
                    Text(
                      'Transaction Type',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: EnterpriseTransactionService
                            .allTransactionTypes
                            .length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final t = EnterpriseTransactionService
                              .allTransactionTypes[i];
                          final isSelected = selectedType == t;
                          return GestureDetector(
                            onTap: () => setSheet(() => selectedType = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                EnterpriseTransactionService.typeLabels[t] ?? t,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.mutedLight,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Title (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount (TSh) *',
                        prefixText: 'TSh ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: cats
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSheet(
                        () => selectedCategory = v ?? selectedCategory,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_accounts.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedAccountId,
                        decoration: InputDecoration(
                          labelText: 'Account',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a['id'] as String,
                                child: Text(
                                  a['account_name'] as String? ?? 'Account',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setSheet(() => selectedAccountId = v),
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
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setSheet(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.outlineLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const CustomIconWidget(
                              iconName: 'calendar_today',
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(selectedDate.toIso8601String()),
                              style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            ),
                          ],
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
                                    .createTransaction(
                                      type: selectedType,
                                      category: selectedCategory,
                                      amount: amount,
                                      date: selectedDate,
                                      title: titleCtrl.text.isEmpty
                                          ? null
                                          : titleCtrl.text,
                                      description: descCtrl.text.isEmpty
                                          ? null
                                          : descCtrl.text,
                                      accountId: selectedAccountId,
                                    );
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
                            : Text(
                                'Add Transaction',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditSheet(Map<String, dynamic> tx) {
    final amountCtrl = TextEditingController(
      text: (tx['amount'] as num).toDouble().toStringAsFixed(0),
    );
    final descCtrl = TextEditingController(
      text: tx['description'] as String? ?? '',
    );
    final titleCtrl = TextEditingController(text: tx['title'] as String? ?? '');
    DateTime selectedDate =
        DateTime.tryParse(tx['transaction_date'] as String? ?? '') ??
        DateTime.now();
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
                                  'This will permanently delete this transaction and update all related calculations.',
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
                                  .deleteTransaction(tx['id'] as String);
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
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await EnterpriseTransactionService.instance
                                .archiveTransaction(tx['id'] as String);
                            _loadData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction archived'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.archive,
                            color: AppTheme.warning,
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
                    color: _typeColor(
                      tx['transaction_type'] as String? ?? 'other',
                    ).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    EnterpriseTransactionService
                            .typeLabels[tx['transaction_type']] ??
                        (tx['transaction_type'] as String? ?? ''),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _typeColor(
                        tx['transaction_type'] as String? ?? 'other',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheet(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.outlineLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CustomIconWidget(
                          iconName: 'calendar_today',
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppTheme.mutedLight,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await EnterpriseTransactionService.instance
                              .duplicateTransaction(tx['id'] as String);
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction duplicated'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Duplicate'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
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
                                    .updateTransaction(tx['id'] as String, {
                                      'amount': amount,
                                      'description': descCtrl.text.isEmpty
                                          ? null
                                          : descCtrl.text,
                                      'title': titleCtrl.text.isEmpty
                                          ? null
                                          : titleCtrl.text,
                                      'transaction_date': selectedDate
                                          .toIso8601String()
                                          .split('T')[0],
                                    });
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadData();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
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
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.mutedLight,
              indicatorColor: AppTheme.primary,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Transactions'),
                Tab(text: 'Analytics'),
                Tab(text: 'Archived'),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const CnaLoadingState(message: 'Loading transactions...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionsList(archived: false),
                        _buildAnalyticsTab(),
                        _buildTransactionsList(archived: true),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionSheet,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add',
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
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: CustomIconWidget(
                      iconName: 'arrow_back',
                      size: 18,
                      color: AppTheme.primary,
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
                      'Transaction Engine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      '${_transactions.length} transactions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const CustomIconWidget(
                  iconName: 'refresh',
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() => _searchQuery = v);
              _loadData();
            },
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _loadData();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outlineLight),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: AppTheme.backgroundLight,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _typeChip('all', 'All'),
                _typeChip('income', 'Income'),
                _typeChip('expense', 'Expense'),
                _typeChip('transfer', 'Transfer'),
                _typeChip('business_income', 'Business'),
                _typeChip('investment_deposit', 'Investment'),
                _typeChip('loan_repayment', 'Loan'),
                _typeChip('savings_deposit', 'Savings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = type);
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.mutedLight,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList({required bool archived}) {
    final txns = archived
        ? _transactions.where((t) => t['is_archived'] == true).toList()
        : _transactions.where((t) => t['is_archived'] != true).toList();

    if (txns.isEmpty) {
      return Center(
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
              archived ? 'No archived transactions' : 'No transactions found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            if (!archived) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddTransactionSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Transaction'),
              ),
            ],
          ],
        ),
      );
    }

    // Group by month
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final t in txns) {
      final dateStr = t['transaction_date'] as String? ?? '';
      try {
        final d = DateTime.parse(dateStr);
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        final key = '${months[d.month - 1]} ${d.year}';
        grouped.putIfAbsent(key, () => []).add(t);
      } catch (_) {}
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: grouped.length,
        itemBuilder: (context, i) {
          final month = grouped.keys.elementAt(i);
          final monthTxns = grouped[month]!;
          final monthIncome = monthTxns
              .where((t) => _isCredit(t['transaction_type'] as String? ?? ''))
              .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
          final monthExpense = monthTxns
              .where(
                (t) =>
                    !_isCredit(t['transaction_type'] as String? ?? '') &&
                    t['transaction_type'] != 'transfer',
              )
              .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Text(
                      month,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+${_formatAmount(monthIncome)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '-${_formatAmount(monthExpense)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...monthTxns.map((t) => _buildTxCard(t)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTxCard(Map<String, dynamic> tx) {
    final type = tx['transaction_type'] as String? ?? 'other';
    final amt = (tx['amount'] as num).toDouble();
    final isCredit = _isCredit(type);
    final color = _typeColor(type);
    final icon = EnterpriseTransactionService.typeIcons[type] ?? 'receipt';
    final isArchived = tx['is_archived'] == true;

    return GestureDetector(
      onTap: () => _showEditSheet(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isArchived
              ? AppTheme.surfaceVariantLight
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: CustomIconWidget(iconName: icon, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['title'] as String? ??
                        tx['description'] as String? ??
                        (tx['category'] as String? ?? type).replaceAll(
                          '_',
                          ' ',
                        ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          EnterpriseTransactionService.typeLabels[type] ?? type,
                          style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(tx['transaction_date'] as String?),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit
                      ? '+'
                      : type == 'transfer'
                      ? ''
                      : '-'}${_formatAmount(amt)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: type == 'transfer'
                        ? AppTheme.primary
                        : isCredit
                        ? AppTheme.success
                        : AppTheme.error,
                  ),
                ),
                if (isArchived)
                  Text(
                    'Archived',
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

  Widget _buildAnalyticsTab() {
    final income = (_analytics['total_income'] as num?)?.toDouble() ?? 0;
    final expense = (_analytics['total_expense'] as num?)?.toDouble() ?? 0;
    final net = income - expense;
    final count = (_analytics['transaction_count'] as num?)?.toInt() ?? 0;
    final categoryTotals =
        (_analytics['category_totals'] as Map<String, dynamic>?) ?? {};
    final sortedCats = categoryTotals.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _analyticsCard(
                  'Total Income',
                  _formatAmount(income),
                  AppTheme.success,
                  'arrow_downward',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _analyticsCard(
                  'Total Expense',
                  _formatAmount(expense),
                  AppTheme.error,
                  'arrow_upward',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _analyticsCard(
                  'Net Cash Flow',
                  _formatAmount(net.abs()),
                  net >= 0 ? AppTheme.success : AppTheme.error,
                  net >= 0 ? 'trending_up' : 'trending_down',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _analyticsCard(
                  'Transactions',
                  '$count',
                  AppTheme.primary,
                  'receipt_long',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Top Categories',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 12),
          ...sortedCats.take(8).map((e) {
            final total = (e.value as num).toDouble();
            final maxVal = sortedCats.isNotEmpty
                ? (sortedCats.first.value as num).toDouble()
                : 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                      Text(
                        _formatAmount(total),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxVal > 0 ? total / maxVal : 0,
                      backgroundColor: AppTheme.outlineLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _analyticsCard(String label, String value, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(iconName: icon, color: color, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
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
            ),
          ),
        ],
      ),
    );
  }
}
