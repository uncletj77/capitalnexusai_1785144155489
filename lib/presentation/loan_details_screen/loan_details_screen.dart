import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class LoanDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> loan;
  const LoanDetailsScreen({super.key, required this.loan});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.client;
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _repayments = [];
  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _collateralAsset;
  late Map<String, dynamic> _loan;

  // Record payment form
  final _paymentAmountCtrl = TextEditingController();
  bool _isRecordingPayment = false;

  @override
  void initState() {
    super.initState();
    _loan = Map<String, dynamic>.from(widget.loan);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final loanId = _loan['id'] as String;
      final userId = _client.auth.currentUser?.id;

      final repaymentsRes = await _client
          .from('loan_repayments')
          .select()
          .eq('loan_id', loanId)
          .order('payment_date', ascending: false);
      final analysisRes = await _client
          .from('loan_analysis')
          .select()
          .eq('loan_id', loanId)
          .order('analysis_date', ascending: false)
          .limit(1);

      // Refresh loan data
      final loanRes = await _client
          .from('loans')
          .select()
          .eq('id', loanId)
          .single();

      Map<String, dynamic>? collateral;
      if (_loan['collateral_asset_id'] != null) {
        try {
          collateral = await _client
              .from('assets')
              .select()
              .eq('id', _loan['collateral_asset_id'])
              .single();
        } catch (_) {}
      }

      setState(() {
        _loan = loanRes;
        _repayments = List<Map<String, dynamic>>.from(repaymentsRes);
        _analysis = analysisRes.isNotEmpty ? analysisRes.first : null;
        _collateralAsset = collateral;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _progress {
    final principal = (_loan['principal_amount'] as num).toDouble();
    final remaining = (_loan['remaining_balance'] as num).toDouble();
    if (principal <= 0) return 0;
    return ((principal - remaining) / principal).clamp(0.0, 1.0);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(2)}M';
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

  Color _riskColor(String? level) {
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

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_paymentAmountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isRecordingPayment = true);
    try {
      final loanId = _loan['id'] as String;
      final userId = _client.auth.currentUser?.id;
      final remaining = (_loan['remaining_balance'] as num).toDouble();
      final rate = (_loan['interest_rate'] as num).toDouble();
      final interestPortion = remaining * (rate / 100 / 12);
      final principalPortion = (amount - interestPortion).clamp(0.0, amount);
      final newBalance = (remaining - principalPortion).clamp(0.0, remaining);

      await _client.from('loan_repayments').insert({
        'loan_id': loanId,
        'user_id': userId,
        'amount_paid': amount,
        'principal_paid': principalPortion,
        'interest_paid': interestPortion,
        'payment_date': DateTime.now().toIso8601String().split('T')[0],
        'remaining_balance': newBalance,
        'status': 'completed',
      });

      await _client
          .from('loans')
          .update({
            'remaining_balance': newBalance,
            'total_paid': (_loan['total_paid'] as num).toDouble() + amount,
            'total_interest_paid':
                (_loan['total_interest_paid'] as num).toDouble() +
                interestPortion,
            'status': newBalance <= 0 ? 'completed' : 'active',
          })
          .eq('id', loanId);

      _paymentAmountCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      setState(() => _isRecordingPayment = false);
    }
  }

  void _showRecordPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Payment',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Remaining: ${_formatCurrency((_loan['remaining_balance'] as num).toDouble())}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _paymentAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Payment Amount (TZS)',
                  prefixText: 'TSh ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _paymentAmountCtrl.text =
                    (_loan['monthly_payment'] as num).toStringAsFixed(0),
                child: Text(
                  'Use scheduled payment: ${_formatCurrency((_loan['monthly_payment'] as num).toDouble())}',
                  style: const TextStyle(color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRecordingPayment ? null : _recordPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isRecordingPayment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Record Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = _loan['status'] == 'active';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _loan['loan_name'] as String? ?? 'Loan Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
            onPressed: () => context
                .push(AppRoutes.addLoanScreen, extra: _loan)
                .then((_) => _loadData()),
          ),
        ],
      ),
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading loan details...')
          : Column(
              children: [
                _buildLoanHeader(theme, isActive),
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.mutedLight,
                  indicatorColor: AppTheme.primary,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Payments'),
                    Tab(text: 'Analysis'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(theme),
                      _buildPaymentsTab(theme),
                      _buildAnalysisTab(theme),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: isActive
          ? FloatingActionButton.extended(
              onPressed: _showRecordPaymentSheet,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text(
                'Record Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLoanHeader(ThemeData theme, bool isActive) {
    final remaining = (_loan['remaining_balance'] as num).toDouble();
    final principal = (_loan['principal_amount'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceLight,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining Balance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    Text(
                      _formatCurrency(remaining),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'of ${_formatCurrency(principal)} principal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryContainer
                      : AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (_loan['status'] as String? ?? '').toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isActive ? AppTheme.primary : AppTheme.success,
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
                '${(_progress * 100).toStringAsFixed(1)}% repaid',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
              Text(
                '${(100 - _progress * 100).toStringAsFixed(1)}% remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppTheme.outlineLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final monthly = (_loan['monthly_payment'] as num).toDouble();
    final totalPaid = (_loan['total_paid'] as num).toDouble();
    final totalInterest = (_loan['total_interest_paid'] as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(theme, 'Loan Terms', [
            _infoRow(theme, 'Lender', _loan['lender'] as String? ?? '—'),
            _infoRow(
              theme,
              'Category',
              (_loan['loan_category'] as String? ?? '').replaceAll('_', ' '),
            ),
            _infoRow(theme, 'Purpose', _loan['purpose'] as String? ?? '—'),
            _infoRow(
              theme,
              'Interest Rate',
              '${(_loan['interest_rate'] as num).toStringAsFixed(2)}% (${_loan['interest_type']})',
            ),
            _infoRow(theme, 'Term', '${_loan['loan_term_months']} months'),
            _infoRow(
              theme,
              'Frequency',
              (_loan['payment_frequency'] as String? ?? '').replaceAll(
                '_',
                ' ',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard(theme, 'Payment Summary', [
            _infoRow(theme, 'Monthly Payment', _formatCurrency(monthly)),
            _infoRow(theme, 'Total Paid', _formatCurrency(totalPaid)),
            _infoRow(
              theme,
              'Interest Paid',
              _formatCurrency(totalInterest),
              valueColor: AppTheme.warning,
            ),
            _infoRow(
              theme,
              'Principal Paid',
              _formatCurrency(totalPaid - totalInterest),
            ),
            _infoRow(
              theme,
              'Next Due Date',
              _formatDate(_loan['next_due_date'] as String?),
            ),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard(theme, 'Dates', [
            _infoRow(
              theme,
              'Start Date',
              _formatDate(_loan['start_date'] as String?),
            ),
            _infoRow(
              theme,
              'End Date',
              _formatDate(_loan['end_date'] as String?),
            ),
          ]),
          if (_collateralAsset != null) ...[
            const SizedBox(height: 12),
            _buildCollateralCard(theme),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCollateralCard(ThemeData theme) {
    final asset = _collateralAsset!;
    final assetValue = (asset['current_value'] as num).toDouble();
    final loanBalance = (_loan['remaining_balance'] as num).toDouble();
    final ltv = loanBalance / assetValue;
    final isWarning = ltv > 0.8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? AppTheme.warningContainer : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? AppTheme.warning.withAlpha(80)
              : AppTheme.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: isWarning ? AppTheme.warning : AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Collateral',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(theme, 'Asset', asset['asset_name'] as String? ?? '—'),
          _infoRow(theme, 'Asset Value', _formatCurrency(assetValue)),
          _infoRow(theme, 'Loan Balance', _formatCurrency(loanBalance)),
          _infoRow(
            theme,
            'LTV Ratio',
            '${(ltv * 100).toStringAsFixed(1)}%',
            valueColor: isWarning ? AppTheme.warning : AppTheme.success,
          ),
          if (isWarning) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppTheme.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Collateral value is close to loan exposure. Consider revaluation.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_repayments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppTheme.mutedLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No payments recorded yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              'Payment History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._repayments.map((payment) => _buildPaymentTile(theme, payment)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(ThemeData theme, Map<String, dynamic> payment) {
    final status = payment['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';
    final isMissed = status == 'missed';
    final color = isCompleted
        ? AppTheme.success
        : isMissed
        ? AppTheme.error
        : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_outline
                  : isMissed
                  ? Icons.cancel_outlined
                  : Icons.pending_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(payment['payment_date'] as String?),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Principal: ${_formatCurrency((payment['principal_paid'] as num).toDouble())} · Interest: ${_formatCurrency((payment['interest_paid'] as num).toDouble())}',
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
                _formatCurrency((payment['amount_paid'] as num).toDouble()),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                status.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(ThemeData theme) {
    final riskLevel = _analysis?['risk_level'] as String? ?? 'moderate';
    final riskScore = _analysis?['risk_score'] as int? ?? 50;
    final riskColor = _riskColor(riskLevel);
    final recommendations = _analysis?['recommendations'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Loan Risk Score',
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
                        color: riskColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        riskLevel.replaceAll('_', ' ').toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: riskScore / 100,
                        strokeWidth: 10,
                        backgroundColor: riskColor.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$riskScore',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: riskColor,
                            ),
                          ),
                          Text(
                            '/100',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (recommendations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Recommendations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...recommendations.map((rec) {
                    final r = rec as Map<String, dynamic>;
                    final priority = r['priority'] as String? ?? 'low';
                    final color = priority == 'high'
                        ? AppTheme.error
                        : priority == 'medium'
                        ? AppTheme.warning
                        : AppTheme.success;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            priority == 'high'
                                ? Icons.priority_high
                                : priority == 'medium'
                                ? Icons.info_outline
                                : Icons.check_circle_outline,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r['action'] as String? ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.onSurfaceLight,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentAmountCtrl.dispose();
    super.dispose();
  }
}