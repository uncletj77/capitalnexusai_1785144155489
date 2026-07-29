import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/finance_service.dart';
import '../../widgets/cna_shared_components.dart';

class FinancialGoalsScreen extends StatefulWidget {
  const FinancialGoalsScreen({super.key});

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await FinanceService.instance.getFinancialGoals();
    if (mounted) {
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
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

  String _estimateCompletion(Map<String, dynamic> goal) {
    final target = (goal['target_amount'] as num).toDouble();
    final current = (goal['current_amount'] as num).toDouble();
    final monthly = (goal['monthly_contribution'] as num? ?? 0).toDouble();
    if (monthly <= 0) return 'No contribution set';
    final remaining = target - current;
    if (remaining <= 0) return 'Goal reached!';
    final months = (remaining / monthly).ceil();
    if (months < 12) return '$months months';
    return '${(months / 12).toStringAsFixed(1)} years';
  }

  void _showAddGoalSheet() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final currentCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController();
    String selectedCategory = 'savings';
    String selectedPriority = 'medium';
    String selectedColor = '#1A5F7A';
    DateTime? deadline;
    bool isSaving = false;

    final categories = [
      'savings',
      'investment',
      'business',
      'property',
      'education',
      'travel',
      'emergency',
      'retirement',
      'other',
    ];
    final priorities = ['low', 'medium', 'high', 'critical'];
    final colors = [
      '#1A5F7A',
      '#10B981',
      '#F59E0B',
      '#EF4444',
      '#8B5CF6',
      '#EC4899',
      '#2D9CDB',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                      'New Financial Goal',
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
                    labelText: 'Goal Name *',
                    hintText: 'e.g. Buy Land in Dodoma',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount (TSh) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Current Savings (TSh)',
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
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: priorities
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSheetState(
                    () => selectedPriority = v ?? selectedPriority,
                  ),
                ),
                const SizedBox(height: 12),
                // Color picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color',
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: colors.map((c) {
                        final color = Color(
                          int.tryParse(c.replaceFirst('#', '0xFF')) ??
                              0xFF1A5F7A,
                        );
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selectedColor == c
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: selectedColor == c
                                  ? [
                                      BoxShadow(
                                        color: color.withAlpha(100),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) {
                      setSheetState(() => deadline = picked);
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
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deadline != null
                              ? 'Deadline: ${deadline!.day}/${deadline!.month}/${deadline!.year}'
                              : 'Set Deadline (Optional)',
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: deadline != null
                                ? AppTheme.onSurfaceLight
                                : AppTheme.mutedLight,
                          ),
                        ),
                      ],
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
                            if (nameCtrl.text.isEmpty ||
                                targetCtrl.text.isEmpty) {
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            final result = await FinanceService.instance
                                .createGoal(
                                  name: nameCtrl.text.trim(),
                                  targetAmount:
                                      double.tryParse(targetCtrl.text) ?? 0,
                                  currentAmount:
                                      double.tryParse(currentCtrl.text) ?? 0,
                                  monthlyContribution:
                                      double.tryParse(monthlyCtrl.text) ?? 0,
                                  category: selectedCategory,
                                  priority: selectedPriority,
                                  color: selectedColor,
                                  deadline: deadline,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (result != null) _loadGoals();
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditGoalSheet(Map<String, dynamic> goal) {
    final nameCtrl = TextEditingController(text: goal['name'] as String? ?? '');
    final targetCtrl = TextEditingController(
      text: (goal['target_amount'] as num).toDouble().toStringAsFixed(0),
    );
    final currentCtrl = TextEditingController(
      text: (goal['current_amount'] as num).toDouble().toStringAsFixed(0),
    );
    final monthlyCtrl = TextEditingController(
      text: ((goal['monthly_contribution'] as num?) ?? 0)
          .toDouble()
          .toStringAsFixed(0),
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                      'Edit Goal',
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
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
                                title: const Text('Delete Goal'),
                                content: const Text(
                                  'Are you sure you want to delete this goal?',
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
                              await FinanceService.instance.deleteGoal(
                                goal['id'] as String,
                              );
                              _loadGoals();
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.error,
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
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Goal Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Current Savings (TSh)',
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
                const SizedBox(height: 12),
                // Pause/Resume toggle
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final isPaused = goal['is_paused'] == true;
                          await FinanceService.instance.updateGoal(
                            goal['id'] as String,
                            {'is_paused': !isPaused},
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadGoals();
                        },
                        icon: Icon(
                          goal['is_paused'] == true
                              ? Icons.play_arrow
                              : Icons.pause,
                          size: 18,
                        ),
                        label: Text(
                          goal['is_paused'] == true
                              ? 'Resume Goal'
                              : 'Pause Goal',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.warning,
                          side: BorderSide(
                            color: AppTheme.warning.withAlpha(80),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setSheetState(() => isSaving = true);
                            await FinanceService.instance
                                .updateGoal(goal['id'] as String, {
                                  'name': nameCtrl.text.trim(),
                                  'target_amount':
                                      double.tryParse(targetCtrl.text) ?? 0,
                                  'current_amount':
                                      double.tryParse(currentCtrl.text) ?? 0,
                                  'monthly_contribution':
                                      double.tryParse(monthlyCtrl.text) ?? 0,
                                });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadGoals();
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
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
    final activeGoals = _goals
        .where((g) => g['goal_status'] == 'active' && g['is_paused'] != true)
        .length;
    final completedGoals = _goals
        .where((g) => g['goal_status'] == 'completed')
        .length;
    final pausedGoals = _goals.where((g) => g['is_paused'] == true).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const CnaLoadingState(message: 'Loading goals...')
            : RefreshIndicator(
                onRefresh: _loadGoals,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Goals',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$activeGoals active · $completedGoals completed${pausedGoals > 0 ? ' · $pausedGoals paused' : ''}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildSummaryRow(theme)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'Your Goals',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    _goals.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    const CustomIconWidget(
                                      iconName: 'flag',
                                      color: AppTheme.mutedLight,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No goals yet',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: AppTheme.mutedLight,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _showAddGoalSheet,
                                      child: const Text('Create First Goal'),
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
                                  16,
                                ),
                                child: _buildGoalCard(theme, _goals[i]),
                              ),
                              childCount: _goals.length,
                            ),
                          ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    final totalTarget = _goals.fold<double>(
      0,
      (s, g) => s + (g['target_amount'] as num).toDouble(),
    );
    final totalCurrent = _goals.fold<double>(
      0,
      (s, g) => s + (g['current_amount'] as num).toDouble(),
    );
    final overallProgress = totalTarget > 0
        ? (totalCurrent / totalTarget * 100)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              theme,
              'Total Target',
              _formatAmount(totalTarget),
              'flag',
              AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              theme,
              'Saved So Far',
              _formatAmount(totalCurrent),
              'savings',
              AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              theme,
              'Progress',
              '${overallProgress.toInt()}%',
              'percent',
              AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    String icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(ThemeData theme, Map<String, dynamic> goal) {
    final color = _parseColor(goal['color'] as String?);
    final target = (goal['target_amount'] as num).toDouble();
    final current = (goal['current_amount'] as num).toDouble();
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isCompleted = goal['goal_status'] == 'completed';
    final isPaused = goal['is_paused'] == true;
    final estimate = _estimateCompletion(goal);
    final priority = goal['priority'] as String? ?? 'medium';

    Color priorityColor;
    switch (priority) {
      case 'critical':
        priorityColor = AppTheme.error;
        break;
      case 'high':
        priorityColor = AppTheme.warning;
        break;
      case 'low':
        priorityColor = AppTheme.mutedLight;
        break;
      default:
        priorityColor = AppTheme.primary;
    }

    return GestureDetector(
      onTap: () => _showEditGoalSheet(goal),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? AppTheme.success.withAlpha(80)
                : isPaused
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: goal['icon'] as String? ?? 'flag',
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
                        goal['name'] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            (goal['category'] as String? ?? 'savings')
                                .toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.mutedLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: priorityColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
                    color: isCompleted
                        ? AppTheme.successContainer
                        : isPaused
                        ? AppTheme.warningContainer
                        : color.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompleted
                        ? 'DONE'
                        : isPaused
                        ? 'PAUSED'
                        : '${(progress * 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCompleted
                          ? AppTheme.success
                          : isPaused
                          ? AppTheme.warning
                          : color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatAmount(current),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'of ${_formatAmount(target)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.outlineLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppTheme.success : color,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const CustomIconWidget(
                    iconName: 'psychology',
                    color: AppTheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCompleted
                          ? 'Goal achieved! Great financial discipline.'
                          : isPaused
                          ? 'Goal is paused. Resume to continue tracking.'
                          : 'AI Estimate: At your current rate, you will reach this goal in $estimate.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (goal['deadline'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const CustomIconWidget(
                    iconName: 'calendar_today',
                    color: AppTheme.mutedLight,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Deadline: ${goal['deadline']}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
