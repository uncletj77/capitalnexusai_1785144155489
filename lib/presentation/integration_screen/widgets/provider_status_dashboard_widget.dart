import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/integration_service.dart';

class ProviderStatusDashboardWidget extends StatefulWidget {
  const ProviderStatusDashboardWidget({super.key});

  @override
  State<ProviderStatusDashboardWidget> createState() =>
      _ProviderStatusDashboardWidgetState();
}

class _ProviderStatusDashboardWidgetState
    extends State<ProviderStatusDashboardWidget> {
  final _service = IntegrationService.instance;
  List<Map<String, dynamic>> _providers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getProviderStatus();
    if (mounted) {
      setState(() {
        _providers = data;
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'connected':
        return const Color(0xFF10B981);
      case 'configured':
        return const Color(0xFF2D9CDB);
      case 'error':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.mutedLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final connected = _providers
        .where((p) => p['status'] == 'connected')
        .length;
    final configured = _providers
        .where((p) => p['status'] == 'configured')
        .length;
    final inactive = _providers.where((p) => p['status'] == 'inactive').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall health
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A5F7A),
                  const Color(0xFF1A5F7A).withAlpha(200),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Integration Health',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _healthStat(
                      'Connected',
                      connected.toString(),
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    _healthStat(
                      'Configured',
                      configured.toString(),
                      const Color(0xFF2D9CDB),
                    ),
                    const SizedBox(width: 12),
                    _healthStat(
                      'Inactive',
                      inactive.toString(),
                      Colors.white54,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Provider Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 10),
          ..._providers.map((p) {
            final statusColor = _statusColor(p['status'] as String);
            final lastSync = p['last_sync'];
            String lastSyncText = 'Never synced';
            if (lastSync != null) {
              try {
                final dt = DateTime.parse(lastSync.toString());
                final diff = DateTime.now().difference(dt);
                if (diff.inMinutes < 60) {
                  lastSyncText = '${diff.inMinutes}m ago';
                } else if (diff.inHours < 24)
                  lastSyncText = '${diff.inHours}h ago';
                else
                  lastSyncText = '${diff.inDays}d ago';
              } catch (_) {}
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
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
                        color: statusColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: p['icon'] as String,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['provider'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (p['type'] as String)
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Last sync: $lastSyncText',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (p['status'] as String)[0].toUpperCase() +
                                    (p['status'] as String).substring(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          // Architecture note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLight.withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'architecture',
                      color: AppTheme.primaryLight,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connector Architecture',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'All integrations use reusable connector interfaces. Banking, Mobile Money, AI, and Payment providers are interchangeable without modifying business logic.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthStat(String label, String value, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    ),
  );
}
