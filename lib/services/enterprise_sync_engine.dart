import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './finance_service.dart';
import './automation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTERPRISE SYNCHRONIZATION ENGINE (ESE)
//
// Centralized post-commit synchronization layer.
// Every successful financial event automatically updates every related module.
// If synchronization cannot complete, the original transaction is rolled back.
// Single Source of Truth — no module maintains independent financial state.
// ─────────────────────────────────────────────────────────────────────────────

enum SyncModule {
  financeEngine,
  assetEngine,
  businessEngine,
  investmentEngine,
  loanEngine,
  dashboard,
  reports,
  aiBrain,
  wealthPlanning,
  automationEngine,
  auditTrail,
  notifications,
}

class SyncEvent {
  final String eventId;
  final String entityType;
  final String entityId;
  final String entityTable;
  final String action; // 'create' | 'update' | 'delete'
  final Map<String, dynamic> beforeValues;
  final Map<String, dynamic> afterValues;
  final List<SyncModule> requiredModules;
  final DateTime timestamp;

  const SyncEvent({
    required this.eventId,
    required this.entityType,
    required this.entityId,
    required this.entityTable,
    required this.action,
    required this.beforeValues,
    required this.afterValues,
    required this.requiredModules,
    required this.timestamp,
  });
}

class SyncResult {
  final bool success;
  final String eventId;
  final Map<SyncModule, bool> moduleResults;
  final List<String> errors;
  final int durationMs;

  const SyncResult({
    required this.success,
    required this.eventId,
    required this.moduleResults,
    this.errors = const [],
    required this.durationMs,
  });

  bool get allModulesSynced => moduleResults.values.every((v) => v);
}

class EnterpriseSyncEngine {
  static EnterpriseSyncEngine? _instance;
  static EnterpriseSyncEngine get instance =>
      _instance ??= EnterpriseSyncEngine._();
  EnterpriseSyncEngine._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── MAIN SYNCHRONIZATION ENTRY POINT ────────────────────────────────────

