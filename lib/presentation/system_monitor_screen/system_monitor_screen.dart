import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/error_service.dart';
import '../../services/monitoring_service.dart';
import '../../widgets/cna_shared_components.dart';

class SystemMonitorScreen extends StatefulWidget {
  const SystemMonitorScreen({super.key});

  @override
  State<SystemMonitorScreen> createState() => _SystemMonitorScreenState();
}

class _SystemMonitorScreenState extends State<SystemMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SystemHealthReport _healthReport;
  List<CnaError> _recentErrors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    // Seed some demo monitoring events
    final monitor = MonitoringService.instance;
    monitor.trackEvent(
      MonitoringEventType.userAction,
      'dashboard',
      description: 'Dashboard loaded',
    );
    monitor.trackEvent(
      MonitoringEventType.aiRequest,
      'ai_brain',
      description: 'AI analysis requested',
    );
    monitor.trackEvent(
      MonitoringEventType.apiCall,
      'finance',
      description: 'Finance data fetched',
    );
    monitor.trackEvent(
      MonitoringEventType.workflowExecution,
      'automation',
      description: 'Loan due alert triggered',
    );
    monitor.trackEvent(
      MonitoringEventType.securityEvent,
      'auth',
      description: 'User login successful',
    );
    monitor.trackApiCall('/api/finance/transactions', 245, 200);
    monitor.trackApiCall('/api/assets', 180, 200);
    monitor.trackApiCall('/api/analytics', 520, 200);
    monitor.trackApiCall('/api/ai/brain', 1200, 200);

    setState(() {
      _healthReport = monitor.getHealthReport();
      _recentErrors = ErrorService.instance.recentErrors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const CustomIconWidget(
                            iconName: 'arrow_back',
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'System Monitor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const CustomIconWidget(
                            iconName: 'refresh',
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _loadData,
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Row(
                        children: [
                          _buildHealthScore(),
                          const SizedBox(width: 16),
                          Expanded(child: _buildQuickStats()),
                        ],
                      ),
                    ),
                  ] else
                    const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Events'),
                      Tab(text: 'Modules'),
                      Tab(text: 'Errors'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const CnaLoadingState(message: 'Loading system data...')
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(theme),
                      _buildEventsTab(theme),
                      _buildModulesTab(theme),
                      _buildErrorsTab(theme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore() {
    final score = _healthReport.score;
    final color = score >= 90
        ? AppTheme.success
        : score >= 75
        ? const Color(0xFF2D9CDB)
        : score >= 60
        ? AppTheme.warning
        : AppTheme.error;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(60), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Health',
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _healthReport.healthLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildStatChip('${_healthReport.totalApiCalls} API calls', 'api'),
            const SizedBox(width: 8),
            _buildStatChip(
              '${_healthReport.aiRequestCount} AI requests',
              'psychology',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildStatChip(
              '${_healthReport.activeModules.length} modules',
              'extension',
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              '${_healthReport.failedLoginCount} failed logins',
              'lock',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Architecture overview
        CnaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'account_tree',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'System Architecture',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildArchLayer(theme, 'Presentation Layer', [
                'Dashboard',
                'Finance',
                'Assets',
                'Loans',
                'Business',
                'Investments',
                'AI',
                'Analytics',
                'Automation',
                'Admin',
                'Integrations',
              ], AppTheme.primaryLight),
              const SizedBox(height: 8),
              _buildArchLayer(theme, 'Business Logic Layer', [
                'Finance Engine',
                'Asset Engine',
                'Loan Engine',
                'Investment Engine',
                'Business Engine',
                'AI Brain',
                'Analytics Engine',
                'Automation Engine',
                'Security Engine',
                'Integration Engine',
              ], AppTheme.success),
              const SizedBox(height: 8),
              _buildArchLayer(theme, 'Infrastructure Layer', [
                'Supabase Auth',
                'Event Bus',
                'Notifications',
                'File Storage',
                'Monitoring',
                'Error Service',
              ], AppTheme.warning),
              const SizedBox(height: 8),
              _buildArchLayer(theme, 'Data Layer', [
                'PostgreSQL (Supabase)',
                'Row Level Security',
                'Object Storage',
                'Cache Layer',
              ], AppTheme.primary),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Module status grid
        CnaSectionHeader(title: 'Module Status', iconName: 'grid_view'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: _getModuleStatuses()
              .map((m) => _buildModuleStatusCard(theme, m))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Performance metrics
        CnaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'speed',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Performance Metrics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPerfRow(
                theme,
                'Avg API Response',
                '${_healthReport.avgApiResponseMs}ms',
                _healthReport.avgApiResponseMs < 500
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
              _buildPerfRow(
                theme,
                'API Error Rate',
                '${(_healthReport.apiErrorRate * 100).toStringAsFixed(1)}%',
                _healthReport.apiErrorRate < 0.05
                    ? AppTheme.success
                    : AppTheme.error,
              ),
              _buildPerfRow(
                theme,
                'Total API Calls',
                '${_healthReport.totalApiCalls}',
                AppTheme.primary,
              ),
              _buildPerfRow(
                theme,
                'AI Requests',
                '${_healthReport.aiRequestCount}',
                AppTheme.primaryLight,
              ),
              _buildPerfRow(
                theme,
                'Integration Failures',
                '${_healthReport.integrationFailures}',
                _healthReport.integrationFailures == 0
                    ? AppTheme.success
                    : AppTheme.error,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArchLayer(
    ThemeData theme,
    String label,
    List<String> items,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleStatusCard(ThemeData theme, Map<String, dynamic> module) {
    final isOnline = module['status'] == 'online';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  module['name'] as String,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOnline ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfRow(
    ThemeData theme,
    String label,
    String value,
    Color valueColor, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: theme.colorScheme.outline),
      ],
    );
  }

  Widget _buildEventsTab(ThemeData theme) {
    final events = _healthReport.recentEvents;
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'event_note',
              color: theme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No events recorded yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final event = events[i];
        return CnaCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _severityColor(event.severity).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: _eventTypeIcon(event.type),
                    color: _severityColor(event.severity),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.description ?? event.type.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${event.module} • ${_formatTime(event.timestamp)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _severityColor(event.severity).withAlpha(20),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  event.severity.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _severityColor(event.severity),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModulesTab(ThemeData theme) {
    final usage = MonitoringService.instance.moduleUsage;
    final allModules = _getModuleStatuses();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CnaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Module Usage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...allModules.map((m) {
                final calls = usage[m['module'] as String] ?? 0;
                final maxCalls = usage.values.fold(1, (a, b) => a > b ? a : b);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m['name'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '$calls calls',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxCalls > 0 ? calls / maxCalls : 0,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CnaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Modules',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _healthReport.activeModules
                    .map(
                      (m) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          m,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorsTab(ThemeData theme) {
    if (_recentErrors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.success,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              'No errors recorded',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'System is running cleanly',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _recentErrors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final error = _recentErrors[i];
        return CnaCard(
          borderColor: AppTheme.error.withAlpha(60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'error_outline',
                    color: AppTheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '[${error.module}] ${error.operation ?? 'Unknown operation'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.error,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTime(error.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                error.message,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getModuleStatuses() => [
    {'name': 'Finance Engine', 'module': 'finance', 'status': 'online'},
    {'name': 'Asset Engine', 'module': 'assets', 'status': 'online'},
    {'name': 'Loan Engine', 'module': 'loans', 'status': 'online'},
    {'name': 'Business Engine', 'module': 'business', 'status': 'online'},
    {'name': 'Investment Engine', 'module': 'investments', 'status': 'online'},
    {'name': 'AI Brain', 'module': 'ai_brain', 'status': 'online'},
    {'name': 'Analytics Engine', 'module': 'analytics', 'status': 'online'},
    {'name': 'Automation Engine', 'module': 'automation', 'status': 'online'},
    {'name': 'Security Engine', 'module': 'security', 'status': 'online'},
    {
      'name': 'Integration Engine',
      'module': 'integrations',
      'status': 'online',
    },
    {'name': 'Decision Engine', 'module': 'decisions', 'status': 'online'},
    {'name': 'Forecast Engine', 'module': 'forecast', 'status': 'online'},
  ];

  Color _severityColor(MonitoringSeverity s) {
    switch (s) {
      case MonitoringSeverity.info:
        return AppTheme.primaryLight;
      case MonitoringSeverity.warning:
        return AppTheme.warning;
      case MonitoringSeverity.error:
        return AppTheme.error;
      case MonitoringSeverity.critical:
        return const Color(0xFF7C0000);
    }
  }

  String _eventTypeIcon(MonitoringEventType t) {
    switch (t) {
      case MonitoringEventType.apiCall:
        return 'api';
      case MonitoringEventType.aiRequest:
        return 'psychology';
      case MonitoringEventType.failedLogin:
        return 'lock';
      case MonitoringEventType.securityEvent:
        return 'security';
      case MonitoringEventType.integrationFailure:
        return 'extension_off';
      case MonitoringEventType.workflowExecution:
        return 'bolt';
      case MonitoringEventType.backgroundJob:
        return 'schedule';
      case MonitoringEventType.dataExport:
        return 'download';
      case MonitoringEventType.permissionEscalation:
        return 'admin_panel_settings';
      case MonitoringEventType.systemError:
        return 'error';
      case MonitoringEventType.userAction:
        return 'person';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}
