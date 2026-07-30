import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// AccountingEngine — Centralized Double-Entry Accounting Engine
/// ALL financial events must pass through this engine.
/// No module may generate ledger entries independently.
class AccountingEngine {
  static AccountingEngine? _instance;
  static AccountingEngine get instance => _instance ??= AccountingEngine._();
  AccountingEngine._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── JOURNAL MANAGEMENT ──────────────────────────────────────────────────

  /// Create a balanced journal entry with lines.
  /// Throws [AccountingException] if debits != credits.
  Future<Map<String, dynamic>> createJournalEntry({
    required String description,
    required DateTime journalDate,
    required List<JournalLine> lines,
    String journalType = 'manual',
    String? reference,
    String? sourceModule,
    String? sourceEntityId,
    String? periodId,
    String? notes,
    bool autoPost = false,
  }) async {
    final userId = _userId;
    if (userId == null) throw AccountingException('User not authenticated');

    // Validate balance
    double totalDebit = 0;
    double totalCredit = 0;
    for (final line in lines) {
      totalDebit += line.debitAmount;
      totalCredit += line.creditAmount;
    }
    if ((totalDebit - totalCredit).abs() > 0.01) {
      throw AccountingException(
        'Journal entry is unbalanced: Debit=$totalDebit, Credit=$totalCredit',
      );
    }
    if (lines.isEmpty) {
      throw AccountingException('Journal entry must have at least 2 lines');
    }

    try {
      // Generate journal number
      final journalNumber = await _generateJournalNumber(userId);

      // Create journal entry
      final journal = await _client
          .from('journal_entries')
          .insert({
            'user_id': userId,
            'journal_number': journalNumber,
            'journal_date': journalDate.toIso8601String().split('T')[0],
            'journal_type': journalType,
            'status': autoPost ? 'posted' : 'draft',
            'description': description,
            'reference': reference,
            'period_id': periodId,
            'source_module': sourceModule,
            'source_entity_id': sourceEntityId,
            'total_debit': totalDebit,
            'total_credit': totalCredit,
            'is_balanced': true,
            'notes': notes,
            if (autoPost) 'posted_at': DateTime.now().toIso8601String(),
            if (autoPost) 'posted_by': userId,
          })
          .select()
          .single();

      final journalId = journal['id'] as String;

      // Create journal lines
      int lineOrder = 0;
      for (final line in lines) {
        await _client.from('journal_entry_lines').insert({
          'journal_entry_id': journalId,
          'user_id': userId,
          'coa_account_id': line.coaAccountId,
          'account_code': line.accountCode,
          'account_name': line.accountName,
          'description': line.description ?? description,
          'debit_amount': line.debitAmount,
          'credit_amount': line.creditAmount,
          'currency': line.currency,
          'line_order': lineOrder++,
        });
      }

      // Auto-post to ledger if requested
      if (autoPost) {
        await postJournalToLedger(journalId);
      }

      // Audit trail
      await _logAudit(
        entityType: 'journal_entry',
        entityId: journalId,
        action: autoPost ? 'post' : 'create',
        description: 'Journal entry created: $journalNumber',
        sourceModule: sourceModule,
      );

      return journal;
    } catch (e) {
      if (e is AccountingException) rethrow;
      throw AccountingException('Failed to create journal entry: $e');
    }
  }

  /// Post a draft journal entry to the General Ledger.
  Future<bool> postJournalToLedger(String journalId) async {
    try {
      final result = await _client.rpc(
        'post_journal_to_ledger',
        params: {'p_journal_id': journalId},
      );
      return result == true;
    } catch (e) {
      throw AccountingException('Failed to post journal to ledger: $e');
    }
  }

