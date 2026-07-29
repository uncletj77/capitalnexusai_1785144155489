import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/finance_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _budgets = [];
  Map<String, double> _actualSpending = {};

  @override
  void initState() {
    super.initState();
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

      final budgetsWithSpending = await FinanceService.instance
          .getBudgetsWithSpending();

      final Map<String, double> spending = {};
      for (final b in budgetsWithSpending) {
        final cat = b['category'] as String? ?? 'other';
        spending[cat] = (b['actual_spent'] as num?)?.toDouble() ?? 0;
      }

      setState(() {
        _budgets = budgetsWithSpending;
        _actualSpending = spending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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

  double get _totalPlanned =>
      _budgets.fold(0, (s, b) => s + (b['planned_amount'] as num).toDouble());
  double get _totalActual => _actualSpending.values.fold(0, (s, v) => s + v);

  void _showAddBudgetSheet() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCategory = 'food';

    final categories = [
      'food',
      'housing',
      'transport',
      'utilities',
      'savings',
      'investments',
      'business',
      'entertainment',
      'health',
      'education',
      'other',
    ];

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
                      'Add Budget',
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
                    labelText: 'Budget Name',
                    hintText: 'e.g. Monthly Food',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Planned Amount (TSh)',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Category',
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelMedium?.copyWith(color: AppTheme.mutedLight),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => selectedCategory = v ?? 'food'),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId = _client.auth.currentUser?.id;
                      if (userId == null ||
                          nameCtrl.text.isEmpty ||
                          amountCtrl.text.isEmpty) {
                        return;
                      }
                      await _client.from('budgets').insert({
                        'user_id': userId,
                        'name': nameCtrl.text.trim(),
                        'category': selectedCategory,
                        'planned_amount': double.tryParse(amountCtrl.text) ?? 0,
                        'period': 'monthly',
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    },
                    child: const Text('Add Budget'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetSheet,
        child: const CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const CnaLoadingState(message: 'Loading budget data...')
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget Planner',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Track planned vs actual spending',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildSummaryCard(theme)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'Budget Categories',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    _budgets.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    const CustomIconWidget(
                                      iconName: 'pie_chart',
                                      color: AppTheme.mutedLight,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No budgets yet',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: AppTheme.mutedLight,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _showAddBudgetSheet,
                                      child: const Text('Create Budget'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  12,
                                ),
                                child: _buildBudgetCard(theme, _budgets[i]),
                              ),
                              childCount: _budgets.length,
                            ),
                          ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final overallProgress = _totalPlanned > 0
        ? (_totalActual / _totalPlanned).clamp(0.0, 1.0)
        : 0.0;
    final isOver = _totalActual > _totalPlanned;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Budget Overview',
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planned',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    _formatAmount(_totalPlanned),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Spent',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    _formatAmount(_totalActual),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isOver
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF4ADE80),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? const Color(0xFFFCA5A5) : const Color(0xFF4ADE80),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOver
                ? 'Over budget by ${_formatAmount(_totalActual - _totalPlanned)}'
                : 'Remaining: ${_formatAmount(_totalPlanned - _totalActual)} (${((1 - overallProgress) * 100).toInt()}%)',
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(ThemeData theme, Map<String, dynamic> budget) {
    final color = _parseColor(budget['color'] as String?);
    final planned = (budget['planned_amount'] as num).toDouble();
    final category = budget['category'] as String? ?? 'other';
    final actual = _actualSpending[category] ?? 0;
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    final isOver = actual > planned;
    final progressColor = isOver
        ? AppTheme.error
        : (progress > 0.8 ? AppTheme.warning : color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver ? AppTheme.error.withAlpha(80) : AppTheme.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: _categoryIcon(category),
                    color: color,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget['name'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'OVER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatAmount(actual),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'of ${_formatAmount(planned)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.outlineLight,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isOver
                ? 'Exceeded by ${_formatAmount(actual - planned)}'
                : '${_formatAmount(planned - actual)} remaining',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isOver ? AppTheme.error : AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryIcon(String category) {
    const icons = {
      'food': 'restaurant',
      'housing': 'home',
      'transport': 'directions_car',
      'utilities': 'bolt',
      'savings': 'savings',
      'investments': 'trending_up',
      'business': 'business',
      'entertainment': 'movie',
      'health': 'health_and_safety',
      'education': 'school',
      'salaries': 'people',
      'fuel': 'local_gas_station',
      'maintenance': 'build',
      'insurance': 'shield',
      'loan_payment': 'account_balance',
    };
    return icons[category] ?? 'category';
  }
}