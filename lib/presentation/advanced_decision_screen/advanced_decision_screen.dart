import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/decision_engine_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/ai_decision_card_widget.dart';
import './widgets/comparison_matrix_widget.dart';
import './widgets/scenario_builder_widget.dart';
import './widgets/simulation_dashboard_widget.dart';

class AdvancedDecisionScreen extends ConsumerStatefulWidget {
  const AdvancedDecisionScreen({super.key});

  @override
  ConsumerState<AdvancedDecisionScreen> createState() =>
      _AdvancedDecisionScreenState();
}

class _AdvancedDecisionScreenState extends ConsumerState<AdvancedDecisionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _selectedScenario;
  int _mainTabIndex = 0; // 0=Scenarios, 1=Builder, 2=Compare

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _mainTabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScenariosTab(),
                _buildBuilderTab(),
                _buildCompareTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceLight,
      elevation: 0,
      leading: IconButton(
        icon: const CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.onSurfaceLight,
          size: 22,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'psychology_alt',
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Decision Engine',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              Text(
                'AI-Powered Strategic Planning',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const CustomIconWidget(
            iconName: 'add_chart',
            color: AppTheme.primary,
            size: 22,
          ),
          onPressed: () => _tabController.animateTo(1),
          tooltip: 'New Scenario',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.outlineLight),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.mutedLight,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
        tabs: const [
          Tab(text: 'Scenarios'),
          Tab(text: 'New Scenario'),
          Tab(text: 'Compare'),
        ],
      ),
    );
  }

  // ─── TAB 1: SCENARIOS LIST ────────────────────────────────────────────────

  Widget _buildScenariosTab() {
    final scenariosAsync = ref.watch(decisionScenariosProvider);

    return scenariosAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => _buildErrorState(),
      data: (scenarios) {
        if (scenarios.isEmpty) return _buildEmptyScenarios();
        return _buildScenariosList(scenarios);
      },
    );
  }

  Widget _buildEmptyScenarios() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'psychology_alt',
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Advanced Decision Engine',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Test financial decisions before making them. Simulate outcomes, analyze risks, and get AI recommendations.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.mutedLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildScenarioTemplateCards(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomIconWidget(
                  iconName: 'add',
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Create First Scenario',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildScenarioTemplateCards() {
    final templates = [
      {
        'label': 'Asset Purchase',
        'icon': 'directions_bus',
        'color': AppTheme.primary,
        'example': 'Buy a transport vehicle',
      },
      {
        'label': 'Loan Decision',
        'icon': 'account_balance',
        'color': const Color(0xFF10B981),
        'example': 'Evaluate a bank loan',
      },
      {
        'label': 'Investment',
        'icon': 'show_chart',
        'color': const Color(0xFF8B5CF6),
        'example': 'Real estate investment',
      },
    ];

    return Row(
      children: templates.map((t) {
        final color = t['color'] as Color;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withAlpha(40)),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: t['icon'] as String,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t['example'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AppTheme.mutedLight,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScenariosList(List<Map<String, dynamic>> scenarios) {
    // If a scenario is selected, show detail view
    if (_selectedScenario != null) {
      return _buildScenarioDetail(_selectedScenario!);
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async => ref.invalidate(decisionScenariosProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Demo Banner for Jonathan
          _buildJonathanDemoBanner(),
          const SizedBox(height: 16),

          // Scenarios
          Text(
            'Your Scenarios (${scenarios.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 12),
          ...scenarios.map((s) => _buildScenarioCard(s)),
        ],
      ),
    );
  }

  Widget _buildJonathanDemoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'directions_bus',
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo: Jonathan\'s Transport Vehicle',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Assets: TSh 300M • Debt: TSh 50M • Income: TSh 8M/mo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(Map<String, dynamic> scenario) {
    final service = DecisionEngineService.instance;
    final category = scenario['category'] as String? ?? 'other';
    final status = scenario['status'] as String? ?? 'draft';
    final statusColor = status == 'simulated'
        ? AppTheme.success
        : status == 'draft'
        ? AppTheme.warning
        : AppTheme.mutedLight;

    return GestureDetector(
      onTap: () => setState(() => _selectedScenario = scenario),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outlineLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName:
                      DecisionEngineService.categoryIcons[category] ??
                      'lightbulb',
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario['name'] as String? ?? 'Scenario',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DecisionEngineService.categoryLabels[category] ?? 'Other',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.mutedLight,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SCENARIO DETAIL VIEW ─────────────────────────────────────────────────

  Widget _buildScenarioDetail(Map<String, dynamic> scenario) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Back + Title
          Container(
            color: AppTheme.surfaceLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedScenario = null),
                  child: const CustomIconWidget(
                    iconName: 'arrow_back',
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scenario['name'] as String? ?? 'Scenario',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildRunSimButton(scenario),
              ],
            ),
          ),
          // Sub-tabs
          Container(
            color: AppTheme.surfaceLight,
            child: TabBar(
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.mutedLight,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Results'),
                Tab(text: 'AI Analysis'),
                Tab(text: 'Details'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                SimulationDashboardWidget(scenario: scenario),
                AiDecisionCardWidget(scenario: scenario),
                _buildScenarioDetailsTab(scenario),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunSimButton(Map<String, dynamic> scenario) {
    return GestureDetector(
      onTap: () async {
        final service = DecisionEngineService.instance;
        Fluttertoast.showToast(
          msg: 'Running simulation...',
          backgroundColor: AppTheme.primary,
        );
        await service.runSimulation(scenario['id'] as String);
        ref.invalidate(simulationResultProvider(scenario['id'] as String));
        ref.invalidate(decisionScenariosProvider);
        Fluttertoast.showToast(
          msg: 'Simulation complete!',
          backgroundColor: AppTheme.success,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomIconWidget(
              iconName: 'play_arrow',
              color: AppTheme.primary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Re-run',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioDetailsTab(Map<String, dynamic> scenario) {
    final scenarioId = scenario['id'] as String;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DecisionEngineService.instance.getScenarioInputs(scenarioId),
      builder: (context, snapshot) {
        final inputs = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(
                'Category',
                DecisionEngineService.categoryLabels[scenario['category']] ??
                    'Other',
              ),
              _detailRow(
                'Status',
                (scenario['status'] as String? ?? 'draft').toUpperCase(),
              ),
              if ((scenario['description'] as String?)?.isNotEmpty == true)
                _detailRow('Description', scenario['description'] as String),
              const SizedBox(height: 16),
              Text(
                'Inputs',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 10),
              ...inputs.map(
                (inp) => _detailRow(
                  inp['input_name'] as String,
                  DecisionEngineService.instance.formatCurrency(
                    (inp['input_value'] as num?)?.toDouble() ?? 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.mutedLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: BUILDER ───────────────────────────────────────────────────────

  Widget _buildBuilderTab() {
    return ScenarioBuilderWidget(
      onScenarioCreated: () {
        _tabController.animateTo(0);
        setState(() => _selectedScenario = null);
      },
    );
  }

  // ─── TAB 3: COMPARE ───────────────────────────────────────────────────────

  Widget _buildCompareTab() {
    final scenariosAsync = ref.watch(decisionScenariosProvider);

    return scenariosAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => _buildErrorState(),
      data: (scenarios) => ComparisonMatrixWidget(scenarios: scenarios),
    );
  }

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CustomIconWidget(
          iconName: 'error_outline',
          color: AppTheme.error,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'Unable to load data',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.mutedLight,
          ),
        ),
      ],
    ),
  );
}