  /// Create a reversing journal entry for a posted journal.
  Future<Map<String, dynamic>> reverseJournalEntry(
    String originalJournalId, {
    String? reason,
    DateTime? reversalDate,
  }) async {
    final userId = _userId;
    if (userId == null) throw AccountingException('User not authenticated');

    try {
      final original = await _client
          .from('journal_entries')
          .select()
          .eq('id', originalJournalId)
          .single();

      if (original['status'] != 'posted') {
        throw AccountingException('Only posted journals can be reversed');
      }
      if (original['reversed_by_id'] != null) {
        throw AccountingException('Journal has already been reversed');
      }

      final lines = await _client
          .from('journal_entry_lines')
          .select()
          .eq('journal_entry_id', originalJournalId)
          .order('line_order');

      // Create reversed lines (swap debit/credit)
      final reversedLines = (lines as List).map((line) {
        return JournalLine(
          coaAccountId: line['coa_account_id'],
          accountCode: line['account_code'] ?? '',
          accountName: line['account_name'] ?? '',
          debitAmount: (line['credit_amount'] as num).toDouble(),
          creditAmount: (line['debit_amount'] as num).toDouble(),
          description: 'REVERSAL: ${line['description'] ?? ''}',
          currency: line['currency'] ?? 'TZS',
        );
      }).toList();

      final reversalJournal = await createJournalEntry(
        description: 'REVERSAL: ${original['description']}',
        journalDate: reversalDate ?? DateTime.now(),
        lines: reversedLines,
        journalType: 'reversing',
        reference: original['journal_number'],
        sourceModule: original['source_module'],
        sourceEntityId: original['source_entity_id'],
        notes: reason ?? 'Reversal of ${original['journal_number']}',
        autoPost: true,
      );

      // Link reversal
      await _client
          .from('journal_entries')
          .update({
            'reversed_by_id': reversalJournal['id'],
            'status': 'reversed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', originalJournalId);

      await _client
          .from('journal_entries')
          .update({
            'reversal_of_id': originalJournalId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reversalJournal['id'] as String);

      return reversalJournal;
    } catch (e) {
      if (e is AccountingException) rethrow;
      throw AccountingException('Failed to reverse journal entry: $e');
    }
  }

  // ─── STANDARD ACCOUNTING ENTRIES ─────────────────────────────────────────

  /// Record an income transaction with double-entry accounting.
  Future<Map<String, dynamic>> recordIncome({
    required double amount,
    required String description,
    required DateTime date,
    String? sourceModule,
    String? sourceEntityId,
    String currency = 'TZS',
    String? reference,
  }) async {
    return createJournalEntry(
      description: description,
      journalDate: date,
      journalType: 'automatic',
      sourceModule: sourceModule,
      sourceEntityId: sourceEntityId,
      reference: reference,
      autoPost: true,
      lines: [
        JournalLine(
          accountCode: '1000',
          accountName: 'Cash/Bank',
          debitAmount: amount,
          creditAmount: 0,
          currency: currency,
        ),
        JournalLine(
          accountCode: '4000',
          accountName: 'Revenue',
          debitAmount: 0,
          creditAmount: amount,
          currency: currency,
        ),
      ],
    );
  }

  /// Record an expense transaction with double-entry accounting.
  Future<Map<String, dynamic>> recordExpense({
    required double amount,
    required String description,
    required DateTime date,
    String? sourceModule,
    String? sourceEntityId,
    String currency = 'TZS',
    String? reference,
  }) async {
    return createJournalEntry(
      description: description,
      journalDate: date,
      journalType: 'automatic',
      sourceModule: sourceModule,
      sourceEntityId: sourceEntityId,
      reference: reference,
      autoPost: true,
      lines: [
        JournalLine(
          accountCode: '5000',
          accountName: 'Expenses',
          debitAmount: amount,
          creditAmount: 0,
          currency: currency,
        ),
        JournalLine(
          accountCode: '1000',
          accountName: 'Cash/Bank',
          debitAmount: 0,
          creditAmount: amount,
          currency: currency,
        ),
      ],
    );
  }

  /// Record an asset purchase with double-entry accounting.
  Future<Map<String, dynamic>> recordAssetPurchase({
    required double amount,
    required String assetName,
    required DateTime date,
    String? sourceEntityId,
    String currency = 'TZS',
  }) async {
    return createJournalEntry(
      description: 'Asset Purchase: $assetName',
      journalDate: date,
      journalType: 'automatic',
      sourceModule: 'assets',
      sourceEntityId: sourceEntityId,
      autoPost: true,
      lines: [
        JournalLine(
          accountCode: '1500',
          accountName: 'Fixed Assets',
          debitAmount: amount,
          creditAmount: 0,
          currency: currency,
        ),
        JournalLine(
          accountCode: '1000',
          accountName: 'Cash/Bank',
          debitAmount: 0,
          creditAmount: amount,
          currency: currency,
        ),
      ],
    );
  }

  /// Record depreciation expense.
  Future<Map<String, dynamic>> recordDepreciation({
    required double amount,
    required String assetName,
    required DateTime date,
    String? assetRegistryId,
    String currency = 'TZS',
  }) async {
    return createJournalEntry(
      description: 'Depreciation: $assetName',
      journalDate: date,
      journalType: 'automatic',
      sourceModule: 'assets',
      sourceEntityId: assetRegistryId,
      autoPost: true,
      lines: [
        JournalLine(
          accountCode: '5100',
          accountName: 'Depreciation Expense',
          debitAmount: amount,
          creditAmount: 0,
          currency: currency,
        ),
        JournalLine(
          accountCode: '1510',
          accountName: 'Accumulated Depreciation',
          debitAmount: 0,
          creditAmount: amount,
          currency: currency,
        ),
      ],
    );
  }

  /// Record loan disbursement.
  Future<Map<String, dynamic>> recordLoanDisbursement({
    required double amount,
    required String loanName,
    required DateTime date,
    String? loanId,
    String currency = 'TZS',
  }) async {
    return createJournalEntry(
      description: 'Loan Disbursement: $loanName',
      journalDate: date,
      journalType: 'automatic',
      sourceModule: 'loans',
      sourceEntityId: loanId,
      autoPost: true,
      lines: [
        JournalLine(
          accountCode: '1000',
          accountName: 'Cash/Bank',
          debitAmount: amount,
          creditAmount: 0,
          currency: currency,
        ),
        JournalLine(
          accountCode: '2100',
          accountName: 'Loans Payable',
          debitAmount: 0,
          creditAmount: amount,
          currency: currency,
        ),
      ],
    );
  }

  /// Record loan repayment.
  Future<Map<String, dynamic>> recordLoanRepayment({
    required double principalAmount,
    required double interestAmount,
    required String loanName,
    required DateTime date,
    String? loanId,
    String currency = 'TZS',
  }) async {
    final total = principalAmount + interestAmount;
    final lines = <JournalLine>[
      JournalLine(
        accountCode: '2100',
        accountName: 'Loans Payable',
        debitAmount: principalAmount,
        creditAmount: 0,
        currency: currency,
      ),
    ];
    if (interestAmount > 0) {
      lines.add(
        JournalLine(
          accountCode: '5200',
          accountName: 'Interest Expense',
          debitAmount: interestAmount,
          creditAmount: 0,
          currency: currency,
        ),
      );
    }
    lines.add(
      JournalLine(
        accountCode: '1000',
        accountName: 'Cash/Bank',
        debitAmount: 0,
        creditAmount: total,
        currency: currency,
      ),
    );

    return createJournalEntry(
      description: 'Loan Repayment: $loanName',
      journalDate: date,
      journalType: 'automatic',
      sourceModule: 'loans',
      sourceEntityId: loanId,
      autoPost: true,
      lines: lines,
    );
  }

  /// Record savings deposit.
  Future<Map<String, dynamic>> recordSavingsDeposit({
    required double amount,
    required String savingsName,
    required DateTime date,
    String? savingsId,
    String currency = 'TZS',
  }) async {
    return createJournalEntry(
      description: 'Savings Deposit: $savingsName',
      journalDate: date,
      journalType: 'automatic',
      sourceModule: 'savings',
      sourceEntityId: savingsId,
      autoPost: true,
      lines: [
        JournalLine(
          accountCode: '1200',
          accountName: 'Savings Account',
          debitAmount: amount,
          creditAmount: 0,
          currency: currency,
        ),
        JournalLine(
          accountCode: '1000',
          accountName: 'Cash/Bank',
          debitAmount: 0,
          creditAmount: amount,
          currency: currency,
        ),
      ],
    );
  }

  /// Record savings withdrawal.
  Future<Map<String, dynamic>> recordSavingsWithdrawal({
    required double amount,
    required String savingsName,
    required DateTime date,
    String? savingsId,
    String currency = 'TZS',
  }) async {
    return createJournalEntry(
      description: 'Savings Withdrawal: $savingsName',
      journalDate: date,
      journalType: 'automatic',
      sourceModule: 'savings',
      sourceEntityId: savingsId,
      autoPost: true,
      lines: [
        JournalLine(
          accountCode: '1000',
          accountName: 'Cash/Bank',
          debitAmount: amount,
          creditAmount: 0,
          currency: currency,
        ),
        JournalLine(
          accountCode: '1200',
          accountName: 'Savings Account',
          debitAmount: 0,
          creditAmount: amount,
          currency: currency,
        ),
      ],
    );
  }

  // ─── LEDGER QUERIES ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getJournalEntries({
    String? status,
    String? journalType,
    DateTime? startDate,
    DateTime? endDate,
    String? sourceModule,
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('journal_entries')
          .select()
          .eq('user_id', userId);
      if (status != null) query = query.eq('status', status);
      if (journalType != null) query = query.eq('journal_type', journalType);
      if (sourceModule != null) query = query.eq('source_module', sourceModule);
      if (startDate != null) {
        query = query.gte(
          'journal_date',
          startDate.toIso8601String().split('T')[0],
        );
      }
      if (endDate != null) {
        query = query.lte(
          'journal_date',
          endDate.toIso8601String().split('T')[0],
        );
      }
      return List<Map<String, dynamic>>.from(
        await query
            .order('journal_date', ascending: false)
            .range(offset, offset + limit - 1),
      );
    } catch (e) {
      throw AccountingException('Failed to fetch journal entries: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getJournalLines(String journalId) async {
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('journal_entry_lines')
            .select()
            .eq('journal_entry_id', journalId)
            .order('line_order'),
      );
    } catch (e) {
      throw AccountingException('Failed to fetch journal lines: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGeneralLedger({
    String? accountCode,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client.from('general_ledger').select().eq('user_id', userId);
      if (accountCode != null) query = query.eq('account_code', accountCode);
      if (startDate != null) {
        query = query.gte(
          'posting_date',
          startDate.toIso8601String().split('T')[0],
        );
      }
      if (endDate != null) {
        query = query.lte(
          'posting_date',
          endDate.toIso8601String().split('T')[0],
        );
      }
      return List<Map<String, dynamic>>.from(
        await query.order('posting_date', ascending: false).limit(limit),
      );
    } catch (e) {
      throw AccountingException('Failed to fetch general ledger: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTrialBalance({
    DateTime? asOfDate,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final result = await _client.rpc(
        'get_trial_balance',
        params: {
          'p_user_id': userId,
          'p_as_of_date': (asOfDate ?? DateTime.now()).toIso8601String().split(
            'T',
          )[0],
        },
      );
      return List<Map<String, dynamic>>.from(result ?? []);
    } catch (e) {
      throw AccountingException('Failed to fetch trial balance: $e');
    }
  }

  // ─── CHART OF ACCOUNTS ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getChartOfAccounts({
    String? accountType,
    bool includeInactive = false,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('chart_of_accounts')
          .select()
          .eq('user_id', userId);
      if (!includeInactive) query = query.eq('is_active', true);
      if (accountType != null) query = query.eq('account_type', accountType);
      return List<Map<String, dynamic>>.from(await query.order('account_code'));
    } catch (e) {
      throw AccountingException('Failed to fetch chart of accounts: $e');
    }
  }

