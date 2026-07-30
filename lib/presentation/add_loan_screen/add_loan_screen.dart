import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../repositories/loan_repository.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AddLoanScreen extends StatefulWidget {
  final Map<String, dynamic>? existingLoan;
  const AddLoanScreen({super.key, this.existingLoan});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _loanRepo = LoanRepository.instance;
  final _client = SupabaseService.client;
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1 - Basic Info
  final _loanNameCtrl = TextEditingController();
  final _lenderCtrl = TextEditingController();
  String _loanCategory = 'personal';
  String _purpose = 'Emergency';

  // Step 2 - Financial Info
  final _principalCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  String _interestType = 'fixed';
  final _termCtrl = TextEditingController(text: '12');
  String _paymentFrequency = 'monthly';
  DateTime _startDate = DateTime.now();

  // Step 3 - Repayment
  final _monthlyPaymentCtrl = TextEditingController();
  String _paymentMethod = 'bank_transfer';
  DateTime? _nextDueDate;

  // Step 4 - Collateral
  List<Map<String, dynamic>> _assets = [];
  String? _selectedCollateralId;
  final _notesCtrl = TextEditingController();

  final List<String> _categories = [
    'personal',
    'business',
    'asset_financing',
    'investment',
    'mortgage',
    'informal',
  ];
  final List<String> _purposes = [
    'Business expansion',
    'Asset purchase',
    'Education',
    'Emergency',
    'Investment',
    'Home improvement',
    'Medical',
    'Other',
  ];
  final List<String> _interestTypes = [
    'fixed',
    'variable',
    'simple',
    'compound',
  ];
  final List<String> _frequencies = [
    'weekly',
    'bi_weekly',
    'monthly',
    'quarterly',
    'annually',
  ];
  final List<String> _paymentMethods = [
    'bank_transfer',
    'mobile_money',
    'cash',
    'cheque',
  ];

  @override
  void initState() {
    super.initState();
    _loadAssets();
    if (widget.existingLoan != null) _populateExisting();
  }

  void _populateExisting() {
    final l = widget.existingLoan!;
    _loanNameCtrl.text = l['loan_name'] ?? '';
    _lenderCtrl.text = l['lender'] ?? '';
    _loanCategory = l['loan_category'] ?? 'personal';
    _purpose = l['purpose'] ?? 'Emergency';
    _principalCtrl.text = (l['principal_amount'] ?? 0).toString();
    _interestRateCtrl.text = (l['interest_rate'] ?? 0).toString();
    _interestType = l['interest_type'] ?? 'fixed';
    _termCtrl.text = (l['loan_term_months'] ?? 12).toString();
    _paymentFrequency = l['payment_frequency'] ?? 'monthly';
    _monthlyPaymentCtrl.text = (l['monthly_payment'] ?? 0).toString();
    _paymentMethod = l['payment_method'] ?? 'bank_transfer';
    _notesCtrl.text = l['notes'] ?? '';
    _selectedCollateralId = l['collateral_asset_id'];
    // Fix: populate start date from existing loan
    if (l['start_date'] != null) {
      _startDate =
          DateTime.tryParse(l['start_date'] as String) ?? DateTime.now();
    } else if (l['created_at'] != null) {
      _startDate =
          DateTime.tryParse(l['created_at'] as String) ?? DateTime.now();
    }
    // Fix: populate next due date from existing loan
    if (l['next_due_date'] != null) {
      _nextDueDate = DateTime.tryParse(l['next_due_date'] as String);
    }
  }

  Future<void> _loadAssets() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _client
          .from('assets')
          .select('id, asset_name, current_value')
          .eq('user_id', userId)
          .neq('asset_status', 'disposed');
      setState(() => _assets = List<Map<String, dynamic>>.from(res));
    } catch (_) {}
  }

  void _calculateMonthlyPayment() {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final rate = double.tryParse(_interestRateCtrl.text) ?? 0;
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
            (1 + monthlyRate).pow(term) /
            ((1 + monthlyRate).pow(term) - 1);
      }
    }
    _monthlyPaymentCtrl.text = monthly.toStringAsFixed(0);
  }

  Future<void> _saveLoan() async {
    setState(() => _isSaving = true);
    try {
      final principal = double.tryParse(_principalCtrl.text) ?? 0;
      final monthly = double.tryParse(_monthlyPaymentCtrl.text) ?? 0;
      final interestRate = double.tryParse(_interestRateCtrl.text) ?? 0;
      final termMonths = int.tryParse(_termCtrl.text) ?? 12;

      if (_loanNameCtrl.text.trim().isEmpty) {
        throw Exception('Loan name is required');
      }
      if (principal <= 0) throw Exception('Principal amount must be positive');

      if (widget.existingLoan != null) {
        await _loanRepo.updateLoan(widget.existingLoan!['id'] as String, {
          'loan_name': _loanNameCtrl.text.trim(),
          'lender': _lenderCtrl.text.trim(),
          'loan_category': _loanCategory,
          'purpose': _purpose,
          'principal_amount': principal,
          'interest_rate': interestRate,
          'interest_type': _interestType,
          'loan_term_months': termMonths,
          'payment_frequency': _paymentFrequency,
          'monthly_payment': monthly,
          'next_due_date': _nextDueDate?.toIso8601String().split('T')[0],
          'payment_method': _paymentMethod,
          'collateral_asset_id': _selectedCollateralId,
          'notes': _notesCtrl.text.trim(),
        });
      } else {
        await _loanRepo.createLoan(
          loanName: _loanNameCtrl.text.trim(),
          lender: _lenderCtrl.text.trim(),
          loanCategory: _loanCategory,
          purpose: _purpose,
          principalAmount: principal,
          interestRate: interestRate,
          interestType: _interestType,
          loanTermMonths: termMonths,
          paymentFrequency: _paymentFrequency,
          monthlyPayment: monthly,
          paymentMethod: _paymentMethod,
          startDate: _startDate,
          nextDueDate: _nextDueDate,
          collateralAssetId: _selectedCollateralId,
          notes: _notesCtrl.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingLoan != null
                  ? 'Loan updated successfully'
                  : 'Loan added successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e
                  .toString()
                  .replaceAll('LoanException: ', '')
                  .replaceAll('Exception: ', ''),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Basic Info', 'Financial', 'Repayment', 'Collateral'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.existingLoan != null ? 'Edit Loan' : 'Add New Loan',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(theme, steps),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme),
                _buildStep4(theme),
              ],
            ),
          ),
          _buildNavButtons(theme),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, List<String> steps) {
    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTheme.success
                              : isActive
                              ? AppTheme.primary
                              : AppTheme.outlineLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.mutedLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.mutedLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    height: 1,
                    width: 16,
                    color: i < _currentStep
                        ? AppTheme.success
                        : AppTheme.outlineLight,
                    margin: const EdgeInsets.only(bottom: 18),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the loan details',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            theme,
            'Loan Name',
            _loanNameCtrl,
            hint: 'e.g. CRDB Business Loan',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            theme,
            'Lender / Creditor',
            _lenderCtrl,
            hint: 'e.g. CRDB Bank, NMB, Family',
          ),
          const SizedBox(height: 20),
          Text(
            'Loan Category',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _loanCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _loanCategory = cat),
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
                    cat.replaceAll('_', ' ').toUpperCase(),
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
          Text(
            'Purpose',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _purposes.map((p) {
              final isSelected = _purpose == p;
              return GestureDetector(
                onTap: () => setState(() => _purpose = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Text(
                    p,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.mutedLight,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Loan amount and interest terms',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            theme,
            'Principal Amount (TZS)',
            _principalCtrl,
            hint: '0',
            isNumber: true,
            onChanged: (_) => _calculateMonthlyPayment(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            theme,
            'Annual Interest Rate (%)',
            _interestRateCtrl,
            hint: '0.0',
            isNumber: true,
            onChanged: (_) => _calculateMonthlyPayment(),
          ),
          const SizedBox(height: 20),
          Text(
            'Interest Type',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interestTypes.map((t) {
              final isSelected = _interestType == t;
              return GestureDetector(
                onTap: () {
                  setState(() => _interestType = t);
                  _calculateMonthlyPayment();
                },
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
          const SizedBox(height: 16),
          _buildTextField(
            theme,
            'Loan Term (months)',
            _termCtrl,
            hint: '12',
            isNumber: true,
            onChanged: (_) => _calculateMonthlyPayment(),
          ),
          const SizedBox(height: 20),
          Text(
            'Payment Frequency',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _frequencies.map((f) {
              final isSelected = _paymentFrequency == f;
              return GestureDetector(
                onTap: () => setState(() => _paymentFrequency = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Text(
                    f.replaceAll('_', ' '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.mutedLight,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2050),
              );
              if (picked != null) {
                setState(() => _startDate = picked);
                _calculateMonthlyPayment();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repayment Setup',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure payment schedule',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 24),
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
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-calculated payment',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Based on principal, rate, and term entered in step 2',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            theme,
            'Monthly Payment (TZS)',
            _monthlyPaymentCtrl,
            hint: '0',
            isNumber: true,
          ),
          const SizedBox(height: 20),
          Text(
            'Payment Method',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods.map((m) {
              final isSelected = _paymentMethod == m;
              return GestureDetector(
                onTap: () => setState(() => _paymentMethod = m),
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
                    m.replaceAll('_', ' ').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? Colors.white : AppTheme.mutedLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2050),
              );
              if (picked != null) setState(() => _nextDueDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Due Date',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      Text(
                        _nextDueDate != null
                            ? '${_nextDueDate!.day}/${_nextDueDate!.month}/${_nextDueDate!.year}'
                            : 'Tap to select',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _nextDueDate != null
                              ? AppTheme.onSurfaceLight
                              : AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collateral & Notes',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Link assets as collateral (optional)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 24),
          if (_assets.isNotEmpty) ...[
            Text(
              'Select Collateral Asset',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    value: null,
                    groupValue: _selectedCollateralId,
                    onChanged: (v) => setState(() => _selectedCollateralId = v),
                    title: Text(
                      'No collateral (unsecured)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    activeColor: AppTheme.primary,
                  ),
                  ..._assets.map(
                    (asset) => RadioListTile<String?>(
                      value: asset['id'] as String,
                      groupValue: _selectedCollateralId,
                      onChanged: (v) =>
                          setState(() => _selectedCollateralId = v),
                      title: Text(
                        asset['asset_name'] as String? ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        'TSh ${((asset['current_value'] as num).toDouble() / 1000000).toStringAsFixed(1)}M',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      activeColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Notes (optional)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Additional notes about this loan...',
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
            ),
          ),
          const SizedBox(height: 24),
          _buildLoanSummary(theme),
        ],
      ),
    );
  }

  Widget _buildLoanSummary(ThemeData theme) {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final monthly = double.tryParse(_monthlyPaymentCtrl.text) ?? 0;
    final term = int.tryParse(_termCtrl.text) ?? 12;
    final totalRepayment = monthly * term;
    final totalInterest = totalRepayment - principal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(10),
            AppTheme.primaryLight.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(
            theme,
            'Principal',
            'TSh ${(principal / 1000000).toStringAsFixed(2)}M',
          ),
          _summaryRow(
            theme,
            'Monthly Payment',
            'TSh ${(monthly / 1000).toStringAsFixed(0)}K',
          ),
          _summaryRow(
            theme,
            'Total Repayment',
            'TSh ${(totalRepayment / 1000000).toStringAsFixed(2)}M',
          ),
          _summaryRow(
            theme,
            'Total Interest Cost',
            'TSh ${(totalInterest / 1000000).toStringAsFixed(2)}M',
            isHighlight: true,
          ),
          _summaryRow(theme, 'Loan Term', '$term months'),
        ],
      ),
    );
  }

  Widget _summaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              color: isHighlight ? AppTheme.warning : AppTheme.onSurfaceLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    ThemeData theme,
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool isNumber = false,
    Function(String)? onChanged,
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
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          onChanged: onChanged,
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

  Widget _buildNavButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primary),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _saveLoan();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep < 3
                          ? 'Continue'
                          : (widget.existingLoan != null
                                ? 'Update Loan'
                                : 'Save Loan'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loanNameCtrl.dispose();
    _lenderCtrl.dispose();
    _principalCtrl.dispose();
    _interestRateCtrl.dispose();
    _termCtrl.dispose();
    _monthlyPaymentCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}

extension _NumPow on double {
  double pow(int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= this;
    }
    return result;
  }
}
