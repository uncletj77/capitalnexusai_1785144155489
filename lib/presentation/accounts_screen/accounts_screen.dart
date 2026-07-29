import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = [];
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
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      var query = _client
          .from('financial_accounts')
          .select()
          .eq('user_id', userId);
      if (_selectedFilter != 'all') {
        query = query.eq('account_category', _selectedFilter);
      }
      final res = await query.order('created_at', ascending: false);
      setState(() {
        _accounts = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalBalance =>
      _accounts.fold(0, (sum, a) => sum + (a['balance'] as num).toDouble());

  String _formatAmount(double amount) {
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

  void _showAddAccountSheet() {
    final nameCtrl = TextEditingController();
    final providerCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String selectedCategory = 'bank';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. CRDB Savings',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Provider / Bank Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Current Balance (TSh)',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Account Type',
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelMedium?.copyWith(color: AppTheme.mutedLight),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['bank', 'mobile_money', 'cash', 'investment'].map((
                    cat,
                  ) {
                    final isSelected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCategory = cat),
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
                          style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.mutedLight,
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
                    onPressed: () async {
                      final userId = _client.auth.currentUser?.id;
                      if (userId == null || nameCtrl.text.isEmpty) return;
                      await _client.from('financial_accounts').insert({
                        'user_id': userId,
                        'account_name': nameCtrl.text.trim(),
                        'provider': providerCtrl.text.trim(),
                        'balance': double.tryParse(balanceCtrl.text) ?? 0,
                        'account_category': selectedCategory,
                        'currency': 'TZS',
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadAccounts();
                    },
                    child: const Text('Add Account'),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final isSelected = _selectedFilter == f['key'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = f['key'] as String);
                      _loadAccounts();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
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
                        f['label'] as String,
                        style: theme.textTheme.labelMedium?.copyWith(
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
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _accounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CustomIconWidget(
                            iconName: 'account_balance_wallet',
                            color: AppTheme.mutedLight,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No accounts yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.mutedLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _showAddAccountSheet,
                            child: const Text('Add Account'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAccounts,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: _accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _buildAccountCard(theme, _accounts[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(ThemeData theme, Map<String, dynamic> acc) {
    final color = _parseColor(acc['color'] as String?);
    final balance = (acc['balance'] as num).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
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
                iconName: acc['icon'] as String? ?? 'account_balance',
                color: color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc['account_name'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${acc['provider'] ?? (acc['account_category'] as String).replaceAll('_', ' ')} • ${acc['currency'] ?? 'TZS'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
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
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  (acc['account_category'] as String).replaceAll('_', ' '),
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}