import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// Enterprise Transaction Service
/// Single Financial Ledger — every financial event creates/updates transactions.
/// Handles full CRUD, all transaction types, and automatic sync to all modules.
class EnterpriseTransactionService {
  static EnterpriseTransactionService? _instance;
  static EnterpriseTransactionService get instance =>
      _instance ??= EnterpriseTransactionService._();
  EnterpriseTransactionService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // All supported transaction types
  static const List<String> allTransactionTypes = [
    'income',
    'expense',
    'transfer',
    'business_income',
    'business_expense',
    'investment_deposit',
    'investment_withdrawal',
    'loan_given',
    'loan_taken',
    'loan_repayment',
    'interest_received',
    'interest_paid',
    'savings_deposit',
    'savings_withdrawal',
    'asset_purchase',
    'asset_sale',
    'equity_contribution',
    'dividend',
    'salary',
    'tax',
    'adjustment',
    'refund',
    'write_off',
    'other',
  ];

  static const Map<String, String> typeLabels = {
    'income': 'Income',
    'expense': 'Expense',
    'transfer': 'Transfer',
    'business_income': 'Business Income',
    'business_expense': 'Business Expense',
    'investment_deposit': 'Investment Deposit',
    'investment_withdrawal': 'Investment Withdrawal',
    'loan_given': 'Loan Given',
    'loan_taken': 'Loan Taken',
    'loan_repayment': 'Loan Repayment',
    'interest_received': 'Interest Received',
    'interest_paid': 'Interest Paid',
    'savings_deposit': 'Savings Deposit',
    'savings_withdrawal': 'Savings Withdrawal',
    'asset_purchase': 'Asset Purchase',
    'asset_sale': 'Asset Sale',
    'equity_contribution': 'Equity Contribution',
    'dividend': 'Dividend',
    'salary': 'Salary',
    'tax': 'Tax',
    'adjustment': 'Adjustment',
    'refund': 'Refund',
    'write_off': 'Write-off',
    'other': 'Other',
  };

  static const Map<String, String> typeIcons = {
    'income': 'arrow_downward',
    'expense': 'arrow_upward',
    'transfer': 'swap_horiz',
    'business_income': 'business_center',
    'business_expense': 'business',
    'investment_deposit': 'trending_up',
    'investment_withdrawal': 'trending_down',
    'loan_given': 'handshake',
    'loan_taken': 'account_balance',
    'loan_repayment': 'payments',
    'interest_received': 'percent',
    'interest_paid': 'money_off',
    'savings_deposit': 'savings',
    'savings_withdrawal': 'account_balance_wallet',
    'asset_purchase': 'add_shopping_cart',
    'asset_sale': 'sell',
    'equity_contribution': 'group_add',
    'dividend': 'monetization_on',
    'salary': 'badge',
    'tax': 'receipt_long',
    'adjustment': 'tune',
    'refund': 'undo',
    'write_off': 'delete_sweep',
    'other': 'receipt',
  };

  // ─── FULL CRUD ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    String? category,
    String? accountId,
    String? businessId,
    String? investmentId,
    String? loanId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool includeArchived = false,
    int limit = 100,
    int offset = 0,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('financial_transactions')
          .select()
          .eq('user_id', userId);

      if (!includeArchived) query = query.eq('is_archived', false);
      if (type != null) query = query.eq('transaction_type', type);
      if (category != null) query = query.eq('category', category);
      if (accountId != null) query = query.eq('account_id', accountId);
      if (businessId != null) {
        query = query.eq('related_business_id', businessId);
      }
      if (investmentId != null) {
        query = query.eq('related_investment_id', investmentId);
      }
      if (loanId != null) query = query.eq('related_loan_id', loanId);
      if (startDate != null) {
        query = query.gte(
          'transaction_date',
          startDate.toIso8601String().split('T')[0],
        );
      }
      if (endDate != null) {
        query = query.lte(
          'transaction_date',
          endDate.toIso8601String().split('T')[0],
        );
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('description', '%$searchQuery%');
      }

