import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './finance_service.dart';

/// Wealth Planning Intelligence Service
/// Generates live wealth plans using actual financial data — never templates.
/// Every recommendation explains why it was generated, which data was used,
/// expected benefits, potential risks, and confidence level.
class WealthIntelligenceService {
  static WealthIntelligenceService? _instance;
  static WealthIntelligenceService get instance =>
      _instance ??= WealthIntelligenceService._();
  WealthIntelligenceService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── LIVE FINANCIAL POSITION ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getLiveFinancialPosition() async {
    final userId = _userId;
    if (userId == null) return {};
    try {
      final results = await Future.wait([
        FinanceService.instance.getDashboardSummary(),
        _getGoals(),
        _getInvestments(),
        _getLoans(),
        _getAssets(),
        _getBusinesses(),
        _getMonthlyTrend(),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final goals = results[1] as List<Map<String, dynamic>>;
      final investments = results[2] as List<Map<String, dynamic>>;
      final loans = results[3] as List<Map<String, dynamic>>;
      final assets = results[4] as List<Map<String, dynamic>>;
      final businesses = results[5] as List<Map<String, dynamic>>;
      final trend = results[6] as List<Map<String, dynamic>>;

      final netWorth = (summary['netWorth'] as double?) ?? 0;
      final monthlyIncome = (summary['monthlyIncome'] as double?) ?? 0;
      final monthlyExpenses = (summary['monthlyExpenses'] as double?) ?? 0;
      final monthlySavings = monthlyIncome - monthlyExpenses;
      final savingsRate = monthlyIncome > 0
          ? (monthlySavings / monthlyIncome * 100)
          : 0.0;

      final totalLoanPayable = loans
          .where((l) => l['loan_type'] == 'payable')
          .fold<double>(
            0,
            (s, l) => s + ((l['outstanding_balance'] as num?)?.toDouble() ?? 0),
          );

      final debtToIncome = monthlyIncome > 0
          ? (totalLoanPayable / (monthlyIncome * 12) * 100)
          : 0.0;

      final totalInvestmentValue = investments.fold<double>(
        0,
        (s, i) => s + ((i['current_value'] as num?)?.toDouble() ?? 0),
      );

      final emergencyFundMonths = monthlyExpenses > 0
          ? ((summary['availableCash'] as double? ?? 0) / monthlyExpenses)
          : 0.0;

      return {
        'net_worth': netWorth,
        'total_assets': summary['totalAssets'] ?? 0.0,
        'total_liabilities': summary['totalLiabilities'] ?? 0.0,
        'available_cash': summary['availableCash'] ?? 0.0,
        'monthly_income': monthlyIncome,
        'monthly_expenses': monthlyExpenses,
        'monthly_savings': monthlySavings,
        'savings_rate': savingsRate,
        'total_investments': totalInvestmentValue,
        'total_businesses': businesses.length,
        'total_loans_payable': totalLoanPayable,
        'debt_to_income_ratio': debtToIncome,
        'emergency_fund_months': emergencyFundMonths,
        'goals': goals,
        'investments': investments,
        'loans': loans,
        'assets': assets,
        'businesses': businesses,
        'monthly_trend': trend,
        'data_sources': {
          'accounts': true,
          'transactions': true,
          'assets': assets.isNotEmpty,
          'investments': investments.isNotEmpty,
          'loans': loans.isNotEmpty,
          'businesses': businesses.isNotEmpty,
          'goals': goals.isNotEmpty,
        },
      };
    } catch (_) {
      return {};
    }
  }

  // ─── WEALTH PROJECTIONS ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWealthProjections({
    int years = 10,
    double? customSavingsRate,
    double? customInvestmentReturn,
  }) async {
    final position = await getLiveFinancialPosition();
    if (position.isEmpty) return [];

    final netWorth = (position['net_worth'] as num?)?.toDouble() ?? 0;
    final monthlySavings =
        (position['monthly_savings'] as num?)?.toDouble() ?? 0;
    final totalInvestments =
        (position['total_investments'] as num?)?.toDouble() ?? 0;

    // Use actual data to determine growth rates
    final savingsRate = customSavingsRate ?? (monthlySavings * 12);
    final investmentReturn = customInvestmentReturn ?? 0.08; // 8% default

    final projections = <Map<String, dynamic>>[];
    double currentNetWorth = netWorth;
    double currentInvestments = totalInvestments;

    for (int year = 1; year <= years; year++) {
      currentInvestments = currentInvestments * (1 + investmentReturn);
      currentNetWorth =
          currentNetWorth +
          savingsRate +
          (currentInvestments - totalInvestments);

      projections.add({
        'year': year,
        'year_label': '${DateTime.now().year + year}',
        'projected_net_worth': currentNetWorth,
        'projected_investments': currentInvestments,
        'cumulative_savings': savingsRate * year,
        'investment_growth': currentInvestments - totalInvestments,
        'assumptions': {
          'annual_savings': savingsRate,
          'investment_return_rate': investmentReturn,
          'base_net_worth': netWorth,
        },
      });
    }

    return projections;
  }

