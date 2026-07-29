import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/decision_engine_service.dart';

/// Comparison Matrix — compare multiple scenarios side by side
class ComparisonMatrixWidget extends ConsumerWidget {
  final List<Map<String, dynamic>> scenarios;

  const ComparisonMatrixWidget({super.key, required this.scenarios});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scenarios.isEmpty) {
      return _buildEmpty();
    }

    // Take up to 3 scenarios for comparison
    final compareList = scenarios.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'compare_arrows',
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scenario Comparison',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  Text(
                    'Comparing ${compareList.length} scenarios',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scenario Cards Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: compareList.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final colors = [
                  AppTheme.primary,
                  const Color(0xFF10B981),
                  const Color(0xFF8B5CF6),
                ];
                return Padding(
                  padding: EdgeInsets.only(
                    right: idx < compareList.length - 1 ? 12 : 0,
                  ),
                  child: _ScenarioCompareCard(
                    scenario: s,
                    color: colors[idx % colors.length],
                    ref: ref,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Comparison Table
          _buildComparisonTable(compareList, ref),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CustomIconWidget(
          iconName: 'compare_arrows',
          color: AppTheme.mutedLight,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'No scenarios to compare',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.mutedLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create at least 2 scenarios to compare',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.mutedLight,
          ),
        ),
      ],
    ),
  );

  Widget _buildComparisonTable(
    List<Map<String, dynamic>> compareList,
    WidgetRef ref,
  ) {
    final metrics = [
      {
        'label': 'Decision Score',
        'key': 'final_decision_score',
        'icon': 'star',
      },
      {'label': 'Risk Score', 'key': 'risk_score', 'icon': 'warning_amber'},
      {
        'label': 'Success Prob.',
        'key': 'success_probability',
        'icon': 'check_circle',
      },
      {
        'label': 'Opportunity',
        'key': 'opportunity_score',
        'icon': 'trending_up',
      },
      {
        'label': 'Affordability',
        'key': 'affordability_score',
        'icon': 'wallet',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Metric',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ),
                ...compareList.asMap().entries.map(
                  (e) => Expanded(
                    child: Text(
                      _truncate(e.value['name'] as String? ?? 'Scenario', 10),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.outlineLight),

          // Metric Rows
          ...metrics.asMap().entries.map((mEntry) {
            final metric = mEntry.value;
            final isLast = mEntry.key == metrics.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: metric['icon'] as String,
                              color: AppTheme.mutedLight,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                metric['label'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.mutedLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...compareList.map((s) {
                        final scenarioId = s['id'] as String;
                        final simAsync = ref.watch(
                          simulationResultProvider(scenarioId),
                        );
                        return Expanded(
                          child: simAsync.when(
                            loading: () => const Center(
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              ),
                            ),
                            error: (_, __) => Text(
                              '—',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.mutedLight,
                              ),
                            ),
                            data: (sim) {
                              if (sim == null) {
                                return Text(
                                  '—',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.mutedLight,
                                  ),
                                );
                              }
                              final val =
                                  (sim[metric['key']] as num?)?.toInt() ?? 0;
                              final isRisk = metric['key'] == 'risk_score';
                              final color = isRisk
                                  ? (val >= 70
                                        ? AppTheme.error
                                        : val >= 40
                                        ? AppTheme.warning
                                        : AppTheme.success)
                                  : (val >= 70
                                        ? AppTheme.success
                                        : val >= 45
                                        ? AppTheme.warning
                                        : AppTheme.error);
                              return Text(
                                '$val',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, color: AppTheme.outlineLight),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _truncate(String text, int maxLen) =>
      text.length > maxLen ? '${text.substring(0, maxLen)}...' : text;
}

class _ScenarioCompareCard extends StatelessWidget {
  final Map<String, dynamic> scenario;
  final Color color;
  final WidgetRef ref;

  const _ScenarioCompareCard({
    required this.scenario,
    required this.color,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final scenarioId = scenario['id'] as String;
    final simAsync = ref.watch(simulationResultProvider(scenarioId));
    final service = DecisionEngineService.instance;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName:
                    DecisionEngineService.categoryIcons[scenario['category']] ??
                    'lightbulb',
                color: color,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            scenario['name'] as String? ?? 'Scenario',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            DecisionEngineService.categoryLabels[scenario['category']] ??
                'Other',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 12),
          simAsync.when(
            loading: () => const SizedBox(
              height: 20,
              child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (sim) {
              if (sim == null) {
                return Text(
                  'Not simulated',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.mutedLight,
                  ),
                );
              }
              final score = (sim['final_decision_score'] as num?)?.toInt() ?? 0;
              final label = service.getDecisionLabel(score);
              final labelColor = score >= 70
                  ? AppTheme.success
                  : score >= 45
                  ? AppTheme.warning
                  : AppTheme.error;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: $score/100',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: labelColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
