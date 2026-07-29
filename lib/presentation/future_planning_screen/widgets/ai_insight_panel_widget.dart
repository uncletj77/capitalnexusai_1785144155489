import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/cna_shared_components.dart';

class AiInsightPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> insights;
  final bool isLoading;

  const AiInsightPanelWidget({
    super.key,
    required this.insights,
    this.isLoading = false,
  });

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'positive':
        return AppTheme.success;
      case 'warning':
        return AppTheme.warning;
      case 'critical':
        return AppTheme.error;
      case 'opportunity':
        return AppTheme.primaryLight;
      default:
        return AppTheme.mutedLight;
    }
  }

  Color _severityBg(String? severity) {
    switch (severity) {
      case 'positive':
        return AppTheme.successContainer;
      case 'warning':
        return AppTheme.warningContainer;
      case 'critical':
        return AppTheme.errorContainer;
      case 'opportunity':
        return AppTheme.primaryContainer;
      default:
        return AppTheme.surfaceVariantLight;
    }
  }

  String _severityIcon(String? severity) {
    switch (severity) {
      case 'positive':
        return '✅';
      case 'warning':
        return '⚠️';
      case 'critical':
        return '🚨';
      case 'opportunity':
        return '💡';
      default:
        return '📊';
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'liquidity':
        return 'Liquidity';
      case 'debt_pressure':
        return 'Debt';
      case 'asset_productivity':
        return 'Assets';
      case 'growth_opportunity':
        return 'Growth';
      case 'risk_warning':
        return 'Risk';
      case 'savings_rate':
        return 'Savings';
      default:
        return 'Insight';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Financial Insights',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Powered by Capital NEXUS AI Brain',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const CnaLoadingState(fullScreen: false)
          else if (insights.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.mutedLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Generate a forecast to receive AI insights.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...insights.take(6).map((insight) => _insightTile(insight)),
        ],
      ),
    );
  }

  Widget _insightTile(Map<String, dynamic> insight) {
    final severity = insight['severity'] as String?;
    final type = insight['insight_type'] as String?;
    final message = insight['message'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _severityBg(severity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _severityColor(severity).withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_severityIcon(severity), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _severityColor(severity).withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _severityColor(severity),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF1A1A2E),
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
