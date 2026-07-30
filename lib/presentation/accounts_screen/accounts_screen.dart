import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/enterprise_reconciliation_service.dart';
import '../../services/finance_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cna_shared_components.dart';
import '../../widgets/custom_icon_widget.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transfers = [];
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'All', 'icon': 'account_balance_wallet'},
    {'key': 'bank', 'label': 'Bank', 'icon': 'account_balance'},
    {'key': 'mobile_money', 'label': 'Mobile', 'icon': 'phone_android'},
    {'key': 'cash', 'label': 'Cash', 'icon': 'payments'},
    {'key': 'investment', 'label': 'Invest', 'icon': 'trending_up'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      FinanceService.instance.getAccountsWithBalances(
        category: _selectedFilter == 'all' ? null : _selectedFilter,
      ),
      EnterpriseReconciliationService.instance.getAccountTransfers(limit: 30),
    ]);
    if (mounted) {
      setState(() {
        _accounts = results[0];
        _transfers = results[1];
        _isLoading = false;
      });
    }
  }

  double get _totalBalance => _accounts.fold(
    0.0,
    (sum, a) => sum + ((a['calculated_balance'] as num?)?.toDouble() ?? 0),
  );

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

  Color _parseColor(String? hex) {
    return Color(
      int.tryParse((hex ?? '#1A5F7A').replaceFirst('#', '0xFF')) ?? 0xFF1A5F7A,
    );
  }

  String _categoryIcon(String? cat) {
    switch (cat) {
      case 'bank':
        return 'account_balance';
      case 'mobile_money':
        return 'phone_android';
      case 'cash':
        return 'payments';
      case 'investment':
        return 'trending_up';
      default:
        return 'account_balance_wallet';
    }
  }

  void _showAddAccountSheet() {
    final nameCtrl = TextEditingController();
    final providerCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String selectedCategory = 'bank';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Account',
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Account Name *',
                    hintText: 'e.g. CRDB Savings',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerCtrl,
                  decoration: InputDecoration(
                    labelText: 'Provider / Bank Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Current Balance (TSh)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Account Type',
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelMedium?.copyWith(color: AppTheme.mutedLight),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        'bank',
                        'mobile_money',
                        'cash',
                        'investment',
                        'savings',
                      ].map((cat) {
                        final isSelected = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setSheet(() => selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.mutedLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.isEmpty) return;
                            setSheet(() => isSaving = true);
                            await FinanceService.instance.createAccount(
                              name: nameCtrl.text.trim(),
                              category: selectedCategory,
                              provider: providerCtrl.text.trim().isEmpty
                                  ? null
                                  : providerCtrl.text.trim(),
                              initialBalance:
                                  double.tryParse(balanceCtrl.text) ?? 0,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadData();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Add Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransferSheet() {
    if (_accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 2 accounts to transfer'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    String? fromAccountId = _accounts[0]['id'] as String?;
    String? toAccountId = _accounts.length > 1
        ? _accounts[1]['id'] as String?
        : null;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transfer Funds',
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: fromAccountId,
                  decoration: InputDecoration(
                    labelText: 'From Account',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _accounts
                      .map(
                        (a) => DropdownMenuItem(
                          value: a['id'] as String,
                          child: Text(
                            '${a['account_name']} (${_formatAmount((a['calculated_balance'] as num?)?.toDouble() ?? 0)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSheet(() => fromAccountId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: toAccountId,
                  decoration: InputDecoration(
                    labelText: 'To Account',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _accounts
                      .where((a) => a['id'] != fromAccountId)
                      .map(
                        (a) => DropdownMenuItem(
                          value: a['id'] as String,
                          child: Text(
                            a['account_name'] as String? ?? 'Account',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSheet(() => toAccountId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount (TSh) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final amount = double.tryParse(amountCtrl.text);
                            if (amount == null ||
                                amount <= 0 ||
                                fromAccountId == null ||
                                toAccountId == null) {
                              return;
                            }
                            if (fromAccountId == toAccountId) return;
                            setSheet(() => isSaving = true);
                            final success =
                                await EnterpriseReconciliationService.instance
                                    .executeAccountTransfer(
                                      fromAccountId: fromAccountId!,
                                      toAccountId: toAccountId!,
                                      amount: amount,
                                      description: descCtrl.text.isEmpty
                                          ? null
                                          : descCtrl.text,
                                    );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Transfer completed successfully'
                                        : 'Transfer failed',
                                  ),
                                  backgroundColor: success
                                      ? AppTheme.success
                                      : AppTheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            _loadData();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Execute Transfer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAccountSheet(Map<String, dynamic> account) {
    final nameCtrl = TextEditingController(
      text: account['account_name'] as String? ?? '',
    );
    final providerCtrl = TextEditingController(
      text: account['provider'] as String? ?? '',
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Account',
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerCtrl,
                  decoration: InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setSheet(() => isSaving = true);
                            await FinanceService.instance
                                .updateAccount(account['id'] as String, {
                                  'account_name': nameCtrl.text.trim(),
                                  'provider': providerCtrl.text.trim(),
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
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Archive button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Archive Account'),
                          content: const Text(
                            'This account will be archived. All transactions will be preserved.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text(
                                'Archive',
                                style: TextStyle(color: AppTheme.warning),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FinanceService.instance.archiveAccount(
                          account['id'] as String,
                        );
                        _loadData();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                      side: const BorderSide(color: AppTheme.warning),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Archive Account'),
                  ),
                ),
                const SizedBox(height: 10),
                // Delete button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                            'This will permanently delete the account. Transaction history will be preserved but unlinked from this account.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deleteAccount(account['id'] as String);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Delete Account'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(String accountId) async {
    try {
      // Soft-delete: mark as inactive (no status column in financial_accounts)
      await FinanceService.instance.updateAccount(accountId, {
        'is_active': false,
        'is_archived': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
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
                        border: Border.all(color: AppTheme.outlineLight),
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
                          'Accounts',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Total: ${_formatAmount(_totalBalance)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showTransferSheet,
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
                          iconName: 'swap_horiz',
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showAddAccountSheet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CustomIconWidget(
                          iconName: 'add',
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final f = _filters[i];
                  final isSelected = _selectedFilter == f['key'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = f['key'] as String);
                      _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.outlineLight,
                        ),
                      ),
                      child: Text(
                        f['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.mutedLight,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.mutedLight,
                indicator: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                tabs: const [
                  Tab(text: 'Accounts'),
                  Tab(text: 'Transfers'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const CnaLoadingState(message: 'Loading accounts...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAccountsTab(theme),
                        _buildTransfersTab(theme),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsTab(ThemeData theme) {
    if (_accounts.isEmpty) {
      return CnaEmptyState(
        iconName: 'account_balance_wallet',
        title: 'No Accounts',
        description:
            'Add your first financial account to start tracking your money.',
        ctaLabel: 'Add Account',
        onCta: _showAddAccountSheet,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _accounts.length,
        itemBuilder: (ctx, i) {
          final acc = _accounts[i];
          final balance = (acc['calculated_balance'] as num?)?.toDouble() ?? 0;
          final color = _parseColor(acc['color'] as String?);
          final category = acc['account_category'] as String? ?? 'bank';

          return GestureDetector(
            onTap: () => _showEditAccountSheet(acc),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName:
                            acc['icon'] as String? ?? _categoryIcon(category),
                        color: color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acc['account_name'] as String? ?? 'Account',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(acc['provider'] as String? ?? '').isNotEmpty ? acc['provider'] : category.replaceAll('_', ' ')} • ${acc['currency'] ?? 'TZS'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(balance),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: balance >= 0
                              ? AppTheme.primary
                              : AppTheme.error,
                        ),
                      ),
                      Text(
                        category.replaceAll('_', ' ').toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransfersTab(ThemeData theme) {
    if (_transfers.isEmpty) {
      return CnaEmptyState(
        iconName: 'swap_horiz',
        title: 'No Transfers',
        description: 'Transfer funds between accounts using the swap button.',
        ctaLabel: 'New Transfer',
        onCta: _showTransferSheet,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _transfers.length,
      itemBuilder: (ctx, i) {
        final t = _transfers[i];
        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
        final date = t['transfer_date'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'swap_horiz',
                    color: AppTheme.primary,
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
                      t['description'] as String? ?? 'Account Transfer',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatAmount(amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
