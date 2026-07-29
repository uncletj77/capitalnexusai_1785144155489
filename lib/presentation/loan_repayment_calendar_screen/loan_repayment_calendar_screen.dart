import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class LoanRepaymentCalendarScreen extends StatefulWidget {
  const LoanRepaymentCalendarScreen({super.key});

  @override
  State<LoanRepaymentCalendarScreen> createState() =>
      _LoanRepaymentCalendarScreenState();
}

class _LoanRepaymentCalendarScreenState
    extends State<LoanRepaymentCalendarScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _loans = [];
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final res = await _client
          .from('loans')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('next_due_date');
      setState(() {
        _loans = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getPaymentsForMonth(DateTime month) {
    return _loans.where((loan) {
      final nextDue = loan['next_due_date'] as String?;
      if (nextDue == null) return false;
      final d = DateTime.tryParse(nextDue);
      if (d == null) return false;
      return d.month == month.month && d.year == month.year;
    }).toList();
  }

  double _totalForMonth(DateTime month) {
    return _getPaymentsForMonth(
      month,
    ).fold(0.0, (s, l) => s + (l['monthly_payment'] as num).toDouble());
  }

  String _formatCurrency(double amount) {
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
      default:
        return AppTheme.mutedLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthPayments = _getPaymentsForMonth(_selectedMonth);
    final monthTotal = _totalForMonth(_selectedMonth);
    const monthNames = [
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Repayment Calendar',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month navigator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(
                                () => _selectedMonth = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month - 1,
                                ),
                              ),
                            ),
                            Text(
                              '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(
                                () => _selectedMonth = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month + 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Due: ${_formatCurrency(monthTotal)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${monthPayments.length} payment${monthPayments.length != 1 ? 's' : ''} this month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scheduled Payments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (monthPayments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 48,
                              color: AppTheme.mutedLight,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No payments due this month',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...monthPayments.map((loan) {
                      final catColor = _categoryColor(
                        loan['loan_category'] as String? ?? 'personal',
                      );
                      final isLate = loan['is_late'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isLate
                              ? AppTheme.errorContainer
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isLate
                                ? AppTheme.error.withAlpha(80)
                                : AppTheme.outlineLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: catColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  (loan['next_due_date'] as String? ?? '')
                                      .split('-')
                                      .last,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: catColor,
                                    fontWeight: FontWeight.w800,
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
                                    loan['loan_name'] as String? ?? '',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${loan['lender']} · ${_formatDate(loan['next_due_date'] as String?)}',
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
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  // 6-month outlook
                  Text(
                    '6-Month Outlook',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(6, (i) {
                    final month = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + i,
                    );
                    final payments = _getPaymentsForMonth(month);
                    final total = _totalForMonth(month);
                    final isCurrentMonth =
                        month.month == DateTime.now().month &&
                        month.year == DateTime.now().year;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentMonth
                            ? AppTheme.primaryContainer
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentMonth
                              ? AppTheme.primary.withAlpha(60)
                              : AppTheme.outlineLight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (isCurrentMonth)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                ),
                              Text(
                                '${monthNames[month.month - 1]} ${month.year}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isCurrentMonth
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isCurrentMonth
                                      ? AppTheme.primary
                                      : AppTheme.onSurfaceLight,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${payments.length} loans',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedLight,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatCurrency(total),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isCurrentMonth
                                      ? AppTheme.primary
                                      : AppTheme.onSurfaceLight,
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
            ),
    );
  }
}