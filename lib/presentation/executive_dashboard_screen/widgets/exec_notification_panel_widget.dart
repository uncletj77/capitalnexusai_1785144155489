import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class ExecNotificationPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const ExecNotificationPanelWidget({required this.notifications, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
      ),
      child: Column(
        children: [
          ...notifications
              .take(3)
              .map((n) => _buildNotificationItem(context, n)),
          InkWell(
            onTap: () => context.go(AppRoutes.notificationCenterScreen),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'View All Notifications',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> n) {
    final theme = Theme.of(context);
    final isRead = n['is_read'] == true || n['status'] == 'read';
    final priority = n['priority'] as String? ?? 'normal';
    final color = priority == 'high'
        ? AppTheme.danger
        : priority == 'medium'
        ? AppTheme.warning
        : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withAlpha(40)),
        ),
        color: isRead ? Colors.transparent : color.withAlpha(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: isRead ? Colors.transparent : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n['title'] as String? ?? 'Notification',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  n['message'] as String? ?? '',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
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
