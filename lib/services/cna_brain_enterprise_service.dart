import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/aiIntegrations/chat_completion_service.dart';

/// CNA Brain Enterprise Intelligence Service — Master Prompt 6
/// Extends AiBrainService with:
/// - Risk Scoring Engine
/// - Opportunity Discovery Engine
/// - Scenario Analysis (What-If Engine)
/// - Recommendation Management with full lifecycle
/// - AI Audit Trail
/// - Personalization Engine
/// - Executive Financial Command Center
class CnaBrainEnterpriseService {
  static CnaBrainEnterpriseService? _instance;
  static CnaBrainEnterpriseService get instance =>
      _instance ??= CnaBrainEnterpriseService._();
  CnaBrainEnterpriseService._();

  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser?.id ?? '';

  // ============================================================
  // RISK SCORING ENGINE
  // ============================================================

  /// Calculates risk scores for all financial areas from real data
  Future<List<Map<String, dynamic>>> calculateRiskScores() async {
    if (_userId.isEmpty) return [];

    try {
      // Gather raw financial data
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        _client
            .from('financial_accounts')
            .select('current_balance')
            .eq('user_id', _userId)
            .eq('is_active', true),
        _client
            .from('financial_transactions')
            .select('transaction_type, amount')
            .eq('user_id', _userId)
            .eq('is_archived', false)
            .gte(
              'transaction_date',
              monthStart.toIso8601String().split('T')[0],
            ),
        _client
            .from('loans')
            .select('outstanding_balance, due_date, status')
            .eq('borrower_id', _userId),
        _client
            .from('investments')
            .select('current_value, purchase_price, category')
            .eq('user_id', _userId),
        _client.from('businesses').select('id, name').eq('owner_id', _userId),
        _client
            .from('financial_goals')
            .select('target_amount, current_amount, status')
            .eq('user_id', _userId)
            .eq('status', 'active'),
      ]);

      final accounts = results[0] as List;
      final txns = results[1] as List;
      final loans = results[2] as List;
      final investments = results[3] as List;
      final businesses = results[4] as List;
      final goals = results[5] as List;

      double totalCash = 0;
      for (final a in accounts) {
        totalCash += (a['current_balance'] as num?)?.toDouble() ?? 0;
      }

