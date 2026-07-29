import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class SystemHealthWidget extends StatelessWidget {
  final Map<String, dynamic> health;

  const SystemHealthWidget({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    final score = health['security_score'] as int? ?? 0;
    final status = health['status'] ?? 'healthy';
    final isHealthy = status == 'healthy';

    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = AppTheme.success;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = AppTheme.primaryLight;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = AppTheme.warning;
      scoreLabel = 'Fair';
    } else {
      scoreColor = AppTheme.error;
      scoreLabel = 'Weak';
    }

    final metrics = [
      {
        'label': 'Active Sessions',
        'value': '${health['active_sessions'] ?? 0}',
        'icon': 'devices',
        'color': AppTheme.primary,
      },
      {
        'label': 'Audit Events (30d)',
        'value': '${health['audit_events_30d'] ?? 0}',
        'icon': 'history',
        'color': AppTheme.primaryLight,
      },
      {
        'label': 'Open Alerts',
        'value': '${health['unresolved_alerts'] ?? 0}',
        'icon': 'warning_amber',
        'color': (health['unresolved_alerts'] ?? 0) > 0
            ? AppTheme.warning
            : AppTheme.success,
      },
      {
        'label': 'Last Backup',
        'value': _getLastBackupStr(health['last_backup']),
        'icon': 'backup',
        'color': AppTheme.success,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2535), Color(0xFF0D1520)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scoreColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: isHealthy ? 'verified_user' : 'security',
                    color: scoreColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Health',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isHealthy
                          ? 'All systems operational'
                          : 'Attention required',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    scoreLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: metrics.map((m) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      CustomIconWidget(
                        iconName: m['icon'] as String,
                        color: m['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['value'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        m['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: Colors.white54,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getLastBackupStr(dynamic lastBackup) {
    if (lastBackup == null) return 'Never';
    final completedAt = lastBackup['completed_at'] as String?;
    if (completedAt == null) return 'Pending';
    final dt = DateTime.tryParse(completedAt);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
