import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class LoanSimulatorScreen extends StatefulWidget {
  const LoanSimulatorScreen({super.key});

  @override
  State<LoanSimulatorScreen> createState() => _LoanSimulatorScreenState();
}

class _LoanSimulatorScreenState extends State<LoanSimulatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _client = SupabaseService.client;

  // New loan simulation
  final _amountCtrl = TextEditingController(text: '50000000');
  final _rateCtrl = TextEditingController(text: '18');
  final _termCtrl = TextEditingController(text: '36');
  String _interestType = 'compound';
  final String _purpose = 'Business expansion';
  bool _hasSimulated = false;

  // Early repayment simulation
  final _extraPaymentCtrl = TextEditingController(text: '500000');
  String? _selectedLoanId;
  List<Map<String, dynamic>> _activeLoans = [];
  bool _hasSimulatedEarly = false;

  // Results
  double _monthlyPayment = 0;
  double _totalRepayment = 0;
  double _totalInterest = 0;
  double _monthsToPayoff = 0;
  double _interestSaved = 0;
  String _affordabilityStatus = '';
  Color _affordabilityColor = AppTheme.success;
  double _dtiAfterLoan = 0;

  // User financial context
  double _monthlyIncome = 0;
  double _existingMonthlyDebt = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final monthStart = DateTime(
        now.year,
        now.month,
        1,
      ).toIso8601String().split('T')[0];

      final txRes = await _client
          .from('financial_transactions')
          .select('amount, transaction_type')
          .eq('user_id', userId)
          .gte('transaction_date', monthStart);
      final loansRes = await _client
          .from('loans')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active');

      double income = 0;
      for (final t in txRes) {
        if (t['transaction_type'] == 'income') {
          income += (t['amount'] as num).toDouble();
        }
      }

      double existingDebt = 0;
      for (final l in loansRes) {
        existingDebt += (l['monthly_payment'] as num).toDouble();
      }

      setState(() {
        _monthlyIncome = income > 0 ? income : 15500000;
        _existingMonthlyDebt = existingDebt;
        _activeLoans = List<Map<String, dynamic>>.from(loansRes);
        if (_activeLoans.isNotEmpty) {
          _selectedLoanId = _activeLoans.first['id'] as String;
        }
      });
    } catch (_) {
      setState(() {
        _monthlyIncome = 15500000;
        _existingMonthlyDebt = 4345000;
      });
    }
  }

  void _simulateNewLoan() {
    final principal = double.tryParse(_amountCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final term = int.tryParse(_termCtrl.text) ?? 12;

    if (principal <= 0 || term <= 0) return;

    double monthly = 0;
    if (_interestType == 'simple') {
      final totalInterest = principal * (rate / 100) * (term / 12);
      monthly = (principal + totalInterest) / term;
    } else {
      final monthlyRate = rate / 100 / 12;
      if (monthlyRate == 0) {
        monthly = principal / term;
      } else {
        monthly =
            principal *
            monthlyRate *
            _pow(1 + monthlyRate, term) /
            (_pow(1 + monthlyRate, term) - 1);
      }
    }

    final totalRep = monthly * term;
    final totalInt = totalRep - principal;
    final newDti = (_existingMonthlyDebt + monthly) / _monthlyIncome;

    String status;
    Color color;
    if (newDti < 0.30) {
      status =
          'Affordable — DTI ratio is healthy at ${(newDti * 100).toStringAsFixed(1)}%';
      color = AppTheme.success;
    } else if (newDti < 0.40) {
      status =
          'Moderate risk — DTI will be ${(newDti * 100).toStringAsFixed(1)}%. Manageable but monitor closely.';
      color = AppTheme.warning;
    } else if (newDti < 0.50) {
      status =
          'High risk — DTI will reach ${(newDti * 100).toStringAsFixed(1)}%. Consider a smaller loan.';
      color = const Color(0xFFEF4444);
    } else {
      status =
          'Critical — DTI will exceed ${(newDti * 100).toStringAsFixed(1)}%. This loan is not recommended.';
      color = const Color(0xFF7F1D1D);
    }

    setState(() {
      _monthlyPayment = monthly;
      _totalRepayment = totalRep;
      _totalInterest = totalInt;
      _affordabilityStatus = status;
      _affordabilityColor = color;
      _dtiAfterLoan = newDti;
      _hasSimulated = true;
    });
  }

  void _simulateEarlyRepayment() {
    if (_selectedLoanId == null) return;
    final loan = _activeLoans.firstWhere(
      (l) => l['id'] == _selectedLoanId,
      orElse: () => {},
    );
    if (loan.isEmpty) return;

    final extra = double.tryParse(_extraPaymentCtrl.text) ?? 0;
    final remaining = (loan['remaining_balance'] as num).toDouble();
    final rate = (loan['interest_rate'] as num).toDouble();
    final monthly = (loan['monthly_payment'] as num).toDouble();
    final monthlyRate = rate / 100 / 12;

    // Calculate months without extra payment
    double bal = remaining;
    int normalMonths = 0;
    while (bal > 0 && normalMonths < 600) {
      final interest = bal * monthlyRate;
      bal -= (monthly - interest);
      normalMonths++;
    }

    // Calculate months with extra payment
    bal = remaining;
    int extraMonths = 0;
    double totalInterestWithExtra = 0;
    double totalInterestNormal = 0;

    // Normal interest
    bal = remaining;
    for (int i = 0; i < normalMonths; i++) {
      final interest = bal * monthlyRate;
      totalInterestNormal += interest;
      bal -= (monthly - interest);
    }

    // With extra
    bal = remaining;
    while (bal > 0 && extraMonths < 600) {
      final interest = bal * monthlyRate;
      totalInterestWithExtra += interest;
      bal -= (monthly + extra - interest);
      extraMonths++;
    }

    setState(() {
      _monthsToPayoff = extraMonths.toDouble();
      _interestSaved = totalInterestNormal - totalInterestWithExtra;
      _hasSimulatedEarly = true;
    });
  }

  double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Loan Simulator',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surfaceLight,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.mutedLight,
              indicatorColor: AppTheme.primary,
              tabs: const [
                Tab(text: 'New Loan'),
                Tab(text: 'Early Repayment'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewLoanTab(theme),
                _buildEarlyRepaymentTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewLoanTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Test any loan scenario before committing. Your current monthly income: ${_formatCurrency(_monthlyIncome)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSimField(
            theme,
            'Loan Amount (TZS)',
            _amountCtrl,
            hint: '50,000,000',
          ),
          const SizedBox(height: 16),
          _buildSimField(
            theme,
            'Annual Interest Rate (%)',
            _rateCtrl,
            hint: '18.0',
          ),
          const SizedBox(height: 16),
          _buildSimField(theme, 'Loan Term (months)', _termCtrl, hint: '36'),
          const SizedBox(height: 16),
          Text(
            'Interest Type',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['fixed', 'variable', 'simple', 'compound'].map((t) {
              final isSelected = _interestType == t;
              return GestureDetector(
                onTap: () => setState(() => _interestType = t),
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
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Text(
                    t.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? Colors.white : AppTheme.mutedLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _simulateNewLoan,
              icon: const Icon(Icons.calculate, color: Colors.white),
              label: const Text(
                'Simulate Loan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_hasSimulated) ...[
            const SizedBox(height: 20),
            _buildSimResults(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSimResults(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulation Results',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _affordabilityColor.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _affordabilityColor.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(
                _dtiAfterLoan < 0.40
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                color: _affordabilityColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _affordabilityStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _affordabilityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: [
              _resultRow(
                theme,
                'Monthly Payment',
                _formatCurrency(_monthlyPayment),
                AppTheme.primary,
              ),
              const Divider(height: 16),
              _resultRow(
                theme,
                'Total Repayment',
                _formatCurrency(_totalRepayment),
                AppTheme.onSurfaceLight,
              ),
              _resultRow(
                theme,
                'Total Interest Cost',
                _formatCurrency(_totalInterest),
                AppTheme.warning,
              ),
              _resultRow(
                theme,
                'Cost of Borrowing',
                '${(_totalInterest / (double.tryParse(_amountCtrl.text) ?? 1) * 100).toStringAsFixed(1)}%',
                AppTheme.warning,
              ),
              const Divider(height: 16),
              _resultRow(
                theme,
                'DTI After Loan',
                '${(_dtiAfterLoan * 100).toStringAsFixed(1)}%',
                _affordabilityColor,
              ),
              _resultRow(
                theme,
                'Existing Monthly Debt',
                _formatCurrency(_existingMonthlyDebt),
                AppTheme.mutedLight,
              ),
              _resultRow(
                theme,
                'Monthly Income',
                _formatCurrency(_monthlyIncome),
                AppTheme.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.addLoanScreen),
            icon: const Icon(Icons.add, color: AppTheme.primary),
            label: const Text(
              'Add This Loan',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarlyRepaymentTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.savings_outlined,
                  color: AppTheme.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'See how much interest you save by paying extra each month',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_activeLoans.isEmpty)
            Center(
              child: Text(
                'No active loans found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedLight,
                ),
              ),
            )
          else ...[
            Text(
              'Select Loan',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLoanId,
                  isExpanded: true,
                  onChanged: (v) => setState(() => _selectedLoanId = v),
                  items: _activeLoans
                      .map(
                        (loan) => DropdownMenuItem<String>(
                          value: loan['id'] as String,
                          child: Text(
                            loan['loan_name'] as String? ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSimField(
              theme,
              'Extra Monthly Payment (TZS)',
              _extraPaymentCtrl,
              hint: '500,000',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simulateEarlyRepayment,
                icon: const Icon(Icons.trending_down, color: Colors.white),
                label: const Text(
                  'Calculate Savings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_hasSimulatedEarly) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withAlpha(20),
                      AppTheme.appreciatingColor.withAlpha(20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.success.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Early Repayment Results',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _resultRow(
                      theme,
                      'Months to Pay Off',
                      '${_monthsToPayoff.toInt()} months',
                      AppTheme.primary,
                    ),
                    _resultRow(
                      theme,
                      'Interest Saved',
                      _formatCurrency(_interestSaved),
                      AppTheme.success,
                    ),
                    _resultRow(
                      theme,
                      'Extra Monthly Payment',
                      _formatCurrency(
                        double.tryParse(_extraPaymentCtrl.text) ?? 0,
                      ),
                      AppTheme.onSurfaceLight,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppTheme.success,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'By paying ${_formatCurrency(double.tryParse(_extraPaymentCtrl.text) ?? 0)} extra per month, you save ${_formatCurrency(_interestSaved)} in interest and pay off ${_monthsToPayoff.toInt()} months early.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSimField(
    ThemeData theme,
    String label,
    TextEditingController ctrl, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariantLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultRow(
    ThemeData theme,
    String label,
    String value,
    Color valueColor,
  ) {
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
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _termCtrl.dispose();
    _extraPaymentCtrl.dispose();
    super.dispose();
  }
}