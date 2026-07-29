import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/cna_module_drawer.dart';
import '../../routes/app_routes.dart';
import './widgets/risk_scoring_dashboard_widget.dart';
import './widgets/recommendation_management_widget.dart';
import './widgets/scenario_analysis_widget.dart';
import './widgets/executive_command_center_widget.dart';

/// CNA AI Workspace — Enterprise Financial Intelligence Command Center
/// Master Prompt 6: Full AI Brain with Risk Scoring, Recommendations,
/// Scenario Analysis, Opportunity Discovery, and Executive Briefings
class AiWorkspaceScreen extends StatefulWidget {
  const AiWorkspaceScreen({super.key});

  @override
  State<AiWorkspaceScreen> createState() => _AiWorkspaceScreenState();
}

class _AiWorkspaceScreenState extends State<AiWorkspaceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _tabs = [
    {
      'label': 'Command',
      'icon': 'dashboard_customize',
      'color': const Color(0xFF1A5F7A),
    },
    {'label': 'Risk', 'icon': 'shield', 'color': const Color(0xFF8B5CF6)},
    {'label': 'Advice', 'icon': 'recommend', 'color': const Color(0xFF10B981)},
    {'label': 'Scenarios', 'icon': 'science', 'color': const Color(0xFF2D9CDB)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() => _selectedTab = _tabController.index);
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
      drawer: const CnaModuleDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ExecutiveCommandCenterWidget(),
                  RiskScoringDashboardWidget(),
                  RecommendationManagementWidget(),
                  ScenarioAnalysisWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final activeColor = _tabs[_selectedTab]['color'] as Color;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.outlineLight.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'menu',
                  color: AppTheme.mutedLight,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [activeColor, activeColor.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: _tabs[_selectedTab]['icon'] as String,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CNA AI Workspace',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Enterprise AI Brain · All Modules Connected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chat shortcut
          GestureDetector(
            onTap: () => context.push(AppRoutes.aiBrainScreen),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1A5F7A).withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1A5F7A).withAlpha(40),
                ),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'chat',
                  color: Color(0xFF1A5F7A),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          final isSelected = _selectedTab == i;
          final color = tab['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : AppTheme.outlineLight.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: tab['icon'] as String,
                      color: isSelected ? Colors.white : AppTheme.mutedLight,
                      size: 16,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    // Only show on Scenarios tab
    if (_selectedTab != 3) return null;
    return FloatingActionButton.extended(
      onPressed: () => context.push(AppRoutes.aiBrainScreen),
      backgroundColor: const Color(0xFF1A5F7A),
      icon: const CustomIconWidget(
        iconName: 'chat',
        color: Colors.white,
        size: 18,
      ),
      label: Text(
        'Ask AI',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
