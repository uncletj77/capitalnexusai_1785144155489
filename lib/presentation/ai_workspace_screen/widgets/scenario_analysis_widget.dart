import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/cna_brain_enterprise_service.dart';

/// Scenario Analysis (What-If Engine) Widget
/// Interactive scenario builder with AI-powered projections
class ScenarioAnalysisWidget extends StatefulWidget {
  const ScenarioAnalysisWidget({super.key});

  @override
  State<ScenarioAnalysisWidget> createState() => _ScenarioAnalysisWidgetState();
}

class _ScenarioAnalysisWidgetState extends State<ScenarioAnalysisWidget> {
  final _service = CnaBrainEnterpriseService.instance;
  final _questionController = TextEditingController();
  List<Map<String, dynamic>> _savedScenarios = [];
  Map<String, dynamic>? _currentResult;
  bool _isLoading = false;
  bool _isRunning = false;
  String _selectedType = 'what_if';

  final List<Map<String, dynamic>> _scenarioTemplates = [
    {
      'type': 'buy_asset',
      'label': 'Buy an Asset',
      'icon': 'real_estate_agent',
      'color': const Color(0xFF2D9CDB),
      'question':
          'If I buy a new vehicle worth TZS 50M, how will it affect my finances?',
    },
    {
      'type': 'sell_asset',
      'label': 'Sell an Asset',
      'icon': 'sell',
      'color': const Color(0xFF10B981),
      'question':
          'If I sell one of my assets, how will it change my net worth and cash flow?',
    },
    {
      'type': 'repay_loan',
      'label': 'Repay Debt Early',
      'icon': 'credit_score',
      'color': const Color(0xFF8B5CF6),
      'question':
          'If I repay my outstanding loans early, what will be the financial impact?',
    },
    {
      'type': 'new_investment',
      'label': 'New Investment',
      'icon': 'trending_up',
      'color': const Color(0xFFF59E0B),
      'question':
          'If I invest TZS 10M in a new investment, what returns can I expect?',
    },
    {
      'type': 'expand_business',
      'label': 'Expand Business',
      'icon': 'business_center',
      'color': const Color(0xFFEC4899),
      'question':
          'If I expand my business with TZS 20M investment, how will it affect my finances?',
    },
    {
      'type': 'increase_savings',
      'label': 'Increase Savings',
      'icon': 'savings',
      'color': const Color(0xFF059669),
      'question':
          'If I increase my monthly savings by TZS 500K, when will I reach my goals?',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedScenarios();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedScenarios() async {
    setState(() => _isLoading = true);
    final scenarios = await _service.getSavedScenarios();
    if (mounted) {
      setState(() {
        _savedScenarios = scenarios;
        _isLoading = false;
      });
    }
  }

  Future<void> _runScenario() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isRunning = true;
      _currentResult = null;
    });

    final result = await _service.runScenarioAnalysis(
      title: question.length > 60
          ? '${question.substring(0, 60)}...'
          : question,
      scenarioType: _selectedType,
      parameters: {'user_question': question, 'scenario_type': _selectedType},
      userQuestion: question,
    );

    if (mounted) {
      setState(() {
        _currentResult = result;
        _isRunning = false;
      });
      _loadSavedScenarios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D9CDB), Color(0xFF1A5F7A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'science',
                    color: Colors.white,
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
                      'What-If Scenario Engine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Model decisions without affecting real records',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Safety notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D9CDB).withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D9CDB).withAlpha(40)),
            ),
            child: Row(
              children: [
                const CustomIconWidget(
                  iconName: 'info',
                  color: Color(0xFF2D9CDB),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scenario analysis is read-only. No financial records will be modified without your explicit confirmation.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF2D9CDB),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scenario type selector
          Text(
            'Choose Scenario Type',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _scenarioTemplates.length,
              itemBuilder: (context, i) {
                final template = _scenarioTemplates[i];
                final isSelected = _selectedType == template['type'];
                final color = template['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = template['type'] as String;
                      _questionController.text = template['question'] as String;
                    });
                  },
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withAlpha(20)
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : AppTheme.outlineLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: template['icon'] as String,
                          color: isSelected ? color : AppTheme.mutedLight,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          template['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? color : AppTheme.mutedLight,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Question input
          Text(
            'Describe Your Scenario',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: TextField(
              controller: _questionController,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.onSurfaceLight,
              ),
              decoration: InputDecoration(
                hintText:
                    'e.g. If I sell my vehicle and repay my loan, how will my net worth change?',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.mutedLight,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Run button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isRunning ? null : _runScenario,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _isRunning
                      ? LinearGradient(
                          colors: [
                            AppTheme.outlineLight,
                            AppTheme.outlineLight,
                          ],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _isRunning
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Analyzing scenario...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CustomIconWidget(
                              iconName: 'science',
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Run Scenario Analysis',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Current result
          if (_currentResult != null && !_currentResult!.containsKey('error'))
            _buildResultCard(_currentResult!),

          if (_currentResult != null && _currentResult!.containsKey('error'))
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEF4444).withAlpha(40),
                ),
              ),
              child: Text(
                'Analysis failed. Please try again.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),

          // Saved scenarios
          if (_savedScenarios.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Saved Scenarios',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 10),
            ..._savedScenarios.take(5).map((s) => _buildSavedScenarioCard(s)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final analysis = result['analysis'] as Map<String, dynamic>? ?? {};
    final outcomes =
        analysis['projected_outcomes'] as Map<String, dynamic>? ?? {};
    final assumptions =
        (analysis['assumptions'] as List?)?.cast<String>() ?? [];
    final risks = (analysis['risks'] as List?)?.cast<String>() ?? [];
    final opportunities =
        (analysis['opportunities'] as List?)?.cast<String>() ?? [];
    final confidence = analysis['confidence_level'] as String? ?? 'medium';
    final recommendation = analysis['ai_recommendation'] as String? ?? '';

    Color confidenceColor;
    switch (confidence) {
      case 'high':
        confidenceColor = const Color(0xFF10B981);
        break;
      case 'low':
        confidenceColor = const Color(0xFFEF4444);
        break;
      default:
        confidenceColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D9CDB).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomIconWidget(
                iconName: 'analytics',
                color: Color(0xFF2D9CDB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Scenario Analysis Result',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${confidence.toUpperCase()} CONFIDENCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: confidenceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Projected outcomes
          if (outcomes.isNotEmpty) ...[
            Text(
              '📊 Projected Outcomes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 6),
            ...outcomes.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: Color(0xFF2D9CDB)),
                    ),
                    Expanded(
                      child: Text(
                        '${e.key.replaceAll('_', ' ')}: ${e.value}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.mutedLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // AI Recommendation
          if (recommendation.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withAlpha(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ AI Recommendation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.onSurfaceLight,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Assumptions
          if (assumptions.isNotEmpty) ...[
            Text(
              '⚠️ Assumptions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 4),
            ...assumptions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $a',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Risks
          if (risks.isNotEmpty) ...[
            Text(
              '🚨 Risks',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 4),
            ...risks.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $r',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Opportunities
          if (opportunities.isNotEmpty) ...[
            Text(
              '💡 Opportunities',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 4),
            ...opportunities.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $o',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          Text(
            '⚠️ This is a projection only. All outcomes are estimates based on current data and stated assumptions.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.mutedLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedScenarioCard(Map<String, dynamic> scenario) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2D9CDB).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'science',
                color: Color(0xFF2D9CDB),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario['title'] as String? ?? 'Scenario',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(scenario['created_at'] as String? ?? ''),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.outlineLight.withAlpha(60),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              (scenario['confidence_level'] as String? ?? 'medium')
                  .toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
