import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/accounting_engine.dart';
import '../services/enterprise_transaction_service.dart';
import '../services/supabase_service.dart';

/// Enterprise Savings Repository
/// Savings accounts as specialized Financial Accounts inheriting Phase 1 architecture.
/// Architecture: UI → Controller → SavingsRepository → Services → DB
class SavingsRepository {
  static SavingsRepository? _instance;
  static SavingsRepository get instance => _instance ??= SavingsRepository._();
  SavingsRepository._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── SAVINGS ACCOUNT CRUD ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSavingsAccounts({
    bool includeArchived = false,
    bool includeInactive = false,
  }) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    try {
      var query = _client
          .from('savings_accounts')
          .select()
          .eq('user_id', userId);
      if (!includeInactive) query = query.eq('is_active', true);
      if (!includeArchived) {
        // Filter out archived if column exists
        try {
          query = query.eq('is_archived', false);
        } catch (_) {}
      }
      return List<Map<String, dynamic>>.from(
        await query.order('created_at', ascending: false),
      );
    } catch (e) {
      if (e is SavingsException) rethrow;
      throw SavingsException('Failed to fetch savings accounts: $e');
    }
  }

  Future<Map<String, dynamic>?> getSavingsAccountById(String accountId) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    try {
      return await _client
          .from('savings_accounts')
          .select()
          .eq('id', accountId)
          .eq('user_id', userId)
          .single();
    } catch (e) {
      throw SavingsException('Failed to fetch savings account: $e');
    }
  }

  Future<Map<String, dynamic>> createSavingsAccount({
    required String name,
    required String type,
    String? linkedAccountId,
    String? linkedGoalId,
    double targetAmount = 0,
    double currentBalance = 0,
    double monthlyContribution = 0,
    double interestRate = 0,
    String interestMethod = 'simple',
    String compoundingFrequency = 'monthly',
    double minimumBalance = 0,
    double maximumBalance = 0,
    DateTime? targetDate,
    DateTime? startDate,
    bool autoTransfer = false,
    int autoTransferDay = 1,
    bool isLocked = false,
    DateTime? lockUntil,
    String color = '#1A5F7A',
    String icon = 'savings',
    String currency = 'TZS',
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    if (name.trim().isEmpty) throw SavingsException('Account name is required');
    if (currentBalance < 0)
      throw SavingsException('Opening balance cannot be negative');
    if (interestRate < 0)
      throw SavingsException('Interest rate cannot be negative');

    try {
      final account = await _client
          .from('savings_accounts')
          .insert({
            'user_id': userId,
            'account_name': name.trim(),
            'savings_type': type,
            'linked_account_id': linkedAccountId,
            'linked_goal_id': linkedGoalId,
            'target_amount': targetAmount,
            'current_balance': currentBalance,
            'monthly_contribution': monthlyContribution,
            'interest_rate': interestRate,
            'interest_method': interestMethod,
            'compounding_frequency': compoundingFrequency,
            'minimum_balance': minimumBalance,
            'maximum_balance': maximumBalance,
            'target_date': targetDate?.toIso8601String().split('T')[0],
            'start_date': (startDate ?? DateTime.now()).toIso8601String().split(
              'T',
            )[0],
            'auto_transfer': autoTransfer,
            'auto_transfer_day': autoTransferDay,
            'is_locked': isLocked,
            'lock_until': lockUntil?.toIso8601String().split('T')[0],
            'color': color,
            'icon': icon,
            'currency': currency,
            'notes': notes,
            'is_active': true,
            'is_archived': false,
            'total_interest_earned': 0,
          })
          .select()
          .single();

      final accountId = account['id'] as String;

      // If opening balance > 0, record initial deposit
      if (currentBalance > 0) {
        await _recordTransaction(
          savingsAccountId: accountId,
          transactionType: 'deposit',
          amount: currentBalance,
          description: 'Opening balance',
          date: startDate ?? DateTime.now(),
          currency: currency,
        );

        // Accounting entry
        try {
          await AccountingEngine.instance.recordSavingsDeposit(
            amount: currentBalance,
            savingsName: name,
            date: startDate ?? DateTime.now(),
            savingsId: accountId,
            currency: currency,
          );
        } catch (_) {}
      }

      await _logAudit(
        entityType: 'savings_account',
        entityId: accountId,
        action: 'create',
        description: 'Savings account created: $name',
        newValues: account,
      );

      return account;
    } catch (e) {
      if (e is SavingsException) rethrow;
      throw SavingsException('Failed to create savings account: $e');
    }
  }

  Future<Map<String, dynamic>> updateSavingsAccount(
    String accountId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    try {
      final oldAccount = await getSavingsAccountById(accountId);
      final updated = await _client
          .from('savings_accounts')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', accountId)
          .eq('user_id', userId)
          .select()
          .single();

      await _logAudit(
        entityType: 'savings_account',
        entityId: accountId,
        action: 'update',
        description: 'Savings account updated',
        oldValues: oldAccount,
        newValues: updated,
      );

      return updated;
    } catch (e) {
      if (e is SavingsException) rethrow;
      throw SavingsException('Failed to update savings account: $e');
    }
  }

  Future<bool> archiveSavingsAccount(String accountId) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    try {
      await _client
          .from('savings_accounts')
          .update({
            'is_archived': true,
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', accountId)
          .eq('user_id', userId);

      await _logAudit(
        entityType: 'savings_account',
        entityId: accountId,
        action: 'archive',
        description: 'Savings account archived',
      );
      return true;
    } catch (e) {
      throw SavingsException('Failed to archive savings account: $e');
    }
  }

  Future<bool> restoreSavingsAccount(String accountId) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    try {
      await _client
          .from('savings_accounts')
          .update({
            'is_archived': false,
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', accountId)
          .eq('user_id', userId);

      await _logAudit(
        entityType: 'savings_account',
        entityId: accountId,
        action: 'restore',
        description: 'Savings account restored',
      );
      return true;
    } catch (e) {
      throw SavingsException('Failed to restore savings account: $e');
    }
  }

  // ─── DEPOSITS & WITHDRAWALS ───────────────────────────────────────────────

  Future<Map<String, dynamic>> deposit({
    required String savingsAccountId,
    required double amount,
    String? sourceAccountId,
    String? description,
    DateTime? date,
  }) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    if (amount <= 0) throw SavingsException('Deposit amount must be positive');

    try {
      final account = await getSavingsAccountById(savingsAccountId);
      final currentBalance =
          (account!['current_balance'] as num?)?.toDouble() ?? 0;
      final maxBalance = (account['maximum_balance'] as num?)?.toDouble() ?? 0;
      final currency = account['currency'] as String? ?? 'TZS';

      if (maxBalance > 0 && currentBalance + amount > maxBalance) {
        throw SavingsException(
          'Deposit would exceed maximum balance of $maxBalance',
        );
      }

      final newBalance = currentBalance + amount;
      final txDate = date ?? DateTime.now();

      // Record savings transaction
      final tx = await _recordTransaction(
        savingsAccountId: savingsAccountId,
        transactionType: 'deposit',
        amount: amount,
        description: description ?? 'Savings deposit',
        sourceAccountId: sourceAccountId,
        date: txDate,
        currency: currency,
      );

      // Update balance
      await _client
          .from('savings_accounts')
          .update({
            'current_balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', savingsAccountId);

      // Accounting entry
      try {
        await AccountingEngine.instance.recordSavingsDeposit(
          amount: amount,
          savingsName: account['account_name'] ?? 'Savings',
          date: txDate,
          savingsId: savingsAccountId,
          currency: currency,
        );
      } catch (_) {}

      // Enterprise transaction
      try {
        await EnterpriseTransactionService.instance.createTransaction(
          type: 'savings_deposit',
          category: account['savings_type'] ?? 'general',
          amount: amount,
          date: txDate,
          title: 'Savings Deposit: ${account['account_name']}',
          description: description ?? 'Savings deposit',
          accountId: sourceAccountId,
          currency: currency,
          status: 'completed',
        );
      } catch (_) {}

      await _logAudit(
        entityType: 'savings_transaction',
        entityId: tx['id'] as String,
        action: 'create',
        description: 'Deposit: $amount',
        newValues: tx,
      );

      return tx;
    } catch (e) {
      if (e is SavingsException) rethrow;
      throw SavingsException('Failed to record deposit: $e');
    }
  }

  Future<Map<String, dynamic>> withdraw({
    required String savingsAccountId,
    required double amount,
    String? destinationAccountId,
    String? description,
    DateTime? date,
  }) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    if (amount <= 0)
      throw SavingsException('Withdrawal amount must be positive');

    try {
      final account = await getSavingsAccountById(savingsAccountId);
      final isLocked = account!['is_locked'] as bool? ?? false;
      final currency = account['currency'] as String? ?? 'TZS';

      if (isLocked) {
        final lockUntil = account['lock_until'] as String?;
        if (lockUntil != null) {
          final lockDate = DateTime.parse(lockUntil);
          if (DateTime.now().isBefore(lockDate)) {
            throw SavingsException('Account is locked until $lockUntil');
          }
        }
      }

      final currentBalance =
          (account['current_balance'] as num?)?.toDouble() ?? 0;
      final minBalance = (account['minimum_balance'] as num?)?.toDouble() ?? 0;

      if (amount > currentBalance) {
        throw SavingsException(
          'Insufficient balance. Available: $currentBalance',
        );
      }
      if (currentBalance - amount < minBalance) {
        throw SavingsException(
          'Withdrawal would breach minimum balance of $minBalance',
        );
      }

      final newBalance = currentBalance - amount;
      final txDate = date ?? DateTime.now();

      final tx = await _recordTransaction(
        savingsAccountId: savingsAccountId,
        transactionType: 'withdrawal',
        amount: amount,
        description: description ?? 'Savings withdrawal',
        sourceAccountId: destinationAccountId,
        date: txDate,
        currency: currency,
      );

      await _client
          .from('savings_accounts')
          .update({
            'current_balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', savingsAccountId);

      // Accounting entry
      try {
        await AccountingEngine.instance.recordSavingsWithdrawal(
          amount: amount,
          savingsName: account['account_name'] ?? 'Savings',
          date: txDate,
          savingsId: savingsAccountId,
          currency: currency,
        );
      } catch (_) {}

      // Enterprise transaction
      try {
        await EnterpriseTransactionService.instance.createTransaction(
          type: 'savings_withdrawal',
          category: account['savings_type'] ?? 'general',
          amount: amount,
          date: txDate,
          title: 'Savings Withdrawal: ${account['account_name']}',
          description: description ?? 'Savings withdrawal',
          accountId: destinationAccountId,
          currency: currency,
          status: 'completed',
        );
      } catch (_) {}

      await _logAudit(
        entityType: 'savings_transaction',
        entityId: tx['id'] as String,
        action: 'create',
        description: 'Withdrawal: $amount',
        newValues: tx,
      );

      return tx;
    } catch (e) {
      if (e is SavingsException) rethrow;
      throw SavingsException('Failed to record withdrawal: $e');
    }
  }

  // ─── INTEREST ENGINE ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> processInterest({
    required String savingsAccountId,
    DateTime? asOfDate,
  }) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');

    try {
      final account = await getSavingsAccountById(savingsAccountId);
      final balance = (account!['current_balance'] as num?)?.toDouble() ?? 0;
      final annualRate = (account['interest_rate'] as num?)?.toDouble() ?? 0;
      final method = account['interest_method'] as String? ?? 'simple';
      final currency = account['currency'] as String? ?? 'TZS';

      if (annualRate <= 0 || balance <= 0) {
        throw SavingsException('No interest applicable for this account');
      }

      // Calculate monthly interest
      double interestAmount;
      if (method == 'compound') {
        final monthlyRate = annualRate / 100.0 / 12.0;
        interestAmount = balance * monthlyRate;
      } else {
        // Simple interest
        interestAmount = balance * (annualRate / 100.0) / 12.0;
      }

      interestAmount = double.parse(interestAmount.toStringAsFixed(2));
      final txDate = asOfDate ?? DateTime.now();
      final newBalance = balance + interestAmount;

      // Record interest transaction
      final tx = await _recordTransaction(
        savingsAccountId: savingsAccountId,
        transactionType: 'interest',
        amount: interestAmount,
        description:
            'Monthly interest at ${annualRate.toStringAsFixed(2)}% p.a.',
        date: txDate,
        currency: currency,
      );

      // Update balance and total interest
      final totalInterest =
          (account['total_interest_earned'] as num?)?.toDouble() ?? 0;
      await _client
          .from('savings_accounts')
          .update({
            'current_balance': newBalance,
            'total_interest_earned': totalInterest + interestAmount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', savingsAccountId);

      // Accounting entry for interest income
      try {
        await AccountingEngine.instance.createJournalEntry(
          description: 'Interest Income: ${account['account_name']}',
          journalDate: txDate,
          journalType: 'automatic',
          sourceModule: 'savings',
          sourceEntityId: savingsAccountId,
          autoPost: true,
          lines: [
            JournalLine(
              accountCode: '1200',
              accountName: 'Savings Account',
              debitAmount: interestAmount,
              creditAmount: 0,
              currency: currency,
            ),
            JournalLine(
              accountCode: '4200',
              accountName: 'Interest Income',
              debitAmount: 0,
              creditAmount: interestAmount,
              currency: currency,
            ),
          ],
        );
      } catch (_) {}

      // Enterprise transaction
      try {
        await EnterpriseTransactionService.instance.createTransaction(
          type: 'interest_received',
          category: 'savings',
          amount: interestAmount,
          date: txDate,
          title: 'Interest: ${account['account_name']}',
          description: 'Monthly interest earned',
          currency: currency,
          status: 'completed',
        );
      } catch (_) {}

      return {
        'transaction': tx,
        'interest_amount': interestAmount,
        'new_balance': newBalance,
      };
    } catch (e) {
      if (e is SavingsException) rethrow;
      throw SavingsException('Failed to process interest: $e');
    }
  }

  // ─── ACCOUNT CLOSURE ──────────────────────────────────────────────────────

  Future<bool> closeSavingsAccount({
    required String savingsAccountId,
    String? destinationAccountId,
    String? reason,
  }) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');

    try {
      final account = await getSavingsAccountById(savingsAccountId);
      final balance = (account!['current_balance'] as num?)?.toDouble() ?? 0;
      final currency = account['currency'] as String? ?? 'TZS';

      // Transfer remaining balance if any
      if (balance > 0 && destinationAccountId != null) {
        await withdraw(
          savingsAccountId: savingsAccountId,
          amount: balance,
          destinationAccountId: destinationAccountId,
          description: 'Account closure - final withdrawal',
        );
      }

      // Close the account
      await _client
          .from('savings_accounts')
          .update({
            'is_active': false,
            'is_archived': true,
            'current_balance': 0,
            'notes':
                '${account['notes'] ?? ''}\nClosed: ${reason ?? 'Account closed'}',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', savingsAccountId)
          .eq('user_id', userId);

      await _logAudit(
        entityType: 'savings_account',
        entityId: savingsAccountId,
        action: 'close',
        description: 'Account closed: ${reason ?? 'No reason provided'}',
        oldValues: account,
      );

      return true;
    } catch (e) {
      if (e is SavingsException) rethrow;
      throw SavingsException('Failed to close savings account: $e');
    }
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSavingsTransactions(
    String savingsAccountId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('savings_transactions')
            .select()
            .eq('savings_account_id', savingsAccountId)
            .order('transaction_date', ascending: false)
            .range(offset, offset + limit - 1),
      );
    } catch (e) {
      throw SavingsException('Failed to fetch transactions: $e');
    }
  }

  Future<Map<String, dynamic>> _recordTransaction({
    required String savingsAccountId,
    required String transactionType,
    required double amount,
    required String description,
    String? sourceAccountId,
    required DateTime date,
    String currency = 'TZS',
  }) async {
    final userId = _userId;
    if (userId == null) throw SavingsException('User not authenticated');
    return await _client
        .from('savings_transactions')
        .insert({
          'user_id': userId,
          'savings_account_id': savingsAccountId,
          'transaction_type': transactionType,
          'amount': amount,
          'description': description,
          'source_account_id': sourceAccountId,
          'transaction_date': date.toIso8601String().split('T')[0],
        })
        .select()
        .single();
  }

  // ─── HEALTH SCORE ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> calculateSavingsHealth() async {
    final userId = _userId;
    if (userId == null) return {'score': 0, 'grade': 'N/A'};
    try {
      final accounts = await getSavingsAccounts();
      if (accounts.isEmpty)
        return {'score': 0, 'grade': 'F', 'message': 'No savings accounts'};

      double totalBalance = 0;
      double totalTarget = 0;
      double totalInterestRate = 0;
      int activeCount = 0;

      for (final acc in accounts) {
        totalBalance += (acc['current_balance'] as num?)?.toDouble() ?? 0;
        totalTarget += (acc['target_amount'] as num?)?.toDouble() ?? 0;
        totalInterestRate += (acc['interest_rate'] as num?)?.toDouble() ?? 0;
        activeCount++;
      }

      double score = 50.0;
      if (totalBalance > 0) score += 20;
      if (totalTarget > 0 && totalBalance / totalTarget >= 0.5) score += 15;
      if (totalInterestRate / activeCount > 5) score += 15;

      score = score.clamp(0, 100);
      String grade;
      if (score >= 90)
        grade = 'A+';
      else if (score >= 80)
        grade = 'A';
      else if (score >= 70)
        grade = 'B';
      else if (score >= 60)
        grade = 'C';
      else
        grade = 'D';

      return {
        'score': score.round(),
        'grade': grade,
        'total_balance': totalBalance,
        'total_target': totalTarget,
        'account_count': activeCount,
        'avg_interest_rate': activeCount > 0
            ? totalInterestRate / activeCount
            : 0,
      };
    } catch (e) {
      return {'score': 0, 'grade': 'N/A'};
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
        'source_module': 'savings',
      });
    } catch (_) {}
  }
}

class SavingsException implements Exception {
  final String message;
  const SavingsException(this.message);

  @override
  String toString() => 'SavingsException: $message';
}