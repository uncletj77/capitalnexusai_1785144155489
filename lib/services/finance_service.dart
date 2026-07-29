import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// FinanceService — Single Source of Truth for all financial data in CNA.
/// All dashboards, analytics, AI, reports, and forecasting read from here.
/// No module may maintain independent balances or fabricate financial data.
class FinanceService {
  static FinanceService? _instance;
  static FinanceService get instance => _instance ??= FinanceService._();
  FinanceService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── ACCOUNTS ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAccounts({
    String? category,
    bool includeArchived = false,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('financial_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);
      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }
      if (category != null && category != 'all') {
        query = query.eq('account_category', category);
      }
      return List<Map<String, dynamic>>.from(
        await query.order('created_at', ascending: false),
      );
    } catch (_) {
      return [];
    }
  }

  Future<double> getAccountBalance(String accountId) async {
    try {
      final res = await _client.rpc(
        'get_account_balance',
        params: {'p_account_id': accountId},
      );
      return (res as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getAccountsWithBalances({
    String? category,
  }) async {
    final accounts = await getAccounts(category: category);
    final enriched = <Map<String, dynamic>>[];
    for (final acc in accounts) {
      final balance = await getAccountBalance(acc['id'] as String);
      enriched.add({...acc, 'calculated_balance': balance});
    }
    return enriched;
  }

  Future<double> getTotalCash() async {
    final accounts = await getAccounts();
    double total = 0;
    for (final acc in accounts) {
      total += await getAccountBalance(acc['id'] as String);
    }
    return total;
  }

  Future<Map<String, dynamic>?> createAccount({
    required String name,
    required String category,
    String? provider,
    String? accountNumber,
    double initialBalance = 0,
    String currency = 'TZS',
    String color = '#1A5F7A',
    String icon = 'account_balance',
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final res = await _client
          .from('financial_accounts')
          .insert({
            'user_id': userId,
            'account_name': name,
            'account_category': category,
            'provider': provider,
            'account_number': accountNumber,
            'balance': initialBalance,
            'initial_balance': initialBalance,
            'currency': currency,
            'color': color,
            'icon': icon,
            'notes': notes,
          })
          .select()
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateAccount(
    String accountId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('financial_accounts')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', accountId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> archiveAccount(String accountId) async {
    return updateAccount(accountId, {'is_archived': true, 'is_active': false});
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    String? category,
    String? accountId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('financial_transactions')
          .select()
          .eq('user_id', userId);

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }
      if (type != null) query = query.eq('transaction_type', type);
      if (category != null) query = query.eq('category', category);
      if (accountId != null) query = query.eq('account_id', accountId);
      if (status != null) {
        query = query.eq('status', status);
      } else {
        query = query.neq('status', 'cancelled');
      }
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

  Future<List<Map<String, dynamic>>> getRecentTransactions({
    int limit = 10,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('financial_transactions')
            .select()
            .eq('user_id', userId)
            .eq('is_archived', false)
            .neq('status', 'cancelled')
            .order('transaction_date', ascending: false)
            .order('created_at', ascending: false)
            .limit(limit),
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
    String? accountId,
    String? description,
    String? notes,
    String? referenceId,
    String? relatedModule,
    String? relatedEntityId,
    String? relatedBusinessId,
    String? relatedInvestmentId,
    String? relatedLoanId,
    String? relatedLoanReceivableId,
    String? relatedGoalId,
    String currency = 'TZS',
    bool isRecurring = false,
    String status = 'completed',
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final res = await _client
          .from('financial_transactions')
          .insert({
            'user_id': userId,
            'account_id': accountId,
            'transaction_type': type,
            'category': category,
            'amount': amount,
            'description': description,
            'notes': notes,
            'reference_id': referenceId,
            'related_module': relatedModule,
            'related_entity_id': relatedEntityId,
            'related_business_id': relatedBusinessId,
            'related_investment_id': relatedInvestmentId,
            'related_loan_id': relatedLoanId,
            'related_loan_receivable_id': relatedLoanReceivableId,
            'related_goal_id': relatedGoalId,
            'transaction_date': date.toIso8601String().split('T')[0],
            'currency': currency,
            'is_recurring': isRecurring,
            'status': status,
            'is_archived': false,
          })
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

  // ─── CASH FLOW ────────────────────────────────────────────────────────────

  Future<Map<String, double>> getCashFlowSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) return {'income': 0, 'expenses': 0, 'net': 0};
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? now;
    try {
      final res = await _client.rpc(
        'get_cash_flow_summary',
        params: {
          'p_user_id': userId,
          'p_start_date': start.toIso8601String().split('T')[0],
          'p_end_date': end.toIso8601String().split('T')[0],
        },
      );
      if (res is List && res.isNotEmpty) {
        final row = res[0] as Map<String, dynamic>;
        return {
          'income': (row['total_income'] as num?)?.toDouble() ?? 0,
          'expenses': (row['total_expenses'] as num?)?.toDouble() ?? 0,
          'net': (row['net_cash_flow'] as num?)?.toDouble() ?? 0,
          'count': (row['transaction_count'] as num?)?.toDouble() ?? 0,
        };
      }
      return _calculateCashFlowManually(userId, start, end);
    } catch (_) {
      return _calculateCashFlowManually(userId, start, end);
    }
  }

  Future<Map<String, double>> _calculateCashFlowManually(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final txns = await _client
          .from('financial_transactions')
          .select('transaction_type, amount')
          .eq('user_id', userId)
          .eq('is_archived', false)
          .neq('status', 'cancelled')
          .gte('transaction_date', start.toIso8601String().split('T')[0])
          .lte('transaction_date', end.toIso8601String().split('T')[0]);

      double income = 0;
      double expenses = 0;
      for (final t in txns) {
        final amt = (t['amount'] as num).toDouble();
        if (t['transaction_type'] == 'income') income += amt;
        if (t['transaction_type'] == 'expense') expenses += amt;
      }
      return {'income': income, 'expenses': expenses, 'net': income - expenses};
    } catch (_) {
      return {'income': 0, 'expenses': 0, 'net': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyCashFlow({
    int months = 6,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final res = await _client.rpc(
        'get_monthly_cash_flow',
        params: {'p_user_id': userId, 'p_months': months},
      );
      return List<Map<String, dynamic>>.from(res ?? []);
    } catch (_) {
      return _calculateMonthlyCashFlowManually(userId, months);
    }
  }

  Future<List<Map<String, dynamic>>> _calculateMonthlyCashFlowManually(
    String userId,
    int months,
  ) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - months + 1, 1);
      final txns = await _client
          .from('financial_transactions')
          .select('transaction_type, amount, transaction_date')
          .eq('user_id', userId)
          .eq('is_archived', false)
          .neq('status', 'cancelled')
          .gte('transaction_date', startDate.toIso8601String().split('T')[0]);

      final monthMap = <String, Map<String, dynamic>>{};
      for (final t in txns) {
        final dateStr = t['transaction_date'] as String;
        final date = DateTime.parse(dateStr);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthMap.putIfAbsent(
          key,
          () => {
            'month_year': _monthLabel(date),
            'month_start': DateTime(
              date.year,
              date.month,
              1,
            ).toIso8601String().split('T')[0],
            'total_income': 0.0,
            'total_expenses': 0.0,
            'net_cash_flow': 0.0,
          },
        );
        final amt = (t['amount'] as num).toDouble();
        if (t['transaction_type'] == 'income') {
          monthMap[key]!['total_income'] =
              (monthMap[key]!['total_income'] as double) + amt;
          monthMap[key]!['net_cash_flow'] =
              (monthMap[key]!['net_cash_flow'] as double) + amt;
        } else if (t['transaction_type'] == 'expense') {
          monthMap[key]!['total_expenses'] =
              (monthMap[key]!['total_expenses'] as double) + amt;
          monthMap[key]!['net_cash_flow'] =
              (monthMap[key]!['net_cash_flow'] as double) - amt;
        }
      }
      final result = monthMap.values.toList();
      result.sort(
        (a, b) =>
            (a['month_start'] as String).compareTo(b['month_start'] as String),
      );
      return result;
    } catch (_) {
      return [];
    }
  }

  String _monthLabel(DateTime d) {
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
    return '${months[d.month - 1]} ${d.year}';
  }

  // ─── NET WORTH ────────────────────────────────────────────────────────────

  Future<Map<String, double>> getNetWorth() async {
    final userId = _userId;
    if (userId == null) return {'assets': 0, 'liabilities': 0, 'netWorth': 0};
    try {
      final res = await _client.rpc(
        'calculate_net_worth',
        params: {'p_user_id': userId},
      );
      if (res is List && res.isNotEmpty) {
        final row = res[0] as Map<String, dynamic>;
        return {
          'assets': (row['total_assets'] as num?)?.toDouble() ?? 0,
          'liabilities': (row['total_liabilities'] as num?)?.toDouble() ?? 0,
          'netWorth': (row['net_worth'] as num?)?.toDouble() ?? 0,
        };
      }
      return _calculateNetWorthManually(userId);
    } catch (_) {
      return _calculateNetWorthManually(userId);
    }
  }

  Future<Map<String, double>> _calculateNetWorthManually(String userId) async {
    try {
      double totalCash = await getTotalCash();
      double assetValue = 0;
      double loanBalance = 0;
      double receivableBalance = 0;

      try {
        final assets = await _client
            .from('assets')
            .select('current_value')
            .eq('user_id', userId)
            .neq('asset_status', 'disposed');
        assetValue = (assets as List).fold(
          0.0,
          (s, a) => s + ((a['current_value'] as num?)?.toDouble() ?? 0),
        );
      } catch (_) {}

      try {
        final loans = await _client
            .from('loans')
            .select('remaining_balance')
            .eq('user_id', userId)
            .eq('status', 'active');
        loanBalance = (loans as List).fold(
          0.0,
          (s, l) => s + ((l['remaining_balance'] as num?)?.toDouble() ?? 0),
        );
      } catch (_) {}

      try {
        final receivables = await _client
            .from('loans_receivable')
            .select('remaining_balance')
            .eq('user_id', userId)
            .inFilter('loan_status', ['active', 'partially_paid', 'overdue']);
        receivableBalance = (receivables as List).fold(
          0.0,
          (s, r) => s + ((r['remaining_balance'] as num?)?.toDouble() ?? 0),
        );
      } catch (_) {}

      final totalAssets = totalCash + assetValue + receivableBalance;
      return {
        'assets': totalAssets,
        'liabilities': loanBalance,
        'netWorth': totalAssets - loanBalance,
      };
    } catch (_) {
      return {'assets': 0, 'liabilities': 0, 'netWorth': 0};
    }
  }

  Future<void> saveNetWorthSnapshot() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final nw = await getNetWorth();
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _client.from('net_worth_snapshots').upsert({
        'user_id': userId,
        'total_assets': nw['assets'],
        'total_liabilities': nw['liabilities'],
        'net_worth': nw['netWorth'],
        'snapshot_date': today,
      }, onConflict: 'user_id,snapshot_date');
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getNetWorthHistory({
    int limit = 12,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('net_worth_snapshots')
            .select()
            .eq('user_id', userId)
            .order('snapshot_date', ascending: true)
            .limit(limit),
      );
    } catch (_) {
      return [];
    }
  }

  // ─── BUDGETS ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBudgetsWithSpending() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final now = DateTime.now();
      final periodStart = DateTime(
        now.year,
        now.month,
        1,
      ).toIso8601String().split('T')[0];
      final periodEnd = DateTime(
        now.year,
        now.month + 1,
        0,
      ).toIso8601String().split('T')[0];

      final budgets = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final spendingRes = await _client.rpc(
        'get_budget_spending',
        params: {
          'p_user_id': userId,
          'p_period_start': periodStart,
          'p_period_end': periodEnd,
        },
      );

      final spendingMap = <String, double>{};
      if (spendingRes is List) {
        for (final row in spendingRes) {
          spendingMap[row['category'] as String] =
              (row['actual_spent'] as num?)?.toDouble() ?? 0;
        }
      }

      return (budgets as List).map((b) {
        final category = b['category'] as String? ?? 'other';
        final actual = spendingMap[category] ?? 0;
        final planned = (b['planned_amount'] as num).toDouble();
        return <String, dynamic>{
          ...Map<String, dynamic>.from(b as Map),
          'actual_spent': actual,
          'remaining': (planned - actual).clamp(0.0, double.infinity),
          'progress': planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0,
          'is_over_budget': actual > planned,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createBudget({
    required String name,
    required String category,
    required double plannedAmount,
    String period = 'monthly',
    String color = '#1A5F7A',
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final now = DateTime.now();
      final res = await _client
          .from('budgets')
          .insert({
            'user_id': userId,
            'name': name,
            'category': category,
            'planned_amount': plannedAmount,
            'period': period,
            'color': color,
            'period_start': DateTime(
              now.year,
              now.month,
              1,
            ).toIso8601String().split('T')[0],
            'period_end': DateTime(
              now.year,
              now.month + 1,
              0,
            ).toIso8601String().split('T')[0],
          })
          .select()
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  // ─── CATEGORIES ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('transaction_categories')
          .select()
          .or('is_system.eq.true,user_id.eq.$userId');
      if (type != null) {
        query = query.eq('category_type', type);
      }
      return List<Map<String, dynamic>>.from(
        await query.order('name', ascending: true),
      );
    } catch (_) {
      return [];
    }
  }

  // ─── LOANS RECEIVABLE ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLoansReceivable({
    String? status,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('loans_receivable')
          .select()
          .eq('user_id', userId);
      if (status != null) {
        query = query.eq('loan_status', status);
      }
      return List<Map<String, dynamic>>.from(
        await query.order('created_at', ascending: false),
      );
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createLoanReceivable({
    required String borrowerName,
    required double amount,
    required DateTime dateGiven,
    String? borrowerContact,
    double interestRate = 0,
    DateTime? dueDate,
    String currency = 'TZS',
    String? notes,
    String? accountId,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      // Create the loan receivable record
      final loan = await _client
          .from('loans_receivable')
          .insert({
            'user_id': userId,
            'borrower_name': borrowerName,
            'borrower_contact': borrowerContact,
            'amount': amount,
            'interest_rate': interestRate,
            'date_given': dateGiven.toIso8601String().split('T')[0],
            'due_date': dueDate?.toIso8601String().split('T')[0],
            'remaining_balance': amount,
            'total_repaid': 0,
            'currency': currency,
            'loan_status': 'active',
            'notes': notes,
          })
          .select()
          .single();

      // Record as a financial transaction (money going out)
      final tx = await createTransaction(
        type: 'expense',
        category: 'loan_given',
        amount: amount,
        date: dateGiven,
        accountId: accountId,
        description: 'Loan given to $borrowerName',
        notes: notes,
        relatedLoanReceivableId: loan['id'] as String,
        relatedModule: 'loans_receivable',
        currency: currency,
      );

      // Link transaction back to loan
      if (tx != null) {
        await _client
            .from('loans_receivable')
            .update({'related_transaction_id': tx['id']})
            .eq('id', loan['id'] as String);
      }

      return loan;
    } catch (_) {
      return null;
    }
  }

  Future<bool> recordLoanReceivableRepayment({
    required String loanReceivableId,
    required double amount,
    required DateTime paymentDate,
    String? accountId,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      // Get current loan details
      final loan = await _client
          .from('loans_receivable')
          .select()
          .eq('id', loanReceivableId)
          .eq('user_id', userId)
          .single();

      final currentBalance = (loan['remaining_balance'] as num).toDouble();
      final newBalance = (currentBalance - amount).clamp(0.0, double.infinity);
      final totalRepaid = (loan['total_repaid'] as num).toDouble() + amount;

      String newStatus = 'active';
      if (newBalance <= 0) {
        newStatus = 'paid';
      } else if (newBalance < (loan['amount'] as num).toDouble()) {
        newStatus = 'partially_paid';
      }

      // Record repayment
      await _client.from('loan_receivable_repayments').insert({
        'user_id': userId,
        'loan_receivable_id': loanReceivableId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String().split('T')[0],
        'notes': notes,
      });

      // Update loan balance
      await _client
          .from('loans_receivable')
          .update({
            'remaining_balance': newBalance,
            'total_repaid': totalRepaid,
            'loan_status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loanReceivableId);

      // Record as income transaction (money coming back)
      await createTransaction(
        type: 'income',
        category: 'loan_repayment_received',
        amount: amount,
        date: paymentDate,
        accountId: accountId,
        description: 'Repayment from ${loan['borrower_name']}',
        notes: notes,
        relatedLoanReceivableId: loanReceivableId,
        relatedModule: 'loans_receivable',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateLoanReceivable(
    String loanId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('loans_receivable')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', loanId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteLoanReceivable(String loanId) async {
    try {
      await _client.from('loans_receivable').delete().eq('id', loanId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLoanReceivableRepayments(
    String loanReceivableId,
  ) async {
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('loan_receivable_repayments')
            .select()
            .eq('loan_receivable_id', loanReceivableId)
            .order('payment_date', ascending: false),
      );
    } catch (_) {
      return [];
    }
  }

  // ─── DASHBOARD SUMMARY ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final userId = _userId;
    if (userId == null) return _emptyDashboard();
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        getNetWorth(),
        getCashFlowSummary(startDate: monthStart, endDate: now),
        getAccounts(),
        _getLoanCount(userId),
        _getInvestmentTotal(userId),
        _getBusinessValue(userId),
      ]);

      final nw = results[0] as Map<String, double>;
      final cf = results[1] as Map<String, double>;
      final accounts = results[2] as List<Map<String, dynamic>>;
      final loanCount = results[3] as int;
      final investTotal = results[4] as double;
      final bizValue = results[5] as double;

      double totalCash = 0;
      for (final acc in accounts) {
        totalCash += await getAccountBalance(acc['id'] as String);
      }

      final income = cf['income'] ?? 0;
      final expenses = cf['expenses'] ?? 0;
      final savings = income - expenses;

      return {
        'netWorth': nw['netWorth'] ?? 0,
        'totalAssets': nw['assets'] ?? 0,
        'totalLiabilities': nw['liabilities'] ?? 0,
        'availableCash': totalCash,
        'monthlyIncome': income,
        'monthlyExpenses': expenses,
        'totalInvestments': investTotal,
        'totalBusinessValue': bizValue,
        'spend': expenses,
        'save': savings > 0 ? savings : 0.0,
        'invest': investTotal,
        'borrowCount': loanCount,
        'savingsRate': income > 0 ? (savings / income * 100) : 0.0,
      };
    } catch (_) {
      return _emptyDashboard();
    }
  }

  Map<String, dynamic> _emptyDashboard() => {
    'netWorth': 0.0,
    'totalAssets': 0.0,
    'totalLiabilities': 0.0,
    'availableCash': 0.0,
    'monthlyIncome': 0.0,
    'monthlyExpenses': 0.0,
    'totalInvestments': 0.0,
    'totalBusinessValue': 0.0,
    'spend': 0.0,
    'save': 0.0,
    'invest': 0.0,
    'borrowCount': 0,
    'savingsRate': 0.0,
  };

  Future<int> _getLoanCount(String userId) async {
    try {
      final res = await _client
          .from('loans')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active');
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _getInvestmentTotal(String userId) async {
    try {
      // Try investments table first
      final res = await _client
          .from('investments')
          .select('current_value')
          .eq('user_id', userId);
      return (res as List).fold<double>(
        0.0,
        (s, i) => s + ((i['current_value'] as num?)?.toDouble() ?? 0),
      );
    } catch (_) {
      try {
        // Fallback to user_investments
        final res = await _client
            .from('user_investments')
            .select('current_value')
            .eq('user_id', userId);
        return (res as List).fold<double>(
          0.0,
          (s, i) => s + ((i['current_value'] as num?)?.toDouble() ?? 0),
        );
      } catch (_) {
        return 0.0;
      }
    }
  }

  Future<double> _getBusinessValue(String userId) async {
    try {
      final res = await _client
          .from('businesses')
          .select('valuation')
          .eq('user_id', userId)
          .eq('is_active', true);
      return (res as List).fold<double>(
        0.0,
        (s, b) => s + ((b['valuation'] as num?)?.toDouble() ?? 0),
      );
    } catch (_) {
      return 0.0;
    }
  }

  // ─── INCOME SOURCES ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getIncomeSources() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('income_sources')
            .select()
            .eq('user_id', userId)
            .eq('is_active', true)
            .order('created_at', ascending: false),
      );
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createIncomeSource({
    required String name,
    required String category,
    required double amount,
    String frequency = 'monthly',
    int reliabilityScore = 80,
    String? description,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      return await _client
          .from('income_sources')
          .insert({
            'user_id': userId,
            'name': name,
            'category': category,
            'amount': amount,
            'frequency': frequency,
            'reliability_score': reliabilityScore,
            'description': description,
          })
          .select()
          .single();
    } catch (_) {
      return null;
    }
  }

  // ─── FINANCIAL GOALS ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFinancialGoals() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('financial_goals')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false),
      );
    } catch (_) {
      return [];
    }
  }

  /// Returns goal progress calculated from actual transactions linked to the goal.
  Future<double> getGoalProgress(String goalId) async {
    final userId = _userId;
    if (userId == null) return 0;
    try {
      final res = await _client.rpc(
        'get_goal_progress',
        params: {'p_goal_id': goalId, 'p_user_id': userId},
      );
      return (res as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      // Fallback: read current_amount from goal
      try {
        final goal = await _client
            .from('financial_goals')
            .select('current_amount')
            .eq('id', goalId)
            .single();
        return (goal['current_amount'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        return 0.0;
      }
    }
  }

  Future<Map<String, dynamic>?> createGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    double monthlyContribution = 0,
    String category = 'savings',
    String priority = 'medium',
    String? fundingSource,
    String? fundingAccountId,
    DateTime? deadline,
    String color = '#1A5F7A',
    String icon = 'flag',
    String? description,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      return await _client
          .from('financial_goals')
          .insert({
            'user_id': userId,
            'name': name,
            'target_amount': targetAmount,
            'current_amount': currentAmount,
            'monthly_contribution': monthlyContribution,
            'category': category,
            'priority': priority,
            'funding_source': fundingSource,
            'funding_account_id': fundingAccountId,
            'deadline': deadline?.toIso8601String().split('T')[0],
            'color': color,
            'icon': icon,
            'description': description,
            'goal_status': 'active',
          })
          .select()
          .single();
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateGoal(String goalId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('financial_goals')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', goalId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    try {
      await _client.from('financial_goals').delete().eq('id', goalId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── ANALYTICS PIPELINE ───────────────────────────────────────────────────

  Future<Map<String, double>> getSpendingByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) return {};
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? now;
    try {
      final txns = await _client
          .from('financial_transactions')
          .select('category, amount')
          .eq('user_id', userId)
          .eq('transaction_type', 'expense')
          .eq('is_archived', false)
          .neq('status', 'cancelled')
          .gte('transaction_date', start.toIso8601String().split('T')[0])
          .lte('transaction_date', end.toIso8601String().split('T')[0]);

      final map = <String, double>{};
      for (final t in txns) {
        final cat = t['category'] as String? ?? 'other';
        map[cat] = (map[cat] ?? 0) + (t['amount'] as num).toDouble();
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, double>> getIncomeByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) return {};
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? now;
    try {
      final txns = await _client
          .from('financial_transactions')
          .select('category, amount')
          .eq('user_id', userId)
          .eq('transaction_type', 'income')
          .eq('is_archived', false)
          .neq('status', 'cancelled')
          .gte('transaction_date', start.toIso8601String().split('T')[0])
          .lte('transaction_date', end.toIso8601String().split('T')[0]);

      final map = <String, double>{};
      for (final t in txns) {
        final cat = t['category'] as String? ?? 'other';
        map[cat] = (map[cat] ?? 0) + (t['amount'] as num).toDouble();
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Returns monthly income/expense trends for the last [months] months.
  Future<List<Map<String, dynamic>>> getMonthlyTrends({int months = 6}) async {
    final userId = _userId;
    if (userId == null) return [];
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    try {
      for (int i = months - 1; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(month.year, month.month + 1, 1);
        final start = month.toIso8601String().split('T')[0];
        final end = nextMonth
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0];

        final txns = await _client
            .from('financial_transactions')
            .select('transaction_type, amount')
            .eq('user_id', userId)
            .eq('is_archived', false)
            .neq('status', 'cancelled')
            .gte('transaction_date', start)
            .lte('transaction_date', end);

        double income = 0;
        double expenses = 0;
        for (final t in txns) {
          final type = t['transaction_type'] as String? ?? '';
          final amount = (t['amount'] as num?)?.toDouble() ?? 0;
          if (type == 'income') {
            income += amount;
          } else if (type == 'expense') {
            expenses += amount;
          }
        }
        result.add({
          'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
          'income': income,
          'expenses': expenses,
          'net': income - expenses,
        });
      }
      return result;
    } catch (_) {
      return [];
    }
  }
}