  Future<Map<String, dynamic>?> createChartAccount({
    required String accountCode,
    required String accountName,
    required String accountType,
    String? accountSubtype,
    String? parentAccountId,
    String? description,
    String normalBalance = 'debit',
    double openingBalance = 0,
    String currency = 'TZS',
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      // Check for duplicate code
      final existing = await _client
          .from('chart_of_accounts')
          .select('id')
          .eq('user_id', userId)
          .eq('account_code', accountCode)
          .maybeSingle();
      if (existing != null) {
        throw AccountingException('Account code $accountCode already exists');
      }

      final result = await _client
          .from('chart_of_accounts')
          .insert({
            'user_id': userId,
            'account_code': accountCode,
            'account_name': accountName,
            'account_type': accountType,
            'account_subtype': accountSubtype,
            'parent_account_id': parentAccountId,
            'description': description,
            'normal_balance': normalBalance,
            'opening_balance': openingBalance,
            'current_balance': openingBalance,
            'currency': currency,
          })
          .select()
          .single();

      await _logAudit(
        entityType: 'chart_of_accounts',
        entityId: result['id'] as String,
        action: 'create',
        description: 'Account created: $accountCode - $accountName',
        sourceModule: 'finance',
      );

      return result;
    } catch (e) {
      if (e is AccountingException) rethrow;
      throw AccountingException('Failed to create account: $e');
    }
  }

