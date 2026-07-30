import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/accounting_engine.dart';
import '../services/enterprise_transaction_service.dart';
import '../services/supabase_service.dart';

/// Enterprise Loan Repository
/// Replaces all direct Supabase access in loan screens.
/// Architecture: UI → Controller → LoanRepository → Services → DB
class LoanRepository {
  static LoanRepository? _instance;
  static LoanRepository get instance => _instance ??= LoanRepository._();
  LoanRepository._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── LOAN CRUD ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLoans({
    String? status,
    bool includeArchived = false,
    int limit = 100,
    int offset = 0,
  }) async {
    final userId = _userId;
    if (userId == null) throw LoanException('User not authenticated');
    try {
      var query = _client.from('loans').select().eq('user_id', userId);
      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }
      if (status != null) query = query.eq('status', status);
      return List<Map<String, dynamic>>.from(
        await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1),
      );
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanException('Failed to fetch loans: $e');
    }
  }

  Future<Map<String, dynamic>?> getLoanById(String loanId) async {
    final userId = _userId;
    if (userId == null) throw LoanException('User not authenticated');
    try {
      return await _client
          .from('loans')
          .select()
          .eq('id', loanId)
          .eq('user_id', userId)
          .single();
    } catch (e) {
      throw LoanException('Failed to fetch loan: $e');
    }
  }

  Future<Map<String, dynamic>> createLoan({
    required String loanName,
    required String lender,
    required String loanCategory,
    required String purpose,
    required double principalAmount,
    required double interestRate,
    required String interestType,
    required int loanTermMonths,
    required String paymentFrequency,
    required double monthlyPayment,
    required String paymentMethod,
    required DateTime startDate,
    DateTime? nextDueDate,
    String? collateralAssetId,
    String? linkedAccountId,
    String? notes,
    String currency = 'TZS',
  }) async {
    final userId = _userId;
    if (userId == null) throw LoanException('User not authenticated');

    // Validate required fields
    if (loanName.trim().isEmpty) throw LoanException('Loan name is required');
    if (principalAmount <= 0)
      throw LoanException('Principal amount must be positive');
    if (interestRate < 0)
      throw LoanException('Interest rate cannot be negative');
    if (loanTermMonths <= 0) throw LoanException('Loan term must be positive');

    try {
      final maturityDate = DateTime(
        startDate.year,
        startDate.month + loanTermMonths,
        startDate.day,
      );

      final loan = await _client
          .from('loans')
          .insert({
            'user_id': userId,
            'loan_name': loanName.trim(),
            'lender': lender.trim(),
            'loan_category': loanCategory,
            'purpose': purpose,
            'principal_amount': principalAmount,
            'remaining_balance': principalAmount,
            'outstanding_balance': principalAmount,
            'interest_rate': interestRate,
            'interest_type': interestType,
            'loan_term_months': loanTermMonths,
            'payment_frequency': paymentFrequency,
            'monthly_payment': monthlyPayment,
            'payment_method': paymentMethod,
            'start_date': startDate.toIso8601String().split('T')[0],
            'next_due_date': nextDueDate?.toIso8601String().split('T')[0],
            'maturity_date': maturityDate.toIso8601String().split('T')[0],
            'collateral_asset_id': collateralAssetId,
            'linked_account_id': linkedAccountId,
            'notes': notes,
            'currency': currency,
            'status': 'active',
            'is_archived': false,
          })
          .select()
          .single();

      final loanId = loan['id'] as String;

      // Generate amortization schedule
      try {
        await _client.rpc(
          'generate_loan_amortization',
          params: {
            'p_user_id': userId,
            'p_loan_id': loanId,
            'p_principal': principalAmount,
            'p_annual_rate': interestRate,
            'p_term_months': loanTermMonths,
            'p_start_date': startDate.toIso8601String().split('T')[0],
          },
        );
      } catch (_) {
        // Amortization generation failure should not block loan creation
      }

      // Create accounting entry for loan disbursement
      try {
        await AccountingEngine.instance.recordLoanDisbursement(
          amount: principalAmount,
          loanName: loanName,
          date: startDate,
          loanId: loanId,
          currency: currency,
        );
      } catch (_) {
        // Accounting failure should not block loan creation
      }

      // Create enterprise transaction
      try {
        await EnterpriseTransactionService.instance.createTransaction(
          type: 'loan_taken',
          category: loanCategory,
          amount: principalAmount,
          date: startDate,
          title: 'Loan: $loanName',
          description: 'Loan from $lender',
          accountId: linkedAccountId,
          loanId: loanId,
          currency: currency,
          status: 'completed',
        );
      } catch (_) {
        // Transaction creation failure should not block loan creation
      }

      // Audit trail
      await _logAudit(
        entityType: 'loan',
        entityId: loanId,
        action: 'create',
        description: 'Loan created: $loanName',
        newValues: loan,
      );

      return loan;
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanException('Failed to create loan: $e');
    }
  }

  Future<Map<String, dynamic>> updateLoan(
    String loanId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _userId;
    if (userId == null) throw LoanException('User not authenticated');
    try {
      final oldLoan = await getLoanById(loanId);
      final updated = await _client
          .from('loans')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', loanId)
          .eq('user_id', userId)
          .select()
          .single();

      await _logAudit(
        entityType: 'loan',
        entityId: loanId,
        action: 'update',
        description: 'Loan updated',
        oldValues: oldLoan,
        newValues: updated,
      );

      return updated;
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanException('Failed to update loan: $e');
    }
  }

  Future<bool> archiveLoan(String loanId) async {
    final userId = _userId;
    if (userId == null) throw LoanException('User not authenticated');
    try {
      await _client
          .from('loans')
          .update({
            'is_archived': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loanId)
          .eq('user_id', userId);

      await _logAudit(
        entityType: 'loan',
        entityId: loanId,
        action: 'archive',
        description: 'Loan archived',
      );
      return true;
    } catch (e) {
      throw LoanException('Failed to archive loan: $e');
    }
  }

  Future<bool> restoreLoan(String loanId) async {
    final userId = _userId;
    if (userId == null) throw LoanException('User not authenticated');
    try {
      await _client
          .from('loans')
          .update({
            'is_archived': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loanId)
          .eq('user_id', userId);

      await _logAudit(
        entityType: 'loan',
        entityId: loanId,
        action: 'restore',
        description: 'Loan restored',
      );
      return true;
    } catch (e) {
      throw LoanException('Failed to restore loan: $e');
    }
  }

  // ─── REPAYMENTS ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLoanRepayments(String loanId) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('loan_repayments')
            .select()
            .eq('loan_id', loanId)
            .eq('user_id', userId)
            .order('payment_date', ascending: false),
      );
    } catch (e) {
      throw LoanException('Failed to fetch repayments: $e');
    }
  }

  Future<Map<String, dynamic>> recordRepayment({
    required String loanId,
    required double amount,
    required DateTime paymentDate,
    double? principalComponent,
    double? interestComponent,
    double? penaltyComponent,
    String? paymentMethod,
    String? reference,
    String? linkedAccountId,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw LoanException('User not authenticated');
    if (amount <= 0) throw LoanException('Repayment amount must be positive');

    try {
      final loan = await getLoanById(loanId);
      final currentBalance =
          (loan!['remaining_balance'] as num?)?.toDouble() ?? 0;

      if (amount > currentBalance + 0.01) {
        throw LoanException('Repayment amount exceeds outstanding balance');
      }

      final principal = principalComponent ?? amount;
      final interest = interestComponent ?? 0.0;
      final penalty = penaltyComponent ?? 0.0;
      final newBalance = (currentBalance - principal).clamp(
        0.0,
        double.infinity,
      );

      // Record repayment
      final repayment = await _client
          .from('loan_repayments')
          .insert({
            'user_id': userId,
            'loan_id': loanId,
            'amount': amount,
            'principal_component': principal,
            'interest_component': interest,
            'penalty_component': penalty,
            'payment_date': paymentDate.toIso8601String().split('T')[0],
            'payment_method': paymentMethod ?? 'bank_transfer',
            'reference': reference,
            'notes': notes,
            'status': 'completed',
          })
          .select()
          .single();

      // Update loan balance
      final newStatus = newBalance <= 0.01 ? 'paid_off' : 'active';
      await _client
          .from('loans')
          .update({
            'remaining_balance': newBalance,
            'outstanding_balance': newBalance,
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loanId);

      // Create accounting entry
      try {
        await AccountingEngine.instance.recordLoanRepayment(
          principalAmount: principal,
          interestAmount: interest,
          loanName: loan!['loan_name'] ?? 'Loan',
          date: paymentDate,
          loanId: loanId,
          currency: loan['currency'] ?? 'TZS',
        );
      } catch (_) {}

      // Create enterprise transaction
      try {
        await EnterpriseTransactionService.instance.createTransaction(
          type: 'loan_repayment',
          category: loan!['loan_category'] ?? 'personal',
          amount: amount,
          date: paymentDate,
          title: 'Loan Repayment: ${loan['loan_name']}',
          description: 'Repayment to ${loan['lender']}',
          accountId: linkedAccountId,
          loanId: loanId,
          currency: loan['currency'] ?? 'TZS',
          status: 'completed',
        );
      } catch (_) {}

      await _logAudit(
        entityType: 'loan_repayment',
        entityId: repayment['id'] as String,
        action: 'create',
        description: 'Repayment recorded: $amount',
        newValues: repayment,
      );

      return repayment;
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanException('Failed to record repayment: $e');
    }
  }

  // ─── AMORTIZATION ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAmortizationSchedule(
    String loanId,
  ) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('loan_amortization_schedules')
            .select()
            .eq('loan_id', loanId)
            .eq('user_id', userId)
            .order('payment_number'),
      );
    } catch (e) {
      throw LoanException('Failed to fetch amortization schedule: $e');
    }
  }

  // ─── DEBT HEALTH ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDebtHealthSnapshots({
    int limit = 12,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('debt_health_snapshots')
            .select()
            .eq('user_id', userId)
            .order('snapshot_date', ascending: false)
            .limit(limit),
      );
    } catch (e) {
      return [];
    }
  }

  // ─── AUDIT ────────────────────────────────────────────────────────────────

  Future<void> _logAudit({
    required String entityType,
    required String entityId,
    required String action,
    String? description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client.from('financial_audit_trail').insert({
        'user_id': userId,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'description': description,
        'old_values': oldValues,
        'new_values': newValues,
        'performed_by': userId,
        'performed_at': DateTime.now().toIso8601String(),
        'source_module': 'loans',
      });
    } catch (_) {}
  }
}

class LoanException implements Exception {
  final String message;
  const LoanException(this.message);

  @override
  String toString() => 'LoanException: $message';
}