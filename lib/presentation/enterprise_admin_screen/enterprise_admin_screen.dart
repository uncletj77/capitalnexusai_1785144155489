import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/security_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/audit_log_viewer_widget.dart';
import './widgets/backup_manager_widget.dart';
import './widgets/role_management_widget.dart';
import './widgets/security_alerts_widget.dart';
import './widgets/system_health_widget.dart';

class EnterpriseAdminScreen extends StatefulWidget {
  const EnterpriseAdminScreen({super.key});

  @override
  State<EnterpriseAdminScreen> createState() => _EnterpriseAdminScreenState();
}

class _EnterpriseAdminScreenState extends State<EnterpriseAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isCreatingBackup = false;

  List<Map<String, dynamic>> _organizations = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _permissions = [];
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _backupJobs = [];
  List<Map<String, dynamic>> _securityEvents = [];
  Map<String, dynamic> _systemHealth = {};
  String? _auditFilterModule;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SecurityService.instance.getOrganizations(),
        SecurityService.instance.getRoles(),
        SecurityService.instance.getPermissions(),
        SecurityService.instance.getAuditLogs(limit: 30),
        SecurityService.instance.getBackupJobs(),
        SecurityService.instance.getSecurityEvents(),
        SecurityService.instance.getSystemHealth(),
      ]);
      setState(() {
        _organizations = results[0] as List<Map<String, dynamic>>;
        _roles = results[1] as List<Map<String, dynamic>>;
        _permissions = results[2] as List<Map<String, dynamic>>;
        _auditLogs = results[3] as List<Map<String, dynamic>>;
        _backupJobs = results[4] as List<Map<String, dynamic>>;
        _securityEvents = results[5] as List<Map<String, dynamic>>;
        _systemHealth = results[6] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    final result = await SecurityService.instance.createBackupJob(
      backupType: 'manual',
      modules: ['finance', 'assets', 'loans', 'investments', 'businesses'],
    );
    if (result.isNotEmpty) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup initiated successfully',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    setState(() => _isCreatingBackup = false);
  }

  Future<void> _resolveSecurityEvent(String eventId) async {
    await SecurityService.instance.resolveSecurityEvent(eventId);
    setState(() {
      final idx = _securityEvents.indexWhere((e) => e['id'] == eventId);
      if (idx != -1) _securityEvents[idx]['is_resolved'] = true;
    });
  }

  Future<void> _loadFilteredAuditLogs(String? module) async {
    setState(() => _auditFilterModule = module);
    final logs = await SecurityService.instance.getAuditLogs(
      module: module,
      limit: 30,
    );
    setState(() => _auditLogs = logs);
  }

  void _showAddRoleDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Create New Role',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Role Name',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.mutedLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.mutedLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.mutedLight),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && _organizations.isNotEmpty) {
                Navigator.pop(ctx);
                await SecurityService.instance.createRole(
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  orgId: _organizations.first['id'] ?? '',
                );
                await _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Create',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildRolesTab(),
                        _buildAuditTab(),
                        _buildBackupTab(),
                        _buildAlertsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  'Enterprise Administration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  'Capital Nexus Holdings',
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

  Widget _buildTabBar() {
    final tabs = [
      {'icon': 'dashboard', 'label': 'Overview'},
      {'icon': 'manage_accounts', 'label': 'Roles'},
      {'icon': 'history', 'label': 'Audit'},
      {'icon': 'backup', 'label': 'Backup'},
      {'icon': 'security', 'label': 'Alerts'},
    ];

    return Container(
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.mutedLight,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        tabs: tabs.map((t) {
          return Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: t['icon']!,
                  color: AppTheme.mutedLight,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(t['label']!),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final org = _organizations.isNotEmpty ? _organizations.first : null;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SystemHealthWidget(health: _systemHealth),
          const SizedBox(height: 16),
          if (org != null) _buildOrgCard(org),
          const SizedBox(height: 16),
          _buildDepartmentsGrid(),
          const SizedBox(height: 16),
          _buildPermissionMatrix(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrgCard(Map<String, dynamic> org) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'business',
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
                  org['name'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  org['description'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              org['is_active'] == true ? 'Active' : 'Inactive',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentsGrid() {
    final depts = [
      {'name': 'Finance', 'icon': 'account_balance', 'color': AppTheme.success},
      {'name': 'Operations', 'icon': 'settings', 'color': AppTheme.primary},
      {
        'name': 'Investments',
        'icon': 'trending_up',
        'color': AppTheme.primaryLight,
      },
      {
        'name': 'Administration',
        'icon': 'admin_panel_settings',
        'color': AppTheme.warning,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Departments',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: depts.length,
          itemBuilder: (context, i) {
            final dept = depts[i];
            final color = dept['color'] as Color;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: dept['icon'] as String,
                        color: color,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dept['name'] as String,
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
          },
        ),
      ],
    );
  }

  Widget _buildPermissionMatrix() {
    final moduleGroups = <String, List<Map<String, dynamic>>>{};
    for (final p in _permissions) {
      final mod = p['module'] ?? 'Other';
      moduleGroups.putIfAbsent(mod, () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permission Matrix',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        ...moduleGroups.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.value.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p['permission_key'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRolesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RoleManagementWidget(
            roles: _roles,
            permissions: _permissions,
            onAddRole: _showAddRoleDialog,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAuditTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AuditLogViewerWidget(
            logs: _auditLogs,
            filterModule: _auditFilterModule,
            onFilterChanged: _loadFilteredAuditLogs,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BackupManagerWidget(
            backupJobs: _backupJobs,
            isCreatingBackup: _isCreatingBackup,
            onCreateBackup: _createBackup,
          ),
          const SizedBox(height: 16),
          _buildSyncArchitectureCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSyncArchitectureCard() {
    final syncItems = [
      {
        'label': 'Offline Queue',
        'status': 'Active',
        'icon': 'offline_bolt',
        'ok': true,
      },
      {
        'label': 'Conflict Resolution',
        'status': 'Timestamp-based',
        'icon': 'merge_type',
        'ok': true,
      },
      {
        'label': 'Auto Sync',
        'status': 'On reconnect',
        'icon': 'sync',
        'ok': true,
      },
      {
        'label': 'Version Control',
        'status': 'Enabled',
        'icon': 'history',
        'ok': true,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomIconWidget(
                iconName: 'cloud_sync',
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Synchronization Engine',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...syncItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: item['icon'] as String,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['status'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SecurityAlertsWidget(
            events: _securityEvents,
            onResolve: _resolveSecurityEvent,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
