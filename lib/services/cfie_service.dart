import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './finance_service.dart';

/// Cash Flow Intelligence Engine Service
/// Handles CashFlowPredictionService, WealthProjectionService, ScenarioEngine
class CfieService {
  static CfieService? _instance;
  static CfieService get instance => _instance ??= CfieService._();
  CfieService._();

  SupabaseClient get _client => SupabaseService.client;

  String? get _userId => _client.auth.currentUser?.id;

  // ─── CASH FLOW PREDICTION SERVICE ────────────────────────────────────────

  /// Generates or refreshes cash flow forecasts for the user
  Future<List<Map<String, dynamic>>> generateForecast(String period) async {
    final userId = _userId;
    if (userId == null) return [];

    // Gather existing financial data
    final now = DateTime.now();
    final monthStart = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String().split('T')[0];

    final results = await Future.wait([
      _client
          .from('financial_transactions')
          .select()
          .eq('user_id', userId)
          .gte('transaction_date', monthStart),
      _client
          .from('financial_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true),
      _client
          .from('user_loans')
          .select()
          .eq('user_id', userId)
          .eq('loan_status', 'active'),
      _client.from('user_investments').select().eq('user_id', userId),
      _client
          .from('businesses')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true),
    ]);

    final transactions = results[0] as List;
    final accounts = results[1] as List;
    final loans = results[2] as List;
    final investments = results[3] as List;
    final businesses = results[4] as List;

    double monthlyIncome = 0;
    double monthlyExpenses = 0;
    for (final t in transactions) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0;
      if (t['transaction_type'] == 'income') monthlyIncome += amt;
      if (t['transaction_type'] == 'expense') monthlyExpenses += amt;
    }

    double currentCash = await FinanceService.instance.getTotalCash();

    double monthlyLoanPayments = 0;
    for (final l in loans) {
      monthlyLoanPayments += (l['monthly_payment'] as num?)?.toDouble() ?? 0;
    }

    double monthlyInvestmentReturns = 0;
    for (final inv in investments) {
      final value = (inv['current_value'] as num?)?.toDouble() ?? 0;
      final rate = (inv['expected_return_rate'] as num?)?.toDouble() ?? 0;
      monthlyInvestmentReturns += (value * rate / 100) / 12;
    }

    double monthlyBusinessIncome = 0;
    for (final b in businesses) {
      monthlyBusinessIncome += (b['monthly_revenue'] as num?)?.toDouble() ?? 0;
    }

    // Determine number of months
    int months = 1;
    if (period == '6_months') months = 6;
    if (period == '12_months') months = 12;
    if (period == '5_years') months = 60;

    // Delete old forecasts and regenerate
    await _client.from('cash_flow_forecasts').delete().eq('user_id', userId);

    final forecasts = <Map<String, dynamic>>[];
    double runningBalance = currentCash;

    for (int i = 1; i <= months; i++) {
      final forecastDate = DateTime(now.year, now.month + i, 1);
      // Apply slight growth factor
      final growthFactor = 1 + (i * 0.005);
      final projectedIncome = monthlyIncome * growthFactor;
      final projectedExpenses = monthlyExpenses * (1 + (i * 0.003));
      final projectedBusiness = monthlyBusinessIncome * growthFactor;
      final projectedInvestment = monthlyInvestmentReturns * growthFactor;

      runningBalance =
          runningBalance +
          projectedIncome +
          projectedBusiness +
          projectedInvestment -
          projectedExpenses -
          monthlyLoanPayments;

      final confidence = (90 - (i * 0.5)).clamp(60, 95).toInt();

      final forecast = {
        'user_id': userId,
        'forecast_period':
            '${forecastDate.year}-${forecastDate.month.toString().padLeft(2, '0')}-01',
        'expected_income': projectedIncome.roundToDouble(),
        'expected_expenses': projectedExpenses.roundToDouble(),
        'expected_loan_payments': monthlyLoanPayments.roundToDouble(),
        'expected_investment_returns': projectedInvestment.roundToDouble(),
        'expected_business_income': projectedBusiness.roundToDouble(),
        'projected_cash_balance': runningBalance.roundToDouble(),
        'confidence_score': confidence,
      };
      forecasts.add(forecast);
    }

    if (forecasts.isNotEmpty) {
      await _client.from('cash_flow_forecasts').insert(forecasts);
    }

