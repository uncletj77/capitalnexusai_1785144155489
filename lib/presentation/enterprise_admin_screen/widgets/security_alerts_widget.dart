import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class SecurityAlertsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Function(String)? onResolve;

  const SecurityAlertsWidget({super.key, required this.events, this.onResolve});

  @override
  Widget build(BuildContext context) {
    final unresolved = events.where((e) => e['is_resolved'] != true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Security Alerts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            if (unresolved.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${unresolved.length} active',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CustomIconWidget(
                  iconName: 'verified_user',
                  color: AppTheme.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'No security alerts detected',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          )
        else
          ...events.map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final severity = event['severity'] ?? 'medium';
    final isResolved = event['is_resolved'] == true;
    final severityColors = {
      'info': AppTheme.primary,
      'medium': AppTheme.warning,
      'warning': AppTheme.warning,
      'high': AppTheme.error,
      'critical': const Color(0xFF7C3AED),
    };
    final severityIcons = {
      'info': 'info',
      'medium': 'warning_amber',
      'warning': 'warning_amber',
      'high': 'error',
      'critical': 'gpp_bad',
    };
    final color = isResolved
        ? AppTheme.mutedLight
        : (severityColors[severity] ?? AppTheme.warning);
    final icon = severityIcons[severity] ?? 'warning_amber';

    final createdAt = event['created_at'] != null
        ? DateTime.tryParse(event['created_at'])
        : null;
    final timeStr = createdAt != null ? _formatTime(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isResolved ? AppTheme.surfaceVariantLight : color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isResolved ? AppTheme.outlineLight : color.withAlpha(60),
        ),
      ),
      child: Row(
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
              child: CustomIconWidget(iconName: icon, color: color, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatEventType(event['event_type'] ?? ''),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isResolved
                              ? AppTheme.mutedLight
                              : AppTheme.onSurfaceLight,
                        ),
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
                const SizedBox(height: 3),
                Text(
                  event['description'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isResolved) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => onResolve?.call(event['id'] ?? ''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Mark Resolved',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.success,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Resolved',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.success,
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
    );
  }

  String _formatEventType(String type) {
    return type
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
