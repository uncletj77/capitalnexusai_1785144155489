import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

/// AI Decision Card — displays situation, analysis, risk, opportunity, action
class AiDecisionCardWidget extends StatelessWidget {
  final Map<String, dynamic> recommendation;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  const AiDecisionCardWidget({
    super.key,
    required this.recommendation,
    this.onAccept,
    this.onDismiss,
  });

  Color get _priorityColor {
    switch (recommendation['priority'] as String? ?? 'medium') {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'medium':
        return const Color(0xFF2D9CDB);
      default:
        return const Color(0xFF10B981);
    }
  }

  String get _agentLabel {
    switch (recommendation['agent_type'] as String? ?? '') {
      case 'financial_analyst':
        return 'Financial Analyst';
      case 'asset_intelligence':
        return 'Asset Intelligence';
      case 'business_advisor':
        return 'Business Advisor';
      case 'investment_analyst':
        return 'Investment Analyst';
      case 'debt_advisor':
        return 'Debt Advisor';
      case 'planning_agent':
        return 'Planning Agent';
      default:
        return 'AI Brain';
    }
  }

  String get _agentIcon {
    switch (recommendation['agent_type'] as String? ?? '') {
      case 'financial_analyst':
        return 'account_balance_wallet';
      case 'asset_intelligence':
        return 'real_estate_agent';
      case 'business_advisor':
        return 'business_center';
      case 'investment_analyst':
        return 'trending_up';
      case 'debt_advisor':
        return 'credit_score';
      case 'planning_agent':
        return 'timeline';
      default:
        return 'psychology';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor;
    final status = recommendation['status'] as String? ?? 'pending';
    final isDismissed = status == 'dismissed' || status == 'accepted';

    return Opacity(
      opacity: isDismissed ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: color.withAlpha(12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: _agentIcon,
                        color: color,
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
                          _agentLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        Text(
                          recommendation['category'] as String? ??
                              'Recommendation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      (recommendation['priority'] as String? ?? 'medium')
                          .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation['recommendation'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.onSurfaceLight,
                      height: 1.5,
                    ),
                  ),
                  if (!isDismissed) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (onAccept != null)
                          Expanded(
                            child: GestureDetector(
                              onTap: onAccept,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withAlpha(60),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Accept',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (onAccept != null && onDismiss != null)
                          const SizedBox(width: 8),
                        if (onDismiss != null)
                          Expanded(
                            child: GestureDetector(
                              onTap: onDismiss,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.outlineLight.withAlpha(40),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.outlineLight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Dismiss',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.mutedLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
