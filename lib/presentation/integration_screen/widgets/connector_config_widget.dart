import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/integration_service.dart';

class ConnectorConfigWidget extends StatefulWidget {
  const ConnectorConfigWidget({super.key});

  @override
  State<ConnectorConfigWidget> createState() => _ConnectorConfigWidgetState();
}

class _ConnectorConfigWidgetState extends State<ConnectorConfigWidget> {
  final _service = IntegrationService.instance;
  List<IntegrationConnector> _connectors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getIntegrations();
    if (mounted) {
      setState(() {
        _connectors = data;
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

  void _showConfigDialog(IntegrationConnector connector) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          connector.providerName,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _configRow(
              'Type',
              connector.providerType.replaceAll('_', ' ').toUpperCase(),
            ),
            _configRow('Status', connector.statusLabel),
            if (connector.configuration['last_sync'] != null)
              _configRow(
                'Last Sync',
                _formatDate(connector.configuration['last_sync']),
              ),
            if (connector.configuration['model'] != null)
              _configRow('Model', connector.configuration['model']),
            if (connector.configuration['provider'] != null)
              _configRow('Provider', connector.configuration['provider']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newStatus = connector.status == 'connected'
                  ? 'inactive'
                  : 'connected';
              await _service.updateIntegrationStatus(connector.id, newStatus);
              _load();
            },
            child: Text(
              connector.status == 'connected' ? 'Disconnect' : 'Activate',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.mutedLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.mutedLight,
          ),
        ),
        Expanded(
          child: Text(
            value,
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
  );

  String _formatDate(dynamic val) {
    try {
      final dt = DateTime.parse(val.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return val.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _connectors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = _connectors[i];
        final statusColor = _statusColor(c.status);
        return GestureDetector(
          onTap: () => _showConfigDialog(c),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: c.typeIcon,
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
                        c.providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.providerType.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
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
                      const SizedBox(width: 5),
                      Text(
                        c.statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.mutedLight,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}