  // ─── GOAL PROGRESS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGoalProgress() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final goals = await _client
          .from('financial_goals')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('target_date', ascending: true);

      final position = await getLiveFinancialPosition();
      final monthlySavings =
          (position['monthly_savings'] as num?)?.toDouble() ?? 0;

      return List<Map<String, dynamic>>.from(goals).map((goal) {
        final target = (goal['target_amount'] as num?)?.toDouble() ?? 0;
        final current = (goal['current_amount'] as num?)?.toDouble() ?? 0;
        final remaining = target - current;
        final progress = target > 0
            ? (current / target * 100).clamp(0, 100)
            : 0.0;

        // Calculate estimated completion date
        String? estimatedCompletion;
        String? completionStatus;
        if (monthlySavings > 0 && remaining > 0) {
          final monthsNeeded = (remaining / monthlySavings).ceil();
          final completionDate = DateTime.now().add(
            Duration(days: monthsNeeded * 30),
          );
          estimatedCompletion =
              '${completionDate.year}-${completionDate.month.toString().padLeft(2, '0')}';

          final targetDate = goal['target_date'] != null
              ? DateTime.tryParse(goal['target_date'] as String)
              : null;
          if (targetDate != null) {
            completionStatus = completionDate.isBefore(targetDate)
                ? 'on_track'
                : 'delayed';
          }
        }

        return {
          ...goal,
          'progress_percent': progress,
          'remaining_amount': remaining,
          'estimated_completion': estimatedCompletion,
          'completion_status': completionStatus ?? 'unknown',
          'monthly_savings_needed': monthlySavings > 0 ? monthlySavings : null,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── RECOMMENDATIONS ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> generateRecommendations() async {
    final position = await getLiveFinancialPosition();
    if (position.isEmpty) return [];

    final recommendations = <Map<String, dynamic>>[];

    final savingsRate = (position['savings_rate'] as num?)?.toDouble() ?? 0;
    final emergencyFundMonths =
        (position['emergency_fund_months'] as num?)?.toDouble() ?? 0;
    final debtToIncome =
        (position['debt_to_income_ratio'] as num?)?.toDouble() ?? 0;
    final monthlySavings =
        (position['monthly_savings'] as num?)?.toDouble() ?? 0;
    final totalInvestments =
        (position['total_investments'] as num?)?.toDouble() ?? 0;
    final monthlyIncome = (position['monthly_income'] as num?)?.toDouble() ?? 0;

    // Emergency Fund
    if (emergencyFundMonths < 3) {
      recommendations.add({
        'id': 'emergency_fund',
        'category': 'savings',
        'priority': 'high',
        'title': 'Build Emergency Fund',
        'description':
            'Your emergency fund covers ${emergencyFundMonths.toStringAsFixed(1)} months of expenses. Target: 3–6 months.',
        'data_used': 'Available cash and monthly expenses from Finance Engine',
        'reasoning':
            'Emergency funds prevent debt accumulation during unexpected events.',
        'expected_benefit': 'Financial security and reduced stress',
        'potential_risk':
            'Without emergency fund, unexpected costs may require loans',
        'confidence': 92.0,
        'action':
            'Allocate a portion of monthly savings to a dedicated emergency account',
        'target_amount':
            (position['monthly_expenses'] as num?)?.toDouble() ?? 0 * 3,
      });
    }

    // Savings Rate
    if (savingsRate < 20 && monthlyIncome > 0) {
      recommendations.add({
        'id': 'savings_rate',
        'category': 'savings',
        'priority': savingsRate < 10 ? 'high' : 'normal',
        'title': 'Increase Savings Rate',
        'description':
            'Current savings rate: ${savingsRate.toStringAsFixed(1)}%. Target: 20%+.',
        'data_used': 'Monthly income and expenses from Finance Engine',
        'reasoning':
            'Higher savings rate accelerates wealth building and goal achievement.',
        'expected_benefit':
            'Reaching financial goals ${savingsRate < 10 ? "significantly" : "moderately"} faster',
        'potential_risk': 'Lifestyle inflation may reduce savings capacity',
        'confidence': 88.0,
        'action':
            'Review expense categories and identify reduction opportunities',
      });
    }

    // Debt Management
    if (debtToIncome > 40) {
      recommendations.add({
        'id': 'debt_reduction',
        'category': 'debt',
        'priority': debtToIncome > 60 ? 'high' : 'normal',
        'title': 'Reduce Debt Burden',
        'description':
            'Debt-to-income ratio: ${debtToIncome.toStringAsFixed(1)}%. Healthy target: below 40%.',
        'data_used':
            'Loan balances and annual income from Loan and Finance Engines',
        'reasoning':
            'High debt-to-income ratio limits financial flexibility and increases risk.',
        'expected_benefit':
            'Improved credit profile and reduced interest costs',
        'potential_risk': 'Aggressive debt repayment may reduce liquidity',
        'confidence': 85.0,
        'action': 'Prioritize highest-interest loans for accelerated repayment',
      });
    }

    // Investment Diversification
    if (totalInvestments < monthlyIncome * 6 && monthlyIncome > 0) {
      recommendations.add({
        'id': 'investment_growth',
        'category': 'investment',
        'priority': 'normal',
        'title': 'Grow Investment Portfolio',
        'description':
            'Investment portfolio is below 6 months of income. Consider increasing investment allocation.',
        'data_used':
            'Investment portfolio value and monthly income from Finance Engine',
        'reasoning':
            'Investments generate passive income and build long-term wealth.',
        'expected_benefit': 'Compound growth and passive income streams',
        'potential_risk': 'Market volatility may affect short-term values',
        'confidence': 78.0,
        'action':
            'Allocate a fixed percentage of monthly income to investments',
      });
    }

    // Positive reinforcement
    if (savingsRate >= 20) {
      recommendations.add({
        'id': 'savings_excellent',
        'category': 'savings',
        'priority': 'low',
        'title': 'Excellent Savings Discipline',
        'description':
            'Savings rate of ${savingsRate.toStringAsFixed(1)}% is above the 20% target. Keep it up!',
        'data_used': 'Monthly income and expenses from Finance Engine',
        'reasoning':
            'Consistent high savings rate is the foundation of wealth.',
        'expected_benefit':
            'Accelerated goal achievement and financial independence',
        'potential_risk': 'None identified',
        'confidence': 95.0,
        'action':
            'Consider increasing investment allocation to maximize returns',
      });
    }

    return recommendations;
  }

  // ─── RISK ANALYSIS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRiskFactors() async {
    final position = await getLiveFinancialPosition();
    if (position.isEmpty) return [];

    final risks = <Map<String, dynamic>>[];
    final loans = position['loans'] as List<Map<String, dynamic>>? ?? [];
    final investments =
        position['investments'] as List<Map<String, dynamic>>? ?? [];

    // Check overdue loans
    final overdueLoans = loans.where((l) {
      final dueDate = l['due_date'] != null
          ? DateTime.tryParse(l['due_date'] as String)
          : null;
      return dueDate != null && dueDate.isBefore(DateTime.now());
    }).toList();

    if (overdueLoans.isNotEmpty) {
      risks.add({
        'id': 'overdue_loans',
        'severity': 'high',
        'category': 'loan',
        'title': 'Overdue Loan Payments',
        'description':
            '${overdueLoans.length} loan(s) have passed their due date.',
        'impact': 'Credit damage, penalty interest, legal risk',
        'action': 'Contact lenders immediately to arrange payment',
        'data_source': 'Loan Engine',
      });
    }

    // Concentration risk in investments
    if (investments.length == 1 && investments.isNotEmpty) {
      risks.add({
        'id': 'concentration_risk',
        'severity': 'medium',
        'category': 'investment',
        'title': 'Investment Concentration Risk',
        'description':
            'All investments are in a single asset. Diversification recommended.',
        'impact': 'High exposure to single asset performance',
        'action': 'Diversify across multiple investment types',
        'data_source': 'Investment Engine',
      });
    }

    // Low emergency fund
    final emergencyMonths =
        (position['emergency_fund_months'] as num?)?.toDouble() ?? 0;
    if (emergencyMonths < 1) {
      risks.add({
        'id': 'no_emergency_fund',
        'severity': 'high',
        'category': 'savings',
        'title': 'No Emergency Fund',
        'description':
            'Less than 1 month of expenses available as emergency reserve.',
        'impact': 'Any unexpected expense may require debt',
        'action': 'Build emergency fund as top priority',
        'data_source': 'Finance Engine',
      });
    }

    return risks;
  }

  // ─── SCENARIO COMPARISON ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> compareScenarios() async {
    final position = await getLiveFinancialPosition();
    if (position.isEmpty) return [];

    final monthlySavings =
        (position['monthly_savings'] as num?)?.toDouble() ?? 0;
    final netWorth = (position['net_worth'] as num?)?.toDouble() ?? 0;

    return [
      {
        'id': 'current',
        'name': 'Current Trajectory',
        'description': 'Continue at current savings and investment rate',
        'net_worth_5y': netWorth + (monthlySavings * 60),
        'net_worth_10y': netWorth + (monthlySavings * 120),
        'assumptions': 'Current savings rate maintained',
        'risk': 'low',
      },
      {
        'id': 'aggressive_savings',
        'name': 'Aggressive Savings (+20%)',
        'description': 'Increase monthly savings by 20%',
        'net_worth_5y': netWorth + (monthlySavings * 1.2 * 60),
        'net_worth_10y': netWorth + (monthlySavings * 1.2 * 120),
        'assumptions': '20% increase in monthly savings',
        'risk': 'low',
      },
      {
        'id': 'invest_more',
        'name': 'Invest 30% of Savings',
        'description':
            'Redirect 30% of savings to investments at 8% annual return',
        'net_worth_5y':
            netWorth +
            (monthlySavings * 0.7 * 60) +
            (monthlySavings * 0.3 * 60 * 1.08),
        'net_worth_10y':
            netWorth +
            (monthlySavings * 0.7 * 120) +
            (monthlySavings * 0.3 * 120 * 1.08),
        'assumptions': '8% annual investment return, 30% of savings invested',
        'risk': 'medium',
      },
    ];
  }

  // ─── GRAPH DATA FOR DRILL-DOWN ────────────────────────────────────────────

  Future<Map<String, dynamic>> getGraphData({
    required String graphType,
    required String period,
    String? businessId,
    String? investmentId,
    String? accountId,
    String? category,
  }) async {
    final userId = _userId;
    if (userId == null) return {};

    try {
      final now = DateTime.now();
      DateTime startDate;
      int dataPoints;

      switch (period) {
        case 'daily':
          startDate = now.subtract(const Duration(days: 30));
          dataPoints = 30;
          break;
        case 'weekly':
          startDate = now.subtract(const Duration(days: 84));
          dataPoints = 12;
          break;
        case 'monthly':
          startDate = DateTime(now.year - 1, now.month, 1);
          dataPoints = 12;
          break;
        case 'quarterly':
          startDate = DateTime(now.year - 2, now.month, 1);
          dataPoints = 8;
          break;
        case 'yearly':
          startDate = DateTime(now.year - 5, 1, 1);
          dataPoints = 5;
          break;
        default:
          startDate = DateTime(now.year, now.month - 5, 1);
          dataPoints = 6;
      }

      switch (graphType) {
        case 'cash_flow':
          return _getCashFlowGraphData(userId, startDate, period, dataPoints);
        case 'net_worth':
          return _getNetWorthGraphData(userId, startDate, period, dataPoints);
        case 'income_expense':
          return _getIncomeExpenseGraphData(
            userId,
            startDate,
            period,
            dataPoints,
          );
        case 'investment_performance':
          return _getInvestmentGraphData(userId, startDate, period, dataPoints);
        default:
          return _getCashFlowGraphData(userId, startDate, period, dataPoints);
      }
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getCashFlowGraphData(
    String userId,
    DateTime startDate,
    String period,
    int dataPoints,
  ) async {
    try {
      final transactions = await _client
          .from('financial_transactions')
          .select(
            'transaction_date, amount, transaction_type, category, description, id',
          )
          .eq('user_id', userId)
          .gte('transaction_date', startDate.toIso8601String().split('T')[0])
          .neq('status', 'cancelled')
          .order('transaction_date', ascending: true);

      final list = List<Map<String, dynamic>>.from(transactions);

      // Group by period
      final grouped = <String, Map<String, dynamic>>{};
      for (final txn in list) {
        final date =
            DateTime.tryParse(txn['transaction_date'] as String? ?? '') ??
            DateTime.now();
        final key = _getPeriodKey(date, period);

        grouped.putIfAbsent(
          key,
          () => {
            'label': key,
            'income': 0.0,
            'expense': 0.0,
            'net': 0.0,
            'transactions': <Map<String, dynamic>>[],
          },
        );

        final amount = (txn['amount'] as num?)?.toDouble() ?? 0;
        final type = txn['transaction_type'] as String? ?? '';

        if (type == 'income' || type == 'salary' || type == 'dividend') {
          grouped[key]!['income'] =
              (grouped[key]!['income'] as double) + amount;
        } else if (type == 'expense' || type == 'fees' || type == 'tax') {
          grouped[key]!['expense'] =
              (grouped[key]!['expense'] as double) + amount;
        }

        (grouped[key]!['transactions'] as List).add({
          'id': txn['id'],
          'date': txn['transaction_date'],
          'amount': amount,
          'type': type,
          'description': txn['description'],
          'category': txn['category'],
        });
      }

      // Calculate net
      for (final key in grouped.keys) {
        final income = grouped[key]!['income'] as double;
        final expense = grouped[key]!['expense'] as double;
        grouped[key]!['net'] = income - expense;
      }

      return {
        'graph_type': 'cash_flow',
        'period': period,
        'data_points': grouped.values.toList(),
        'total_income': list
            .where(
              (t) => [
                'income',
                'salary',
                'dividend',
              ].contains(t['transaction_type']),
            )
            .fold<double>(
              0,
              (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0),
            ),
        'total_expense': list
            .where(
              (t) => ['expense', 'fees', 'tax'].contains(t['transaction_type']),
            )
            .fold<double>(
              0,
              (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0),
            ),
        'data_source': 'financial_transactions',
        'record_count': list.length,
      };
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getNetWorthGraphData(
    String userId,
    DateTime startDate,
    String period,
    int dataPoints,
  ) async {
    try {
      final snapshots = await _client
          .from('net_worth_snapshots')
          .select('snapshot_date, net_worth, total_assets, total_liabilities')
          .eq('user_id', userId)
          .gte('snapshot_date', startDate.toIso8601String().split('T')[0])
          .order('snapshot_date', ascending: true);

      return {
        'graph_type': 'net_worth',
        'period': period,
        'data_points': List<Map<String, dynamic>>.from(snapshots)
            .map(
              (s) => {
                'label': s['snapshot_date'],
                'net_worth': (s['net_worth'] as num?)?.toDouble() ?? 0,
                'total_assets': (s['total_assets'] as num?)?.toDouble() ?? 0,
                'total_liabilities':
                    (s['total_liabilities'] as num?)?.toDouble() ?? 0,
              },
            )
            .toList(),
        'data_source': 'net_worth_snapshots',
      };
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getIncomeExpenseGraphData(
    String userId,
    DateTime startDate,
    String period,
    int dataPoints,
  ) async {
    return _getCashFlowGraphData(userId, startDate, period, dataPoints);
  }

  Future<Map<String, dynamic>> _getInvestmentGraphData(
    String userId,
    DateTime startDate,
    String period,
    int dataPoints,
  ) async {
    try {
      final investments = await _client
          .from('investments')
          .select(
            'id, name, current_value, capital_invested, category, created_at',
          )
          .eq('owner_id', userId)
          .eq('is_active', true);

      return {
        'graph_type': 'investment_performance',
        'period': period,
        'data_points': List<Map<String, dynamic>>.from(investments)
            .map(
              (inv) => {
                'label': inv['name'],
                'current_value':
                    (inv['current_value'] as num?)?.toDouble() ?? 0,
                'capital_invested':
                    (inv['capital_invested'] as num?)?.toDouble() ?? 0,
                'roi': _calculateROI(inv),
                'category': inv['category'],
                'id': inv['id'],
              },
            )
            .toList(),
        'data_source': 'investments',
      };
    } catch (_) {
      return {};
    }
  }

  double _calculateROI(Map<String, dynamic> inv) {
    final current = (inv['current_value'] as num?)?.toDouble() ?? 0;
    final invested = (inv['capital_invested'] as num?)?.toDouble() ?? 1;
    return invested > 0 ? ((current - invested) / invested * 100) : 0;
  }

  String _getPeriodKey(DateTime date, String period) {
    switch (period) {
      case 'daily':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'weekly':
        final weekNum = ((date.day - 1) / 7).floor() + 1;
        return '${date.year}-W$weekNum-${date.month.toString().padLeft(2, '0')}';
      case 'monthly':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case 'quarterly':
        final q = ((date.month - 1) / 3).floor() + 1;
        return '${date.year}-Q$q';
      case 'yearly':
        return '${date.year}';
      default:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }
  }

  // ─── PRIVATE HELPERS ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getGoals() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('financial_goals')
            .select()
            .eq('user_id', userId)
            .eq('is_active', true),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getInvestments() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('investments')
            .select()
            .eq('owner_id', userId)
            .eq('is_active', true),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getLoans() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('loans')
            .select()
            .eq('user_id', userId)
            .neq('status', 'settled'),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAssets() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('assets')
            .select()
            .eq('user_id', userId)
            .eq('is_active', true),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getBusinesses() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('businesses')
            .select()
            .eq('owner_id', userId)
            .eq('is_active', true),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getMonthlyTrend() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      return List<Map<String, dynamic>>.from(
        await _client
            .from('financial_transactions')
            .select('transaction_date, amount, transaction_type')
            .eq('user_id', userId)
            .gte(
              'transaction_date',
              sixMonthsAgo.toIso8601String().split('T')[0],
            )
            .neq('status', 'cancelled')
            .order('transaction_date', ascending: true),
      );
    } catch (_) {
      return [];
    }
  }
}
