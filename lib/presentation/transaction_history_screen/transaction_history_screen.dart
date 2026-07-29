import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/cna_shared_components.dart';
import '../../services/finance_service.dart';

enum TransactionFilter { all, income, expense }

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  TransactionFilter _filter = TransactionFilter.all;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
    _loadTransactions();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final type = _filter == TransactionFilter.income
        ? 'income'
        : _filter == TransactionFilter.expense
        ? 'expense'
        : null;
    final txns = await FinanceService.instance.getTransactions(
      type: type,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      limit: 100,
    );
    if (mounted) {
      setState(() {
        _allTransactions = txns;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered => _allTransactions;

  Map<String, List<Map<String, dynamic>>> get _groupedByMonth {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final t in _filtered) {
      final dateStr = t['transaction_date'] as String? ?? '';
      DateTime? date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        continue;
      }
      final key = _monthKey(date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  String _monthKey(DateTime d) {
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
    return '${months[d.month - 1]} ${d.year}';
  }

  double _monthIncome(List<Map<String, dynamic>> txns) => txns
      .where((t) => t['transaction_type'] == 'income')
      .fold(0, (s, t) => s + (t['amount'] as num).toDouble());

  double _monthExpense(List<Map<String, dynamic>> txns) => txns
      .where((t) => t['transaction_type'] == 'expense')
      .fold(0, (s, t) => s + (t['amount'] as num).toDouble());

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
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
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatFullDate(String? dateStr) {
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

  Color _categoryColor(String? category) {
    switch (category) {
      case 'business':
        return AppTheme.appreciatingColor;
      case 'rental':
        return AppTheme.currentAssetColor;
      case 'investment':
        return AppTheme.fixedAssetColor;
      case 'salary':
        return AppTheme.success;
      case 'dividends':
        return AppTheme.primaryLight;
      case 'fuel':
        return AppTheme.depreciatingColor;
      case 'salaries':
        return AppTheme.warning;
      case 'loan_payment':
        return AppTheme.error;
      case 'utilities':
        return AppTheme.mutedLight;
      case 'marketing':
        return AppTheme.intangibleColor;
      case 'housing':
        return AppTheme.warningContainer;
      default:
        return AppTheme.primary;
    }
  }

  String _categoryIcon(String? category) {
    const icons = {
      'business': 'business_center',
      'rental': 'apartment',
      'investment': 'trending_up',
      'dividends': 'show_chart',
      'salary': 'wallet',
      'consulting': 'work',
      'freelance': 'laptop',
      'food': 'restaurant',
      'transport': 'directions_car',
      'fuel': 'local_gas_station',
      'utilities': 'bolt',
      'housing': 'home',
      'healthcare': 'local_hospital',
      'education': 'school',
      'entertainment': 'movie',
      'salaries': 'people',
      'loan_payment': 'account_balance',
      'insurance': 'shield',
      'maintenance': 'build',
      'marketing': 'campaign',
      'subscriptions': 'subscriptions',
      'taxes': 'receipt_long',
    };
    return icons[category?.toLowerCase()] ?? 'receipt';
  }

  void _setFilter(TransactionFilter f) {
    if (_filter == f) return;
    setState(() => _filter = f);
    _animController.forward(from: 0);
    _loadTransactions();
  }

  void _openAddSheet({bool isIncome = false}) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCategory = isIncome ? 'business' : 'food';
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    final incomeCategories = [
      'business',
      'salary',
      'rental',
      'investment',
      'dividends',
      'consulting',
      'freelance',
      'other_income',
    ];
    final expenseCategories = [
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
      'other',
    ];
    final categories = isIncome ? incomeCategories : expenseCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isIncome ? 'Add Income' : 'Add Expense',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const CustomIconWidget(iconName: 'close', size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (TZS)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixText: 'TZS ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.replaceAll('_', ' ').toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSheetState(
                    () => selectedCategory = v ?? selectedCategory,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
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
                          _formatFullDate(selectedDate.toIso8601String()),
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
                            setSheetState(() => isSaving = true);
                            final result = await FinanceService.instance
                                .createTransaction(
                                  type: isIncome ? 'income' : 'expense',
                                  category: selectedCategory,
                                  amount: amount,
                                  date: selectedDate,
                                  description: descCtrl.text.isEmpty
                                      ? null
                                      : descCtrl.text,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (result != null) _loadTransactions();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIncome
                          ? AppTheme.success
                          : AppTheme.error,
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
                            isIncome ? 'Add Income' : 'Add Expense',
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
      ),
    );
  }

  void _openEditSheet(Map<String, dynamic> tx) {
    final descCtrl = TextEditingController(
      text: tx['description'] as String? ?? '',
    );
    final amountCtrl = TextEditingController(
      text: (tx['amount'] as num).toDouble().toStringAsFixed(0),
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                        color: AppTheme.onSurfaceLight,
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
                                  'Are you sure you want to delete this transaction? This cannot be undone.',
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
                              await FinanceService.instance.deleteTransaction(
                                tx['id'] as String,
                              );
                              _loadTransactions();
                            }
                          },
                          icon: const CustomIconWidget(
                            iconName: 'delete',
                            size: 20,
                            color: AppTheme.error,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const CustomIconWidget(
                            iconName: 'close',
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (TZS)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixText: 'TZS ',
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
                            setSheetState(() => isSaving = true);
                            await FinanceService.instance
                                .updateTransaction(tx['id'] as String, {
                                  'amount': amount,
                                  'description': descCtrl.text.isEmpty
                                      ? null
                                      : descCtrl.text,
                                });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadTransactions();
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
                            'Save Changes',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupedByMonth;
    final monthKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
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
                          iconName: 'arrow_back',
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transactions',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openAddSheet(isIncome: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CustomIconWidget(
                            iconName: 'add',
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  _loadTransactions();
                },
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                            _loadTransactions();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.outlineLight),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterTab(
                    label: 'All',
                    isSelected: _filter == TransactionFilter.all,
                    onTap: () => _setFilter(TransactionFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Income',
                    isSelected: _filter == TransactionFilter.income,
                    onTap: () => _setFilter(TransactionFilter.income),
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Expense',
                    isSelected: _filter == TransactionFilter.expense,
                    onTap: () => _setFilter(TransactionFilter.expense),
                    color: AppTheme.error,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openAddSheet(isIncome: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.success.withAlpha(77),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'add',
                            size: 14,
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Income',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Transaction list
            Expanded(
              child: _isLoading
                  ? const CnaLoadingState(message: 'Loading transactions...')
                  : _allTransactions.isEmpty
                  ? CnaEmptyState(
                      iconName: 'receipt_long',
                      title: 'No transactions found',
                      description: _searchQuery.isNotEmpty
                          ? 'Try a different search term'
                          : 'Add your first income or expense to get started',
                      ctaLabel: 'Add Transaction',
                      onCta: () => _openAddSheet(),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: monthKeys.length,
                          itemBuilder: (ctx, mi) {
                            final monthKey = monthKeys[mi];
                            final txns = grouped[monthKey]!;
                            final income = _monthIncome(txns);
                            final expense = _monthExpense(txns);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        monthKey,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.onSurfaceLight,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (income > 0)
                                        Text(
                                          '+${_formatAmount(income)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.success,
                                          ),
                                        ),
                                      if (income > 0 && expense > 0)
                                        const SizedBox(width: 8),
                                      if (expense > 0)
                                        Text(
                                          '-${_formatAmount(expense)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.error,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.outlineLight,
                                    ),
                                  ),
                                  child: Column(
                                    children: List.generate(txns.length, (ti) {
                                      final tx = txns[ti];
                                      final isIncome =
                                          tx['transaction_type'] == 'income';
                                      final amount = (tx['amount'] as num)
                                          .toDouble();
                                      final color = isIncome
                                          ? AppTheme.success
                                          : AppTheme.error;
                                      final category =
                                          tx['category'] as String? ?? 'other';
                                      final description =
                                          tx['description'] as String? ??
                                          category.replaceAll('_', ' ');
                                      final dateStr =
                                          tx['transaction_date'] as String?;

                                      return Column(
                                        children: [
                                          InkWell(
                                            onTap: () => _openEditSheet(tx),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      color: _categoryColor(
                                                        category,
                                                      ).withAlpha(26),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: CustomIconWidget(
                                                        iconName: _categoryIcon(
                                                          category,
                                                        ),
                                                        color: _categoryColor(
                                                          category,
                                                        ),
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          description,
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppTheme
                                                                .onSurfaceLight,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        Text(
                                                          category
                                                              .replaceAll(
                                                                '_',
                                                                ' ',
                                                              )
                                                              .toUpperCase(),
                                                          style:
                                                              GoogleFonts.plusJakartaSans(
                                                                fontSize: 10,
                                                                color: AppTheme
                                                                    .mutedLight,
                                                                letterSpacing:
                                                                    0.5,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '${isIncome ? '+' : '-'} ${_formatAmount(amount)}',
                                                        style:
                                                            GoogleFonts.plusJakartaSans(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: color,
                                                            ),
                                                      ),
                                                      Text(
                                                        _formatDate(dateStr),
                                                        style:
                                                            GoogleFonts.plusJakartaSans(
                                                              fontSize: 10,
                                                              color: AppTheme
                                                                  .mutedLight,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (ti < txns.length - 1)
                                            Divider(
                                              height: 1,
                                              color: AppTheme.outlineLight,
                                              indent: 64,
                                            ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.outlineLight,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.mutedLight,
          ),
        ),
      ),
    );
  }
}