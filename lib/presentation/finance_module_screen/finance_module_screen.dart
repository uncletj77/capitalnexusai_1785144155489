import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/accounting_engine.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cna_shared_components.dart';
import '../../widgets/custom_icon_widget.dart';

/// Finance Module Screen — Chart of Accounts, Journal Entries, General Ledger,
/// Trial Balance, Financial Periods — Enterprise Finance Foundation
class FinanceModuleScreen extends StatefulWidget {
  const FinanceModuleScreen({super.key});

  @override
  State<FinanceModuleScreen> createState() => _FinanceModuleScreenState();
}

class _FinanceModuleScreenState extends State<FinanceModuleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _engine = AccountingEngine.instance;

  bool _isLoading = false;
  String? _errorMessage;

  // Chart of Accounts
  List<Map<String, dynamic>> _accounts = [];
  String _coaFilter = 'all';

  // Journal Entries
  List<Map<String, dynamic>> _journals = [];
  String _journalFilter = 'all';

  // General Ledger
  List<Map<String, dynamic>> _ledgerEntries = [];

  // Trial Balance
  List<Map<String, dynamic>> _trialBalance = [];

  // Financial Periods
  List<Map<String, dynamic>> _periods = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadTabData(_tabController.index);
    });
    _loadTabData(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTabData(int index) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      switch (index) {
        case 0:
          final data = await _engine.getChartOfAccounts(
            accountType: _coaFilter == 'all' ? null : _coaFilter,
          );
          if (mounted) setState(() => _accounts = data);
          break;
        case 1:
          final data = await _engine.getJournalEntries(
            status: _journalFilter == 'all' ? null : _journalFilter,
            limit: 100,
          );
          if (mounted) setState(() => _journals = data);
          break;
        case 2:
          final data = await _engine.getGeneralLedger(limit: 100);
          if (mounted) setState(() => _ledgerEntries = data);
          break;
        case 3:
          final data = await _engine.getTrialBalance();
          if (mounted) setState(() => _trialBalance = data);
          break;
        case 4:
          final data = await _engine.getFinancialPeriods();
          if (mounted) setState(() => _periods = data);
          break;
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _errorMessage = e.toString().replaceAll(
            'AccountingException: ',
            '',
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Finance Module',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTabData(_tabController.index),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(_tabController.index),
            tooltip: 'Add',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Chart of Accounts'),
            Tab(text: 'Journal Entries'),
            Tab(text: 'General Ledger'),
            Tab(text: 'Trial Balance'),
            Tab(text: 'Periods'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChartOfAccounts(),
                _buildJournalEntries(),
                _buildGeneralLedger(),
                _buildTrialBalance(),
                _buildFinancialPeriods(),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 2.h),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.sp),
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () => _loadTabData(_tabController.index),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CHART OF ACCOUNTS ───────────────────────────────────────────────────

  Widget _buildChartOfAccounts() {
    final types = ['all', 'asset', 'liability', 'equity', 'revenue', 'expense'];
    return Column(
      children: [
        _buildFilterChips(types, _coaFilter, (val) {
          setState(() => _coaFilter = val);
          _loadTabData(0);
        }),
        Expanded(
          child: _accounts.isEmpty
              ? _buildEmptyState(
                  'No accounts found',
                  'Create your first account of accounts entry',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: _accounts.length,
                  itemBuilder: (ctx, i) => _buildCoaCard(_accounts[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildCoaCard(Map<String, dynamic> account) {
    final type = account['account_type'] as String? ?? 'asset';
    final balance = (account['current_balance'] as num?)?.toDouble() ?? 0;
    final color = _accountTypeColor(type);

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              account['account_code'] as String? ?? '?',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        title: Text(
          account['account_name'] as String? ?? 'Unknown',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          type.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 10.sp, color: color),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatAmount(balance),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                color: balance >= 0 ? AppTheme.success : Colors.red,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (account['is_active'] as bool? ?? true)
                    ? AppTheme.success.withAlpha(30)
                    : Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (account['is_active'] as bool? ?? true) ? 'Active' : 'Inactive',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: (account['is_active'] as bool? ?? true)
                      ? AppTheme.success
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showCoaDetails(account),
      ),
    );
  }

  // ─── JOURNAL ENTRIES ─────────────────────────────────────────────────────

  Widget _buildJournalEntries() {
    final statuses = ['all', 'draft', 'approved', 'posted', 'reversed'];
    return Column(
      children: [
        _buildFilterChips(statuses, _journalFilter, (val) {
          setState(() => _journalFilter = val);
          _loadTabData(1);
        }),
        Expanded(
          child: _journals.isEmpty
              ? _buildEmptyState(
                  'No journal entries',
                  'Create your first journal entry',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: _journals.length,
                  itemBuilder: (ctx, i) => _buildJournalCard(_journals[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> journal) {
    final status = journal['status'] as String? ?? 'draft';
    final isBalanced = journal['is_balanced'] as bool? ?? false;
    final totalDebit = (journal['total_debit'] as num?)?.toDouble() ?? 0;
    final statusColor = _journalStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showJournalDetails(journal),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      journal['journal_number'] as String? ?? 'JE-???',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                journal['description'] as String? ?? '',
                style: GoogleFonts.inter(fontSize: 12.sp),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'calendar_today',
                    size: 12,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    journal['journal_date'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isBalanced ? Icons.check_circle : Icons.warning,
                    size: 14,
                    color: isBalanced ? AppTheme.success : Colors.orange,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatAmount(totalDebit),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── GENERAL LEDGER ───────────────────────────────────────────────────────

  Widget _buildGeneralLedger() {
    return _ledgerEntries.isEmpty
        ? _buildEmptyState(
            'No ledger entries',
            'Post journal entries to populate the ledger',
          )
        : ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: _ledgerEntries.length,
            itemBuilder: (ctx, i) => _buildLedgerCard(_ledgerEntries[i]),
          );
  }

  Widget _buildLedgerCard(Map<String, dynamic> entry) {
    final debit = (entry['debit_amount'] as num?)?.toDouble() ?? 0;
    final credit = (entry['credit_amount'] as num?)?.toDouble() ?? 0;
    final balance = (entry['running_balance'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['account_name'] as String? ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    entry['posting_date'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                debit > 0 ? _formatAmount(debit) : '-',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                credit > 0 ? _formatAmount(credit) : '-',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                _formatAmount(balance),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: balance >= 0 ? AppTheme.primary : Colors.red,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TRIAL BALANCE ────────────────────────────────────────────────────────

  Widget _buildTrialBalance() {
    if (_trialBalance.isEmpty) {
      return _buildEmptyState(
        'No trial balance data',
        'Post journal entries to generate trial balance',
      );
    }

    double totalDebit = 0;
    double totalCredit = 0;
    for (final row in _trialBalance) {
      totalDebit += (row['debit_total'] as num?)?.toDouble() ?? 0;
      totalCredit += (row['credit_total'] as num?)?.toDouble() ?? 0;
    }
    final isBalanced = (totalDebit - totalCredit).abs() < 0.01;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(3.w),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isBalanced
                ? AppTheme.success.withAlpha(20)
                : Colors.red.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isBalanced ? AppTheme.success : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isBalanced ? Icons.check_circle : Icons.warning,
                color: isBalanced ? AppTheme.success : Colors.red,
              ),
              SizedBox(width: 2.w),
              Text(
                isBalanced
                    ? 'Trial Balance is BALANCED'
                    : 'Trial Balance is UNBALANCED',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: isBalanced ? AppTheme.success : Colors.red,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Account',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Debit',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  'Credit',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            itemCount: _trialBalance.length + 1,
            itemBuilder: (ctx, i) {
              if (i == _trialBalance.length) {
                return _buildTrialBalanceTotals(totalDebit, totalCredit);
              }
              return _buildTrialBalanceRow(_trialBalance[i]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrialBalanceRow(Map<String, dynamic> row) {
    final debit = (row['debit_total'] as num?)?.toDouble() ?? 0;
    final credit = (row['credit_total'] as num?)?.toDouble() ?? 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['account_name'] as String? ?? '',
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  row['account_type'] as String? ?? '',
                  style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              debit > 0 ? _formatAmount(debit) : '-',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.success,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              credit > 0 ? _formatAmount(credit) : '-',
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.red),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBalanceTotals(double totalDebit, double totalCredit) {
    return Container(
      margin: EdgeInsets.only(top: 1.h),
      padding: EdgeInsets.symmetric(vertical: 1.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'TOTALS',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatAmount(totalDebit),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 12.sp,
                color: AppTheme.success,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              _formatAmount(totalCredit),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 12.sp,
                color: Colors.red,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ─── FINANCIAL PERIODS ────────────────────────────────────────────────────

  Widget _buildFinancialPeriods() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(3.w),
          child: ElevatedButton.icon(
            onPressed: _showCreatePeriodDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Period'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 44),
            ),
          ),
        ),
        Expanded(
          child: _periods.isEmpty
              ? _buildEmptyState(
                  'No financial periods',
                  'Create accounting periods to manage your fiscal year',
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  itemCount: _periods.length,
                  itemBuilder: (ctx, i) => _buildPeriodCard(_periods[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildPeriodCard(Map<String, dynamic> period) {
    final status = period['status'] as String? ?? 'open';
    final statusColor = status == 'open'
        ? AppTheme.success
        : status == 'closed'
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_month, color: statusColor, size: 20),
        ),
        title: Text(
          period['period_name'] as String? ?? 'Period',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
        ),
        subtitle: Text(
          '${period['start_date']} → ${period['end_date']}',
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (status == 'open')
              IconButton(
                icon: const Icon(Icons.lock, size: 18),
                color: Colors.orange,
                onPressed: () => _closePeriod(period['id'] as String),
                tooltip: 'Close Period',
              ),
          ],
        ),
      ),
    );
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────

  void _showAddDialog(int tabIndex) {
    switch (tabIndex) {
      case 0:
        _showCreateAccountDialog();
        break;
      case 1:
        _showCreateJournalDialog();
        break;
      case 4:
        _showCreatePeriodDialog();
        break;
    }
  }

  void _showCreateAccountDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedType = 'asset';
    String normalBalance = 'debit';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'New Account',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Code *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 1.5.h),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 1.5.h),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Account Type',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'asset',
                            'liability',
                            'equity',
                            'revenue',
                            'expense',
                            'cost_of_sales',
                            'other_income',
                            'other_expense',
                          ]
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.replaceAll('_', ' ').toUpperCase()),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        selectedType = v;
                        normalBalance =
                            ['asset', 'expense', 'cost_of_sales'].contains(v)
                            ? 'debit'
                            : 'credit';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              onPressed: () async {
                if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _engine.createChartAccount(
                    accountCode: codeCtrl.text.trim(),
                    accountName: nameCtrl.text.trim(),
                    accountType: selectedType,
                    normalBalance: normalBalance,
                  );
                  _loadTabData(0);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('AccountingException: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateJournalDialog() {
    final descCtrl = TextEditingController();
    DateTime journalDate = DateTime.now();
    final lines = <Map<String, dynamic>>[
      {'account_code': '', 'account_name': '', 'debit': 0.0, 'credit': 0.0},
      {'account_code': '', 'account_name': '', 'debit': 0.0, 'credit': 0.0},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'New Journal Entry',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Add at least 2 lines with balanced debits and credits.',
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to full journal entry form
              _showFullJournalForm(descCtrl.text);
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullJournalForm(String initialDescription) {
    // Full journal entry creation with line items
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _JournalEntryForm(
        initialDescription: initialDescription,
        onSave: (description, lines, autoPost) async {
          try {
            await _engine.createJournalEntry(
              description: description,
              journalDate: DateTime.now(),
              lines: lines,
              autoPost: autoPost,
            );
            _loadTabData(1);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    autoPost
                        ? 'Journal posted successfully'
                        : 'Journal saved as draft',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    e.toString().replaceAll('AccountingException: ', ''),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showCreatePeriodDialog() {
    final nameCtrl = TextEditingController();
    String periodType = 'monthly';
    DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime endDate = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'New Financial Period',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Period Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 1.5.h),
              DropdownButtonFormField<String>(
                value: periodType,
                decoration: const InputDecoration(
                  labelText: 'Period Type',
                  border: OutlineInputBorder(),
                ),
                items: ['monthly', 'quarterly', 'annual']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) periodType = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _engine.createFinancialPeriod(
                  periodName: nameCtrl.text.trim(),
                  periodType: periodType,
                  fiscalYear: DateTime.now().year,
                  periodNumber: DateTime.now().month,
                  startDate: startDate,
                  endDate: endDate,
                );
                _loadTabData(4);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Period created'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCoaDetails(Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    account['account_name'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            _detailRow('Code', account['account_code'] as String? ?? ''),
            _detailRow(
              'Type',
              (account['account_type'] as String? ?? '').toUpperCase(),
            ),
            _detailRow(
              'Normal Balance',
              (account['normal_balance'] as String? ?? '').toUpperCase(),
            ),
            _detailRow(
              'Current Balance',
              _formatAmount(
                (account['current_balance'] as num?)?.toDouble() ?? 0,
              ),
            ),
            _detailRow('Currency', account['currency'] as String? ?? 'TZS'),
            if (account['description'] != null)
              _detailRow('Description', account['description'] as String),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditAccountDialog(account);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _engine.updateChartAccount(
                        account['id'] as String,
                        {'is_active': false},
                      );
                      _loadTabData(0);
                    },
                    icon: const Icon(Icons.archive, color: Colors.white),
                    label: const Text(
                      'Archive',
                      style: TextStyle(color: Colors.white),
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

  void _showEditAccountDialog(Map<String, dynamic> account) {
    final nameCtrl = TextEditingController(
      text: account['account_name'] as String? ?? '',
    );
    final descCtrl = TextEditingController(
      text: account['description'] as String? ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit Account',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              await _engine.updateChartAccount(account['id'] as String, {
                'account_name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
              });
              _loadTabData(0);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showJournalDetails(Map<String, dynamic> journal) async {
    final lines = await _engine.getJournalLines(journal['id'] as String);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(4.w),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      journal['journal_number'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              _detailRow('Date', journal['journal_date'] as String? ?? ''),
              _detailRow(
                'Type',
                (journal['journal_type'] as String? ?? '').toUpperCase(),
              ),
              _detailRow(
                'Status',
                (journal['status'] as String? ?? '').toUpperCase(),
              ),
              _detailRow(
                'Description',
                journal['description'] as String? ?? '',
              ),
              SizedBox(height: 2.h),
              Text(
                'Journal Lines',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
              const Divider(),
              ...lines.map(
                (line) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.8.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line['account_name'] as String? ?? '',
                              style: GoogleFonts.inter(fontSize: 12.sp),
                            ),
                            Text(
                              line['account_code'] as String? ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ((line['debit_amount'] as num?)?.toDouble() ?? 0) > 0
                            ? _formatAmount(
                                (line['debit_amount'] as num).toDouble(),
                              )
                            : '-',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: AppTheme.success,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        ((line['credit_amount'] as num?)?.toDouble() ?? 0) > 0
                            ? _formatAmount(
                                (line['credit_amount'] as num).toDouble(),
                              )
                            : '-',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (journal['status'] == 'draft') ...[
                SizedBox(height: 2.h),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await _engine.postJournalToLedger(
                        journal['id'] as String,
                      );
                      _loadTabData(1);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Journal posted to ledger'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.publish, color: Colors.white),
                  label: const Text(
                    'Post to Ledger',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              if (journal['status'] == 'posted') ...[
                SizedBox(height: 2.h),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await _engine.reverseJournalEntry(
                        journal['id'] as String,
                      );
                      _loadTabData(1);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Journal reversed'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('Reverse Journal'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _closePeriod(String periodId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Period'),
        content: const Text(
          'Are you sure you want to close this period? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Close Period',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _engine.closePeriod(periodId);
        _loadTabData(4);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Period closed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  Widget _buildFilterChips(
    List<String> options,
    String selected,
    Function(String) onSelect,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(opt.replaceAll('_', ' ').toUpperCase()),
              selected: isSelected,
              onSelected: (_) => onSelect(opt),
              selectedColor: AppTheme.primary.withAlpha(30),
              checkmarkColor: AppTheme.primary,
              labelStyle: GoogleFonts.inter(
                fontSize: 10.sp,
                color: isSelected ? AppTheme.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey.withAlpha(100)),
            SizedBox(height: 2.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _accountTypeColor(String type) {
    switch (type) {
      case 'asset':
        return AppTheme.success;
      case 'liability':
        return Colors.red;
      case 'equity':
        return AppTheme.primary;
      case 'revenue':
        return Colors.teal;
      case 'expense':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _journalStatusColor(String status) {
    switch (status) {
      case 'posted':
        return AppTheme.success;
      case 'approved':
        return AppTheme.primary;
      case 'draft':
        return Colors.orange;
      case 'reversed':
        return Colors.grey;
      case 'locked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

// ─── JOURNAL ENTRY FORM ───────────────────────────────────────────────────────

class _JournalEntryForm extends StatefulWidget {
  final String initialDescription;
  final Function(String description, List<JournalLine> lines, bool autoPost)
  onSave;

  const _JournalEntryForm({
    required this.initialDescription,
    required this.onSave,
  });

  @override
  State<_JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends State<_JournalEntryForm> {
  late TextEditingController _descCtrl;
  final List<_LineItem> _lines = [_LineItem(), _LineItem()];
  bool _autoPost = false;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  double get _totalDebit => _lines.fold(0, (s, l) => s + l.debit);
  double get _totalCredit => _lines.fold(0, (s, l) => s + l.credit);
  bool get _isBalanced => (_totalDebit - _totalCredit).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 4.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 4.w,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'New Journal Entry',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Text(
                  'Journal Lines',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_LineItem())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Line'),
                ),
              ],
            ),
            // Header
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Account',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Debit',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Credit',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
            const Divider(),
            ..._lines.asMap().entries.map((entry) {
              final i = entry.key;
              final line = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: line.accountCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Account code',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: TextField(
                        controller: line.debitCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 11.sp),
                        onChanged: (v) => setState(
                          () => line.debit = double.tryParse(v) ?? 0,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: TextField(
                        controller: line.creditCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 11.sp),
                        onChanged: (v) => setState(
                          () => line.credit = double.tryParse(v) ?? 0,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: _lines.length > 2
                          ? () => setState(() => _lines.removeAt(i))
                          : null,
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              children: [
                Text(
                  'Totals',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
                const Spacer(),
                Text(
                  'Dr: ${_totalDebit.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  'Cr: ${_totalCredit.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  _isBalanced ? Icons.check_circle : Icons.warning,
                  color: _isBalanced ? AppTheme.success : Colors.orange,
                  size: 18,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            SwitchListTile(
              title: Text(
                'Post immediately',
                style: GoogleFonts.inter(fontSize: 12.sp),
              ),
              subtitle: Text(
                'Post to General Ledger now',
                style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
              ),
              value: _autoPost,
              onChanged: (v) => setState(() => _autoPost = v),
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: 1.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBalanced ? AppTheme.primary : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isBalanced && _descCtrl.text.isNotEmpty
                    ? () {
                        final journalLines = _lines
                            .map(
                              (l) => JournalLine(
                                accountCode: l.accountCtrl.text.trim(),
                                accountName: l.accountCtrl.text.trim(),
                                debitAmount: l.debit,
                                creditAmount: l.credit,
                              ),
                            )
                            .toList();
                        Navigator.pop(context);
                        widget.onSave(
                          _descCtrl.text.trim(),
                          journalLines,
                          _autoPost,
                        );
                      }
                    : null,
                child: Text(
                  _autoPost ? 'Post Journal Entry' : 'Save as Draft',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

class _LineItem {
  final accountCtrl = TextEditingController();
  final debitCtrl = TextEditingController();
  final creditCtrl = TextEditingController();
  double debit = 0;
  double credit = 0;
}