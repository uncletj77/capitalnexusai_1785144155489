import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/app_export.dart';
import '../../services/cfie_service.dart';
import '../../widgets/cna_shared_components.dart';
import './widgets/ai_insight_panel_widget.dart';
import './widgets/cash_flow_chart_widget.dart';
import './widgets/financial_forecast_card_widget.dart';
import './widgets/scenario_simulator_widget.dart';
import './widgets/wealth_projection_graph_widget.dart';

class FuturePlanningScreen extends ConsumerStatefulWidget {
  const FuturePlanningScreen({super.key});

  @override
  ConsumerState<FuturePlanningScreen> createState() =>
      _FuturePlanningScreenState();
}

class _FuturePlanningScreenState extends ConsumerState<FuturePlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isGeneratingAI = false;
  String _selectedPeriod = '6_months';

  List<Map<String, dynamic>> _forecasts = [];
  List<Map<String, dynamic>> _projections = [];
  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _insights = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        CfieService.instance.getForecasts(),
        CfieService.instance.getWealthProjections(),
        CfieService.instance.getFinancialGoals(),
        CfieService.instance.getAiInsights(),
        CfieService.instance.getFinancialSummary(),
      ]);
      setState(() {
        _forecasts = results[0] as List<Map<String, dynamic>>;
        _projections = results[1] as List<Map<String, dynamic>>;
        _goals = results[2] as List<Map<String, dynamic>>;
        _insights = results[3] as List<Map<String, dynamic>>;
        _summary = results[4] as Map<String, dynamic>;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateForecast() async {
    setState(() => _isGenerating = true);
    try {
      final forecasts = await CfieService.instance.generateForecast(
        _selectedPeriod,
      );
      final projections = await CfieService.instance.calculateFutureNetWorth(5);
      setState(() {
        _forecasts = forecasts;
        _projections = projections;
      });
      Fluttertoast.showToast(
        msg: 'Forecast generated successfully!',
        backgroundColor: AppTheme.success,
      );
    } catch (_) {
      Fluttertoast.showToast(
        msg: 'Failed to generate forecast',
        backgroundColor: AppTheme.error,
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateAIInsights() async {
    setState(() => _isGeneratingAI = true);
    try {
      final summary = await CfieService.instance.getFinancialSummary();
      final netWorth = (summary['net_worth'] as num?)?.toDouble() ?? 0;
      final assets = (summary['total_assets'] as num?)?.toDouble() ?? 0;
      final liabilities =
          (summary['total_liabilities'] as num?)?.toDouble() ?? 0;
      final cash = (summary['available_cash'] as num?)?.toDouble() ?? 0;
      final loanPayments =
          (summary['monthly_loan_payments'] as num?)?.toDouble() ?? 0;
      final businessRevenue =
          (summary['monthly_business_revenue'] as num?)?.toDouble() ?? 0;

      final insights = [
        {
          'type': 'liquidity',
          'message':
              'Available cash TZS ${(cash / 1000000).toStringAsFixed(1)}M vs liabilities TZS ${(liabilities / 1000000).toStringAsFixed(1)}M.',
          'severity': cash > liabilities * 0.1 ? 'positive' : 'warning',
        },
        {
          'type': 'debt_pressure',
          'message':
              'Monthly loan payments TZS ${(loanPayments / 1000000).toStringAsFixed(1)}M relative to revenue.',
          'severity': loanPayments < businessRevenue * 0.3
              ? 'positive'
              : 'critical',
        },
        {
          'type': 'asset_productivity',
          'message':
              'Total assets TZS ${(assets / 1000000).toStringAsFixed(1)}M generating revenue TZS ${(businessRevenue / 1000000).toStringAsFixed(1)}M/mo.',
          'severity': 'opportunity',
        },
        {
          'type': 'growth_opportunity',
          'message':
              'Net worth TZS ${(netWorth / 1000000).toStringAsFixed(1)}M. Consider reinvesting surplus cash.',
          'severity': 'opportunity',
        },
      ];

      for (final item in insights) {
        await CfieService.instance.saveAiInsight(
          insightType: item['type'] ?? 'general',
          message: item['message'] ?? '',
          severity: item['severity'] ?? 'positive',
          relatedModule: 'cfie',
        );
      }
      final newInsights = await CfieService.instance.getAiInsights();
      setState(() => _insights = newInsights);
      Fluttertoast.showToast(
        msg: 'AI insights generated!',
        backgroundColor: AppTheme.success,
      );
    } catch (_) {
      Fluttertoast.showToast(
        msg: 'Failed to generate AI insights',
        backgroundColor: AppTheme.error,
      );
    } finally {
      setState(() => _isGeneratingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A5F7A), Color(0xFF0A3344)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.timeline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Future Planning',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Cash Flow Intelligence Engine',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _summaryRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
              isScrollable: true,
              tabs: const [
                Tab(text: 'Cash Flow'),
                Tab(text: 'Wealth'),
                Tab(text: 'Scenarios'),
                Tab(text: 'Goals'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const CnaLoadingState(message: 'Loading forecasts...')
            : TabBarView(
                controller: _tabController,
                children: [
                  _cashFlowTab(),
                  _wealthTab(),
                  _scenariosTab(),
                  _goalsTab(),
                ],
              ),
      ),
    );
  }

  Widget _summaryRow() {
    final netWorth =
        ((_summary['net_worth'] as num?)?.toDouble() ?? 0) / 1000000;
    final cash =
        ((_summary['available_cash'] as num?)?.toDouble() ?? 0) / 1000000;
    return Row(
      children: [
        _summaryChip('Net Worth', 'TZS ${netWorth.toStringAsFixed(0)}M'),
        const SizedBox(width: 16),
        _summaryChip('Cash', 'TZS ${cash.toStringAsFixed(1)}M'),
        const SizedBox(width: 16),
        _summaryChip('Forecasts', '${_forecasts.length}'),
      ],
    );
  }

  Widget _summaryChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: Colors.white54),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _cashFlowTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector + Generate button
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.outlineLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.onSurfaceLight,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '1_month',
                            child: Text('Next Month'),
                          ),
                          DropdownMenuItem(
                            value: '6_months',
                            child: Text('6 Months'),
                          ),
                          DropdownMenuItem(
                            value: '12_months',
                            child: Text('12 Months'),
                          ),
                          DropdownMenuItem(
                            value: '5_years',
                            child: Text('5 Years'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedPeriod = v ?? '6_months'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateForecast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_graph, size: 16),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Forecast cards horizontal scroll
            if (_forecasts.isNotEmpty) ...[
              Text(
                'Monthly Forecasts',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 175,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _forecasts.length,
                  itemBuilder: (ctx, i) => FinancialForecastCardWidget(
                    forecast: _forecasts[i],
                    isFirst: i == 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            CashFlowChartWidget(forecasts: _forecasts),
            const SizedBox(height: 16),
            // AI Insights
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isGeneratingAI ? null : _generateAIInsights,
                  icon: _isGeneratingAI
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.psychology, size: 16),
                  label: Text(
                    _isGeneratingAI ? 'Analyzing...' : 'Refresh AI',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AiInsightPanelWidget(
              insights: _insights,
              isLoading: _isGeneratingAI,
            ),
          ],
        ),
      ),
    );
  }

  Widget _wealthTab() {
    final currentNW = (_summary['net_worth'] as num?)?.toDouble() ?? 250000000;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_projections.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Generate a forecast first to see wealth projections.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isGenerating ? null : _generateForecast,
                      child: Text(
                        'Generate',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              WealthProjectionGraphWidget(
                projections: _projections,
                currentNetWorth: currentNW,
              ),
              const SizedBox(height: 16),
              Text(
                'Year-by-Year Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 10),
              ..._projections.map((p) => _projectionRow(p, currentNW)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _projectionRow(Map<String, dynamic> p, double currentNW) {
    final nw = (p['projected_networth'] as num?)?.toDouble() ?? 0;
    final assets = (p['projected_assets'] as num?)?.toDouble() ?? 0;
    final liabilities = (p['projected_liabilities'] as num?)?.toDouble() ?? 0;
    final growth = (p['growth_percentage'] as num?)?.toDouble() ?? 0;
    final date = p['projection_date'] as String? ?? '';
    final year = date.isNotEmpty ? date.split('-')[0] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                year,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TZS ${(nw / 1000000).toStringAsFixed(0)}M Net Worth',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  'Assets: TZS ${(assets / 1000000).toStringAsFixed(0)}M  •  Debt: TZS ${(liabilities / 1000000).toStringAsFixed(0)}M',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${growth.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scenariosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: const ScenarioSimulatorWidget(),
    );
  }

  Widget _goalsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Goals',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                IconButton(
                  onPressed: _showAddGoalDialog,
                  icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_goals.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineLight),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        size: 40,
                        color: AppTheme.mutedLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No goals yet. Tap + to add your first goal.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.mutedLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._goals.map((g) => _goalCard(g)),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(Map<String, dynamic> goal) {
    final target = (goal['target_amount'] as num?)?.toDouble() ?? 1;
    final current = (goal['current_amount'] as num?)?.toDouble() ?? 0;
    final progress = (current / target).clamp(0.0, 1.0);
    final priority = goal['priority'] as String? ?? 'medium';
    final status = goal['goal_status'] as String? ?? 'active';

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = AppTheme.error;
        break;
      case 'medium':
        priorityColor = AppTheme.warning;
        break;
      default:
        priorityColor = AppTheme.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal['goal_name'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TZS ${(current / 1000000).toStringAsFixed(1)}M / TZS ${(target / 1000000).toStringAsFixed(1)}M',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.mutedLight,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.outlineLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.success : AppTheme.primary,
              ),
              minHeight: 6,
            ),
          ),
          if (goal['target_date'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Target: ${goal['target_date']}',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.mutedLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final currentCtrl = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Add Financial Goal',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Goal Name',
                    labelStyle: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount (TZS)',
                    labelStyle: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Current Amount (TZS)',
                    labelStyle: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    labelStyle: GoogleFonts.inter(fontSize: 13),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => priority = v ?? 'medium'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                await CfieService.instance.upsertGoal({
                  'goal_name': nameCtrl.text,
                  'target_amount': double.tryParse(targetCtrl.text) ?? 0,
                  'current_amount': double.tryParse(currentCtrl.text) ?? 0,
                  'priority': priority,
                  'goal_status': 'active',
                });
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _parseJsonArray(String jsonStr) {
    try {
      final items = <Map<String, dynamic>>[];
      final pattern = RegExp(r'\{[^{}]+\}');
      for (final match in pattern.allMatches(jsonStr)) {
        final obj = match.group(0) ?? '';
        final typeMatch = RegExp(r'"type"\s*:\s*"([^"]+)"').firstMatch(obj);
        final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(obj);
        final sevMatch = RegExp(r'"severity"\s*:\s*"([^"]+)"').firstMatch(obj);
        if (typeMatch != null && msgMatch != null) {
          items.add({
            'type': typeMatch.group(1) ?? 'general',
            'message': msgMatch.group(1) ?? '',
            'severity': sevMatch?.group(1) ?? 'positive',
          });
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }
}
