import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class AuditLogViewerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final String? filterModule;
  final ValueChanged<String?>? onFilterChanged;

  const AuditLogViewerWidget({
    super.key,
    required this.logs,
    this.filterModule,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      'All',
      'Auth',
      'Finance',
      'Assets',
      'Loans',
      'Investments',
      'Administration',
      'AI',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audit Log',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final mod = modules[i];
              final isSelected =
                  (filterModule == null && mod == 'All') || filterModule == mod;
              return GestureDetector(
                onTap: () => onFilterChanged?.call(mod == 'All' ? null : mod),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mod,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.mutedLight,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Center(
              child: Text(
                'No audit logs found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.mutedLight,
                ),
              ),
            ),
          )
        else
          ...logs.map((log) => _buildLogItem(log)),
      ],
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final severity = log['severity'] ?? 'info';
    final severityColors = {
      'info': AppTheme.primary,
      'warning': AppTheme.warning,
      'error': AppTheme.error,
      'critical': const Color(0xFF7C3AED),
    };
    final severityIcons = {
      'info': 'info',
      'warning': 'warning',
      'error': 'error',
      'critical': 'gpp_bad',
    };
    final color = severityColors[severity] ?? AppTheme.primary;
    final icon = severityIcons[severity] ?? 'info';

    final createdAt = log['created_at'] != null
        ? DateTime.tryParse(log['created_at'])
        : null;
    final timeStr = createdAt != null ? _formatTime(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(iconName: icon, color: color, size: 16),
            ),
          ),
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
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log['module'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        log['action'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const CustomIconWidget(
                      iconName: 'devices',
                      color: AppTheme.mutedLight,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        log['device_info'] ?? 'Unknown device',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.mutedLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
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
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