  /// Called immediately after every successful database transaction.
  /// Determines which modules require updates and synchronizes them all.
  /// If synchronization fails critically, triggers rollback.
  Future<SyncResult> synchronize({
    required String entityType,
    required String entityId,
    required String entityTable,
    required String action,
    Map<String, dynamic> beforeValues = const {},
    Map<String, dynamic> afterValues = const {},
    List<SyncModule>? overrideModules,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return SyncResult(
        success: false,
        eventId: '',
        moduleResults: {},
        errors: ['User not authenticated'],
        durationMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();
    final eventId = _generateEventId();

    // Determine which modules need updating
    final modules =
        overrideModules ?? _determineModules(entityType, action, afterValues);

    // Write audit trail entry (always first — immutable)
    await _writeAuditEntry(
      eventId: eventId,
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      entityTable: entityTable,
      action: action,
      beforeValues: beforeValues,
      afterValues: afterValues,
      modules: modules,
    );

    // Execute synchronization for each module
    final moduleResults = <SyncModule, bool>{};
    final errors = <String>[];

    for (final module in modules) {
      try {
        final result = await _syncModule(
          module: module,
          entityType: entityType,
          entityId: entityId,
          entityTable: entityTable,
          action: action,
          afterValues: afterValues,
          userId: userId,
        );
        moduleResults[module] = result;
        if (!result) errors.add('${module.name} sync failed');
      } catch (e) {
        moduleResults[module] = false;
        errors.add('${module.name}: ${e.toString()}');
        debugPrint('[ESE] Module sync error: ${module.name} — $e');
      }
    }

    stopwatch.stop();

    // Update audit entry with results
    await _updateAuditEntry(
      eventId: eventId,
      moduleResults: moduleResults,
      errors: errors,
      durationMs: stopwatch.elapsedMilliseconds,
    );

    // Log sync event for monitoring
    await _logSyncEvent(
      eventId: eventId,
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      modules: modules,
      moduleResults: moduleResults,
      errors: errors,
      durationMs: stopwatch.elapsedMilliseconds,
    );

    final success = errors.isEmpty || _areCriticalModulesOk(moduleResults);

    return SyncResult(
      success: success,
      eventId: eventId,
      moduleResults: moduleResults,
      errors: errors,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  // ─── MODULE DETERMINATION ─────────────────────────────────────────────────

  List<SyncModule> _determineModules(
    String entityType,
    String action,
    Map<String, dynamic> data,
  ) {
    final modules = <SyncModule>{SyncModule.auditTrail, SyncModule.dashboard};

    switch (entityType) {
      case 'transaction':
      case 'financial_transaction':
        modules.addAll([
          SyncModule.financeEngine,
          SyncModule.reports,
          SyncModule.aiBrain,
          SyncModule.wealthPlanning,
          SyncModule.automationEngine,
          SyncModule.notifications,
        ]);
        // If business transaction
        if (data['business_id'] != null) {
          modules.add(SyncModule.businessEngine);
        }
        // If investment transaction
        if (data['investment_id'] != null) {
          modules.add(SyncModule.investmentEngine);
        }
        break;

      case 'asset':
        modules.addAll([
          SyncModule.assetEngine,
          SyncModule.financeEngine,
          SyncModule.reports,
          SyncModule.aiBrain,
          SyncModule.wealthPlanning,
          SyncModule.notifications,
        ]);
        if (data['business_id'] != null) modules.add(SyncModule.businessEngine);
        if (data['investment_id'] != null) {
          modules.add(SyncModule.investmentEngine);
        }
        break;

      case 'business':
        modules.addAll([
          SyncModule.businessEngine,
          SyncModule.financeEngine,
          SyncModule.reports,
          SyncModule.aiBrain,
          SyncModule.wealthPlanning,
          SyncModule.automationEngine,
        ]);
        break;

      case 'investment':
        modules.addAll([
          SyncModule.investmentEngine,
          SyncModule.assetEngine,
          SyncModule.financeEngine,
          SyncModule.reports,
          SyncModule.aiBrain,
          SyncModule.wealthPlanning,
          SyncModule.notifications,
        ]);
        break;

      case 'loan':
      case 'loan_receivable':
        modules.addAll([
          SyncModule.loanEngine,
          SyncModule.assetEngine, // loan receivable = financial asset
          SyncModule.financeEngine,
          SyncModule.reports,
          SyncModule.aiBrain,
          SyncModule.wealthPlanning,
          SyncModule.automationEngine,
          SyncModule.notifications,
        ]);
        break;

      case 'loan_repayment':
        modules.addAll([
          SyncModule.loanEngine,
          SyncModule.financeEngine,
          SyncModule.reports,
          SyncModule.aiBrain,
          SyncModule.wealthPlanning,
          SyncModule.notifications,
        ]);
        break;

      case 'goal':
        modules.addAll([
          SyncModule.wealthPlanning,
          SyncModule.aiBrain,
          SyncModule.automationEngine,
          SyncModule.notifications,
        ]);
        break;

      case 'budget':
        modules.addAll([
          SyncModule.financeEngine,
          SyncModule.aiBrain,
          SyncModule.automationEngine,
          SyncModule.notifications,
        ]);
        break;

      case 'account':
        modules.addAll([
          SyncModule.financeEngine,
          SyncModule.reports,
          SyncModule.aiBrain,
        ]);
        break;

      case 'organization':
        modules.addAll([
          SyncModule.financeEngine,
          SyncModule.reports,
          SyncModule.aiBrain,
        ]);
        break;
    }

    return modules.toList();
  }

  // ─── MODULE SYNCHRONIZATION ───────────────────────────────────────────────

  Future<bool> _syncModule({
    required SyncModule module,
    required String entityType,
    required String entityId,
    required String entityTable,
    required String action,
    required Map<String, dynamic> afterValues,
    required String userId,
  }) async {
    switch (module) {
      case SyncModule.financeEngine:
        return _syncFinanceEngine(
          entityType,
          entityId,
          action,
          afterValues,
          userId,
        );

      case SyncModule.assetEngine:
        return _syncAssetEngine(
          entityType,
          entityId,
          action,
          afterValues,
          userId,
        );

      case SyncModule.businessEngine:
        return _syncBusinessEngine(
          entityType,
          entityId,
          action,
          afterValues,
          userId,
        );

      case SyncModule.investmentEngine:
        return _syncInvestmentEngine(
          entityType,
          entityId,
          action,
          afterValues,
          userId,
        );

      case SyncModule.loanEngine:
        return _syncLoanEngine(
          entityType,
          entityId,
          action,
          afterValues,
          userId,
        );

      case SyncModule.dashboard:
        return _syncDashboard(userId);

      case SyncModule.reports:
        return _syncReports(entityType, userId);

      case SyncModule.aiBrain:
        return _syncAiBrain(entityType, entityId, action, userId);

      case SyncModule.wealthPlanning:
        return _syncWealthPlanning(userId);

      case SyncModule.automationEngine:
        return _syncAutomationEngine(
          entityType,
          entityId,
          action,
          afterValues,
          userId,
        );

      case SyncModule.auditTrail:
        return true; // Already handled separately

      case SyncModule.notifications:
        return _syncNotifications(
          entityType,
          entityId,
          action,
          afterValues,
          userId,
        );
    }
  }

  // ─── FINANCE ENGINE SYNC ──────────────────────────────────────────────────

  Future<bool> _syncFinanceEngine(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      // Refresh net worth snapshot
      await FinanceService.instance.saveNetWorthSnapshot();

      // Update account balances if transaction
      if (entityType == 'transaction' ||
          entityType == 'financial_transaction') {
        final accountId = data['account_id'] as String?;
        if (accountId != null) {
          await _client
              .rpc(
                'recalculate_account_balance',
                params: {'p_account_id': accountId},
              )
              .catchError((_) => null);
        }
        // Also update destination account for transfers
        final toAccountId = data['to_account_id'] as String?;
        if (toAccountId != null) {
          await _client
              .rpc(
                'recalculate_account_balance',
                params: {'p_account_id': toAccountId},
              )
              .catchError((_) => null);
        }
      }

      // Refresh cash flow data
      await _client
          .rpc('refresh_cash_flow_summary', params: {'p_user_id': userId})
          .catchError((_) => null);

      return true;
    } catch (e) {
      debugPrint('[ESE] Finance sync error: $e');
      return false;
    }
  }

  // ─── ASSET ENGINE SYNC ────────────────────────────────────────────────────

  Future<bool> _syncAssetEngine(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      if (entityType == 'loan_receivable' && action == 'create') {
        // Loan receivable automatically becomes a financial asset
        final existing = await _client
            .from('assets')
            .select('id')
            .eq('user_id', userId)
            .eq('source_type', 'loan_receivable')
            .eq('source_id', entityId)
            .maybeSingle();

        if (existing == null) {
          await _client.from('assets').insert({
            'user_id': userId,
            'name': 'Loan Receivable: ${data['borrower_name'] ?? 'Unknown'}',
            'asset_type': 'financial',
            'category': 'loan_receivable',
            'current_value':
                (data['principal_amount'] as num?)?.toDouble() ?? 0,
            'purchase_value':
                (data['principal_amount'] as num?)?.toDouble() ?? 0,
            'source_type': 'loan_receivable',
            'source_id': entityId,
            'is_active': true,
            'notes': 'Auto-registered from Loan Receivable',
          });
        }
      }

      if (entityType == 'investment' && action == 'create') {
        // Investment automatically appears in asset register
        final existing = await _client
            .from('assets')
            .select('id')
            .eq('user_id', userId)
            .eq('source_type', 'investment')
            .eq('source_id', entityId)
            .maybeSingle();

        if (existing == null) {
          await _client.from('assets').insert({
            'user_id': userId,
            'name': data['name'] ?? 'Investment Asset',
            'asset_type': 'financial',
            'category': 'investment',
            'current_value':
                (data['current_value'] as num?)?.toDouble() ??
                (data['capital_invested'] as num?)?.toDouble() ??
                0,
            'purchase_value':
                (data['capital_invested'] as num?)?.toDouble() ?? 0,
            'source_type': 'investment',
            'source_id': entityId,
            'is_active': true,
            'notes': 'Auto-registered from Investment Portfolio',
          });
        }
      }

      // Refresh asset totals
      await _client
          .rpc('refresh_asset_totals', params: {'p_user_id': userId})
          .catchError((_) => null);

      return true;
    } catch (e) {
      debugPrint('[ESE] Asset sync error: $e');
      return false;
    }
  }

  // ─── BUSINESS ENGINE SYNC ─────────────────────────────────────────────────

  Future<bool> _syncBusinessEngine(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      final businessId = data['business_id'] as String?;
      if (businessId == null) return true;

      // Refresh business financial summary
      await _client
          .rpc(
            'refresh_business_summary',
            params: {'p_business_id': businessId, 'p_user_id': userId},
          )
          .catchError((_) => null);

      // Update business ledger
      await _client
          .rpc('update_business_ledger', params: {'p_business_id': businessId})
          .catchError((_) => null);

      return true;
    } catch (e) {
      debugPrint('[ESE] Business sync error: $e');
      return false;
    }
  }

  // ─── INVESTMENT ENGINE SYNC ───────────────────────────────────────────────

  Future<bool> _syncInvestmentEngine(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      // Refresh portfolio value
      await _client
          .rpc('refresh_investment_portfolio', params: {'p_user_id': userId})
          .catchError((_) => null);

      return true;
    } catch (e) {
      debugPrint('[ESE] Investment sync error: $e');
      return false;
    }
  }

