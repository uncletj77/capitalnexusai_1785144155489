import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/decision_engine_service.dart';

/// Simulation Dashboard — shows results, charts, risk scores for a scenario
class SimulationDashboardWidget extends ConsumerWidget {
  final Map<String, dynamic> scenario;

  const SimulationDashboardWidget({super.key, required this.scenario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarioId = scenario['id'] as String;
    final simAsync = ref.watch(simulationResultProvider(scenarioId));

    return simAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => _buildEmpty(),
      data: (sim) {
        if (sim == null) return _buildEmpty();
        return _buildDashboard(context, sim);
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CustomIconWidget(
          iconName: 'analytics',
          color: AppTheme.mutedLight,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'No simulation results yet',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.mutedLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Run a simulation to see results',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.mutedLight,
          ),
        ),
      ],
    ),
  );

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> sim) {
    final service = DecisionEngineService.instance;
    final riskScore = (sim['risk_score'] as num?)?.toInt() ?? 50;
    final successProb = (sim['success_probability'] as num?)?.toInt() ?? 50;
    final finalScore = (sim['final_decision_score'] as num?)?.toInt() ?? 50;
    final cashEffect = (sim['cash_flow_effect'] as num?)?.toDouble() ?? 0;
    final networthEffect = (sim['networth_effect'] as num?)?.toDouble() ?? 0;
    final monthlyImpact = (sim['monthly_impact'] as num?)?.toDouble() ?? 0;
    final breakEven = (sim['break_even_months'] as num?)?.toInt() ?? 0;
    final decisionLabel = service.getDecisionLabel(finalScore);
    final decisionColor = finalScore >= 70
        ? AppTheme.success
        : finalScore >= 45
        ? AppTheme.warning
        : AppTheme.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decision Verdict Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: decisionColor.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: decisionColor.withAlpha(60)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: finalScore >= 70
                          ? 'check_circle'
                          : finalScore >= 45
                          ? 'warning'
                          : 'cancel',
                      color: decisionColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      decisionLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: decisionColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Decision Score: $finalScore / 100',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Score Grid
          Row(
            children: [
              Expanded(
                child: _scoreCard(
                  'Opportunity',
                  sim['opportunity_score'],
                  const Color(0xFF10B981),
                  'trending_up',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _scoreCard(
                  'Affordability',
                  sim['affordability_score'],
                  AppTheme.primary,
                  'wallet',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _scoreCard(
                  'Risk',
                  riskScore,
                  AppTheme.error,
                  'warning_amber',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key Metrics
          _sectionTitle('Key Metrics'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Cash Flow Effect',
                  service.formatCurrency(cashEffect),
                  cashEffect >= 0 ? AppTheme.success : AppTheme.error,
                  'account_balance_wallet',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Net Worth Effect',
                  service.formatCurrency(networthEffect),
                  networthEffect >= 0 ? AppTheme.success : AppTheme.error,
                  'bar_chart',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Monthly Impact',
                  service.formatCurrency(monthlyImpact),
                  monthlyImpact >= 0 ? AppTheme.success : AppTheme.error,
                  'calendar_month',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Break-even',
                  breakEven > 0 ? '$breakEven months' : 'N/A',
                  AppTheme.warning,
                  'schedule',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Success Probability Bar
          _sectionTitle('Success Probability'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Probability of Success',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    Text(
                      '$successProb%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: successProb / 100,
                    backgroundColor: AppTheme.outlineLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      successProb >= 70
                          ? AppTheme.success
                          : successProb >= 45
                          ? AppTheme.warning
                          : AppTheme.error,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Result Summary
          _sectionTitle('Analysis Summary'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomIconWidget(
                  iconName: 'info_outline',
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sim['result_summary'] as String? ?? 'Simulation complete.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.onSurfaceLight,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline Projection
          const SizedBox(height: 16),
          _buildTimelineProjection(sim, service),
        ],
      ),
    );
  }

  Widget _buildTimelineProjection(
    Map<String, dynamic> sim,
    DecisionEngineService service,
  ) {
    final monthlyImpact = (sim['monthly_impact'] as num?)?.toDouble() ?? 0;
    final timelineMonths = (sim['timeline_months'] as num?)?.toInt() ?? 12;

    final milestones = [
      {'month': 1, 'label': 'Month 1', 'value': monthlyImpact},
      {'month': 3, 'label': '3 Months', 'value': monthlyImpact * 3},
      {'month': 6, 'label': '6 Months', 'value': monthlyImpact * 6},
      {'month': 12, 'label': '1 Year', 'value': monthlyImpact * 12},
      {
        'month': timelineMonths,
        'label': '$timelineMonths Months',
        'value': monthlyImpact * timelineMonths,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Timeline Projection'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: milestones.map((m) {
              final val = (m['value'] as double?) ?? 0;
              final isPositive = val >= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isPositive ? AppTheme.success : AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ),
                    Text(
                      service.formatCurrency(val),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _scoreCard(String label, dynamic score, Color color, String icon) {
    final s = (score as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$s',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(iconName: icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.mutedLight,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppTheme.onSurfaceLight,
    ),
  );
}
