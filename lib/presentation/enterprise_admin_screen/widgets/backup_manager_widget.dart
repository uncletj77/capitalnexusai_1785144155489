import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class BackupManagerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> backupJobs;
  final bool isCreatingBackup;
  final VoidCallback? onCreateBackup;

  const BackupManagerWidget({
    super.key,
    required this.backupJobs,
    this.isCreatingBackup = false,
    this.onCreateBackup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Backup Manager',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            GestureDetector(
              onTap: isCreatingBackup ? null : onCreateBackup,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCreatingBackup
                      ? AppTheme.surfaceVariantLight
                      : AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isCreatingBackup
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.success,
                            ),
                          )
                        : const CustomIconWidget(
                            iconName: 'backup',
                            color: AppTheme.success,
                            size: 14,
                          ),
                    const SizedBox(width: 4),
                    Text(
                      isCreatingBackup ? 'Creating...' : 'Backup Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBackupScheduleRow(),
        const SizedBox(height: 12),
        ...backupJobs.map((job) => _buildBackupJobCard(job)),
      ],
    );
  }

  Widget _buildBackupScheduleRow() {
    final schedules = [
      {'label': 'Daily', 'icon': 'today', 'active': true},
      {'label': 'Weekly', 'icon': 'date_range', 'active': true},
      {'label': 'Monthly', 'icon': 'calendar_month', 'active': false},
    ];
    return Row(
      children: schedules.map((s) {
        final active = s['active'] as bool;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryContainer
                  : AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? AppTheme.primary.withAlpha(60)
                    : AppTheme.outlineLight,
              ),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: s['icon'] as String,
                  color: active ? AppTheme.primary : AppTheme.mutedLight,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  s['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? AppTheme.primary : AppTheme.mutedLight,
                  ),
                ),
                Text(
                  active ? 'Active' : 'Off',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: active ? AppTheme.success : AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBackupJobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? 'pending';
    final statusColors = {
      'completed': AppTheme.success,
      'pending': AppTheme.warning,
      'running': AppTheme.primary,
      'failed': AppTheme.error,
    };
    final statusIcons = {
      'completed': 'check_circle',
      'pending': 'schedule',
      'running': 'sync',
      'failed': 'error',
    };
    final color = statusColors[status] ?? AppTheme.mutedLight;
    final icon = statusIcons[status] ?? 'backup';

    final sizeBytes = job['size_bytes'] as int? ?? 0;
    final sizeStr = sizeBytes > 1048576
        ? '${(sizeBytes / 1048576).toStringAsFixed(1)} MB'
        : '${(sizeBytes / 1024).toStringAsFixed(0)} KB';

    final metadata = job['metadata'] as Map<String, dynamic>? ?? {};
    final records = metadata['records'] ?? 0;

    final completedAt = job['completed_at'] != null
        ? DateTime.tryParse(job['completed_at'])
        : null;
    final timeStr = completedAt != null ? _formatTime(completedAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(iconName: icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${job['backup_type']?.toString().toUpperCase() ?? 'FULL'} Backup',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$sizeStr • $records records • $timeStr',
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
