import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/cna_shared_components.dart';

class ReportViewerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> reports;
  final bool isLoading;
  final VoidCallback? onGenerateReport;

  const ReportViewerWidget({
    super.key,
    required this.reports,
    this.isLoading = false,
    this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CnaLoadingState(fullScreen: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Generated Reports',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            if (onGenerateReport != null)
              TextButton.icon(
                onPressed: onGenerateReport,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Generate',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (reports.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Center(
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'description',
                    color: AppTheme.mutedLight,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No reports generated yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...reports.map((report) => _ReportCard(report: report)),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final type = report['report_type'] as String? ?? 'financial';
    final title = report['title'] as String? ?? 'Report';
    final content = report['content'] as Map<String, dynamic>? ?? {};
    final createdAt = report['created_at'] as String? ?? '';
    final color = _typeColor(type);
    final icon = _typeIcon(type);

    DateTime? date;
    try {
      date = DateTime.parse(createdAt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.outlineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Center(
              child: CustomIconWidget(iconName: icon, color: color, size: 20),
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            date != null ? '${date.day}/${date.month}/${date.year}' : '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.mutedLight,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if (content['summary'] != null) ...[
                    Text(
                      content['summary'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.mutedLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: content.entries
                        .where((e) => e.key != 'summary' && e.value is num)
                        .map(
                          (e) => _MetricChip(
                            label: _formatKey(e.key),
                            value: _formatValue(e.key, e.value),
                            color: color,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  String _formatValue(String key, dynamic value) {
    if (key.contains('rate') ||
        key.contains('roi') ||
        key.contains('margin') ||
        key.contains('growth')) {
      return '${(value as num).toStringAsFixed(1)}%';
    }
    final numValue = (value as num).toDouble();
    if (numValue >= 1000000) {
      return 'TSh ${(numValue / 1000000).toStringAsFixed(1)}M';
    }
    if (numValue >= 1000) return 'TSh ${(numValue / 1000).toStringAsFixed(0)}K';
    return 'TSh ${numValue.toStringAsFixed(0)}';
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'financial':
        return AppTheme.primary;
      case 'business':
        return AppTheme.success;
      case 'investment':
        return const Color(0xFF8B5CF6);
      case 'executive':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  String _typeIcon(String t) {
    switch (t) {
      case 'financial':
        return 'account_balance';
      case 'business':
        return 'business_center';
      case 'investment':
        return 'trending_up';
      case 'executive':
        return 'dashboard';
      default:
        return 'description';
    }
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppTheme.mutedLight,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
