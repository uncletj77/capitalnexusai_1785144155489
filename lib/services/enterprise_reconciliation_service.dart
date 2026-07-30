import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './finance_service.dart';
import './master_asset_registry_service.dart';

/// Enterprise Data Reconciliation & Registration Engine
/// Auto-inspects, re-links, recalculates, and synchronizes every existing record.
class EnterpriseReconciliationService {
  static EnterpriseReconciliationService? _instance;
  static EnterpriseReconciliationService get instance =>
      _instance ??= EnterpriseReconciliationService._();
  EnterpriseReconciliationService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── FULL RECONCILIATION ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> runFullReconciliation() async {
    final userId = _userId;
    if (userId == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final log = <Map<String, dynamic>>[];
    int totalFixed = 0;
    int totalRegistered = 0;

    // 1. Reconcile account balances
    final accountsFixed = await _reconcileAccountBalances(userId, log);
    totalFixed += accountsFixed;

    // 2. Auto-register all qualifying assets
    final assetsRegistered = await MasterAssetRegistryService.instance
        .autoRegisterAllAssets();
    totalRegistered += assetsRegistered;
    log.add({
      'module': 'master_asset_registry',
      'action': 'auto_registered',
      'count': assetsRegistered,
      'message': 'Auto-registered $assetsRegistered assets from all modules',
    });

    // 3. Reconcile goal progress
    final goalsFixed = await _reconcileGoalProgress(userId, log);
    totalFixed += goalsFixed;

    // 4. Save net worth snapshot
    await FinanceService.instance.saveNetWorthSnapshot();
    log.add({
      'module': 'net_worth',
      'action': 'snapshot_saved',
      'message': 'Net worth snapshot saved with live data',
    });

    // 5. Reconcile financial calendar events
    await _generateCalendarEvents(userId, log);

    // 6. Log reconciliation
    await _logReconciliation(userId, log);

    return {
      'success': true,
      'total_fixed': totalFixed,
      'total_registered': totalRegistered,
      'log': log,
      'completed_at': DateTime.now().toIso8601String(),
      'message':
          'Reconciliation complete. $totalFixed records fixed, $totalRegistered assets registered.',
    };
  }

  Future<int> _reconcileAccountBalances(
    String userId,
    List<Map<String, dynamic>> log,
  ) async {
    int fixed = 0;
    try {
      final accounts = await _client
          .from('financial_accounts')
          .select('id, account_name, balance')
          .eq('user_id', userId)
          .eq('is_active', true);

      for (final account in accounts) {
        final accountId = account['id'] as String;
        try {
          // Calculate balance from transactions
          final txns = await _client
              .from('financial_transactions')
              .select('transaction_type, amount')
              .eq('user_id', userId)
              .eq('account_id', accountId)
              .eq('is_archived', false)
              .neq('status', 'cancelled');

          double calculatedBalance = 0;
          for (final t in txns) {
            final amt = (t['amount'] as num).toDouble();
            if (t['transaction_type'] == 'income') {
              calculatedBalance += amt;
            } else if (t['transaction_type'] == 'expense') {
              calculatedBalance -= amt;
            }
          }

          // Add initial balance
          final accDetails = await _client
              .from('financial_accounts')
              .select('initial_balance')
              .eq('id', accountId)
              .maybeSingle();
          final initialBalance =
              (accDetails?['initial_balance'] as num?)?.toDouble() ?? 0;
          calculatedBalance += initialBalance;

          final storedBalance = (account['balance'] as num?)?.toDouble() ?? 0;
          if ((calculatedBalance - storedBalance).abs() > 0.01) {
            await _client
                .from('financial_accounts')
                .update({'balance': calculatedBalance})
                .eq('id', accountId);
            log.add({
              'module': 'accounts',
              'action': 'balance_reconciled',
              'entity': account['account_name'],
              'old_value': storedBalance,
              'new_value': calculatedBalance,
            });
            fixed++;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return fixed;
  }

  Future<int> _reconcileGoalProgress(
    String userId,
    List<Map<String, dynamic>> log,
  ) async {
    int fixed = 0;
    try {
      final goals = await _client
          .from('financial_goals')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      for (final goal in goals) {
        final goalId = goal['id'] as String;
        try {
          // Sum savings transactions linked to this goal
          final savingsAccounts = await _client
              .from('savings_accounts')
              .select('current_balance')
              .eq('user_id', userId)
              .eq('linked_goal_id', goalId);

          double totalSaved = (savingsAccounts as List).fold(
            0.0,
            (s, a) => s + ((a['current_balance'] as num?)?.toDouble() ?? 0),
          );

          // Also check transactions linked to goal
          final txns = await _client
              .from('financial_transactions')
              .select('amount')
              .eq('user_id', userId)
              .eq('related_goal_id', goalId)
              .eq('transaction_type', 'income');

          totalSaved += (txns as List).fold(
            0.0,
            (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0),
          );

          final storedAmount =
              (goal['current_amount'] as num?)?.toDouble() ?? 0;
          if (totalSaved > storedAmount && totalSaved > 0) {
            await _client
                .from('financial_goals')
                .update({'current_amount': totalSaved})
                .eq('id', goalId);
            log.add({
              'module': 'goals',
              'action': 'progress_reconciled',
              'entity': goal['goal_name'],
              'old_value': storedAmount,
              'new_value': totalSaved,
            });
            fixed++;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return fixed;
  }

  Future<void> _generateCalendarEvents(
    String userId,
    List<Map<String, dynamic>> log,
  ) async {
    try {
      int eventsCreated = 0;

      // Generate events from active loans
      try {
        final loans = await _client
            .from('loans')
            .select('id, loan_name, next_payment_date, monthly_payment')
            .eq('user_id', userId)
            .eq('status', 'active');

        for (final loan in loans) {
          if (loan['next_payment_date'] == null) continue;
          final existing = await _client
              .from('financial_calendar_events')
              .select('id')
              .eq('user_id', userId)
              .eq('related_entity_id', loan['id'] as String)
              .eq('event_type', 'payment_due')
              .maybeSingle();

          if (existing == null) {
            await _client.from('financial_calendar_events').insert({
              'user_id': userId,
              'event_title': 'Loan Payment: ${loan['loan_name'] ?? 'Loan'}',
              'event_type': 'payment_due',
              'event_date': loan['next_payment_date'],
              'amount': loan['monthly_payment'] ?? 0,
              'related_module': 'loans',
              'related_entity_id': loan['id'],
              'color': '#EF4444',
            });
            eventsCreated++;
          }
        }
      } catch (_) {}

      // Generate events from goals with deadlines
      try {
        final goals = await _client
            .from('financial_goals')
            .select('id, goal_name, deadline, target_amount')
            .eq('user_id', userId)
            .eq('is_active', true)
            .not('deadline', 'is', null);

        for (final goal in goals) {
          final existing = await _client
              .from('financial_calendar_events')
              .select('id')
              .eq('user_id', userId)
              .eq('related_entity_id', goal['id'] as String)
              .eq('event_type', 'goal_deadline')
              .maybeSingle();

          if (existing == null) {
            await _client.from('financial_calendar_events').insert({
              'user_id': userId,
              'event_title': 'Goal Deadline: ${goal['goal_name']}',
              'event_type': 'goal_deadline',
              'event_date': goal['deadline'],
              'amount': goal['target_amount'] ?? 0,
              'related_module': 'goals',
              'related_entity_id': goal['id'],
              'color': '#10B981',
            });
            eventsCreated++;
          }
        }
      } catch (_) {}

      if (eventsCreated > 0) {
        log.add({
          'module': 'financial_calendar',
          'action': 'events_generated',
          'count': eventsCreated,
          'message':
              'Generated $eventsCreated calendar events from financial records',
        });
      }
    } catch (_) {}
  }

  Future<void> _logReconciliation(
    String userId,
    List<Map<String, dynamic>> log,
  ) async {
    try {
      final entries = log
          .map(
            (entry) => {
              'user_id': userId,
              'reconciliation_type': 'full_reconciliation',
              'module': entry['module'] ?? 'system',
              'action_taken': entry['action'] ?? 'reconciled',
              'entity_name': entry['entity'] as String?,
              'new_value': entry['new_value'] != null
                  ? {'value': entry['new_value']}
                  : null,
              'old_value': entry['old_value'] != null
                  ? {'value': entry['old_value']}
                  : null,
              'status': 'completed',
            },
          )
          .toList();

      if (entries.isNotEmpty) {
        await _client.from('reconciliation_log').insert(entries);
      }
    } catch (_) {}
  }

  // ─── ACCOUNT TRANSFERS ───────────────────────────────────────────────────

  Future<bool> executeAccountTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
    double fee = 0,
    DateTime? transferDate,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      final date = transferDate ?? DateTime.now();
      final dateStr = date.toIso8601String().split('T')[0];

      // Create debit transaction from source account
      final debitTxn = await FinanceService.instance.createTransaction(
        type: 'expense',
        category: 'transfer',
        amount: amount + fee,
        date: date,
        accountId: fromAccountId,
        description: description ?? 'Account transfer',
        status: 'completed',
      );

      // Create credit transaction to destination account
      final creditTxn = await FinanceService.instance.createTransaction(
        type: 'income',
        category: 'transfer',
        amount: amount,
        date: date,
        accountId: toAccountId,
        description: description ?? 'Account transfer received',
        status: 'completed',
      );

      // Record transfer
      await _client.from('account_transfers').insert({
        'user_id': userId,
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'amount': amount,
        'fee': fee,
        'description': description ?? 'Account transfer',
        'transfer_date': dateStr,
        'status': 'completed',
        'from_transaction_id': debitTxn?['id'],
        'to_transaction_id': creditTxn?['id'],
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAccountTransfers({
    int limit = 50,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('account_transfers')
            .select()
            .eq('user_id', userId)
            .order('transfer_date', ascending: false)
            .limit(limit),
      );
    } catch (_) {
      return [];
    }
  }

  // ─── FINANCIAL CALENDAR ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 2, 0);

      return List<Map<String, dynamic>>.from(
        await _client
            .from('financial_calendar_events')
            .select()
            .eq('user_id', userId)
            .gte('event_date', start.toIso8601String().split('T')[0])
            .lte('event_date', end.toIso8601String().split('T')[0])
            .order('event_date', ascending: true),
      );
    } catch (_) {
      return [];
    }
  }

  Future<bool> createCalendarEvent({
    required String title,
    required String type,
    required DateTime date,
    double? amount,
    String? relatedModule,
    String? relatedEntityId,
    bool isRecurring = false,
    String? notes,
    String color = '#1A5F7A',
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _client.from('financial_calendar_events').insert({
        'user_id': userId,
        'event_title': title,
        'event_type': type,
        'event_date': date.toIso8601String().split('T')[0],
        'amount': amount,
        'related_module': relatedModule,
        'related_entity_id': relatedEntityId,
        'is_recurring': isRecurring,
        'notes': notes,
        'color': color,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
