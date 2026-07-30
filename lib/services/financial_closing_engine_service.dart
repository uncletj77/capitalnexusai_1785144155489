import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './finance_service.dart';

/// Financial Closing Engine Service
/// Generates executive daily/weekly/monthly/quarterly/yearly financial reviews.
class FinancialClosingEngineService {
  static FinancialClosingEngineService? _instance;
  static FinancialClosingEngineService get instance =>
      _instance ??= FinancialClosingEngineService._();
  FinancialClosingEngineService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── GENERATE CLOSING REPORT ─────────────────────────────────────────────

  Future<Map<String, dynamic>> generateClosingReport({
    required String periodType,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final userId = _userId;
    if (userId == null) return {};

    final now = DateTime.now();
    DateTime periodStart;
    DateTime periodEnd;
    String periodLabel;

    switch (periodType) {
      case 'daily':
        periodStart = DateTime(now.year, now.month, now.day);
        periodEnd = now;
        periodLabel = 'Daily Review — ${_formatDate(now)}';
        break;
      case 'weekly':
        final weekday = now.weekday;
        periodStart = now.subtract(Duration(days: weekday - 1));
        periodStart = DateTime(
          periodStart.year,
          periodStart.month,
          periodStart.day,
        );
        periodEnd = now;
        periodLabel = 'Weekly Review — Week of ${_formatDate(periodStart)}';
        break;
      case 'monthly':
        periodStart = DateTime(now.year, now.month, 1);
        periodEnd = now;
        periodLabel = 'Monthly Review — ${_monthName(now.month)} ${now.year}';
        break;
      case 'quarterly':
        final quarter = ((now.month - 1) ~/ 3);
        periodStart = DateTime(now.year, quarter * 3 + 1, 1);
        periodEnd = now;
        periodLabel = 'Q${quarter + 1} ${now.year} Review';
        break;
      case 'yearly':
        periodStart = DateTime(now.year, 1, 1);
        periodEnd = now;
        periodLabel = 'Annual Review ${now.year}';
        break;
      default:
        periodStart = customStart ?? DateTime(now.year, now.month, 1);
        periodEnd = customEnd ?? now;
        periodLabel = 'Custom Period Review';
    }

    // Fetch all data in parallel
    final results = await Future.wait([
      FinanceService.instance.getCashFlowSummary(
        startDate: periodStart,
        endDate: periodEnd,
      ),
      FinanceService.instance.getNetWorth(),
      _getBusinessSummary(userId, periodStart, periodEnd),
      _getInvestmentSummary(userId),
      _getLoanSummary(userId, periodStart, periodEnd),
      FinanceService.instance.getFinancialGoals(),
      FinanceService.instance.getAccountsWithBalances(),
    ]);

    final cf = results[0] as Map<String, double>;
    final nw = results[1] as Map<String, double>;
    final bizSummary = results[2] as Map<String, dynamic>;
    final invSummary = results[3] as Map<String, dynamic>;
    final loanSummary = results[4] as Map<String, dynamic>;
    final goals = results[5] as List<Map<String, dynamic>>;
    final accounts = results[6] as List<Map<String, dynamic>>;

    final income = cf['income'] ?? 0;
    final expenses = cf['expenses'] ?? 0;
    final netCashFlow = income - expenses;
    final totalCash = accounts.fold(
      0.0,
      (s, a) => s + ((a['calculated_balance'] as num?)?.toDouble() ?? 0),
    );

    // Prior period comparison
    final priorStart = periodStart.subtract(
      Duration(days: periodEnd.difference(periodStart).inDays + 1),
    );
    final priorCf = await FinanceService.instance.getCashFlowSummary(
      startDate: priorStart,
      endDate: periodStart.subtract(const Duration(days: 1)),
    );
    final priorIncome = priorCf['income'] ?? 0;
    final priorExpenses = priorCf['expenses'] ?? 0;

    // Health score
    final healthScore = _computeHealthScore(income, expenses, nw);

    // Goals progress
    final goalsProgress = goals.map((g) {
      final target = (g['target_amount'] as num?)?.toDouble() ?? 0;
      final current = (g['current_amount'] as num?)?.toDouble() ?? 0;
      final progress = target > 0 ? (current / target * 100) : 0.0;
      return {
        'name': g['goal_name'],
        'progress': progress,
        'current': current,
        'target': target,
        'status': progress >= 100
            ? 'completed'
            : progress >= 50
            ? 'on_track'
            : 'behind',
      };
    }).toList();

    final goalsCompleted = goalsProgress
        .where((g) => g['status'] == 'completed')
        .length;

    // Income breakdown
    final incomeBreakdown = await _getIncomeBreakdown(
      userId,
      periodStart,
      periodEnd,
    );
    final expenseBreakdown = await _getExpenseBreakdown(
      userId,
      periodStart,
      periodEnd,
    );

    // Build report
    final report = {
      'user_id': userId,
      'period_type': periodType,
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      'period_label': periodLabel,
      'total_income': income,
      'income_breakdown': incomeBreakdown,
      'income_vs_prior': priorIncome > 0
          ? ((income - priorIncome) / priorIncome)
          : 0.0,
      'total_expenses': expenses,
      'expense_breakdown': expenseBreakdown,
      'expense_vs_prior': priorExpenses > 0
          ? ((expenses - priorExpenses) / priorExpenses)
          : 0.0,
      'net_cash_flow': netCashFlow,
      'closing_cash': totalCash,
      'closing_net_worth': nw['netWorth'] ?? 0,
      'net_worth_change':
          (nw['netWorth'] ?? 0) -
          ((nw['assets'] ?? 0) - (nw['liabilities'] ?? 0)),
      'total_asset_value': nw['assets'] ?? 0,
      'business_revenue': bizSummary['revenue'] ?? 0,
      'business_expenses': bizSummary['expenses'] ?? 0,
      'business_profit': bizSummary['profit'] ?? 0,
      'portfolio_value': invSummary['portfolio_value'] ?? 0,
      'investment_returns': invSummary['returns'] ?? 0,
      'loan_payables_balance': loanSummary['payables'] ?? 0,
      'loan_receivables_balance': loanSummary['receivables'] ?? 0,
      'repayments_made': loanSummary['repayments_made'] ?? 0,
      'repayments_received': loanSummary['repayments_received'] ?? 0,
      'goals_progress': goalsProgress,
      'goals_completed': goalsCompleted,
      'financial_health_score': healthScore,
      'debt_to_income_ratio': income > 0
          ? (loanSummary['payables'] ?? 0) / income
          : 0.0,
      'savings_to_income_ratio': income > 0
          ? (netCashFlow > 0 ? netCashFlow / income : 0)
          : 0.0,
      'profit_margin': income > 0 ? (netCashFlow / income) : 0.0,
      'ai_executive_summary': _generateExecutiveSummary(
        income: income,
        expenses: expenses,
        netCashFlow: netCashFlow,
        netWorth: nw['netWorth'] ?? 0,
        healthScore: healthScore,
        periodLabel: periodLabel,
        priorIncome: priorIncome,
        priorExpenses: priorExpenses,
        bizProfit: bizSummary['profit'] ?? 0,
        goalsCompleted: goalsCompleted,
      ),
      'ai_key_insights': _generateKeyInsights(
        income: income,
        expenses: expenses,
        netCashFlow: netCashFlow,
        priorIncome: priorIncome,
        priorExpenses: priorExpenses,
        bizProfit: bizSummary['profit'] ?? 0,
        invReturns: invSummary['returns'] ?? 0,
      ),
      'ai_risks': _generateRisks(
        income: income,
        expenses: expenses,
        netCashFlow: netCashFlow,
        loanPayables: loanSummary['payables'] ?? 0,
      ),
      'ai_recommendations': _generateRecommendations(
        income: income,
        expenses: expenses,
        netCashFlow: netCashFlow,
        healthScore: healthScore,
        goalsCompleted: goalsCompleted,
        totalGoals: goals.length,
      ),
      'next_period_forecast': {
        'projected_income': income * 1.05,
        'projected_expenses': expenses * 1.02,
        'projected_net_worth': (nw['netWorth'] ?? 0) + netCashFlow,
      },
      'milestones_achieved': _detectMilestones(
        income: income,
        netWorth: nw['netWorth'] ?? 0,
        goalsCompleted: goalsCompleted,
      ),
      'generated_at': DateTime.now().toIso8601String(),
    };

    // Save to database
    try {
      await _client.from('financial_closing_reports').insert(report);
    } catch (_) {}

    return report;
  }

  Future<List<Map<String, dynamic>>> getClosingReports({
    String? periodType,
    int limit = 20,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('financial_closing_reports')
          .select()
          .eq('user_id', userId);
      if (periodType != null) query = query.eq('period_type', periodType);
      return List<Map<String, dynamic>>.from(
        await query.order('generated_at', ascending: false).limit(limit),
      );
    } catch (_) {
      return [];
    }
  }

  // ─── PRIVATE HELPERS ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _getBusinessSummary(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final txns = await SupabaseService.client
          .from('financial_transactions')
          .select('transaction_type, amount')
          .eq('user_id', userId)
          .not('related_business_id', 'is', null)
          .gte('transaction_date', start.toIso8601String().split('T')[0])
          .lte('transaction_date', end.toIso8601String().split('T')[0]);

      double revenue = 0;
      double expenses = 0;
      for (final t in txns) {
        final amt = (t['amount'] as num).toDouble();
        if (t['transaction_type'] == 'income') revenue += amt;
        if (t['transaction_type'] == 'expense') expenses += amt;
      }
      return {
        'revenue': revenue,
        'expenses': expenses,
        'profit': revenue - expenses,
      };
    } catch (_) {
      return {'revenue': 0.0, 'expenses': 0.0, 'profit': 0.0};
    }
  }

  Future<Map<String, dynamic>> _getInvestmentSummary(String userId) async {
    try {
      final investments = await SupabaseService.client
          .from('investments')
          .select('amount_invested, current_value')
          .eq('user_id', userId)
          .neq('status', 'closed');

      double portfolioValue = 0;
      double invested = 0;
      for (final inv in investments) {
        portfolioValue +=
            (inv['current_value'] as num?)?.toDouble() ??
            (inv['amount_invested'] as num?)?.toDouble() ??
            0;
        invested += (inv['amount_invested'] as num?)?.toDouble() ?? 0;
      }
      return {
        'portfolio_value': portfolioValue,
        'returns': portfolioValue - invested,
      };
    } catch (_) {
      return {'portfolio_value': 0.0, 'returns': 0.0};
    }
  }

  Future<Map<String, dynamic>> _getLoanSummary(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      double payables = 0;
      double receivables = 0;
      double repaymentsMade = 0;
      double repaymentsReceived = 0;

      try {
        final loans = await SupabaseService.client
            .from('loans')
            .select('remaining_balance')
            .eq('user_id', userId)
            .eq('status', 'active');
        payables = (loans as List).fold(
          0.0,
          (s, l) => s + ((l['remaining_balance'] as num?)?.toDouble() ?? 0),
        );
      } catch (_) {}

      try {
        final recv = await SupabaseService.client
            .from('loans_receivable')
            .select('remaining_balance')
            .eq('user_id', userId)
            .inFilter('loan_status', ['active', 'partially_paid', 'overdue']);
        receivables = (recv as List).fold(
          0.0,
          (s, r) => s + ((r['remaining_balance'] as num?)?.toDouble() ?? 0),
        );
      } catch (_) {}

      return {
        'payables': payables,
        'receivables': receivables,
        'repayments_made': repaymentsMade,
        'repayments_received': repaymentsReceived,
      };
    } catch (_) {
      return {
        'payables': 0.0,
        'receivables': 0.0,
        'repayments_made': 0.0,
        'repayments_received': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _getIncomeBreakdown(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final txns = await SupabaseService.client
          .from('financial_transactions')
          .select('category, amount')
          .eq('user_id', userId)
          .eq('transaction_type', 'income')
          .gte('transaction_date', start.toIso8601String().split('T')[0])
          .lte('transaction_date', end.toIso8601String().split('T')[0]);

      final breakdown = <String, double>{};
      for (final t in txns) {
        final cat = t['category'] as String? ?? 'other';
        breakdown[cat] =
            (breakdown[cat] ?? 0) + (t['amount'] as num).toDouble();
      }
      return breakdown;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getExpenseBreakdown(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final txns = await SupabaseService.client
          .from('financial_transactions')
          .select('category, amount')
          .eq('user_id', userId)
          .eq('transaction_type', 'expense')
          .gte('transaction_date', start.toIso8601String().split('T')[0])
          .lte('transaction_date', end.toIso8601String().split('T')[0]);

      final breakdown = <String, double>{};
      for (final t in txns) {
        final cat = t['category'] as String? ?? 'other';
        breakdown[cat] =
            (breakdown[cat] ?? 0) + (t['amount'] as num).toDouble();
      }
      return breakdown;
    } catch (_) {
      return {};
    }
  }

  int _computeHealthScore(
    double income,
    double expenses,
    Map<String, double> nw,
  ) {
    int score = 50;
    if (income > 0) {
      final ratio = expenses / income;
      if (ratio < 0.5) {
        score += 20;
      } else if (ratio < 0.7)
        score += 10;
      else if (ratio > 0.9)
        score -= 10;
    }
    if ((nw['netWorth'] ?? 0) > 0) score += 15;
    if ((nw['liabilities'] ?? 0) < (nw['assets'] ?? 0) * 0.3) score += 15;
    return score.clamp(0, 100);
  }

  String _generateExecutiveSummary({
    required double income,
    required double expenses,
    required double netCashFlow,
    required double netWorth,
    required int healthScore,
    required String periodLabel,
    required double priorIncome,
    required double priorExpenses,
    required double bizProfit,
    required int goalsCompleted,
  }) {
    final healthLabel = healthScore >= 75
        ? 'excellent'
        : healthScore >= 50
        ? 'good'
        : 'fair';
    final cashFlowStatus = netCashFlow >= 0 ? 'positive' : 'negative';
    final incomeChange = priorIncome > 0
        ? ((income - priorIncome) / priorIncome * 100)
        : 0.0;

    return 'Financial Health: $healthLabel ($healthScore/100). '
        'Cash flow is $cashFlowStatus at ${_formatAmount(netCashFlow)}. '
        'Income ${incomeChange >= 0 ? 'increased' : 'decreased'} by ${incomeChange.abs().toStringAsFixed(1)}% vs prior period. '
        'Net Worth stands at ${_formatAmount(netWorth)}. '
        '${goalsCompleted > 0 ? '$goalsCompleted goal(s) completed this period. ' : ''}'
        '${bizProfit > 0 ? 'Business operations generated ${_formatAmount(bizProfit)} profit.' : ''}';
  }

  List<Map<String, dynamic>> _generateKeyInsights({
    required double income,
    required double expenses,
    required double netCashFlow,
    required double priorIncome,
    required double priorExpenses,
    required double bizProfit,
    required double invReturns,
  }) {
    final insights = <Map<String, dynamic>>[];

    if (income > 0 && priorIncome > 0) {
      final change = (income - priorIncome) / priorIncome * 100;
      insights.add({
        'type': change >= 0 ? 'positive' : 'negative',
        'title': 'Income ${change >= 0 ? 'Growth' : 'Decline'}',
        'detail':
            'Income ${change >= 0 ? 'increased' : 'decreased'} by ${change.abs().toStringAsFixed(1)}% vs prior period',
      });
    }

    if (netCashFlow > 0) {
      insights.add({
        'type': 'positive',
        'title': 'Positive Cash Flow',
        'detail':
            'Generated ${_formatAmount(netCashFlow)} net cash flow this period',
      });
    } else if (netCashFlow < 0) {
      insights.add({
        'type': 'warning',
        'title': 'Negative Cash Flow',
        'detail':
            'Expenses exceeded income by ${_formatAmount(netCashFlow.abs())}',
      });
    }

    if (bizProfit > 0) {
      insights.add({
        'type': 'positive',
        'title': 'Business Profitability',
        'detail':
            'Business operations contributed ${_formatAmount(bizProfit)} profit',
      });
    }

    if (invReturns > 0) {
      insights.add({
        'type': 'positive',
        'title': 'Investment Returns',
        'detail':
            'Investment portfolio generated ${_formatAmount(invReturns)} in returns',
      });
    }

    return insights;
  }

  List<Map<String, dynamic>> _generateRisks({
    required double income,
    required double expenses,
    required double netCashFlow,
    required double loanPayables,
  }) {
    final risks = <Map<String, dynamic>>[];

    if (netCashFlow < 0) {
      risks.add({
        'severity': 'high',
        'title': 'Negative Cash Flow',
        'description':
            'Expenses are exceeding income. Immediate action required.',
      });
    }

    if (income > 0 && expenses / income > 0.85) {
      risks.add({
        'severity': 'medium',
        'title': 'High Expense Ratio',
        'description':
            'Expenses represent ${(expenses / income * 100).toStringAsFixed(0)}% of income.',
      });
    }

    if (income > 0 && loanPayables / income > 0.4) {
      risks.add({
        'severity': 'medium',
        'title': 'High Debt Burden',
        'description': 'Loan obligations are high relative to income.',
      });
    }

    return risks;
  }

  List<Map<String, dynamic>> _generateRecommendations({
    required double income,
    required double expenses,
    required double netCashFlow,
    required int healthScore,
    required int goalsCompleted,
    required int totalGoals,
  }) {
    final recs = <Map<String, dynamic>>[];

    if (netCashFlow < 0) {
      recs.add({
        'priority': 'high',
        'title': 'Reduce Expenses',
        'action':
            'Review and cut non-essential expenses to restore positive cash flow.',
      });
    }

    if (healthScore < 60) {
      recs.add({
        'priority': 'high',
        'title': 'Improve Financial Health',
        'action':
            'Focus on increasing income sources and reducing debt obligations.',
      });
    }

    if (totalGoals > 0 && goalsCompleted == 0) {
      recs.add({
        'priority': 'medium',
        'title': 'Accelerate Goal Progress',
        'action': 'Increase monthly contributions to financial goals.',
      });
    }

    if (income > 0 && netCashFlow / income < 0.1) {
      recs.add({
        'priority': 'medium',
        'title': 'Increase Savings Rate',
        'action': 'Target saving at least 10-20% of monthly income.',
      });
    }

    return recs;
  }

  List<Map<String, dynamic>> _detectMilestones({
    required double income,
    required double netWorth,
    required int goalsCompleted,
  }) {
    final milestones = <Map<String, dynamic>>[];

    if (goalsCompleted > 0) {
      milestones.add({
        'type': 'goal_completed',
        'title':
            '$goalsCompleted Goal${goalsCompleted > 1 ? 's' : ''} Completed',
        'description': 'Congratulations on achieving your financial goals!',
      });
    }

    if (netWorth >= 1000000) {
      milestones.add({
        'type': 'net_worth',
        'title': 'Millionaire Milestone',
        'description': 'Net worth has reached ${_formatAmount(netWorth)}',
      });
    }

    return milestones;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return 'TSh ${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