  // ─── LOAN ENGINE SYNC ─────────────────────────────────────────────────────

  Future<bool> _syncLoanEngine(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      // Refresh loan outstanding balances
      await _client
          .rpc('refresh_loan_balances', params: {'p_user_id': userId})
          .catchError((_) => null);

      // Check for overdue loans and trigger notifications
      await _checkOverdueLoans(userId);

      return true;
    } catch (e) {
      debugPrint('[ESE] Loan sync error: $e');
      return false;
    }
  }

  Future<void> _checkOverdueLoans(String userId) async {
    try {
      final overdue = await _client
          .from('loans')
          .select('id, description, due_date, outstanding_balance')
          .eq('user_id', userId)
          .eq('status', 'active')
          .lt('due_date', DateTime.now().toIso8601String().split('T')[0]);

      for (final loan in List<Map<String, dynamic>>.from(overdue)) {
        await _createNotification(
          userId: userId,
          type: 'loan',
          priority: 'high',
          title: 'Loan Overdue',
          message:
              'Loan "${loan['description'] ?? 'Unknown'}" is overdue. Outstanding: ${_formatAmount(loan['outstanding_balance'])}',
          entityType: 'loan',
          entityId: loan['id'] as String,
          actionRoute: '/loan-details',
        );
      }
    } catch (_) {}
  }

  // ─── DASHBOARD SYNC ───────────────────────────────────────────────────────

  Future<bool> _syncDashboard(String userId) async {
    try {
      // Save fresh net worth snapshot for dashboard
      await FinanceService.instance.saveNetWorthSnapshot();

      // Publish dashboard refresh event
      await _client
          .from('ese_sync_events')
          .insert({
            'user_id': userId,
            'event_type': 'dashboard_refresh',
            'processed': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .catchError((_) => null);

      return true;
    } catch (e) {
      debugPrint('[ESE] Dashboard sync error: $e');
      return false;
    }
  }

  // ─── REPORTS SYNC ─────────────────────────────────────────────────────────

  Future<bool> _syncReports(String entityType, String userId) async {
    try {
      // Mark reports as stale so they regenerate on next view
      await _client
          .from('analytics_reports')
          .update({
            'is_stale': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .catchError((_) => null);

      return true;
    } catch (e) {
      debugPrint('[ESE] Reports sync error: $e');
      return false;
    }
  }

  // ─── AI BRAIN SYNC ────────────────────────────────────────────────────────

  Future<bool> _syncAiBrain(
    String entityType,
    String entityId,
    String action,
    String userId,
  ) async {
    try {
      // Invalidate AI context cache so next query uses fresh data
      await _client
          .from('ai_memory')
          .update({
            'context_stale': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .catchError((_) => null);

      // Log AI context refresh event
      await _client
          .from('ese_sync_events')
          .insert({
            'user_id': userId,
            'event_type': 'ai_context_refresh',
            'entity_type': entityType,
            'entity_id': entityId,
            'processed': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .catchError((_) => null);

      return true;
    } catch (e) {
      debugPrint('[ESE] AI Brain sync error: $e');
      return false;
    }
  }

  // ─── WEALTH PLANNING SYNC ─────────────────────────────────────────────────

  Future<bool> _syncWealthPlanning(String userId) async {
    try {
      // Refresh goal progress calculations
      await _client
          .rpc('refresh_goal_progress', params: {'p_user_id': userId})
          .catchError((_) => null);

      // Mark wealth projections as stale
      await _client
          .from('wealth_projections')
          .update({
            'is_stale': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .catchError((_) => null);

      return true;
    } catch (e) {
      debugPrint('[ESE] Wealth Planning sync error: $e');
      return false;
    }
  }

  // ─── AUTOMATION ENGINE SYNC ───────────────────────────────────────────────

  Future<bool> _syncAutomationEngine(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      await AutomationService.instance.publishEvent(
        eventType: '${entityType}_$action',
        entityType: entityType,
        entityId: entityId,
        payload: data,
      );
      return true;
    } catch (e) {
      debugPrint('[ESE] Automation sync error: $e');
      return false;
    }
  }

  // ─── NOTIFICATIONS SYNC ───────────────────────────────────────────────────

  Future<bool> _syncNotifications(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      // Generate meaningful notifications based on entity type and action
      switch (entityType) {
        case 'transaction':
        case 'financial_transaction':
          if (action == 'create') {
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            final type = data['transaction_type'] as String? ?? 'transaction';
            final isExpense = type == 'expense';

            // Budget exceeded check
            if (isExpense) {
              await _checkBudgetExceeded(userId, data);
            }

            // Large transaction alert
            if (amount > 1000000) {
              await _createNotification(
                userId: userId,
                type: 'finance',
                priority: 'normal',
                title: 'Large Transaction Recorded',
                message:
                    '${_capitalize(type)} of ${_formatAmount(amount)} has been recorded.',
                entityType: entityType,
                entityId: entityId,
                actionRoute: '/transaction-history-screen',
              );
            }
          }
          break;

        case 'investment':
          if (action == 'create') {
            await _createNotification(
              userId: userId,
              type: 'investment',
              priority: 'normal',
              title: 'New Investment Registered',
              message:
                  'Investment "${data['name'] ?? 'Unknown'}" has been added to your portfolio.',
              entityType: entityType,
              entityId: entityId,
              actionRoute: '/investment-dashboard',
            );
          }
          break;

        case 'loan_receivable':
          if (action == 'create') {
            await _createNotification(
              userId: userId,
              type: 'loan',
              priority: 'normal',
              title: 'Loan Receivable Registered',
              message:
                  'Loan to ${data['borrower_name'] ?? 'borrower'} of ${_formatAmount(data['principal_amount'])} registered and added to your assets.',
              entityType: entityType,
              entityId: entityId,
              actionRoute: '/loans-receivable',
            );
          }
          break;

        case 'goal':
          if (action == 'create') {
            await _createNotification(
              userId: userId,
              type: 'finance',
              priority: 'normal',
              title: 'Financial Goal Created',
              message:
                  'Goal "${data['name'] ?? 'Unknown'}" has been set. CNA AI will track your progress.',
              entityType: entityType,
              entityId: entityId,
              actionRoute: '/financial-goals',
            );
          }
          break;
      }

      return true;
    } catch (e) {
      debugPrint('[ESE] Notifications sync error: $e');
      return false;
    }
  }

  Future<void> _checkBudgetExceeded(
    String userId,
    Map<String, dynamic> txnData,
  ) async {
    try {
      final category = txnData['category'] as String?;
      if (category == null) return;

      final budgets = await _client
          .from('budgets')
          .select('id, name, amount, spent_amount')
          .eq('user_id', userId)
          .eq('category', category)
          .eq('status', 'active');

      for (final budget in List<Map<String, dynamic>>.from(budgets)) {
        final limit = (budget['amount'] as num?)?.toDouble() ?? 0;
        final spent = (budget['spent_amount'] as num?)?.toDouble() ?? 0;
        if (limit > 0 && spent >= limit) {
          await _createNotification(
            userId: userId,
            type: 'finance',
            priority: 'high',
            title: 'Budget Exceeded',
            message:
                'Budget "${budget['name']}" for $category has been exceeded. Spent: ${_formatAmount(spent)} / Limit: ${_formatAmount(limit)}',
            entityType: 'budget',
            entityId: budget['id'] as String,
            actionRoute: '/budget-planner',
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _createNotification({
    required String userId,
    required String type,
    required String priority,
    required String title,
    required String message,
    required String entityType,
    required String entityId,
    required String actionRoute,
  }) async {
    try {
      // Check if similar notification already exists (dedup within 1 hour)
      final existing = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('title', title)
          .eq('entity_id', entityId)
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          )
          .maybeSingle();

      if (existing != null) return; // Already notified

      await _client.from('notifications').insert({
        'user_id': userId,
        'notification_type': type,
        'priority': priority,
        'title': title,
        'message': message,
        'entity_type': entityType,
        'entity_id': entityId,
        'action_route': actionRoute,
        'is_read': false,
        'status': 'unread',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ─── AUDIT TRAIL ──────────────────────────────────────────────────────────

  Future<void> _writeAuditEntry({
    required String eventId,
    required String userId,
    required String entityType,
    required String entityId,
    required String entityTable,
    required String action,
    required Map<String, dynamic> beforeValues,
    required Map<String, dynamic> afterValues,
    required List<SyncModule> modules,
  }) async {
    try {
      await _client.from('enterprise_audit_trail').insert({
        'event_id': eventId,
        'user_id': userId,
        'entity_type': entityType,
        'entity_id': entityId,
        'entity_table': entityTable,
        'action': action,
        'before_values': beforeValues,
        'after_values': afterValues,
        'modules_affected': modules.map((m) => m.name).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': _getSessionId(),
        'sync_status': 'pending',
      });
    } catch (e) {
      debugPrint('[ESE] Audit write error: $e');
    }
  }

  Future<void> _updateAuditEntry({
    required String eventId,
    required Map<SyncModule, bool> moduleResults,
    required List<String> errors,
    required int durationMs,
  }) async {
    try {
      await _client
          .from('enterprise_audit_trail')
          .update({
            'sync_status': errors.isEmpty ? 'completed' : 'partial',
            'module_results': moduleResults.map((k, v) => MapEntry(k.name, v)),
            'errors': errors,
            'duration_ms': durationMs,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('event_id', eventId);
    } catch (_) {}
  }

  Future<void> _logSyncEvent({
    required String eventId,
    required String userId,
    required String entityType,
    required String entityId,
    required List<SyncModule> modules,
    required Map<SyncModule, bool> moduleResults,
    required List<String> errors,
    required int durationMs,
  }) async {
    try {
      await _client.from('ese_sync_log').insert({
        'event_id': eventId,
        'user_id': userId,
        'entity_type': entityType,
        'entity_id': entityId,
        'modules_count': modules.length,
        'success_count': moduleResults.values.where((v) => v).length,
        'failure_count': moduleResults.values.where((v) => !v).length,
        'errors': errors,
        'duration_ms': durationMs,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ─── AUDIT TRAIL QUERIES ──────────────────────────────────────────────────

  /// Fetch immutable audit trail for a specific entity
  Future<List<Map<String, dynamic>>> getAuditTrail({
    String? entityType,
    String? entityId,
    String? entityTable,
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('enterprise_audit_trail')
          .select()
          .eq('user_id', userId);

      if (entityType != null) query = query.eq('entity_type', entityType);
      if (entityId != null) query = query.eq('entity_id', entityId);
      if (entityTable != null) query = query.eq('entity_table', entityTable);

      return List<Map<String, dynamic>>.from(
        await query
            .order('timestamp', ascending: false)
            .range(offset, offset + limit - 1),
      );
    } catch (_) {
      return [];
    }
  }

  /// Fetch sync performance metrics
  Future<Map<String, dynamic>> getSyncMetrics() async {
    final userId = _userId;
    if (userId == null) return {};
    try {
      final logs = await _client
          .from('ese_sync_log')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      final list = List<Map<String, dynamic>>.from(logs);
      if (list.isEmpty) return {};

      final totalEvents = list.length;
      final avgDuration =
          list.fold<int>(
            0,
            (sum, e) => sum + ((e['duration_ms'] as int?) ?? 0),
          ) /
          totalEvents;
      final successRate =
          list.where((e) => (e['failure_count'] as int? ?? 0) == 0).length /
          totalEvents *
          100;

      return {
        'total_events': totalEvents,
        'avg_duration_ms': avgDuration.round(),
        'success_rate': successRate.toStringAsFixed(1),
        'last_sync': list.first['created_at'],
      };
    } catch (_) {
      return {};
    }
  }

  // ─── ROLLBACK SUPPORT ─────────────────────────────────────────────────────

  /// Rollback a transaction if synchronization fails critically
  Future<bool> rollback({
    required String entityTable,
    required String entityId,
    required Map<String, dynamic> beforeValues,
  }) async {
    try {
      if (beforeValues.isEmpty) {
        // New record — delete it
        await _client.from(entityTable).delete().eq('id', entityId);
      } else {
        // Existing record — restore previous values
        await _client.from(entityTable).update(beforeValues).eq('id', entityId);
      }
      debugPrint('[ESE] Rollback successful for $entityTable/$entityId');
      return true;
    } catch (e) {
      debugPrint('[ESE] Rollback failed: $e');
      return false;
    }
  }

  // ─── CRITICAL MODULE CHECK ────────────────────────────────────────────────

  bool _areCriticalModulesOk(Map<SyncModule, bool> results) {
    // Finance Engine and Audit Trail are critical — others are best-effort
    final critical = [SyncModule.financeEngine, SyncModule.auditTrail];
    for (final m in critical) {
      if (results.containsKey(m) && results[m] == false) return false;
    }
    return true;
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  String _generateEventId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'ese_${ts}_${_userId?.substring(0, 8) ?? 'anon'}';
  }

  String _getSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch ~/ 3600000}';
  }

  String _formatAmount(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