      double income = 0, expenses = 0;
      for (final t in txns) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0;
        if (t['transaction_type'] == 'income') income += amt;
        if (t['transaction_type'] == 'expense') expenses += amt;
      }

      double totalDebt = 0;
      int overdueLoans = 0;
      for (final l in loans) {
        totalDebt += (l['outstanding_balance'] as num?)?.toDouble() ?? 0;
        final due = l['due_date'] != null
            ? DateTime.tryParse(l['due_date'] as String)
            : null;
        if (due != null && due.isBefore(now)) overdueLoans++;
      }

      double investmentValue = 0, investmentCost = 0;
      final categories = <String>{};
      for (final i in investments) {
        investmentValue += (i['current_value'] as num?)?.toDouble() ?? 0;
        investmentCost += (i['purchase_price'] as num?)?.toDouble() ?? 0;
        if (i['category'] != null) categories.add(i['category'] as String);
      }

      double goalProgress = 0;
      if (goals.isNotEmpty) {
        double totalTarget = 0, totalCurrent = 0;
        for (final g in goals) {
          totalTarget += (g['target_amount'] as num?)?.toDouble() ?? 0;
          totalCurrent += (g['current_amount'] as num?)?.toDouble() ?? 0;
        }
        goalProgress = totalTarget > 0 ? totalCurrent / totalTarget * 100 : 0;
      }

      final scores = <Map<String, dynamic>>[];

      // 1. Overall Financial Health
      int healthScore = 50;
      final tips = <String>[];
      if (income > 0 && expenses < income) healthScore += 15;
      if (totalCash > expenses * 3) healthScore += 15;
      if (overdueLoans == 0) healthScore += 10;
      if (investments.isNotEmpty) healthScore += 10;
      if (healthScore > 100) healthScore = 100;
      if (income == 0) {
        tips.add('Record your income sources to improve analysis');
      }
      if (expenses > income && income > 0) {
        tips.add('Expenses exceed income — review spending');
        healthScore -= 20;
      }
      scores.add({
        'score_type': 'overall_financial_health',
        'label': 'Financial Health',
        'icon': 'favorite',
        'score': healthScore.clamp(0, 100),
        'rating': _getRating(healthScore.clamp(0, 100)),
        'explanation': income > 0
            ? 'Based on ${accounts.length} accounts, monthly income of ${_fmt(income)}, and expenses of ${_fmt(expenses)}.'
            : 'Add transactions to get a personalized health score.',
        'improvement_tips': tips,
        'color': _getRatingColor(healthScore.clamp(0, 100)),
      });

      // 2. Cash Flow Risk
      int cashScore = 50;
      final cashTips = <String>[];
      if (income > 0 && expenses <= income * 0.7) {
        cashScore = 85;
      } else if (income > 0 && expenses <= income * 0.9)
        cashScore = 65;
      else if (income > 0 && expenses > income) {
        cashScore = 25;
        cashTips.add('Reduce expenses or increase income to improve cash flow');
      }
      if (totalCash > expenses * 6) cashScore = (cashScore + 10).clamp(0, 100);
      if (totalCash < expenses) {
        cashScore = (cashScore - 20).clamp(0, 100);
        cashTips.add('Cash reserves are below one month of expenses');
      }
      scores.add({
        'score_type': 'cash_flow_risk',
        'label': 'Cash Flow',
        'icon': 'account_balance_wallet',
        'score': cashScore,
        'rating': _getRating(cashScore),
        'explanation':
            'Cash balance: ${_fmt(totalCash)} | Monthly net: ${_fmt(income - expenses)}',
        'improvement_tips': cashTips,
        'color': _getRatingColor(cashScore),
      });

      // 3. Loan Risk
      int loanScore = 80;
      final loanTips = <String>[];
      if (overdueLoans > 0) {
        loanScore -= overdueLoans * 20;
        loanTips.add('$overdueLoans overdue loan(s) — prioritize repayment');
      }
      if (income > 0 && totalDebt > income * 12) {
        loanScore -= 15;
        loanTips.add(
          'Debt exceeds annual income — consider debt reduction strategy',
        );
      }
      if (loans.isEmpty) loanScore = 90;
      scores.add({
        'score_type': 'loan_risk',
        'label': 'Loan Health',
        'icon': 'credit_score',
        'score': loanScore.clamp(0, 100),
        'rating': _getRating(loanScore.clamp(0, 100)),
        'explanation':
            '${loans.length} active loan(s) | Outstanding: ${_fmt(totalDebt)} | Overdue: $overdueLoans',
        'improvement_tips': loanTips,
        'color': _getRatingColor(loanScore.clamp(0, 100)),
      });

      // 4. Investment Risk
      int investScore = 50;
      final investTips = <String>[];
      if (investments.isEmpty) {
        investScore = 30;
        investTips.add(
          'No investments found — consider diversifying your wealth',
        );
      } else {
        if (categories.length >= 3) {
          investScore += 20;
        } else {
          investTips.add('Diversify across more asset classes');
        }
        final roi = investmentCost > 0
            ? (investmentValue - investmentCost) / investmentCost * 100
            : 0;
        if (roi > 10) {
          investScore += 20;
        } else if (roi < 0) {
          investScore -= 15;
          investTips.add(
            'Portfolio is currently at a loss — review underperformers',
          );
        }
        investScore += 10;
      }
      scores.add({
        'score_type': 'investment_risk',
        'label': 'Investment',
        'icon': 'trending_up',
        'score': investScore.clamp(0, 100),
        'rating': _getRating(investScore.clamp(0, 100)),
        'explanation':
            '${investments.length} investment(s) | Value: ${_fmt(investmentValue)} | ${categories.length} categories',
        'improvement_tips': investTips,
        'color': _getRatingColor(investScore.clamp(0, 100)),
      });

      // 5. Business Risk
      int bizScore = businesses.isEmpty ? 40 : 70;
      final bizTips = <String>[];
      if (businesses.isEmpty) {
        bizTips.add(
          'No businesses registered — consider adding income-generating businesses',
        );
      } else if (businesses.length == 1) {
        bizTips.add(
          'Single business dependency — consider diversifying income sources',
        );
        bizScore -= 10;
      }
      scores.add({
        'score_type': 'business_risk',
        'label': 'Business',
        'icon': 'business_center',
        'score': bizScore.clamp(0, 100),
        'rating': _getRating(bizScore.clamp(0, 100)),
        'explanation': '${businesses.length} registered business(es)',
        'improvement_tips': bizTips,
        'color': _getRatingColor(bizScore.clamp(0, 100)),
      });

      // 6. Goal Achievement Risk
      int goalScore = goals.isEmpty ? 40 : (goalProgress.round()).clamp(0, 100);
      final goalTips = <String>[];
      if (goals.isEmpty) {
        goalTips.add(
          'Set financial goals to track your wealth-building progress',
        );
      } else if (goalProgress < 25) {
        goalTips.add('Goals are behind — increase monthly contributions');
      }
      scores.add({
        'score_type': 'goal_achievement_risk',
        'label': 'Goals',
        'icon': 'flag',
        'score': goalScore,
        'rating': _getRating(goalScore),
        'explanation':
            '${goals.length} active goal(s) | Average progress: ${goalProgress.toStringAsFixed(0)}%',
        'improvement_tips': goalTips,
        'color': _getRatingColor(goalScore),
      });

      // Persist scores
      for (final s in scores) {
        await _client.from('ai_risk_scores').insert({
          'user_id': _userId,
          'score_type': s['score_type'],
          'score': s['score'],
          'rating': s['rating'],
          'explanation': s['explanation'],
          'improvement_tips': s['improvement_tips'],
        });
      }

      // Audit trail
      await _logAuditTrail(
        activityType: 'risk_assessment',
        aiService: 'Risk Scoring Engine',
        modulesConsulted: [
          'Finance',
          'Loans',
          'Investments',
          'Businesses',
          'Goals',
        ],
        resultSummary:
            'Calculated ${scores.length} risk scores. Overall health: ${scores.first['score']}',
      );

      return scores;
    } catch (e) {
      return _getDefaultRiskScores();
    }
  }

  List<Map<String, dynamic>> _getDefaultRiskScores() {
    return [
      {
        'score_type': 'overall_financial_health',
        'label': 'Financial Health',
        'icon': 'favorite',
        'score': 0,
        'rating': 'unknown',
        'explanation': 'Add financial data to calculate your health score.',
        'improvement_tips': [
          'Add accounts, transactions, and goals to get started',
        ],
        'color': 0xFF94A3B8,
      },
    ];
  }

  String _getRating(int score) {
    if (score >= 80) return 'excellent';
    if (score >= 65) return 'good';
    if (score >= 45) return 'fair';
    if (score >= 25) return 'poor';
    return 'critical';
  }

  int _getRatingColor(int score) {
    if (score >= 80) return 0xFF10B981;
    if (score >= 65) return 0xFF2D9CDB;
    if (score >= 45) return 0xFFF59E0B;
    if (score >= 25) return 0xFFEF4444;
    return 0xFF7F1D1D;
  }

  // ============================================================
  // OPPORTUNITY DISCOVERY ENGINE
  // ============================================================

  Future<List<Map<String, dynamic>>> discoverOpportunities() async {
    if (_userId.isEmpty) return [];

    try {
      // Gather context for AI-driven opportunity discovery
      final accounts = await _client
          .from('financial_accounts')
          .select('current_balance, account_category')
          .eq('user_id', _userId)
          .eq('is_active', true);

      final investments = await _client
          .from('investments')
          .select('name, category, current_value, purchase_price')
          .eq('user_id', _userId);

      final loans = await _client
          .from('loans')
          .select('outstanding_balance, interest_rate, status')
          .eq('borrower_id', _userId);

      final goals = await _client
          .from('financial_goals')
          .select('name, target_amount, current_amount')
          .eq('user_id', _userId)
          .eq('status', 'active');

      double totalCash = 0;
      for (final a in accounts) {
        totalCash += (a['current_balance'] as num?)?.toDouble() ?? 0;
      }

      final opportunities = <Map<String, dynamic>>[];

      // Rule-based opportunities (fast, no AI cost)
      if (totalCash > 0) {
        // Idle cash opportunity
        if (investments.isEmpty && totalCash > 1000000) {
          opportunities.add({
            'opportunity_type': 'investment_diversification',
            'title': 'Idle Cash Opportunity',
            'description':
                'You have ${_fmt(totalCash)} in cash with no investments. Consider allocating a portion to investments to grow your wealth.',
            'estimated_benefit':
                'Potential 8-15% annual return on invested capital',
            'supporting_evidence':
                'Cash balance: ${_fmt(totalCash)} | Investments: 0',
            'priority': 'high',
          });
        }

        // Emergency fund check
        if (totalCash < 500000) {
          opportunities.add({
            'opportunity_type': 'savings_optimization',
            'title': 'Build Emergency Fund',
            'description':
                'Your cash reserves are low. Building an emergency fund of 3-6 months of expenses provides financial security.',
            'estimated_benefit': 'Financial security against unexpected events',
            'supporting_evidence': 'Current cash: ${_fmt(totalCash)}',
            'priority': 'high',
          });
        }
      }

      // High-interest debt opportunity
      for (final l in loans) {
        final rate = (l['interest_rate'] as num?)?.toDouble() ?? 0;
        if (rate > 15) {
          final bal = (l['outstanding_balance'] as num?)?.toDouble() ?? 0;
          opportunities.add({
            'opportunity_type': 'debt_optimization',
            'title': 'High-Interest Debt Reduction',
            'description':
                'You have a loan with ${rate.toStringAsFixed(1)}% interest rate. Early repayment could save significant interest costs.',
            'estimated_benefit':
                'Save up to ${_fmt(bal * rate / 100)} per year in interest',
            'supporting_evidence':
                'Outstanding: ${_fmt(bal)} at ${rate.toStringAsFixed(1)}% p.a.',
            'priority': 'medium',
          });
        }
      }

      // Investment diversification
      if (investments.isNotEmpty) {
        final categories = investments
            .map((i) => i['category'] as String? ?? 'other')
            .toSet();
        if (categories.length < 3) {
          opportunities.add({
            'opportunity_type': 'investment_diversification',
            'title': 'Diversify Investment Portfolio',
            'description':
                'Your portfolio is concentrated in ${categories.length} category(ies). Diversifying reduces risk and can improve returns.',
            'estimated_benefit':
                'Reduced portfolio risk through diversification',
            'supporting_evidence':
                '${investments.length} investments across ${categories.length} categories',
            'priority': 'medium',
          });
        }
      }

      // Goal acceleration
      for (final g in goals) {
        final target = (g['target_amount'] as num?)?.toDouble() ?? 0;
        final current = (g['current_amount'] as num?)?.toDouble() ?? 0;
        final progress = target > 0 ? current / target * 100 : 0;
        if (progress < 20 && target > 0) {
          opportunities.add({
            'opportunity_type': 'savings_optimization',
            'title': 'Accelerate Goal: ${g['name']}',
            'description':
                'Your goal "${g['name']}" is only ${progress.toStringAsFixed(0)}% complete. Increasing monthly contributions can help you reach it faster.',
            'estimated_benefit': 'Reach target of ${_fmt(target)} sooner',
            'supporting_evidence':
                'Progress: ${_fmt(current)} of ${_fmt(target)}',
            'priority': progress < 10 ? 'high' : 'medium',
          });
        }
      }

      // Persist opportunities
      for (final opp in opportunities) {
        await _client.from('ai_opportunity_log').insert({
          'user_id': _userId,
          ...opp,
        });
      }

      await _logAuditTrail(
        activityType: 'opportunity_discovery',
        aiService: 'Opportunity Discovery Engine',
        modulesConsulted: ['Finance', 'Investments', 'Loans', 'Goals'],
        resultSummary: 'Discovered ${opportunities.length} opportunities',
      );

      return opportunities;
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // SCENARIO ANALYSIS — WHAT-IF ENGINE
  // ============================================================

  /// Runs a what-if scenario analysis using AI + real financial data
  Future<Map<String, dynamic>> runScenarioAnalysis({
    required String title,
    required String scenarioType,
    required Map<String, dynamic> parameters,
    required String userQuestion,
  }) async {
    if (_userId.isEmpty) {
      return {'error': 'User not authenticated'};
    }

    try {
      // Build financial snapshot
      final accounts = await _client
          .from('financial_accounts')
          .select('current_balance')
          .eq('user_id', _userId)
          .eq('is_active', true);

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final txns = await _client
          .from('financial_transactions')
          .select('transaction_type, amount')
          .eq('user_id', _userId)
          .eq('is_archived', false)
          .gte('transaction_date', monthStart.toIso8601String().split('T')[0]);

      double totalCash = 0;
      for (final a in accounts) {
        totalCash += (a['current_balance'] as num?)?.toDouble() ?? 0;
      }
      double income = 0, expenses = 0;
      for (final t in txns) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0;
        if (t['transaction_type'] == 'income') income += amt;
        if (t['transaction_type'] == 'expense') expenses += amt;
      }

      final baselineSnapshot = {
        'total_cash': totalCash,
        'monthly_income': income,
        'monthly_expenses': expenses,
        'net_monthly_cash_flow': income - expenses,
        'snapshot_date': now.toIso8601String(),
      };

      // Build AI prompt for scenario analysis
      final prompt =
          '''You are the CNA Brain performing a SCENARIO ANALYSIS.

CURRENT FINANCIAL POSITION (verified data):
- Total Cash: ${_fmt(totalCash)}
- Monthly Income: ${_fmt(income)}
- Monthly Expenses: ${_fmt(expenses)}
- Net Monthly Cash Flow: ${_fmt(income - expenses)}

SCENARIO TYPE: $scenarioType
SCENARIO PARAMETERS: ${parameters.toString()}

USER QUESTION: $userQuestion

Analyze this scenario and respond in this EXACT JSON format (no other text):
{
  "projected_outcomes": {
    "net_worth_change": "description of net worth impact",
    "cash_flow_change": "description of cash flow impact",
    "monthly_savings_change": "description of savings impact",
    "12_month_projection": "description of 12-month outlook"
  },
  "assumptions": ["assumption 1", "assumption 2", "assumption 3"],
  "risks": ["risk 1", "risk 2"],
  "opportunities": ["opportunity 1", "opportunity 2"],
  "confidence_level": "high|medium|low",
  "ai_recommendation": "Your clear, evidence-based recommendation in 2-3 sentences",
  "alternative_strategies": ["strategy 1", "strategy 2"]
}

RULES:
- Base all projections on the verified financial data above
- Clearly state all assumptions
- Never fabricate financial figures
- If data is insufficient, state what additional information is needed
- Mark all projections as estimates, not guarantees''';

      final response = await getChatCompletion(
        'OPEN_AI',
        'gpt-4.1',
        [
          {'role': 'user', 'content': prompt},
        ],
        parameters: {'max_completion_tokens': 1000},
      );

      final content =
          response['choices']?[0]?['message']?['content'] as String? ?? '{}';

      // Parse JSON response
      Map<String, dynamic> analysisResult = {};
      try {
        final startIdx = content.indexOf('{');
        final endIdx = content.lastIndexOf('}');
        if (startIdx >= 0 && endIdx > startIdx) {
          final jsonStr = content.substring(startIdx, endIdx + 1);
          // Simple key-value extraction
          analysisResult = _parseScenarioJson(jsonStr);
        }
      } catch (_) {}

      // Persist scenario
      final savedId = await _client
          .from('ai_scenario_analyses')
          .insert({
            'user_id': _userId,
            'title': title,
            'scenario_type': scenarioType,
            'input_parameters': parameters,
            'baseline_snapshot': baselineSnapshot,
            'projected_outcomes': analysisResult['projected_outcomes'] ?? {},
            'assumptions':
                (analysisResult['assumptions'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            'risks':
                (analysisResult['risks'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            'opportunities':
                (analysisResult['opportunities'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            'confidence_level': analysisResult['confidence_level'] ?? 'medium',
            'ai_recommendation': analysisResult['ai_recommendation'] ?? content,
          })
          .select('id')
          .single();

      await _logAuditTrail(
        activityType: 'scenario_simulation',
        aiService: 'Scenario Analysis Engine',
        modulesConsulted: ['Finance', 'Assets', 'Loans'],
        resultSummary:
            'Scenario: $title | Confidence: ${analysisResult['confidence_level'] ?? 'medium'}',
      );

      return {
        'id': savedId['id'],
        'title': title,
        'baseline': baselineSnapshot,
        'analysis': analysisResult,
        'raw_response': content,
      };
    } catch (e) {
      return {'error': 'Scenario analysis failed: $e'};
    }
  }

  Map<String, dynamic> _parseScenarioJson(String json) {
    // Extract key fields from JSON string
    final result = <String, dynamic>{};

    // Extract string fields
    for (final key in ['confidence_level', 'ai_recommendation']) {
      final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
      final match = pattern.firstMatch(json);
      if (match != null) result[key] = match.group(1);
    }

    // Extract nested object for projected_outcomes
    final outcomesMatch = RegExp(
      '"projected_outcomes"\\s*:\\s*\\{([^}]*)\\}',
    ).firstMatch(json);
    if (outcomesMatch != null) {
      final outcomesStr = outcomesMatch.group(1) ?? '';
      final outcomes = <String, dynamic>{};
      final kvPattern = RegExp('"(\\w+)"\\s*:\\s*"([^"]*)"');
      for (final kv in kvPattern.allMatches(outcomesStr)) {
        outcomes[kv.group(1)!] = kv.group(2)!;
      }
      result['projected_outcomes'] = outcomes;
    }

    // Extract arrays
    for (final key in [
      'assumptions',
      'risks',
      'opportunities',
      'alternative_strategies',
    ]) {
      final arrayMatch = RegExp(
        '"$key"\\s*:\\s*\\[([^\\]]*)\\]',
      ).firstMatch(json);
      if (arrayMatch != null) {
        final arrayStr = arrayMatch.group(1) ?? '';
        final items = RegExp(
          '"([^"]*)"',
        ).allMatches(arrayStr).map((m) => m.group(1)!).toList();
        result[key] = items;
      }
    }

    return result;
  }

  // ============================================================
  // RECOMMENDATION MANAGEMENT SYSTEM
  // ============================================================

  Future<List<Map<String, dynamic>>> getRecommendationsWithHistory({
    String? status,
    int limit = 20,
  }) async {
    try {
      var query = _client
          .from('ai_recommendations')
          .select('*')
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(await query);
    } catch (_) {
      return [];
    }
  }

  Future<void> updateRecommendationAction(
    String id,
    String action, {
    // 'accepted','declined','postponed','completed','archived'
    String? notes,
  }) async {
    try {
      await _client
          .from('ai_recommendations')
          .update({
            'status': action,
            'user_action': action,
            'action_taken_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', _userId);

      await _logAuditTrail(
        activityType: 'recommendation_$action',
        aiService: 'Recommendation Engine',
        modulesConsulted: [],
        resultSummary: 'Recommendation $id: $action',
        userAction: action,
      );
    } catch (_) {}
  }

  /// Generate new AI-powered recommendations from real financial data
  Future<List<Map<String, dynamic>>> generateEnterpriseRecommendations() async {
    if (_userId.isEmpty) return [];

    try {
      // Build financial context
      final accounts = await _client
          .from('financial_accounts')
          .select('current_balance, account_category')
          .eq('user_id', _userId)
          .eq('is_active', true);

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final txns = await _client
          .from('financial_transactions')
          .select('transaction_type, amount, category')
          .eq('user_id', _userId)
          .eq('is_archived', false)
          .gte('transaction_date', monthStart.toIso8601String().split('T')[0]);

      final loans = await _client
          .from('loans')
          .select('outstanding_balance, due_date, status')
          .eq('borrower_id', _userId);

      final investments = await _client
          .from('investments')
          .select('name, category, current_value, purchase_price')
          .eq('user_id', _userId);

      final goals = await _client
          .from('financial_goals')
          .select('name, target_amount, current_amount, priority')
          .eq('user_id', _userId)
          .eq('status', 'active');

      double totalCash = 0;
      for (final a in accounts) {
        totalCash += (a['current_balance'] as num?)?.toDouble() ?? 0;
      }
      double income = 0, expenses = 0;
      for (final t in txns) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0;
        if (t['transaction_type'] == 'income') income += amt;
        if (t['transaction_type'] == 'expense') expenses += amt;
      }

      final prompt =
          '''You are the CNA Brain generating ENTERPRISE FINANCIAL RECOMMENDATIONS.

VERIFIED FINANCIAL DATA:
- Cash: ${_fmt(totalCash)} across ${accounts.length} accounts
- Monthly Income: ${_fmt(income)}
- Monthly Expenses: ${_fmt(expenses)}
- Net Cash Flow: ${_fmt(income - expenses)}
- Active Loans: ${loans.length} | Total Debt: ${_fmt(loans.fold(0.0, (s, l) => s + ((l['outstanding_balance'] as num?)?.toDouble() ?? 0)))}
- Investments: ${investments.length} | Value: ${_fmt(investments.fold(0.0, (s, i) => s + ((i['current_value'] as num?)?.toDouble() ?? 0)))}
- Active Goals: ${goals.length}

Generate exactly 4 personalized recommendations. Return ONLY a JSON array:
[
  {
    "title": "recommendation title",
    "body": "detailed explanation with specific TZS amounts from the data",
    "category": "warning|opportunity|info",
    "priority": "high|medium|low",
    "agent_type": "financial_analyst|debt_advisor|investment_analyst|planning_agent",
    "supporting_evidence": "which data points support this",
    "estimated_impact": "quantified expected benefit",
    "confidence_level": "high|medium|low",
    "potential_drawbacks": "what could go wrong",
    "modules_referenced": ["Finance", "Loans"]
  }
]

RULES:
- Every recommendation must reference specific numbers from the data above
- Never invent financial figures
- If data is insufficient, recommend adding more data
- Prioritize by financial impact''';

      final response = await getChatCompletion(
        'OPEN_AI',
        'gpt-4.1',
        [
          {'role': 'user', 'content': prompt},
        ],
        parameters: {'max_completion_tokens': 1200},
      );

      final content =
          response['choices']?[0]?['message']?['content'] as String? ?? '[]';

      final recs = _parseRecommendationsJson(content);

      // Persist recommendations
      for (final rec in recs) {
        await _client.from('ai_recommendations').insert({
          'user_id': _userId,
          'title': rec['title'],
          'body': rec['body'],
          'category': rec['category'] ?? 'info',
          'priority': rec['priority'] ?? 'medium',
          'agent_type': rec['agent_type'],
          'supporting_evidence': rec['supporting_evidence'],
          'estimated_impact': rec['estimated_impact'],
          'confidence_level': rec['confidence_level'] ?? 'medium',
          'potential_drawbacks': rec['potential_drawbacks'],
          'modules_referenced': rec['modules_referenced'],
          'status': 'pending',
        });
      }

      await _logAuditTrail(
        activityType: 'recommendation_created',
        aiService: 'Recommendation Engine',
        modulesConsulted: ['Finance', 'Loans', 'Investments', 'Goals'],
        resultSummary: 'Generated ${recs.length} recommendations',
      );

      return recs;
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _parseRecommendationsJson(String json) {
    try {
      final startIdx = json.indexOf('[');
      final endIdx = json.lastIndexOf(']');
      if (startIdx < 0 || endIdx <= startIdx) return [];

      final recs = <Map<String, dynamic>>[];
      // Extract each object
      final objPattern = RegExp(r'\{[^{}]*\}', dotAll: true);
      for (final match in objPattern.allMatches(
        json.substring(startIdx, endIdx + 1),
      )) {
        final obj = match.group(0) ?? '';
        final rec = <String, dynamic>{};
        final kvPattern = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
        for (final kv in kvPattern.allMatches(obj)) {
          rec[kv.group(1)!] = kv.group(2)!;
        }
        // Extract array fields
        for (final key in ['modules_referenced']) {
          final arrayMatch = RegExp(
            '"$key"\\s*:\\s*\\[([^\\]]*)\\]',
          ).firstMatch(obj);
          if (arrayMatch != null) {
            final items = RegExp('"([^"]*)"')
                .allMatches(arrayMatch.group(1) ?? '')
                .map((m) => m.group(1)!)
                .toList();
            rec[key] = items;
          }
        }
        if (rec.isNotEmpty && rec.containsKey('title')) recs.add(rec);
      }
      return recs;
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // EXECUTIVE FINANCIAL COMMAND CENTER
  // ============================================================

  Future<Map<String, dynamic>> generateExecutiveCommandBriefing() async {
    if (_userId.isEmpty) return {'error': 'Not authenticated'};

    try {
      // Get last briefing timestamp
      final lastBriefing = await _client
          .from('ai_audit_trail')
          .select('created_at')
          .eq('user_id', _userId)
          .eq('activity_type', 'executive_briefing')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastReviewDate = lastBriefing != null
          ? DateTime.tryParse(lastBriefing['created_at'] as String)
          : null;

      // Gather comprehensive financial data
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);

      final results = await Future.wait([
        _client
            .from('financial_accounts')
            .select('current_balance, account_category')
            .eq('user_id', _userId)
            .eq('is_active', true),
        _client
            .from('financial_transactions')
            .select('transaction_type, amount, category, transaction_date')
            .eq('user_id', _userId)
            .eq('is_archived', false)
            .gte(
              'transaction_date',
              monthStart.toIso8601String().split('T')[0],
            ),
        _client
            .from('financial_transactions')
            .select('transaction_type, amount')
            .eq('user_id', _userId)
            .eq('is_archived', false)
            .gte(
              'transaction_date',
              lastMonthStart.toIso8601String().split('T')[0],
            )
            .lte(
              'transaction_date',
              lastMonthEnd.toIso8601String().split('T')[0],
            ),
        _client
            .from('loans')
            .select('loan_name, outstanding_balance, due_date, status')
            .eq('borrower_id', _userId),
        _client
            .from('investments')
            .select('name, current_value, purchase_price')
            .eq('user_id', _userId),
        _client
            .from('businesses')
            .select('name, business_type')
            .eq('owner_id', _userId),
        _client
            .from('financial_goals')
            .select('name, target_amount, current_amount, priority')
            .eq('user_id', _userId)
            .eq('status', 'active'),
        _client
            .from('assets')
            .select('name, current_value, asset_type')
            .eq('owner_id', _userId),
      ]);

      final accounts = results[0] as List;
      final currentTxns = results[1] as List;
      final lastMonthTxns = results[2] as List;
      final loans = results[3] as List;
      final investments = results[4] as List;
      final businesses = results[5] as List;
      final goals = results[6] as List;
      final assets = results[7] as List;

      double totalCash = 0;
      for (final a in accounts) {
        totalCash += (a['current_balance'] as num?)?.toDouble() ?? 0;
      }

      double curIncome = 0, curExpenses = 0;
      for (final t in currentTxns) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0;
        if (t['transaction_type'] == 'income') curIncome += amt;
        if (t['transaction_type'] == 'expense') curExpenses += amt;
      }

      double lastIncome = 0, lastExpenses = 0;
      for (final t in lastMonthTxns) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0;
        if (t['transaction_type'] == 'income') lastIncome += amt;
        if (t['transaction_type'] == 'expense') lastExpenses += amt;
      }

      double totalDebt = 0;
      int overdueLoans = 0;
      for (final l in loans) {
        totalDebt += (l['outstanding_balance'] as num?)?.toDouble() ?? 0;
        final due = l['due_date'] != null
            ? DateTime.tryParse(l['due_date'] as String)
            : null;
        if (due != null && due.isBefore(now)) overdueLoans++;
      }

      double investmentValue = 0, investmentCost = 0;
      for (final i in investments) {
        investmentValue += (i['current_value'] as num?)?.toDouble() ?? 0;
        investmentCost += (i['purchase_price'] as num?)?.toDouble() ?? 0;
      }

      double assetValue = 0;
      for (final a in assets) {
        assetValue += (a['current_value'] as num?)?.toDouble() ?? 0;
      }

      double netWorth = totalCash + investmentValue + assetValue - totalDebt;

      double goalProgress = 0;
      if (goals.isNotEmpty) {
        double tt = 0, tc = 0;
        for (final g in goals) {
          tt += (g['target_amount'] as num?)?.toDouble() ?? 0;
          tc += (g['current_amount'] as num?)?.toDouble() ?? 0;
        }
        goalProgress = tt > 0 ? tc / tt * 100 : 0;
      }

      final incomeChange = lastIncome > 0
          ? ((curIncome - lastIncome) / lastIncome * 100).toStringAsFixed(1)
          : 'N/A';
      final expenseChange = lastExpenses > 0
          ? ((curExpenses - lastExpenses) / lastExpenses * 100).toStringAsFixed(
              1,
            )
          : 'N/A';

      final briefingData = {
        'generated_at': now.toIso8601String(),
        'last_review': lastReviewDate?.toIso8601String(),
        'net_worth': netWorth,
        'total_cash': totalCash,
        'monthly_income': curIncome,
        'monthly_expenses': curExpenses,
        'net_cash_flow': curIncome - curExpenses,
        'income_change_pct': incomeChange,
        'expense_change_pct': expenseChange,
        'total_debt': totalDebt,
        'overdue_loans': overdueLoans,
        'investment_value': investmentValue,
        'investment_roi_pct': investmentCost > 0
            ? ((investmentValue - investmentCost) / investmentCost * 100)
                  .toStringAsFixed(1)
            : 'N/A',
        'asset_value': assetValue,
        'business_count': businesses.length,
        'goal_count': goals.length,
        'goal_progress_pct': goalProgress.toStringAsFixed(0),
        'new_risks': overdueLoans > 0 ? ['$overdueLoans overdue loan(s)'] : [],
        'new_opportunities': investmentValue == 0 && totalCash > 1000000
            ? ['Idle cash available for investment']
            : [],
      };

      await _logAuditTrail(
        activityType: 'executive_briefing',
        aiService: 'Executive Command Center',
        modulesConsulted: [
          'Finance',
          'Assets',
          'Investments',
          'Loans',
          'Businesses',
          'Goals',
        ],
        resultSummary:
            'Net Worth: ${_fmt(netWorth)} | Cash Flow: ${_fmt(curIncome - curExpenses)}',
      );

      return briefingData;
    } catch (e) {
      return {'error': 'Unable to generate briefing: $e'};
    }
  }

  // ============================================================
  // PERSONALIZATION ENGINE
  // ============================================================

  Future<Map<String, dynamic>> getPersonalizationSettings() async {
    try {
      final result = await _client
          .from('ai_personalization')
          .select('*')
          .eq('user_id', _userId)
          .maybeSingle();

      return result ??
          {
            'communication_style': 'balanced',
            'recommendation_style': 'balanced',
            'preferred_currency': 'TZS',
            'enable_memory': true,
            'enable_proactive_insights': true,
            'enable_risk_monitoring': true,
          };
    } catch (_) {
      return {
        'communication_style': 'balanced',
        'recommendation_style': 'balanced',
        'preferred_currency': 'TZS',
        'enable_memory': true,
        'enable_proactive_insights': true,
        'enable_risk_monitoring': true,
      };
    }
  }

  Future<void> updatePersonalizationSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      await _client.from('ai_personalization').upsert({
        'user_id': _userId,
        ...settings,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ============================================================
  // AI AUDIT TRAIL
  // ============================================================

  Future<void> _logAuditTrail({
    required String activityType,
    String? aiService,
    List<String>? modulesConsulted,
    String? resultSummary,
    String? userAction,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('ai_audit_trail').insert({
        'user_id': _userId,
        'activity_type': activityType,
        'ai_service': aiService,
        'modules_consulted': modulesConsulted,
        'result_summary': resultSummary,
        'user_action': userAction,
        'metadata': metadata ?? {},
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAuditTrail({int limit = 50}) async {
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('ai_audit_trail')
            .select('*')
            .eq('user_id', _userId)
            .order('created_at', ascending: false)
            .limit(limit),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSavedScenarios() async {
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('ai_scenario_analyses')
            .select('*')
            .eq('user_id', _userId)
            .order('created_at', ascending: false)
            .limit(20),
      );
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _fmt(double value) {
    if (value >= 1000000000) {
      return 'TZS ${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${value.toStringAsFixed(0)}';
  }
}
