import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class LoanDashboardScreen extends StatefulWidget {
  const LoanDashboardScreen({super.key});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _loans = [];
  List<Map<String, dynamic>> _repayments = [];
  Map<String, dynamic>? _healthSnapshot;
  final int _touchedIndex = -1;

  double get _totalDebt => _loans
      .where((l) => l['status'] == 'active')
      .fold(0.0, (s, l) => s + (l['remaining_balance'] as num).toDouble());
  double get _totalMonthlyPayment => _loans
      .where((l) => l['status'] == 'active')
      .fold(0.0, (s, l) => s + (l['monthly_payment'] as num).toDouble());
  int get _activeLoans => _loans.where((l) => l['status'] == 'active').length;
  int get _overdueLoans => _loans.where((l) => l['is_late'] == true).length;

  int get _debtHealthScore {
    if (_healthSnapshot != null) {
      return (_healthSnapshot!['debt_health_score'] as num).toInt();
    }
    return 65;
  }

  String get _riskLevel {
    if (_healthSnapshot != null) {
      return _healthSnapshot!['risk_level'] as String? ?? 'moderate';
    }
    return 'moderate';
  }

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

      final loansRes = await _client
          .from('loans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final repaymentsRes = await _client
          .from('loan_repayments')
          .select()
          .eq('user_id', userId)
          .order('payment_date', ascending: false)
          .limit(20);
      final healthRes = await _client
          .from('debt_health_snapshots')
          .select()
          .eq('user_id', userId)
          .order('snapshot_date', ascending: false)
          .limit(1);

      setState(() {
        _loans = List<Map<String, dynamic>>.from(loansRes);
        _repayments = List<Map<String, dynamic>>.from(repaymentsRes);
        _healthSnapshot = healthRes.isNotEmpty ? healthRes.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'healthy':
        return AppTheme.success;
      case 'moderate':
        return AppTheme.warning;
      case 'high_risk':
        return const Color(0xFFEF4444);
      case 'critical':
        return const Color(0xFF7F1D1D);
      default:
        return AppTheme.warning;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'business':
        return AppTheme.primary;
      case 'asset_financing':
        return AppTheme.fixedAssetColor;
      case 'personal':
        return const Color(0xFFEF4444);
      case 'investment':
        return AppTheme.appreciatingColor;
      case 'mortgage':
        return AppTheme.currentAssetColor;
      default:
        return AppTheme.mutedLight;
    }
  }

  String _formatCurrency(double amount) {
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
    if (dateStr == null) return '—';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '—';
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
  }

  double _repaymentProgress(Map<String, dynamic> loan) {
    final principal = (loan['principal_amount'] as num).toDouble();
    final remaining = (loan['remaining_balance'] as num).toDouble();
    if (principal <= 0) return 0;
    return ((principal - remaining) / principal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading loan data...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(theme),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        _buildDebtSummaryCard(theme),
                        const SizedBox(height: 16),
                        _buildHealthScoreCard(theme),
                        const SizedBox(height: 16),
                        _buildMetricsRow(theme),
                        const SizedBox(height: 16),
                        _buildUpcomingPayments(theme),
                        const SizedBox(height: 16),
                        _buildLoansList(theme),
                        const SizedBox(height: 16),
                        _buildQuickActions(theme),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addLoanScreen),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Loan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan Center',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Liability Intelligence',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.psychology_outlined, color: AppTheme.primary),
          onPressed: () => context.push(AppRoutes.aiDebtAdvisorScreen),
          tooltip: 'AI Debt Advisor',
        ),
        IconButton(
          icon: const Icon(Icons.calculate_outlined, color: AppTheme.primary),
          onPressed: () => context.push(AppRoutes.loanSimulatorScreen),
          tooltip: 'Loan Simulator',
        ),
      ],
    );
  }

  Widget _buildDebtSummaryCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Outstanding Debt',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_activeLoans Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(_totalDebt),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDebtStatChip(
                theme,
                'Monthly Payment',
                _formatCurrency(_totalMonthlyPayment),
                Icons.calendar_month,
              ),
              const SizedBox(width: 12),
              _buildDebtStatChip(
                theme,
                'Overdue',
                '$_overdueLoans loans',
                Icons.warning_amber,
                isWarning: _overdueLoans > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtStatChip(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isWarning
              ? Colors.red.withAlpha(60)
              : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: isWarning
              ? Border.all(color: Colors.red.withAlpha(100))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isWarning ? Colors.redAccent : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(ThemeData theme) {
    final score = _debtHealthScore;
    final risk = _riskLevel;
    final color = _riskColor(risk);
    final dti = _healthSnapshot != null
        ? ((_healthSnapshot!['dti_ratio'] as num).toDouble() * 100)
              .toStringAsFixed(1)
        : '28.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Debt Health Score',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  risk.replaceAll('_', ' ').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: color.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '$score',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRatioRow(
                      theme,
                      'Debt-to-Income',
                      '$dti%',
                      score >= 60 ? AppTheme.success : AppTheme.warning,
                    ),
                    const SizedBox(height: 8),
                    _buildRatioRow(
                      theme,
                      'Debt-to-Assets',
                      _healthSnapshot != null
                          ? '${((_healthSnapshot!['dta_ratio'] as num).toDouble() * 100).toStringAsFixed(1)}%'
                          : '10.2%',
                      AppTheme.success,
                    ),
                    const SizedBox(height: 8),
                    _buildRatioRow(
                      theme,
                      'Repayment Stability',
                      score >= 70 ? 'Stable' : 'Moderate',
                      score >= 70 ? AppTheme.success : AppTheme.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: AppTheme.outlineLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioRow(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedLight,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(ThemeData theme) {
    final totalPaid = _loans.fold(
      0.0,
      (s, l) => s + (l['total_paid'] as num).toDouble(),
    );
    final totalInterest = _loans.fold(
      0.0,
      (s, l) => s + (l['total_interest_paid'] as num).toDouble(),
    );
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            'Total Paid',
            _formatCurrency(totalPaid),
            Icons.check_circle_outline,
            AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            theme,
            'Interest Cost',
            _formatCurrency(totalInterest),
            Icons.trending_up,
            AppTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            theme,
            'Loans',
            '$_activeLoans Active',
            Icons.receipt_long_outlined,
            AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPayments(ThemeData theme) {
    final upcoming =
        _loans
            .where((l) => l['status'] == 'active' && l['next_due_date'] != null)
            .toList()
          ..sort(
            (a, b) => (a['next_due_date'] as String).compareTo(
              b['next_due_date'] as String,
            ),
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Payments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.primary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            Center(
              child: Text(
                'No upcoming payments',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            )
          else
            ...upcoming.take(3).map((loan) {
              final isLate = loan['is_late'] == true;
              final catColor = _categoryColor(
                loan['loan_category'] as String? ?? 'personal',
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLate
                      ? AppTheme.errorContainer
                      : AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(12),
                  border: isLate
                      ? Border.all(color: AppTheme.error.withAlpha(80))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        color: catColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan['loan_name'] as String? ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(loan['next_due_date'] as String?),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isLate
                                  ? AppTheme.error
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(
                            (loan['monthly_payment'] as num).toDouble(),
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isLate
                                ? AppTheme.error
                                : AppTheme.onSurfaceLight,
                          ),
                        ),
                        if (isLate)
                          Text(
                            'OVERDUE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLoansList(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Loans',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push(AppRoutes.loanRepaymentCalendarScreen),
                child: Text(
                  'Calendar',
                  style: TextStyle(color: AppTheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 48,
                      color: AppTheme.mutedLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No loans added yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._loans.map((loan) => _buildLoanTile(theme, loan)),
        ],
      ),
    );
  }

  Widget _buildLoanTile(ThemeData theme, Map<String, dynamic> loan) {
    final progress = _repaymentProgress(loan);
    final catColor = _categoryColor(
      loan['loan_category'] as String? ?? 'personal',
    );
    final isActive = loan['status'] == 'active';

    return GestureDetector(
      onTap: () => context.push(AppRoutes.loanDetailsScreen, extra: loan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: catColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan['loan_name'] as String? ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        loan['lender'] as String? ?? '',
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
                      _formatCurrency(
                        (loan['remaining_balance'] as num).toDouble(),
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryContainer
                            : AppTheme.successContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (loan['status'] as String? ?? '').toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isActive ? AppTheme.primary : AppTheme.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% repaid',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                ),
                Text(
                  '${(loan['interest_rate'] as num).toStringAsFixed(1)}% ${loan['interest_type']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppTheme.outlineLight,
                valueColor: AlwaysStoppedAnimation<Color>(catColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            theme,
            'AI Advisor',
            Icons.psychology_outlined,
            AppTheme.primary,
            () => context.push(AppRoutes.aiDebtAdvisorScreen),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            theme,
            'Receivable',
            Icons.payments_outlined,
            AppTheme.success,
            () => context.push(AppRoutes.loansReceivableScreen),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            theme,
            'Simulator',
            Icons.calculate_outlined,
            AppTheme.fixedAssetColor,
            () => context.push(AppRoutes.loanSimulatorScreen),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            theme,
            'Calendar',
            Icons.calendar_month_outlined,
            AppTheme.appreciatingColor,
            () => context.push(AppRoutes.loanRepaymentCalendarScreen),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
