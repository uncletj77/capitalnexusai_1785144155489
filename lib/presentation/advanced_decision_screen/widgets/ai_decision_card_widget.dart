import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/decision_engine_service.dart';

/// AI Decision Card — displays AI-generated recommendation with reasoning
class AiDecisionCardWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> scenario;

  const AiDecisionCardWidget({super.key, required this.scenario});

  @override
  ConsumerState<AiDecisionCardWidget> createState() =>
      _AiDecisionCardWidgetState();
}

class _AiDecisionCardWidgetState extends ConsumerState<AiDecisionCardWidget> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final scenarioId = widget.scenario['id'] as String;
    final recAsync = ref.watch(decisionRecommendationProvider(scenarioId));

    return recAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => _buildEmpty(scenarioId),
      data: (rec) {
        if (rec == null) return _buildEmpty(scenarioId);
        return _buildCard(context, rec, scenarioId);
      },
    );
  }

  Widget _buildEmpty(String scenarioId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CustomIconWidget(
                      iconName: 'psychology',
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI Decision Analysis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get AI-powered strategic reasoning for this decision. The AI will analyze your financial context and provide a detailed recommendation.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.mutedLight,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGenerating
                        ? null
                        : () => _generateAi(scenarioId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CustomIconWidget(
                                iconName: 'auto_awesome',
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Generate AI Recommendation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    Map<String, dynamic> rec,
    String scenarioId,
  ) {
    final riskLevel = rec['risk_level'] as String? ?? 'medium';
    final confidence = (rec['confidence_score'] as num?)?.toInt() ?? 70;
    final riskColor = riskLevel == 'low'
        ? AppTheme.success
        : riskLevel == 'high'
        ? AppTheme.error
        : AppTheme.warning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'psychology',
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
                      'AI Strategic Recommendation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Powered by CNA Decision Engine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withAlpha(60)),
                ),
                child: Text(
                  '${riskLevel.toUpperCase()} RISK',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confidence Score
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const CustomIconWidget(
                  iconName: 'verified',
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Confidence: $confidence%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence / 100,
                      backgroundColor: AppTheme.outlineLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recommendation
          _buildSection(
            'Recommendation',
            rec['recommendation'] as String? ?? '',
            'lightbulb',
            AppTheme.warning,
          ),

          if ((rec['reasoning'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildSection(
              'Reasoning',
              rec['reasoning'] as String,
              'analytics',
              AppTheme.primary,
            ),
          ],

          if ((rec['advantages'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildSection(
              'Advantages',
              rec['advantages'] as String,
              'thumb_up',
              AppTheme.success,
            ),
          ],

          if ((rec['disadvantages'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildSection(
              'Risks & Disadvantages',
              rec['disadvantages'] as String,
              'thumb_down',
              AppTheme.error,
            ),
          ],

          if ((rec['suggested_actions'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildSection(
              'Suggested Actions',
              rec['suggested_actions'] as String,
              'task_alt',
              const Color(0xFF8B5CF6),
            ),
          ],

          const SizedBox(height: 16),

          // Regenerate Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isGenerating ? null : () => _generateAi(scenarioId),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomIconWidget(
                          iconName: 'refresh',
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Regenerate AI Analysis',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAi(String scenarioId) async {
    setState(() => _isGenerating = true);

    final service = DecisionEngineService.instance;
    final simResult = await service.getSimulationResult(scenarioId);
    final inputs = await service.getScenarioInputs(scenarioId);

    if (simResult == null) {
      // Run simulation first
      await service.runSimulation(scenarioId);
    }

    final inputMap = <String, double>{};
    for (final inp in inputs) {
      inputMap[inp['input_name'] as String] =
          (inp['input_value'] as num?)?.toDouble() ?? 0;
    }

    final userContext = await service.getUserFinancialContext();

    final aiText = await service.generateAiRecommendation(
      scenarioName: widget.scenario['name'] as String? ?? 'Scenario',
      category: widget.scenario['category'] as String? ?? 'other',
      simulationResult: simResult ?? {},
      inputs: inputMap,
      userContext: userContext,
    );

    if (aiText != null && aiText.isNotEmpty) {
      // Parse risk level from AI text
      String riskLevel = 'medium';
      if (aiText.toLowerCase().contains('high risk') ||
          aiText.toLowerCase().contains('do not proceed')) {
        riskLevel = 'high';
      } else if (aiText.toLowerCase().contains('low risk') ||
          aiText.toLowerCase().contains('proceed')) {
        riskLevel = 'low';
      }

      await service.saveRecommendation(
        scenarioId: scenarioId,
        recommendation: aiText,
        riskLevel: riskLevel,
        confidenceScore: 80,
      );

      ref.invalidate(decisionRecommendationProvider(scenarioId));
      Fluttertoast.showToast(
        msg: 'AI analysis complete!',
        backgroundColor: AppTheme.success,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'AI analysis unavailable. Check your OpenAI API key.',
        backgroundColor: Colors.orange,
      );
    }

    setState(() => _isGenerating = false);
  }

  Widget _buildSection(String title, String content, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(iconName: icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.onSurfaceLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
