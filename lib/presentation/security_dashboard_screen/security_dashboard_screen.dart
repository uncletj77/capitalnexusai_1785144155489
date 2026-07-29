import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/security_service.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() =>
      _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic>? _userProfile;
  int _securityScore = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load profile first — independent of security service
      Map<String, dynamic>? profile;
      try {
        profile = await client
            .from('user_profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {}

      // Load sessions, logs, events independently so one failure doesn't block all
      List<Map<String, dynamic>> sessions = [];
      List<Map<String, dynamic>> logs = [];
      List<Map<String, dynamic>> events = [];

      try {
        sessions = await SecurityService.instance.getActiveSessions();
      } catch (_) {}

      try {
        logs = await SecurityService.instance.getAuditLogs(limit: 20);
      } catch (_) {}

      try {
        final rawEvents = await SecurityService.instance.getSecurityEvents(
          unresolvedOnly: false,
        );
        events = rawEvents;
      } catch (_) {}

      // Map security events to alerts format
      final alerts = events
          .map(
            (e) => {
              'id': e['id'],
              'message': e['description'] ?? '',
              'severity': e['severity'] ?? 'low',
              'is_read': e['is_resolved'] == true,
              'created_at': e['created_at'],
            },
          )
          .toList();

      int score = 40;
      if (profile?['email_verified'] == true) score += 15;
      if (profile?['phone_verified'] == true) score += 10;
      if (profile?['two_factor_enabled'] == true) score += 20;
      if (profile?['biometric_enabled'] == true) score += 15;
      if (score > 100) score = 100;

      setState(() {
        _userProfile = profile;
        _sessions = sessions;
        _auditLogs = logs;
        _alerts = alerts;
        _securityScore = score;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissAlert(String alertId) async {
    await SecurityService.instance.resolveSecurityEvent(alertId);
    setState(() {
      final idx = _alerts.indexWhere((a) => a['id'] == alertId);
      if (idx != -1) _alerts[idx]['is_read'] = true;
    });
  }

  Future<void> _terminateSession(String sessionId) async {
    await SecurityService.instance.terminateSession(sessionId);
    setState(() {
      final idx = _sessions.indexWhere((s) => s['id'] == sessionId);
      if (idx != -1) _sessions[idx]['is_active'] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSecurityScoreCard(),
                          const SizedBox(height: 16),
                          _buildAlertsSection(),
                          const SizedBox(height: 16),
                          _buildActiveDevicesSection(),
                          const SizedBox(height: 16),
                          _buildRecentActivitySection(),
                          const SizedBox(height: 16),
                          _buildSecuritySettings(),
                          const SizedBox(height: 16),
                          _buildEnterpriseAdminLink(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppTheme.surfaceLight,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.onSurfaceLight,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Dashboard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  'Monitor your account security',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'refresh',
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityScoreCard() {
    Color scoreColor;
    String scoreLabel;
    if (_securityScore >= 80) {
      scoreColor = AppTheme.success;
      scoreLabel = 'Excellent';
    } else if (_securityScore >= 60) {
      scoreColor = AppTheme.primaryLight;
      scoreLabel = 'Good';
    } else if (_securityScore >= 40) {
      scoreColor = AppTheme.warning;
      scoreLabel = 'Fair';
    } else {
      scoreColor = AppTheme.error;
      scoreLabel = 'Weak';
    }

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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Score',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_securityScore',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '/100',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: scoreColor.withAlpha(80)),
                      ),
                      child: Text(
                        scoreLabel,
                        style: GoogleFonts.plusJakartaSans(
                          color: scoreColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _securityScore / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                    CustomIconWidget(
                      iconName: 'shield',
                      color: scoreColor,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildScoreFactor(
                'Email',
                _userProfile?['email_verified'] == true,
              ),
              const SizedBox(width: 8),
              _buildScoreFactor(
                'Phone',
                _userProfile?['phone_verified'] == true,
              ),
              const SizedBox(width: 8),
              _buildScoreFactor(
                '2FA',
                _userProfile?['two_factor_enabled'] == true,
              ),
              const SizedBox(width: 8),
              _buildScoreFactor(
                'Biometric',
                _userProfile?['biometric_enabled'] == true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreFactor(String label, bool enabled) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.success.withAlpha(20)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppTheme.success.withAlpha(60) : Colors.white12,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: enabled ? 'check_circle' : 'cancel',
              color: enabled ? AppTheme.success : Colors.white30,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    final unread = _alerts.where((a) => a['is_read'] != true).toList();
    if (unread.isEmpty) return const SizedBox.shrink();

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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${unread.length}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...unread.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String? ?? 'low';
    Color severityColor;
    String severityIcon;
    switch (severity) {
      case 'high':
      case 'critical':
        severityColor = AppTheme.error;
        severityIcon = 'warning';
        break;
      case 'medium':
        severityColor = AppTheme.warning;
        severityIcon = 'info';
        break;
      default:
        severityColor = AppTheme.primaryLight;
        severityIcon = 'notifications';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: severityColor.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: severityColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: severityColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: severityIcon,
                color: severityColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['message'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(alert['created_at'] as String?),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _dismissAlert(alert['id'] as String),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const CustomIconWidget(
                iconName: 'close',
                color: AppTheme.mutedLight,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Devices',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        if (_sessions.isEmpty)
          _buildEmptyState('No active sessions found', 'devices')
        else
          ..._sessions.map((session) => _buildDeviceCard(session)),
      ],
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> session) {
    final isActive = session['is_active'] == true;
    final deviceType = session['device_type'] as String? ?? 'Unknown';
    String deviceIcon;
    switch (deviceType.toLowerCase()) {
      case 'android':
      case 'ios':
        deviceIcon = 'smartphone';
        break;
      case 'desktop':
        deviceIcon = 'laptop';
        break;
      default:
        deviceIcon = 'devices';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.success.withAlpha(15)
                  : AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: deviceIcon,
                color: isActive ? AppTheme.success : AppTheme.mutedLight,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session['device_name'] as String? ?? 'Unknown Device',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.successContainer
                            : AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.plusJakartaSans(
                          color: isActive
                              ? AppTheme.success
                              : AppTheme.mutedLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${session['location'] ?? 'Unknown'} · ${session['ip_address'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Last active: ${_formatDate(session['last_active_at'] as String?)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            GestureDetector(
              onTap: () => _terminateSession(session['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'End',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        if (_auditLogs.isEmpty)
          _buildEmptyState('No activity recorded yet', 'history')
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: List.generate(
                _auditLogs.length > 8 ? 8 : _auditLogs.length,
                (i) {
                  final log = _auditLogs[i];
                  final isLast =
                      i == (_auditLogs.length > 8 ? 7 : _auditLogs.length - 1);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getSeverityColor(
                                  log['severity'] as String?,
                                ).withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: _getModuleIcon(
                                    log['module'] as String?,
                                  ),
                                  color: _getSeverityColor(
                                    log['severity'] as String?,
                                  ),
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log['action'] as String? ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.onSurfaceLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatDate(log['created_at'] as String?),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AppTheme.mutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: AppTheme.outlineLight,
                          indent: 56,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: [
              _buildSettingRow(
                'Two-Factor Authentication',
                'security',
                _userProfile?['two_factor_enabled'] == true,
                const Color(0xFFF59E0B),
              ),
              Divider(height: 1, color: AppTheme.outlineLight, indent: 56),
              _buildSettingRow(
                'Biometric Login',
                'fingerprint',
                _userProfile?['biometric_enabled'] == true,
                const Color(0xFF10B981),
              ),
              Divider(height: 1, color: AppTheme.outlineLight, indent: 56),
              _buildSettingRow(
                'Email Verified',
                'email',
                _userProfile?['email_verified'] == true,
                AppTheme.primaryLight,
              ),
              Divider(height: 1, color: AppTheme.outlineLight, indent: 56),
              _buildSettingRow(
                'Phone Verified',
                'phone',
                _userProfile?['phone_verified'] == true,
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(
    String label,
    String icon,
    bool enabled,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(iconName: icon, color: color, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceLight,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: enabled
                  ? AppTheme.successContainer
                  : AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              enabled ? 'Enabled' : 'Disabled',
              style: GoogleFonts.plusJakartaSans(
                color: enabled ? AppTheme.success : AppTheme.mutedLight,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, String icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Center(
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.mutedLight,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.mutedLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'high':
      case 'critical':
        return AppTheme.error;
      case 'medium':
        return AppTheme.warning;
      default:
        return AppTheme.primaryLight;
    }
  }

  String _getModuleIcon(String? module) {
    switch (module) {
      case 'finance':
        return 'account_balance';
      case 'assets':
        return 'real_estate_agent';
      case 'business':
        return 'business_center';
      case 'settings':
        return 'settings';
      default:
        return 'history';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildEnterpriseAdminLink() {
    return GestureDetector(
      onTap: () => context.push('/enterprise-admin'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'admin_panel_settings',
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enterprise Administration',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Roles, permissions, audit logs, backup',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