      return List<Map<String, dynamic>>.from(
        await query
            .order('transaction_date', ascending: false)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1),
      );
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createTransaction({
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    String? title,
    String? description,
    String? accountId,
    String? sourceAccountId,
    String? destinationAccountId,
    String? businessId,
    String? investmentId,
    String? loanId,
    String? goalId,
    String? referenceNumber,
    List<String>? tags,
    String currency = 'TZS',
    String status = 'completed',
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'transaction_type': type,
        'category': category,
        'amount': amount,
        'transaction_date': date.toIso8601String().split('T')[0],
        'status': status,
        'currency': currency,
        'is_archived': false,
      };
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (accountId != null) data['account_id'] = accountId;
      if (sourceAccountId != null) data['source_account_id'] = sourceAccountId;
      if (destinationAccountId != null) {
        data['destination_account_id'] = destinationAccountId;
      }
      if (businessId != null) data['related_business_id'] = businessId;
      if (investmentId != null) data['related_investment_id'] = investmentId;
      if (loanId != null) data['related_loan_id'] = loanId;
      if (goalId != null) data['related_goal_id'] = goalId;
      if (referenceNumber != null) data['reference_number'] = referenceNumber;
      if (tags != null) data['tags'] = tags;

      final res = await _client
          .from('financial_transactions')
          .insert(data)
          .select()
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateTransaction(
    String transactionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('financial_transactions')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', transactionId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _client
          .from('financial_transactions')
          .delete()
          .eq('id', transactionId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> archiveTransaction(String transactionId) async {
    return updateTransaction(transactionId, {'is_archived': true});
  }

  Future<bool> restoreTransaction(String transactionId) async {
    return updateTransaction(transactionId, {'is_archived': false});
  }

  Future<Map<String, dynamic>?> duplicateTransaction(
    String transactionId,
  ) async {
    try {
      final original = await _client
          .from('financial_transactions')
          .select()
          .eq('id', transactionId)
          .single();
      final copy = Map<String, dynamic>.from(original);
      copy.remove('id');
      copy.remove('created_at');
      copy.remove('updated_at');
      copy['transaction_date'] = DateTime.now().toIso8601String().split('T')[0];
      copy['description'] = '${copy['description'] ?? ''} (Copy)'.trim();
      final res = await _client
          .from('financial_transactions')
          .insert(copy)
          .select()
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  // ─── TRANSFER ENGINE ─────────────────────────────────────────────────────

  Future<bool> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    final txDate = (date ?? DateTime.now()).toIso8601String().split('T')[0];
    try {
      // Create debit transaction
      final debit = await _client
          .from('financial_transactions')
          .insert({
            'user_id': userId,
            'transaction_type': 'transfer',
            'category': 'transfer_out',
            'amount': amount,
            'account_id': fromAccountId,
            'source_account_id': fromAccountId,
            'destination_account_id': toAccountId,
            'description': description ?? 'Transfer',
            'transaction_date': txDate,
            'status': 'completed',
            'currency': 'TZS',
            'is_archived': false,
          })
          .select()
          .single();

      // Create credit transaction
      final credit = await _client
          .from('financial_transactions')
          .insert({
            'user_id': userId,
            'transaction_type': 'transfer',
            'category': 'transfer_in',
            'amount': amount,
            'account_id': toAccountId,
            'source_account_id': fromAccountId,
            'destination_account_id': toAccountId,
            'description': description ?? 'Transfer',
            'transaction_date': txDate,
            'status': 'completed',
            'currency': 'TZS',
            'is_archived': false,
            'linked_transfer_id': debit['id'],
          })
          .select()
          .single();

      // Link debit to credit
      await _client
          .from('financial_transactions')
          .update({'linked_transfer_id': credit['id']})
          .eq('id', debit['id'] as String);

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── BUSINESS TRANSACTION SYNC ───────────────────────────────────────────

  Future<bool> syncBusinessTransactionToLedger(
    String businessTransactionId,
  ) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      // First try the RPC function
      await _client.rpc(
        'sync_business_transaction_to_ledger',
        params: {
          'p_business_transaction_id': businessTransactionId,
          'p_user_id': userId,
        },
      );
      return true;
    } catch (_) {
      // RPC failed — fall back to direct insert into financial_transactions
      try {
        final bt = await _client
            .from('business_transactions')
            .select()
            .eq('id', businessTransactionId)
            .maybeSingle();
        if (bt == null) return false;

        // Check if already synced to avoid duplicates
        if (bt['financial_transaction_id'] != null) {
          // Already linked — update the existing financial transaction instead
          final txType = bt['transaction_type'] == 'revenue'
              ? 'business_income'
              : 'business_expense';
          try {
            await _client
                .from('financial_transactions')
                .update({
                  'amount': bt['amount'],
                  'description': bt['description'] ?? bt['category'] ?? txType,
                  'transaction_date': bt['transaction_date'],
                  'transaction_type': txType,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', bt['financial_transaction_id'] as String);
          } catch (_) {}
          return true;
        }

        final txType = bt['transaction_type'] == 'revenue'
            ? 'business_income'
            : 'business_expense';

        final ft = await _client
            .from('financial_transactions')
            .insert({
              'user_id': userId,
              'transaction_type': txType,
              'category': bt['category'] ?? txType,
              'amount': bt['amount'],
              'description': bt['description'] ?? bt['category'] ?? txType,
              'transaction_date': bt['transaction_date'],
              'related_business_id': bt['business_id'],
              'status': 'completed',
              'currency': 'TZS',
              'is_archived': false,
              'title':
                  '${bt['transaction_type'] == 'revenue' ? 'Revenue' : 'Expense'}: ${bt['category'] ?? ''}',
            })
            .select()
            .single();

        // Link the financial transaction back to the business transaction
        try {
          await _client
              .from('business_transactions')
              .update({'financial_transaction_id': ft['id']})
              .eq('id', businessTransactionId);
        } catch (_) {}

        return true;
      } catch (e) {
        return false;
      }
    }
  }

  Future<bool> createBusinessTransaction({
    required String businessId,
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    String? description,
    String? branchId,
    String? customerClient,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      final bt = await _client
          .from('business_transactions')
          .insert({
            'business_id': businessId,
            'transaction_type': type,
            'category': category,
            'amount': amount,
            'description': description,
            'branch_id': branchId,
            'customer_client': customerClient,
            'transaction_date': date.toIso8601String().split('T')[0],
            'is_archived': false,
          })
          .select()
          .single();

      // Sync to financial ledger — creates entry in financial_transactions
      // This ensures the transaction appears in the Enterprise Transaction Engine
      await syncBusinessTransactionToLedger(bt['id'] as String);

      // Also create a direct financial_transactions entry linked to the business
      // as a backup to ensure it always appears in business transaction history
      try {
        final txType = type == 'revenue'
            ? 'business_income'
            : 'business_expense';
        final existing = await _client
            .from('financial_transactions')
            .select('id')
            .eq('user_id', userId)
            .eq('related_business_id', businessId)
            .eq('transaction_date', date.toIso8601String().split('T')[0])
            .eq('amount', amount)
            .eq('transaction_type', txType)
            .limit(1);
        if ((existing as List).isEmpty) {
          // No duplicate found — the sync above should have created it
          // If not, create it now
          final btUpdated = await _client
              .from('business_transactions')
              .select('financial_transaction_id')
              .eq('id', bt['id'] as String)
              .maybeSingle();
          if (btUpdated == null ||
              btUpdated['financial_transaction_id'] == null) {
            await _client.from('financial_transactions').insert({
              'user_id': userId,
              'transaction_type': txType,
              'category': category,
              'amount': amount,
              'description': description ?? category,
              'transaction_date': date.toIso8601String().split('T')[0],
              'related_business_id': businessId,
              'status': 'completed',
              'currency': 'TZS',
              'is_archived': false,
              'title':
                  '${type == 'revenue' ? 'Revenue' : 'Expense'}: $category',
            });
          }
        }
      } catch (_) {
        // Backup sync failed — primary sync may have succeeded
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBusinessTransaction(
    String btId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('business_transactions')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', btId);

      // Re-sync to ledger: update the linked financial transaction
      final bt = await _client
          .from('business_transactions')
          .select(
            'financial_transaction_id, amount, description, category, transaction_date, transaction_type',
          )
          .eq('id', btId)
          .maybeSingle();

      if (bt != null && bt['financial_transaction_id'] != null) {
        final txType = bt['transaction_type'] == 'revenue'
            ? 'business_income'
            : 'business_expense';
        await _client
            .from('financial_transactions')
            .update({
              'amount': bt['amount'],
              'description': bt['description'] ?? bt['category'],
              'transaction_date': bt['transaction_date'],
              'transaction_type': txType,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', bt['financial_transaction_id'] as String);
      } else if (bt != null) {
        // No linked transaction yet — create one now
        await syncBusinessTransactionToLedger(btId);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBusinessTransaction(String btId) async {
    try {
      // Get linked financial transaction before deleting
      final bt = await _client
          .from('business_transactions')
          .select('financial_transaction_id')
          .eq('id', btId)
          .maybeSingle();

      // Delete from business_transactions
      await _client.from('business_transactions').delete().eq('id', btId);

      // Delete linked financial transaction if it exists
      if (bt != null && bt['financial_transaction_id'] != null) {
        await _client
            .from('financial_transactions')
            .delete()
            .eq('id', bt['financial_transaction_id'] as String);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── ANALYTICS ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTransactionAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) return {};
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? now;

    try {
      final txns = await getTransactions(
        startDate: start,
        endDate: end,
        limit: 500,
      );

      double totalIncome = 0;
      double totalExpense = 0;
      final categoryTotals = <String, double>{};
      final typeTotals = <String, double>{};
      Map<String, dynamic>? largest;

      for (final t in txns) {
        final amt = (t['amount'] as num).toDouble();
        final type = t['transaction_type'] as String;
        final cat = t['category'] as String? ?? 'other';

        if ([
          'income',
          'business_income',
          'investment_deposit',
          'interest_received',
          'dividend',
          'salary',
          'refund',
          'savings_withdrawal',
          'asset_sale',
          'loan_repayment',
        ].contains(type)) {
          totalIncome += amt;
        } else if ([
          'expense',
          'business_expense',
          'investment_withdrawal',
          'interest_paid',
          'tax',
          'savings_deposit',
          'asset_purchase',
          'loan_given',
          'loan_taken',
          'write_off',
        ].contains(type)) {
          totalExpense += amt;
        }

        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
        typeTotals[type] = (typeTotals[type] ?? 0) + amt;

        if (largest == null || amt > (largest['amount'] as num).toDouble()) {
          largest = t;
        }
      }

      return {
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'net': totalIncome - totalExpense,
        'transaction_count': txns.length,
        'category_totals': categoryTotals,
        'type_totals': typeTotals,
        'largest_transaction': largest,
        'average_transaction': txns.isEmpty
            ? 0
            : (totalIncome + totalExpense) / txns.length,
      };
    } catch (_) {
      return {};
    }
  }
}