  Future<bool> updateChartAccount(
    String accountId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('chart_of_accounts')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', accountId);
      return true;
    } catch (e) {
      throw AccountingException('Failed to update account: $e');
    }
  }

  // ─── FINANCIAL PERIODS ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFinancialPeriods({
    String? status,
    int? fiscalYear,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('financial_periods')
          .select()
          .eq('user_id', userId);
      if (status != null) query = query.eq('status', status);
      if (fiscalYear != null) query = query.eq('fiscal_year', fiscalYear);
      return List<Map<String, dynamic>>.from(
        await query.order('start_date', ascending: false),
      );
    } catch (e) {
      throw AccountingException('Failed to fetch financial periods: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentPeriod() async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final result = await _client
          .from('financial_periods')
          .select()
          .eq('user_id', userId)
          .eq('status', 'open')
          .lte('start_date', today)
          .gte('end_date', today)
          .maybeSingle();
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createFinancialPeriod({
    required String periodName,
    required String periodType,
    required int fiscalYear,
    required int periodNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final result = await _client
          .from('financial_periods')
          .insert({
            'user_id': userId,
            'period_name': periodName,
            'period_type': periodType,
            'fiscal_year': fiscalYear,
            'period_number': periodNumber,
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
            'status': 'open',
          })
          .select()
          .single();
      return result;
    } catch (e) {
      throw AccountingException('Failed to create financial period: $e');
    }
  }

  Future<bool> closePeriod(String periodId) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _client
          .from('financial_periods')
          .update({
            'status': 'closed',
            'closed_at': DateTime.now().toIso8601String(),
            'closed_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', periodId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      throw AccountingException('Failed to close period: $e');
    }
  }

  // ─── AUDIT TRAIL ─────────────────────────────────────────────────────────

  Future<void> _logAudit({
    required String entityType,
    required String entityId,
    required String action,
    String? description,
    String? sourceModule,
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
        'source_module': sourceModule,
        'old_values': oldValues,
        'new_values': newValues,
        'performed_by': userId,
        'performed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Audit logging should never block main operations
    }
  }

  Future<List<Map<String, dynamic>>> getAuditTrail({
    String? entityType,
    String? entityId,
    int limit = 50,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('financial_audit_trail')
          .select()
          .eq('user_id', userId);
      if (entityType != null) query = query.eq('entity_type', entityType);
      if (entityId != null) query = query.eq('entity_id', entityId);
      return List<Map<String, dynamic>>.from(
        await query.order('performed_at', ascending: false).limit(limit),
      );
    } catch (e) {
      return [];
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  Future<String> _generateJournalNumber(String userId) async {
    try {
      final result = await _client.rpc(
        'generate_journal_number',
        params: {'p_user_id': userId},
      );
      return result as String;
    } catch (_) {
      final now = DateTime.now();
      return 'JE-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    }
  }
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class JournalLine {
  final String? coaAccountId;
  final String accountCode;
  final String accountName;
  final double debitAmount;
  final double creditAmount;
  final String? description;
  final String currency;

  const JournalLine({
    this.coaAccountId,
    required this.accountCode,
    required this.accountName,
    required this.debitAmount,
    required this.creditAmount,
    this.description,
    this.currency = 'TZS',
  });
}

class AccountingException implements Exception {
  final String message;
  const AccountingException(this.message);

  @override
  String toString() => 'AccountingException: $message';
}