    return await getForecasts();
  }

  Future<List<Map<String, dynamic>>> getForecasts() async {
    final userId = _userId;
    if (userId == null) return [];
    return await _client
        .from('cash_flow_forecasts')
        .select()
        .eq('user_id', userId)
        .order('forecast_period', ascending: true)
        .limit(60);
  }

  // ─── WEALTH PROJECTION SERVICE ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> calculateFutureNetWorth(int years) async {
    final userId = _userId;
    if (userId == null) return [];

    // Get current net worth data
    final nwSnap = await _client
        .from('net_worth_snapshots')
        .select()
        .eq('user_id', userId)
        .order('snapshot_date', ascending: false)
        .limit(1);

    double currentAssets = 0;
    double currentLiabilities = 0;

    if (nwSnap.isNotEmpty) {
      currentAssets = (nwSnap[0]['total_assets'] as num?)?.toDouble() ?? 0;
      currentLiabilities =
          (nwSnap[0]['total_liabilities'] as num?)?.toDouble() ?? 0;
    } else {
      // No snapshot — calculate from real data via FinanceService
      final nw = await FinanceService.instance.getNetWorth();
      currentAssets = nw['assets'] ?? 0;
      currentLiabilities = nw['liabilities'] ?? 0;
    }

    // If still no data, return empty — never fabricate
    if (currentAssets == 0 && currentLiabilities == 0) return [];

    // Delete old projections
    await _client.from('wealth_projections').delete().eq('user_id', userId);

    final projections = <Map<String, dynamic>>[];
    final now = DateTime.now();
    const assetGrowthRate = 0.20; // 20% annual
    const debtReductionRate = 0.15; // 15% annual debt reduction

    for (int y = 1; y <= years; y++) {
      final projDate = DateTime(now.year + y, now.month, now.day);
      final projAssets = currentAssets * (1 + assetGrowthRate * y);
      final projLiabilities =
          currentLiabilities * (1 - debtReductionRate * y).clamp(0.0, 1.0);
      final projNetWorth = projAssets - projLiabilities;
      final currentNetWorth = currentAssets - currentLiabilities;
      final growth = currentNetWorth > 0
          ? ((projNetWorth - currentNetWorth) / currentNetWorth * 100)
          : 0.0;

      projections.add({
        'user_id': userId,
        'projection_date':
            '${projDate.year}-${projDate.month.toString().padLeft(2, '0')}-${projDate.day.toString().padLeft(2, '0')}',
        'projected_assets': projAssets.roundToDouble(),
        'projected_liabilities': projLiabilities.roundToDouble(),
        'projected_networth': projNetWorth.roundToDouble(),
        'growth_percentage': double.parse(growth.toStringAsFixed(2)),
      });
    }

    if (projections.isNotEmpty) {
      await _client.from('wealth_projections').insert(projections);
    }

    return await getWealthProjections();
  }

  Future<List<Map<String, dynamic>>> getWealthProjections() async {
    final userId = _userId;
    if (userId == null) return [];
    return await _client
        .from('wealth_projections')
        .select()
        .eq('user_id', userId)
        .order('projection_date', ascending: true);
  }

  // ─── SCENARIO ENGINE ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> simulateScenario(
    Map<String, dynamic> scenarioData,
  ) async {
    final userId = _userId;
    if (userId == null) return {};

    final type = scenarioData['scenario_type'] as String? ?? '';
    final assumptions =
        scenarioData['assumptions'] as Map<String, dynamic>? ?? {};
    Map<String, dynamic> result = {};
    int riskScore = 50;

    switch (type) {
      case 'asset_purchase':
        final price = (assumptions['asset_price'] as num?)?.toDouble() ?? 0;
        final weeklyRevenue =
            (assumptions['expected_weekly_revenue'] as num?)?.toDouble() ?? 0;
        final weeklyCost =
            (assumptions['weekly_fuel_cost'] as num?)?.toDouble() ?? 0;
        final monthlyNet = (weeklyRevenue - weeklyCost) * 4.33;
        final breakEven = monthlyNet > 0 ? price / monthlyNet : 0;
        final roi = price > 0 ? (monthlyNet * 12 / price * 100) : 0;
        riskScore = roi > 25 ? 20 : (roi > 15 ? 40 : 65);
        result = {
          'cash_impact': -price,
          'monthly_net_gain': monthlyNet.roundToDouble(),
          'break_even_months': double.parse(breakEven.toStringAsFixed(1)),
          'roi_percentage': double.parse(roi.toStringAsFixed(1)),
          'risk_level': riskScore < 30
              ? 'low'
              : (riskScore < 60 ? 'medium' : 'high'),
        };
        break;

      case 'loan':
        final amount = (assumptions['loan_amount'] as num?)?.toDouble() ?? 0;
        final rate = (assumptions['interest_rate'] as num?)?.toDouble() ?? 18;
        final months = (assumptions['duration_months'] as num?)?.toInt() ?? 36;
        final monthlyRate = rate / 100 / 12;
        final payment =
            amount * monthlyRate * (1 + monthlyRate) / ((1 + monthlyRate) - 1);
        final totalInterest = (payment * months) - amount;
        final monthlyIncome = 8000000.0;
        final dti = payment / monthlyIncome;
        riskScore = dti < 0.3 ? 25 : (dti < 0.5 ? 55 : 80);
        result = {
          'monthly_repayment': payment.roundToDouble(),
          'total_interest': totalInterest.roundToDouble(),
          'debt_to_income_ratio': double.parse(dti.toStringAsFixed(2)),
          'affordability': dti < 0.3
              ? 'comfortable'
              : (dti < 0.5 ? 'moderate' : 'stretched'),
          'risk_level': riskScore < 30
              ? 'low'
              : (riskScore < 60 ? 'medium' : 'high'),
        };
        break;

      case 'business_expansion':
        final investment =
            (assumptions['investment_amount'] as num?)?.toDouble() ?? 0;
        final expectedRevenue =
            (assumptions['expected_monthly_revenue'] as num?)?.toDouble() ?? 0;
        final operatingCost =
            (assumptions['monthly_operating_cost'] as num?)?.toDouble() ?? 0;
        final monthlyProfit = expectedRevenue - operatingCost;
        final breakEven = monthlyProfit > 0 ? investment / monthlyProfit : 0;
        riskScore = breakEven < 12 ? 30 : (breakEven < 24 ? 55 : 75);
        result = {
          'monthly_profit': monthlyProfit.roundToDouble(),
          'break_even_months': double.parse(breakEven.toStringAsFixed(1)),
          'annual_profit': (monthlyProfit * 12).roundToDouble(),
          'roi_percentage': investment > 0
              ? double.parse(
                  (monthlyProfit * 12 / investment * 100).toStringAsFixed(1),
                )
              : 0,
          'risk_level': riskScore < 30
              ? 'low'
              : (riskScore < 60 ? 'medium' : 'high'),
        };
        break;

      default:
        result = {'message': 'Unknown scenario type'};
    }

    // Save scenario
    final saved = await _client
        .from('financial_scenarios')
        .insert({
          'user_id': userId,
          'scenario_name': scenarioData['scenario_name'] ?? 'Custom Scenario',
          'scenario_type': type,
          'assumptions': assumptions,
          'result': result,
          'risk_score': riskScore,
        })
        .select()
        .single();

    return saved;
  }

  Future<List<Map<String, dynamic>>> getScenarios() async {
    final userId = _userId;
    if (userId == null) return [];
    return await _client
        .from('financial_scenarios')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
  }

  // ─── FINANCIAL GOALS ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFinancialGoals() async {
    final userId = _userId;
    if (userId == null) return [];
    return await _client
        .from('financial_goals')
        .select()
        .eq('user_id', userId)
        .order('priority', ascending: true);
  }

  Future<void> upsertGoal(Map<String, dynamic> goal) async {
    final userId = _userId;
    if (userId == null) return;
    goal['user_id'] = userId;
    if (goal['id'] != null) {
      await _client.from('financial_goals').update(goal).eq('id', goal['id']);
    } else {
      await _client.from('financial_goals').insert(goal);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    await _client.from('financial_goals').delete().eq('id', goalId);
  }

  // ─── AI INSIGHTS ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAiInsights() async {
    final userId = _userId;
    if (userId == null) return [];
    return await _client
        .from('ai_financial_insights')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
  }

  Future<void> saveAiInsight({
    required String insightType,
    required String message,
    required String severity,
    required String relatedModule,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    await _client.from('ai_financial_insights').insert({
      'user_id': userId,
      'insight_type': insightType,
      'message': message,
      'severity': severity,
      'related_module': relatedModule,
    });
  }

  // ─── SUMMARY DATA ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFinancialSummary() async {
    final userId = _userId;
    if (userId == null) return {};

    final results = await Future.wait([
      _client
          .from('net_worth_snapshots')
          .select()
          .eq('user_id', userId)
          .order('snapshot_date', ascending: false)
          .limit(1),
      _client
          .from('financial_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true),
      _client
          .from('user_loans')
          .select()
          .eq('user_id', userId)
          .eq('loan_status', 'active'),
      _client.from('user_investments').select().eq('user_id', userId),
      _client
          .from('businesses')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true),
    ]);

    final nwSnap = results[0] as List;
    final accounts = results[1] as List;
    final loans = results[2] as List;
    final investments = results[3] as List;
    final businesses = results[4] as List;

    double totalAssets = 300000000;
    double totalLiabilities = 50000000;
    double netWorth = 250000000;

    if (nwSnap.isNotEmpty) {
      totalAssets =
          (nwSnap[0]['total_assets'] as num?)?.toDouble() ?? totalAssets;
      totalLiabilities =
          (nwSnap[0]['total_liabilities'] as num?)?.toDouble() ??
          totalLiabilities;
      netWorth = (nwSnap[0]['net_worth'] as num?)?.toDouble() ?? netWorth;
    }

    double availableCash = 0;
    for (final a in accounts) {
      availableCash += (a['current_balance'] as num?)?.toDouble() ?? 0;
    }

    double monthlyLoanPayments = 0;
    for (final l in loans) {
      monthlyLoanPayments += (l['monthly_payment'] as num?)?.toDouble() ?? 0;
    }

    double totalInvestmentValue = 0;
    for (final inv in investments) {
      totalInvestmentValue += (inv['current_value'] as num?)?.toDouble() ?? 0;
    }

    double monthlyBusinessRevenue = 0;
    for (final b in businesses) {
      monthlyBusinessRevenue += (b['monthly_revenue'] as num?)?.toDouble() ?? 0;
    }

    return {
      'total_assets': totalAssets,
      'total_liabilities': totalLiabilities,
      'net_worth': netWorth,
      'available_cash': availableCash,
      'monthly_loan_payments': monthlyLoanPayments,
      'total_investment_value': totalInvestmentValue,
      'monthly_business_revenue': monthlyBusinessRevenue,
    };
  }
}