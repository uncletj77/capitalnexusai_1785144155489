import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/integration_marketplace_widget.dart';
import './widgets/connector_config_widget.dart';
import './widgets/api_key_manager_widget.dart';
import './widgets/import_wizard_widget.dart';
import './widgets/export_wizard_widget.dart';
import './widgets/webhook_monitor_widget.dart';
import './widgets/integration_logs_widget.dart';
import './widgets/event_monitor_widget.dart';
import './widgets/provider_status_dashboard_widget.dart';

class IntegrationScreen extends StatefulWidget {
  const IntegrationScreen({super.key});

  @override
  State<IntegrationScreen> createState() => _IntegrationScreenState();
}

class _IntegrationScreenState extends State<IntegrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = [
    {'label': 'Marketplace', 'icon': 'store'},
    {'label': 'Connectors', 'icon': 'cable'},
    {'label': 'API Keys', 'icon': 'vpn_key'},
    {'label': 'Import', 'icon': 'upload_file'},
    {'label': 'Export', 'icon': 'download'},
    {'label': 'Webhooks', 'icon': 'webhook'},
    {'label': 'Logs', 'icon': 'receipt_long'},
    {'label': 'Events', 'icon': 'sensors'},
    {'label': 'Status', 'icon': 'monitor_heart'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.onSurfaceLight,
              size: 22,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Integration Engine',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            Text(
              'Enterprise Extensibility Platform',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.mutedLight,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Live',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.outlineLight)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primaryLight,
              indicatorWeight: 2,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.mutedLight,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
              tabs: _tabs
                  .map(
                    (t) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: t['icon']!,
                            color: AppTheme.mutedLight,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(t['label']!),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          IntegrationMarketplaceWidget(
            onConnectTap: () => _tabController.animateTo(1),
          ),
          const ConnectorConfigWidget(),
          const ApiKeyManagerWidget(),
          const ImportWizardWidget(),
          const ExportWizardWidget(),
          const WebhookMonitorWidget(),
          const IntegrationLogsWidget(),
          const EventMonitorWidget(),
          const ProviderStatusDashboardWidget(),
        ],
      ),
    );
  }
}