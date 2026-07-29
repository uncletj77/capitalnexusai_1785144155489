import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class AiInsightCardWidget extends StatelessWidget {
  final String insightType;
  final String message;
  final String severity;
  final String? relatedModule;
  final VoidCallback? onTap;

  const AiInsightCardWidget({
    super.key,
    required this.insightType,
    required this.message,
    required this.severity,
    this.relatedModule,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    final icon = _typeIcon(insightType);
    final typeLabel = _typeLabel(insightType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: CustomIconWidget(iconName: icon, color: color, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      if (relatedModule != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${relatedModule!.toUpperCase()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.onSurfaceLight,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'positive':
        return AppTheme.success;
      case 'warning':
        return AppTheme.warning;
      case 'critical':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  String _typeIcon(String t) {
    switch (t) {
      case 'trend':
        return 'trending_up';
      case 'anomaly':
        return 'warning_amber';
      case 'opportunity':
        return 'lightbulb';
      case 'risk':
        return 'shield';
      default:
        return 'psychology';
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'trend':
        return 'Trend';
      case 'anomaly':
        return 'Anomaly';
      case 'opportunity':
        return 'Opportunity';
      case 'risk':
        return 'Risk';
      default:
        return 'Insight';
    }
  }
}
