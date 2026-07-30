import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Advanced Decision Engine Service
/// Scenario Manager, Simulation Engine, Decision Analyzer
class DecisionEngineService {
  static DecisionEngineService? _instance;
  static DecisionEngineService get instance =>
      _instance ??= DecisionEngineService._();
  DecisionEngineService._();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── SCENARIO CATEGORIES ─────────────────────────────────────────────────

  static const Map<String, String> categoryLabels = {
    'asset_purchase': 'Asset Purchase',
    'loan': 'Loan Decision',
    'business_expansion': 'Business Expansion',
    'investment': 'Investment',
    'financial_survival': 'Financial Survival',
    'other': 'Other',
  };

  static const Map<String, String> categoryIcons = {
    'asset_purchase': 'directions_bus',
    'loan': 'account_balance',
    'business_expansion': 'trending_up',
    'investment': 'show_chart',
    'financial_survival': 'shield',
    'other': 'lightbulb',
  };

  // ─── SCENARIO MANAGER ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getScenarios() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final data = await _client
          .from('decision_scenarios')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getScenarioById(String scenarioId) async {
    try {
      final data = await _client
          .from('decision_scenarios')
          .select()
          .eq('id', scenarioId)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<String?> createScenario({
    required String name,
    required String category,
    String? description,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final result = await _client
          .from('decision_scenarios')
          .insert({
            'user_id': userId,
            'name': name,
            'category': category,
            'description': description ?? '',
            'status': 'draft',
          })
          .select('id')
          .single();
      return result['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateScenario(
    String scenarioId, {
    String? name,
    String? description,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (status != null) updates['status'] = status;
      await _client
          .from('decision_scenarios')
          .update(updates)
          .eq('id', scenarioId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteScenario(String scenarioId) async {
    try {
      await _client.from('decision_scenarios').delete().eq('id', scenarioId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── SCENARIO INPUTS ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getScenarioInputs(
    String scenarioId,
  ) async {
    try {
      final data = await _client
          .from('scenario_inputs')
          .select()
          .eq('scenario_id', scenarioId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveScenarioInputs(
    String scenarioId,
    List<Map<String, dynamic>> inputs,
  ) async {
    try {
      // Delete existing inputs for this scenario
      await _client
          .from('scenario_inputs')
          .delete()
          .eq('scenario_id', scenarioId);
      // Insert new inputs
      final rows = inputs
          .map(
            (inp) => {
              'scenario_id': scenarioId,
              'input_name': inp['input_name'],
              'input_value': inp['input_value'],
              'input_type': inp['input_type'] ?? 'amount',
            },
          )
          .toList();
      if (rows.isNotEmpty) {
        await _client.from('scenario_inputs').insert(rows);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── SIMULATION ENGINE ────────────────────────────────────────────────────

  /// Runs simulation for a given scenario and saves results
  Future<Map<String, dynamic>?> runSimulation(String scenarioId) async {
    try {
      final scenario = await getScenarioById(scenarioId);
      if (scenario == null) return null;

      final inputs = await getScenarioInputs(scenarioId);
      final inputMap = <String, double>{};
      for (final inp in inputs) {
        inputMap[inp['input_name'] as String] =
            (inp['input_value'] as num?)?.toDouble() ?? 0;
      }

      final category = scenario['category'] as String? ?? 'other';
      Map<String, dynamic> result;

      switch (category) {
        case 'asset_purchase':
          result = _simulateAssetPurchase(inputMap);
          break;
        case 'loan':
          result = _simulateLoan(inputMap);
          break;
        case 'business_expansion':
          result = _simulateBusinessExpansion(inputMap);
          break;
        case 'investment':
          result = _simulateInvestment(inputMap);
          break;
        case 'financial_survival':
          result = _simulateFinancialSurvival(inputMap);
          break;
        default:
          result = _simulateGeneric(inputMap);
      }

      // Save simulation result
      await _client.from('simulation_results').upsert({
        'scenario_id': scenarioId,
        'cash_flow_effect': result['cash_flow_effect'],
        'networth_effect': result['networth_effect'],
        'risk_score': result['risk_score'],
        'success_probability': result['success_probability'],
        'opportunity_score': result['opportunity_score'],
        'affordability_score': result['affordability_score'],
        'final_decision_score': result['final_decision_score'],
        'result_summary': result['result_summary'],
        'timeline_months': result['timeline_months'],
        'break_even_months': result['break_even_months'],
        'monthly_impact': result['monthly_impact'],
      });

      // Update scenario status
      await updateScenario(scenarioId, status: 'simulated');

      return result;
    } catch (e) {
      return null;
    }
  }

  // ─── SCENARIO 1: ASSET PURCHASE ──────────────────────────────────────────

  Map<String, dynamic> _simulateAssetPurchase(Map<String, double> inputs) {
    final price = inputs['Purchase Price'] ?? 0;
    final loanAmount = inputs['Loan Amount'] ?? 0;
    final interestRate = (inputs['Interest Rate (%)'] ?? 18) / 100 / 12;
    final durationMonths = (inputs['Loan Duration (months)'] ?? 36).toInt();
    final monthlyIncome = inputs['Expected Monthly Income'] ?? 0;
    final operatingCosts = inputs['Monthly Operating Costs'] ?? 0;
    final downPayment = inputs['Down Payment'] ?? (price - loanAmount);

    // Monthly loan repayment (PMT formula)
    double monthlyRepayment = 0;
    if (loanAmount > 0 && interestRate > 0) {
      monthlyRepayment =
          loanAmount *
          (interestRate * _pow(1 + interestRate, durationMonths.toDouble())) /
          (_pow(1 + interestRate, durationMonths.toDouble()) - 1);
    }

    final monthlyNetIncome = monthlyIncome - operatingCosts - monthlyRepayment;
    final cashFlowEffect = -downPayment;
    final networthEffect = price - loanAmount;

    // Break-even
    int breakEvenMonths = 0;
    if (monthlyNetIncome > 0) {
      breakEvenMonths = (downPayment / monthlyNetIncome).ceil();
    }

    // Scores
    final opportunityScore = _clamp(
      ((monthlyIncome / (price / 60)) * 50).round(),
      0,
      100,
    );
    final riskScore = _clamp(
      ((loanAmount / (price == 0 ? 1 : price)) * 80).round(),
      0,
      100,
    );
    final affordabilityScore = _clamp(
      (monthlyNetIncome > 0
          ? 70 + (monthlyNetIncome / 1000000 * 5).round()
          : 30),
      0,
      100,
    );
    final finalScore = _clamp(
      opportunityScore + affordabilityScore - riskScore,
      0,
      100,
    );
    final successProb = _clamp(finalScore + 10, 0, 100);

    return {
      'cash_flow_effect': cashFlowEffect,
      'networth_effect': networthEffect,
      'risk_score': riskScore,
      'success_probability': successProb,
      'opportunity_score': opportunityScore,
      'affordability_score': affordabilityScore,
      'final_decision_score': finalScore,
      'timeline_months': durationMonths,
      'break_even_months': breakEvenMonths,
      'monthly_impact': monthlyNetIncome,
      'monthly_repayment': monthlyRepayment,
      'result_summary':
          'Asset purchase simulation complete. Monthly net income after all costs: TSh ${_fmt(monthlyNetIncome)}. '
          'Break-even in $breakEvenMonths months. Initial cash outflow: TSh ${_fmt(downPayment.abs())}. '
          'Net worth impact: +TSh ${_fmt(networthEffect)}.',
    };
  }

  // ─── SCENARIO 2: LOAN DECISION ────────────────────────────────────────────

  Map<String, dynamic> _simulateLoan(Map<String, double> inputs) {
    final loanAmount = inputs['Loan Amount'] ?? 0;
    final interestRate = (inputs['Interest Rate (%)'] ?? 18) / 100 / 12;
    final durationMonths = (inputs['Loan Duration (months)'] ?? 36).toInt();
    final monthlyIncome = inputs['Monthly Income'] ?? 8000000;

    double monthlyRepayment = 0;
    if (loanAmount > 0 && interestRate > 0) {
      monthlyRepayment =
          loanAmount *
          (interestRate * _pow(1 + interestRate, durationMonths.toDouble())) /
          (_pow(1 + interestRate, durationMonths.toDouble()) - 1);
    }

    final totalRepayment = monthlyRepayment * durationMonths;
    final totalInterest = totalRepayment - loanAmount;
    final debtRatio = monthlyIncome > 0
        ? (monthlyRepayment / monthlyIncome * 100)
        : 100;

    final riskScore = _clamp(debtRatio.round(), 0, 100);
    final affordabilityScore = _clamp(100 - riskScore, 0, 100);
    final opportunityScore = 60;
    final finalScore = _clamp(
      opportunityScore + affordabilityScore - riskScore,
      0,
      100,
    );

    return {
      'cash_flow_effect': loanAmount,
      'networth_effect': -totalInterest,
      'risk_score': riskScore,
      'success_probability': _clamp(affordabilityScore, 0, 100),
      'opportunity_score': opportunityScore,
      'affordability_score': affordabilityScore,
      'final_decision_score': finalScore,
      'timeline_months': durationMonths,
      'break_even_months': durationMonths,
      'monthly_impact': -monthlyRepayment,
      'result_summary':
          'Loan simulation: Monthly repayment TSh ${_fmt(monthlyRepayment)}. '
          'Total repayment TSh ${_fmt(totalRepayment)} (interest: TSh ${_fmt(totalInterest)}). '
          'Debt-to-income ratio: ${debtRatio.toStringAsFixed(1)}%. '
          '${debtRatio < 35 ? "Loan is affordable." : "Loan creates significant cash pressure."}',
    };
  }

  // ─── SCENARIO 3: BUSINESS EXPANSION ──────────────────────────────────────

  Map<String, dynamic> _simulateBusinessExpansion(Map<String, double> inputs) {
    final expansionCost = inputs['Expansion Cost'] ?? 0;
    final revenueIncrease = inputs['Expected Revenue Increase'] ?? 0;
    final additionalExpenses = inputs['Additional Monthly Expenses'] ?? 0;
    final netMonthlyGain = revenueIncrease - additionalExpenses;

    int breakEvenMonths = 0;
    if (netMonthlyGain > 0) {
      breakEvenMonths = (expansionCost / netMonthlyGain).ceil();
    }

    final riskScore = _clamp(
      breakEvenMonths > 24
          ? 70
          : breakEvenMonths > 12
          ? 50
          : 30,
      0,
      100,
    );
    final opportunityScore = _clamp(
      (netMonthlyGain / (expansionCost == 0 ? 1 : expansionCost) * 1200 * 50)
          .round(),
      0,
      100,
    );
    final affordabilityScore = netMonthlyGain > 0 ? 70 : 30;
    final finalScore = _clamp(
      opportunityScore + affordabilityScore - riskScore,
      0,
      100,
    );

    return {
      'cash_flow_effect': -expansionCost,
      'networth_effect': netMonthlyGain * 24,
      'risk_score': riskScore,
      'success_probability': _clamp(finalScore + 5, 0, 100),
      'opportunity_score': _clamp(opportunityScore, 0, 100),
      'affordability_score': affordabilityScore,
      'final_decision_score': finalScore,
      'timeline_months': 24,
      'break_even_months': breakEvenMonths,
      'monthly_impact': netMonthlyGain,
      'result_summary':
          'Business expansion simulation: Net monthly gain TSh ${_fmt(netMonthlyGain)}. '
          'Break-even in $breakEvenMonths months. '
          'Initial investment: TSh ${_fmt(expansionCost)}. '
          '2-year projected net worth increase: TSh ${_fmt(netMonthlyGain * 24)}.',
    };
  }

  // ─── SCENARIO 4: INVESTMENT ───────────────────────────────────────────────

  Map<String, dynamic> _simulateInvestment(Map<String, double> inputs) {
    final amount = inputs['Investment Amount'] ?? 0;
    final annualReturn = (inputs['Expected Annual Return (%)'] ?? 10) / 100;
    final years = (inputs['Investment Period (years)'] ?? 5).toInt();
    final riskLevel = (inputs['Risk Level'] ?? 3).toInt();

    final futureValue = amount * _pow(1 + annualReturn, years.toDouble());
    final totalReturn = futureValue - amount;

    final riskScore = _clamp(riskLevel * 20, 0, 100);
    final opportunityScore = _clamp((annualReturn * 500).round(), 0, 100);
    final affordabilityScore = 70;
    final finalScore = _clamp(
      opportunityScore + affordabilityScore - riskScore,
      0,
      100,
    );

    return {
      'cash_flow_effect': -amount,
      'networth_effect': totalReturn,
      'risk_score': riskScore,
      'success_probability': _clamp(100 - riskScore, 0, 100),
      'opportunity_score': opportunityScore,
      'affordability_score': affordabilityScore,
      'final_decision_score': finalScore,
      'timeline_months': years * 12,
      'break_even_months': (12 / annualReturn).ceil(),
      'monthly_impact': totalReturn / (years * 12),
      'result_summary':
          'Investment simulation: TSh ${_fmt(amount)} invested at ${(annualReturn * 100).toStringAsFixed(1)}% annual return. '
          'Future value in $years years: TSh ${_fmt(futureValue)}. '
          'Total return: TSh ${_fmt(totalReturn)} (${(totalReturn / amount * 100).toStringAsFixed(1)}%).',
    };
  }

  // ─── SCENARIO 5: FINANCIAL SURVIVAL ──────────────────────────────────────

  Map<String, dynamic> _simulateFinancialSurvival(Map<String, double> inputs) {
    final savings = inputs['Current Savings'] ?? 0;
    final monthlyExpenses = inputs['Monthly Expenses'] ?? 0;
    final debtPayments = inputs['Monthly Debt Payments'] ?? 0;
    final totalMonthlyObligations = monthlyExpenses + debtPayments;

    int survivalMonths = 0;
    if (totalMonthlyObligations > 0) {
      survivalMonths = (savings / totalMonthlyObligations).floor();
    }

    final emergencyFundTarget = totalMonthlyObligations * 6;
    final riskScore = _clamp(
      survivalMonths < 3
          ? 90
          : survivalMonths < 6
          ? 60
          : 30,
      0,
      100,
    );

    return {
      'cash_flow_effect': 0,
      'networth_effect': 0,
      'risk_score': riskScore,
      'success_probability': _clamp(100 - riskScore, 0, 100),
      'opportunity_score': 50,
      'affordability_score': _clamp(survivalMonths * 10, 0, 100),
      'final_decision_score': _clamp(100 - riskScore, 0, 100),
      'timeline_months': survivalMonths,
      'break_even_months': 0,
      'monthly_impact': -totalMonthlyObligations,
      'result_summary':
          'Financial survival analysis: With TSh ${_fmt(savings)} in savings and TSh ${_fmt(totalMonthlyObligations)} monthly obligations, '
          'you can survive $survivalMonths months without income. '
          'Recommended emergency fund: TSh ${_fmt(emergencyFundTarget)} (6 months of expenses). '
          '${survivalMonths < 6 ? "URGENT: Build emergency fund immediately." : "Emergency fund is adequate."}',
    };
  }

  Map<String, dynamic> _simulateGeneric(Map<String, double> inputs) {
    return {
      'cash_flow_effect': 0,
      'networth_effect': 0,
      'risk_score': 50,
      'success_probability': 50,
      'opportunity_score': 50,
      'affordability_score': 50,
      'final_decision_score': 50,
      'timeline_months': 12,
      'break_even_months': 12,
      'monthly_impact': 0,
      'result_summary':
          'Generic simulation complete. Add specific inputs for detailed analysis.',
    };
  }

  // ─── SIMULATION RESULTS ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getSimulationResult(String scenarioId) async {
    try {
      final data = await _client
          .from('simulation_results')
          .select()
          .eq('scenario_id', scenarioId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  // ─── DECISION ANALYZER ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getRecommendation(String scenarioId) async {
    try {
      final data = await _client
          .from('decision_recommendations')
          .select()
          .eq('scenario_id', scenarioId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Generate AI recommendation using OpenAI via Lambda
  Future<String?> generateAiRecommendation({
    required String scenarioName,
    required String category,
    required Map<String, dynamic> simulationResult,
    required Map<String, double> inputs,
    String? userContext,
  }) async {
    try {
      final inputText = inputs.entries
          .map((e) => '- ${e.key}: TSh ${_fmt(e.value)}')
          .join('\n');

      final systemPrompt =
          '''You are the CNA Advanced Decision Engine — a financial decision intelligence system for Capital NEXUS AI.
Analyze financial decisions using the Decision Framework:
1. SITUATION: What is happening?
2. ANALYSIS: Why is it happening?
3. RISK: What could go wrong?
4. OPPORTUNITY: What can improve?
5. ACTION: What should the user do?

Always use TZS (Tanzanian Shilling) figures. Be specific, concise, and actionable.
Provide a structured recommendation in 4-5 sentences.''';

      final userMessage =
          '''Analyze this financial decision:

SCENARIO: $scenarioName
CATEGORY: ${categoryLabels[category] ?? category}

INPUTS:
$inputText

SIMULATION RESULTS:
- Cash Flow Effect: TSh ${_fmt((simulationResult['cash_flow_effect'] as num?)?.toDouble() ?? 0)}
- Net Worth Effect: TSh ${_fmt((simulationResult['networth_effect'] as num?)?.toDouble() ?? 0)}
- Risk Score: ${simulationResult['risk_score']}/100
- Success Probability: ${simulationResult['success_probability']}%
- Opportunity Score: ${simulationResult['opportunity_score']}/100
- Affordability Score: ${simulationResult['affordability_score']}/100
- Final Decision Score: ${simulationResult['final_decision_score']}/100
- Monthly Impact: TSh ${_fmt((simulationResult['monthly_impact'] as num?)?.toDouble() ?? 0)}
- Break-even: ${simulationResult['break_even_months']} months

${userContext != null ? 'USER CONTEXT:\n$userContext' : ''}

Provide a clear PROCEED / PROCEED WITH CAUTION / DO NOT PROCEED recommendation with reasoning.''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_completion_tokens': 500,
        }),
      );
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      final content =
          responseBody['choices']?[0]?['message']?['content'] as String?;
      return content;
    } catch (e) {
      return null;
    }
  }

  /// Save AI-generated recommendation to database
  Future<bool> saveRecommendation({
    required String scenarioId,
    required String recommendation,
    String? reasoning,
    String riskLevel = 'medium',
    int confidenceScore = 70,
  }) async {
    try {
      await _client.from('decision_recommendations').upsert({
        'scenario_id': scenarioId,
        'recommendation': recommendation,
        'reasoning': reasoning ?? '',
        'risk_level': riskLevel,
        'confidence_score': confidenceScore,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── SCENARIO COMPARISON ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> compareScenarios(
    List<String> scenarioIds,
  ) async {
    final results = <Map<String, dynamic>>[];
    for (final id in scenarioIds) {
      final scenario = await getScenarioById(id);
      final simResult = await getSimulationResult(id);
      if (scenario != null) {
        results.add({'scenario': scenario, 'simulation': simResult});
      }
    }
    return results;
  }

  // ─── USER FINANCIAL CONTEXT ───────────────────────────────────────────────

  Future<String> getUserFinancialContext() async {
    final userId = _userId;
    if (userId == null) return '';
    try {
      final results = await Future.wait([
        _client
            .from('financial_accounts')
            .select('current_balance')
            .eq('user_id', userId)
            .eq('is_active', true),
        _client
            .from('user_loans')
            .select('outstanding_balance, monthly_payment')
            .eq('user_id', userId)
            .eq('loan_status', 'active'),
        _client
            .from('financial_transactions')
            .select('amount, transaction_type')
            .eq('user_id', userId)
            .gte(
              'transaction_date',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String(),
            ),
      ]);

      final accounts = results[0] as List;
      final loans = results[1] as List;
      final transactions = results[2] as List;

      double totalCash = 0;
      for (final a in accounts) {
        totalCash += (a['current_balance'] as num?)?.toDouble() ?? 0;
      }

      double totalDebt = 0;
      double monthlyDebtPayments = 0;
      for (final l in loans) {
        totalDebt += (l['outstanding_balance'] as num?)?.toDouble() ?? 0;
        monthlyDebtPayments += (l['monthly_payment'] as num?)?.toDouble() ?? 0;
      }

      double monthlyIncome = 0;
      double monthlyExpenses = 0;
      for (final t in transactions) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0;
        if (t['transaction_type'] == 'income') monthlyIncome += amt;
        if (t['transaction_type'] == 'expense') monthlyExpenses += amt;
      }

      return 'Available Cash: TSh ${_fmt(totalCash)}, '
          'Total Debt: TSh ${_fmt(totalDebt)}, '
          'Monthly Income: TSh ${_fmt(monthlyIncome)}, '
          'Monthly Expenses: TSh ${_fmt(monthlyExpenses)}, '
          'Monthly Debt Payments: TSh ${_fmt(monthlyDebtPayments)}';
    } catch (e) {
      return '';
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  double _pow(double base, double exp) {
    double result = 1;
    for (int i = 0; i < exp.round(); i++) {
      result *= base;
    }
    return result;
  }

  int _clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  String _fmt(double value) {
    if (value.abs() >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String formatCurrency(double value) {
    final absValue = value.abs();
    final prefix = value < 0 ? '-' : '';
    if (absValue >= 1000000000) {
      return '${prefix}TSh ${(absValue / 1000000000).toStringAsFixed(2)}B';
    } else if (absValue >= 1000000) {
      return '${prefix}TSh ${(absValue / 1000000).toStringAsFixed(1)}M';
    } else if (absValue >= 1000) {
      return '${prefix}TSh ${(absValue / 1000).toStringAsFixed(0)}K';
    }
    return '${prefix}TSh ${absValue.toStringAsFixed(0)}';
  }

  String getRiskLabel(int score) {
    if (score >= 70) return 'High Risk';
    if (score >= 40) return 'Medium Risk';
    return 'Low Risk';
  }

  String getDecisionLabel(int score) {
    if (score >= 70) return 'PROCEED';
    if (score >= 45) return 'PROCEED WITH CAUTION';
    return 'DO NOT PROCEED';
  }
}

// ─── RIVERPOD PROVIDERS ───────────────────────────────────────────────────

final decisionScenariosProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return DecisionEngineService.instance.getScenarios();
});

final scenarioDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
      return DecisionEngineService.instance.getScenarioById(id);
    });

final simulationResultProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      scenarioId,
    ) async {
      return DecisionEngineService.instance.getSimulationResult(scenarioId);
    });

final decisionRecommendationProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      scenarioId,
    ) async {
      return DecisionEngineService.instance.getRecommendation(scenarioId);
    });
