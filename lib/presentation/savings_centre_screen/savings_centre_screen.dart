import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/finance_service.dart';
import '../../services/savings_centre_service.dart';
import '../../widgets/cna_shared_components.dart';

class SavingsCentreScreen extends StatefulWidget {
  const SavingsCentreScreen({super.key});

  @override
  State<SavingsCentreScreen> createState() => _SavingsCentreScreenState();
}

class _SavingsCentreScreenState extends State<SavingsCentreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = [];
  Map<String, dynamic> _healthData = {};
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      SavingsCentreService.instance.getSavingsAccounts(),
      SavingsCentreService.instance.getSavingsHealthScore(),
      FinanceService.instance.getFinancialGoals(),
    ]);
    if (mounted) {
      setState(() {
        _accounts = results[0] as List<Map<String, dynamic>>;
        _healthData = results[1] as Map<String, dynamic>;
        _goals = results[2] as List<Map<String, dynamic>>;
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

  Color _parseColor(String? hex) {
    return Color(
      int.tryParse((hex ?? '#1A5F7A').replaceFirst('#', '0xFF')) ?? 0xFF1A5F7A,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'excellent':
        return AppTheme.success;
      case 'good':
        return AppTheme.primaryLight;
      case 'fair':
        return AppTheme.warning;
      default:
        return AppTheme.error;
    }
  }

  void _showAddSavingsSheet() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController();
    String selectedType = 'general';
    bool isSaving = false;

    final types = [
      {'key': 'general', 'label': 'General Savings'},
      {'key': 'emergency', 'label': 'Emergency Fund'},
      {'key': 'goal_linked', 'label': 'Goal-Linked'},
      {'key': 'fixed_deposit', 'label': 'Fixed Deposit'},
      {'key': 'locked', 'label': 'Locked Savings'},
    ];

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Savings Account',
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
                    hintText: 'e.g. Emergency Fund',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Savings Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: types
                      .map(
                        (t) => DropdownMenuItem(
                          value: t['key'],
                          child: Text(t['label']!),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setSheet(() => selectedType = v ?? selectedType),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount (TSh)',
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
                TextField(
                  controller: monthlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monthly Contribution (TSh)',
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
                            if (nameCtrl.text.isEmpty) return;
                            setSheet(() => isSaving = true);
                            await SavingsCentreService.instance
                                .createSavingsAccount(
                                  name: nameCtrl.text.trim(),
                                  type: selectedType,
                                  targetAmount:
                                      double.tryParse(targetCtrl.text) ?? 0,
                                  currentBalance:
                                      double.tryParse(balanceCtrl.text) ?? 0,
                                  monthlyContribution:
                                      double.tryParse(monthlyCtrl.text) ?? 0,
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
                            'Create Savings Account',
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

  void _showDepositSheet(Map<String, dynamic> account) {
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
                      'Deposit to Savings',
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
                const SizedBox(height: 8),
                Text(
                  account['account_name'] as String? ?? '',
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedLight),
                ),
                const SizedBox(height: 16),
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
                            if (amount == null || amount <= 0) return;
                            setSheet(() => isSaving = true);
                            await SavingsCentreService.instance
                                .recordSavingsDeposit(
                                  savingsAccountId: account['id'] as String,
                                  amount: amount,
                                  description: descCtrl.text.isEmpty
                                      ? null
                                      : descCtrl.text,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadData();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
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
                            'Deposit',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = (_healthData['score'] as num?)?.toInt() ?? 0;
    final scoreLabel = _healthData['label'] as String? ?? 'No Data';
    final totalSavings =
        (_healthData['total_savings'] as num?)?.toDouble() ?? 0;
    final availableToSave =
        (_healthData['available_to_save'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
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
                          'Savings Centre',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Enterprise savings management',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadData,
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
                          iconName: 'refresh',
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Health Score Banner
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Savings',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatAmount(totalSavings),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Available to save: ${_formatAmount(availableToSave)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scoreLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
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
                  Tab(text: 'Health'),
                  Tab(text: 'Goals'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const CnaLoadingState(message: 'Loading savings data...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAccountsTab(theme),
                        _buildHealthTab(theme),
                        _buildGoalsTab(theme),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSavingsSheet,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAccountsTab(ThemeData theme) {
    if (_accounts.isEmpty) {
      return CnaEmptyState(
        iconName: 'savings',
        title: 'No Savings Accounts',
        description:
            'Create your first savings account to start building wealth.',
        ctaLabel: 'Add Savings Account',
        onCta: _showAddSavingsSheet,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _accounts.length,
      itemBuilder: (ctx, i) {
        final acc = _accounts[i];
        final balance = (acc['current_balance'] as num?)?.toDouble() ?? 0;
        final target = (acc['target_amount'] as num?)?.toDouble() ?? 0;
        final progress = target > 0 ? (balance / target).clamp(0.0, 1.0) : 0.0;
        final color = _parseColor(acc['color'] as String?);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: acc['icon'] as String? ?? 'savings',
                          color: color,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc['account_name'] as String? ?? 'Savings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            (acc['savings_type'] as String? ?? 'general')
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
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
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        if (target > 0)
                          Text(
                            'of ${_formatAmount(target)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.mutedLight,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (target > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% of target',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDepositSheet(acc),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Deposit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.success,
                          side: const BorderSide(color: AppTheme.success),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.remove, size: 16),
                        label: const Text('Withdraw'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.mutedLight,
                        side: const BorderSide(color: AppTheme.outlineLight),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const CustomIconWidget(
                        iconName: 'more_horiz',
                        color: AppTheme.mutedLight,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthTab(ThemeData theme) {
    final indicators =
        (_healthData['indicators'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final score = (_healthData['score'] as num?)?.toInt() ?? 0;
    final scoreLabel = _healthData['label'] as String? ?? 'No Data';
    final scoreColor = score >= 75
        ? AppTheme.success
        : score >= 60
        ? AppTheme.primaryLight
        : score >= 40
        ? AppTheme.warning
        : AppTheme.error;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings Health Score',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on your savings behavior',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scoreColor.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(color: scoreColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: scoreColor.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                scoreLabel,
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...indicators.map((ind) {
          final status = ind['status'] as String? ?? 'fair';
          final color = _statusColor(status);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ind['label'] as String? ?? '',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ind['description'] as String? ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ind['value'] as String? ?? '',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGoalsTab(ThemeData theme) {
    if (_goals.isEmpty) {
      return CnaEmptyState(
        iconName: 'flag',
        title: 'No Financial Goals',
        description: 'Set financial goals to link with your savings accounts.',
        ctaLabel: 'View Goals',
        onCta: () => context.push(AppRoutes.financialGoalsScreen),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _goals.length,
      itemBuilder: (ctx, i) {
        final goal = _goals[i];
        final target = (goal['target_amount'] as num?)?.toDouble() ?? 0;
        final current = (goal['current_amount'] as num?)?.toDouble() ?? 0;
        final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
        final color = _parseColor(goal['color'] as String?);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal['goal_name'] as String? ?? 'Goal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatAmount(current),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  Text(
                    _formatAmount(target),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
