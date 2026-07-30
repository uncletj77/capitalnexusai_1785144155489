import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './finance_service.dart';

/// Enterprise Savings Centre Service
/// Manages savings accounts, goal integration, health scoring, and auto-progression.
class SavingsCentreService {
  static SavingsCentreService? _instance;
  static SavingsCentreService get instance =>
      _instance ??= SavingsCentreService._();
  SavingsCentreService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── SAVINGS ACCOUNTS ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSavingsAccounts() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('savings_accounts')
            .select()
            .eq('user_id', userId)
            .eq('is_active', true)
            .order('created_at', ascending: false),
      );
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createSavingsAccount({
    required String name,
    required String type,
    String? linkedAccountId,
    String? linkedGoalId,
    double targetAmount = 0,
    double currentBalance = 0,
    double monthlyContribution = 0,
    double interestRate = 0,
    DateTime? targetDate,
    bool autoTransfer = false,
    int autoTransferDay = 1,
    String color = '#1A5F7A',
    String icon = 'savings',
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final res = await _client
          .from('savings_accounts')
          .insert({
            'user_id': userId,
            'account_name': name,
            'savings_type': type,
            'linked_account_id': linkedAccountId,
            'linked_goal_id': linkedGoalId,
            'target_amount': targetAmount,
            'current_balance': currentBalance,
            'monthly_contribution': monthlyContribution,
            'interest_rate': interestRate,
            'target_date': targetDate?.toIso8601String().split('T')[0],
            'auto_transfer': autoTransfer,
            'auto_transfer_day': autoTransferDay,
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

  Future<bool> updateSavingsAccount(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('savings_accounts')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSavingsAccount(String id) async {
    try {
      await _client
          .from('savings_accounts')
          .update({'is_active': false})
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── SAVINGS TRANSACTIONS ────────────────────────────────────────────────

  Future<bool> recordSavingsDeposit({
    required String savingsAccountId,
    required double amount,
    String? sourceAccountId,
    String? description,
    DateTime? date,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      // Record savings transaction
      await _client.from('savings_transactions').insert({
        'user_id': userId,
        'savings_account_id': savingsAccountId,
        'transaction_type': 'deposit',
        'amount': amount,
        'description': description ?? 'Savings deposit',
        'source_account_id': sourceAccountId,
        'transaction_date': (date ?? DateTime.now()).toIso8601String().split(
          'T',
        )[0],
      });

      // Update savings balance
      final account = await _client
          .from('savings_accounts')
          .select('current_balance')
          .eq('id', savingsAccountId)
          .single();
      final newBalance =
          ((account['current_balance'] as num?)?.toDouble() ?? 0) + amount;
      await _client
          .from('savings_accounts')
          .update({
            'current_balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', savingsAccountId);

      // If source account provided, create debit transaction
      if (sourceAccountId != null) {
        await FinanceService.instance.createTransaction(
          type: 'expense',
          category: 'savings',
          amount: amount,
          date: date ?? DateTime.now(),
          accountId: sourceAccountId,
          description: description ?? 'Transfer to savings',
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordSavingsWithdrawal({
    required String savingsAccountId,
    required double amount,
    String? destinationAccountId,
    String? description,
    DateTime? date,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      final account = await _client
          .from('savings_accounts')
          .select('current_balance, is_locked, lock_until')
          .eq('id', savingsAccountId)
          .single();

      final isLocked = account['is_locked'] as bool? ?? false;
      if (isLocked) {
        final lockUntil = account['lock_until'] as String?;
        if (lockUntil != null) {
          final lockDate = DateTime.parse(lockUntil);
          if (DateTime.now().isBefore(lockDate)) return false;
        }
      }

      final currentBalance =
          (account['current_balance'] as num?)?.toDouble() ?? 0;
      if (amount > currentBalance) return false;

      await _client.from('savings_transactions').insert({
        'user_id': userId,
        'savings_account_id': savingsAccountId,
        'transaction_type': 'withdrawal',
        'amount': amount,
        'description': description ?? 'Savings withdrawal',
        'source_account_id': destinationAccountId,
        'transaction_date': (date ?? DateTime.now()).toIso8601String().split(
          'T',
        )[0],
      });

      await _client
          .from('savings_accounts')
          .update({
            'current_balance': currentBalance - amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', savingsAccountId);

      if (destinationAccountId != null) {
        await FinanceService.instance.createTransaction(
          type: 'income',
          category: 'savings',
          amount: amount,
          date: date ?? DateTime.now(),
          accountId: destinationAccountId,
          description: description ?? 'Withdrawal from savings',
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSavingsTransactions(
    String savingsAccountId, {
    int limit = 50,
  }) async {
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('savings_transactions')
            .select()
            .eq('savings_account_id', savingsAccountId)
            .order('transaction_date', ascending: false)
            .limit(limit),
      );
    } catch (_) {
      return [];
    }
  }

  // ─── SAVINGS HEALTH SCORE ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSavingsHealthScore() async {
    final userId = _userId;
    if (userId == null) {
      return {'score': 0, 'label': 'No Data', 'indicators': []};
    }
    try {
      final accounts = await getSavingsAccounts();
      final cf = await FinanceService.instance.getCashFlowSummary();
      final income = cf['income'] ?? 0;
      final expenses = cf['expenses'] ?? 0;

      double totalSavings = accounts.fold(
        0.0,
        (s, a) => s + ((a['current_balance'] as num?)?.toDouble() ?? 0),
      );
      double totalTarget = accounts.fold(
        0.0,
        (s, a) => s + ((a['target_amount'] as num?)?.toDouble() ?? 0),
      );
      double monthlyContributions = accounts.fold(
        0.0,
        (s, a) => s + ((a['monthly_contribution'] as num?)?.toDouble() ?? 0),
      );

      int score = 40;
      final indicators = <Map<String, dynamic>>[];

      // Savings rate
      final savingsRate = income > 0 ? (monthlyContributions / income) : 0.0;
      if (savingsRate >= 0.2) {
        score += 25;
        indicators.add({
          'label': 'Savings Rate',
          'value': '${(savingsRate * 100).toStringAsFixed(1)}%',
          'status': 'excellent',
          'description':
              'Saving ${(savingsRate * 100).toStringAsFixed(0)}% of income',
        });
      } else if (savingsRate >= 0.1) {
        score += 15;
        indicators.add({
          'label': 'Savings Rate',
          'value': '${(savingsRate * 100).toStringAsFixed(1)}%',
          'status': 'good',
          'description':
              'Saving ${(savingsRate * 100).toStringAsFixed(0)}% of income',
        });
      } else {
        indicators.add({
          'label': 'Savings Rate',
          'value': '${(savingsRate * 100).toStringAsFixed(1)}%',
          'status': 'poor',
          'description': 'Target: save at least 10% of income',
        });
      }

      // Emergency fund
      final hasEmergency = accounts.any(
        (a) => a['savings_type'] == 'emergency',
      );
      if (hasEmergency) {
        score += 15;
        indicators.add({
          'label': 'Emergency Fund',
          'value': 'Active',
          'status': 'excellent',
          'description': 'Emergency savings account exists',
        });
      } else {
        indicators.add({
          'label': 'Emergency Fund',
          'value': 'Missing',
          'status': 'poor',
          'description': 'Create an emergency savings account',
        });
      }

      // Goal progress
      if (totalTarget > 0) {
        final progress = totalSavings / totalTarget;
        if (progress >= 0.5) {
          score += 10;
          indicators.add({
            'label': 'Goal Progress',
            'value': '${(progress * 100).toStringAsFixed(0)}%',
            'status': 'good',
            'description': 'Halfway to savings targets',
          });
        } else {
          indicators.add({
            'label': 'Goal Progress',
            'value': '${(progress * 100).toStringAsFixed(0)}%',
            'status': 'fair',
            'description': 'Continue building toward targets',
          });
        }
      }

      // Available to save
      final availableToSave = income - expenses;
      indicators.add({
        'label': 'Available to Save',
        'value': _formatAmount(availableToSave),
        'status': availableToSave > 0 ? 'good' : 'poor',
        'description': availableToSave > 0
            ? 'Positive cash flow available'
            : 'Expenses exceed income',
      });

      final label = score >= 75
          ? 'Excellent'
          : score >= 60
          ? 'Good'
          : score >= 40
          ? 'Fair'
          : 'Needs Attention';

      return {
        'score': score.clamp(0, 100),
        'label': label,
        'total_savings': totalSavings,
        'total_target': totalTarget,
        'monthly_contributions': monthlyContributions,
        'savings_rate': savingsRate,
        'available_to_save': availableToSave,
        'account_count': accounts.length,
        'indicators': indicators,
      };
    } catch (_) {
      return {'score': 0, 'label': 'No Data', 'indicators': []};
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }
}
