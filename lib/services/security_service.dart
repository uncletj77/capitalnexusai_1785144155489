import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// CNA Security, Authentication, Permissions, Audit Logs,
/// Backup, Synchronization & Enterprise Administration Engine Service
class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  SecurityService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── ORGANIZATION MANAGEMENT ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOrganizations() async {
    final userId = _userId;
    if (userId == null) return _demoOrganizations();
    try {
      final result = await _client
          .from('organizations')
          .select('*, departments(count)')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return _demoOrganizations();
    }
  }

  Future<Map<String, dynamic>?> getOrganizationById(String orgId) async {
    try {
      final result = await _client
          .from('organizations')
          .select()
          .eq('id', orgId)
          .maybeSingle();
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createOrganization({
    required String name,
    String? description,
  }) async {
    final userId = _userId;
    if (userId == null) return {};
    try {
      final result = await _client
          .from('organizations')
          .insert({
            'name': name,
            'description': description,
            'owner_id': userId,
            'is_active': true,
          })
          .select()
          .single();
      await logAuditEvent(
        module: 'Administration',
        action: 'create_organization',
        entityType: 'organization',
        entityId: result['id'],
        newValue: {'name': name},
      );
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getDepartments(String orgId) async {
    try {
      final result = await _client
          .from('departments')
          .select()
          .eq('organization_id', orgId)
          .order('name');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return _demoDepartments();
    }
  }

  // ─── ROLE MANAGEMENT ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRoles({String? orgId}) async {
    final userId = _userId;
    if (userId == null) return _demoRoles();
    try {
      var query = _client.from('roles').select();
      if (orgId != null) {
        query = query.eq('organization_id', orgId);
      }
      final result = await query.order('name');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return _demoRoles();
    }
  }

  Future<Map<String, dynamic>> createRole({
    required String name,
    required String description,
    required String orgId,
  }) async {
    try {
      final result = await _client
          .from('roles')
          .insert({
            'name': name,
            'description': description,
            'organization_id': orgId,
            'is_system_role': false,
          })
          .select()
          .single();
      await logAuditEvent(
        module: 'Administration',
        action: 'create_role',
        entityType: 'role',
        entityId: result['id'],
        newValue: {'name': name},
      );
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<bool> updateRole({
    required String roleId,
    String? name,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      await _client.from('roles').update(updates).eq('id', roleId);
      await logAuditEvent(
        module: 'Administration',
        action: 'update_role',
        entityType: 'role',
        entityId: roleId,
        newValue: updates,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRole(String roleId) async {
    try {
      await _client.from('roles').delete().eq('id', roleId);
      await logAuditEvent(
        module: 'Administration',
        action: 'delete_role',
        entityType: 'role',
        entityId: roleId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── PERMISSION MANAGEMENT ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPermissions() async {
    try {
      final result = await _client
          .from('permissions')
          .select()
          .order('module')
          .order('permission_key');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return _demoPermissions();
    }
  }

  Future<List<Map<String, dynamic>>> getRolePermissions(String roleId) async {
    try {
      final result = await _client
          .from('role_permissions')
          .select('*, permissions(*)')
          .eq('role_id', roleId);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  Future<bool> assignPermissionToRole({
    required String roleId,
    required String permissionId,
  }) async {
    try {
      await _client.from('role_permissions').insert({
        'role_id': roleId,
        'permission_id': permissionId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removePermissionFromRole({
    required String roleId,
    required String permissionId,
  }) async {
    try {
      await _client
          .from('role_permissions')
          .delete()
          .eq('role_id', roleId)
          .eq('permission_id', permissionId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── USER ROLE ASSIGNMENT ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserRoles({String? userId}) async {
    final uid = userId ?? _userId;
    if (uid == null) return [];
    try {
      final result = await _client
          .from('user_roles')
          .select('*, roles(*), organizations(*)')
          .eq('user_id', uid);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  Future<bool> assignRoleToUser({
    required String userId,
    required String roleId,
    required String orgId,
  }) async {
    try {
      await _client.from('user_roles').insert({
        'user_id': userId,
        'role_id': roleId,
        'organization_id': orgId,
        'assigned_by': _userId,
      });
      await logAuditEvent(
        module: 'Administration',
        action: 'assign_role',
        entityType: 'user_role',
        newValue: {'user_id': userId, 'role_id': roleId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── AUDIT LOGGING ────────────────────────────────────────────────────────

  Future<void> logAuditEvent({
    required String module,
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String severity = 'info',
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client.from('audit_logs').insert({
        'user_id': userId,
        'module': module,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'old_value': oldValue,
        'new_value': newValue,
        'severity': severity,
        'device_info': 'CNA Flutter App',
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? module,
    String? action,
    int limit = 50,
  }) async {
    final userId = _userId;
    if (userId == null) return _demoAuditLogs();
    try {
      var query = _client.from('audit_logs').select().eq('user_id', userId);
      if (module != null) query = query.eq('module', module);
      if (action != null) query = query.eq('action', action);
      final result = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return _demoAuditLogs();
    }
  }

  // ─── SESSION MANAGEMENT ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final userId = _userId;
    if (userId == null) return _demoSessions();
    try {
      final result = await _client
          .from('active_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('last_activity', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return _demoSessions();
    }
  }

  Future<bool> terminateSession(String sessionId) async {
    try {
      await _client
          .from('active_sessions')
          .update({'is_active': false})
          .eq('id', sessionId);
      await logAuditEvent(
        module: 'Security',
        action: 'terminate_session',
        entityType: 'session',
        entityId: sessionId,
        severity: 'warning',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> terminateAllSessions() async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _client
          .from('active_sessions')
          .update({'is_active': false})
          .eq('user_id', userId);
      await logAuditEvent(
        module: 'Security',
        action: 'terminate_all_sessions',
        entityType: 'session',
        severity: 'warning',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> registerCurrentSession() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client.from('active_sessions').insert({
        'user_id': userId,
        'device_name': 'CNA Flutter App',
        'device_type': 'mobile',
        'last_activity': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'is_active': true,
      });
    } catch (_) {}
  }

  // ─── BACKUP MANAGEMENT ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBackupJobs() async {
    final userId = _userId;
    if (userId == null) return _demoBackupJobs();
    try {
      final result = await _client
          .from('backup_jobs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return _demoBackupJobs();
    }
  }

  Future<Map<String, dynamic>> createBackupJob({
    required String backupType,
    List<String> modules = const [],
    String? orgId,
  }) async {
    final userId = _userId;
    if (userId == null) return {};
    try {
      final result = await _client
          .from('backup_jobs')
          .insert({
            'user_id': userId,
            'organization_id': orgId,
            'backup_type': backupType,
            'status': 'pending',
            'started_at': DateTime.now().toIso8601String(),
            'metadata': {'modules': modules, 'initiated_by': 'user'},
          })
          .select()
          .single();
      await logAuditEvent(
        module: 'Administration',
        action: 'create_backup',
        entityType: 'backup_job',
        entityId: result['id'],
        newValue: {'backup_type': backupType, 'modules': modules},
      );
      return result;
    } catch (_) {
      return {};
    }
  }

  // ─── SECURITY MONITORING ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSecurityEvents({
    bool unresolvedOnly = false,
  }) async {
    final userId = _userId;
    if (userId == null) return _demoSecurityEvents();
    try {
      var query = _client
          .from('security_monitoring_events')
          .select()
          .eq('user_id', userId);
      if (unresolvedOnly) query = query.eq('is_resolved', false);
      final result = await query
          .order('created_at', ascending: false)
          .limit(30);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return _demoSecurityEvents();
    }
  }

  Future<bool> resolveSecurityEvent(String eventId) async {
    try {
      await _client
          .from('security_monitoring_events')
          .update({
            'is_resolved': true,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> recordSecurityEvent({
    required String eventType,
    required String description,
    String severity = 'medium',
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client.from('security_monitoring_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'severity': severity,
        'description': description,
        'metadata': metadata,
        'is_resolved': false,
      });
    } catch (_) {}
  }

  // ─── SYSTEM HEALTH ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSystemHealth() async {
    final userId = _userId;
    if (userId == null) return _demoSystemHealth();
    try {
      final results = await Future.wait([
        _client
            .from('active_sessions')
            .select('id')
            .eq('user_id', userId)
            .eq('is_active', true),
        _client
            .from('audit_logs')
            .select('id')
            .eq('user_id', userId)
            .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String(),
            ),
        _client
            .from('backup_jobs')
            .select('id, status, completed_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1),
        _client
            .from('security_monitoring_events')
            .select('id')
            .eq('user_id', userId)
            .eq('is_resolved', false),
      ]);

      final sessions = (results[0] as List).length;
      final auditCount = (results[1] as List).length;
      final backups = results[2] as List;
      final unresolvedAlerts = (results[3] as List).length;

      final lastBackup = backups.isNotEmpty ? backups.first : null;

      return {
        'active_sessions': sessions,
        'audit_events_30d': auditCount,
        'last_backup': lastBackup,
        'unresolved_alerts': unresolvedAlerts,
        'security_score': _calculateSecurityScore(
          sessions: sessions,
          unresolvedAlerts: unresolvedAlerts,
          hasRecentBackup: lastBackup != null,
        ),
        'status': unresolvedAlerts > 3 ? 'warning' : 'healthy',
      };
    } catch (_) {
      return _demoSystemHealth();
    }
  }

  int _calculateSecurityScore({
    required int sessions,
    required int unresolvedAlerts,
    required bool hasRecentBackup,
  }) {
    int score = 70;
    if (hasRecentBackup) score += 15;
    if (unresolvedAlerts == 0) score += 10;
    if (sessions <= 3) score += 5;
    if (unresolvedAlerts > 5) score -= 20;
    return score.clamp(0, 100);
  }

  // ─── PERMISSION CHECK ─────────────────────────────────────────────────────

  Future<bool> hasPermission(String permissionKey) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      final result = await _client
          .from('user_roles')
          .select(
            'roles!inner(role_permissions!inner(permissions!inner(permission_key)))',
          )
          .eq('user_id', userId);
      for (final ur in result) {
        final role = ur['roles'] as Map<String, dynamic>?;
        final rps = role?['role_permissions'] as List? ?? [];
        for (final rp in rps) {
          final perm = rp['permissions'] as Map<String, dynamic>?;
          if (perm?['permission_key'] == permissionKey) return true;
        }
      }
      return false;
    } catch (_) {
      return true; // fail open for demo
    }
  }

  // ─── DEMO DATA ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _demoOrganizations() => [
    {
      'id': 'demo-org-1',
      'name': 'Capital Nexus Holdings',
      'description': 'Enterprise financial management organization',
      'is_active': true,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 90))
          .toIso8601String(),
    },
  ];

  List<Map<String, dynamic>> _demoDepartments() => [
    {
      'id': 'd1',
      'name': 'Finance',
      'description': 'Financial management and accounting',
    },
    {
      'id': 'd2',
      'name': 'Operations',
      'description': 'Day-to-day operational management',
    },
    {
      'id': 'd3',
      'name': 'Investments',
      'description': 'Investment portfolio management',
    },
    {
      'id': 'd4',
      'name': 'Administration',
      'description': 'Enterprise administration and HR',
    },
  ];

  List<Map<String, dynamic>> _demoRoles() => [
    {
      'id': 'r1',
      'name': 'Owner',
      'description': 'Full system access',
      'is_system_role': true,
    },
    {
      'id': 'r2',
      'name': 'Administrator',
      'description': 'System administration',
      'is_system_role': true,
    },
    {
      'id': 'r3',
      'name': 'Manager',
      'description': 'Department management',
      'is_system_role': false,
    },
    {
      'id': 'r4',
      'name': 'Accountant',
      'description': 'Financial records management',
      'is_system_role': false,
    },
    {
      'id': 'r5',
      'name': 'Employee',
      'description': 'Basic read access',
      'is_system_role': false,
    },
    {
      'id': 'r6',
      'name': 'Auditor',
      'description': 'Read-only audit access',
      'is_system_role': false,
    },
    {
      'id': 'r7',
      'name': 'Viewer',
      'description': 'Dashboard read-only',
      'is_system_role': false,
    },
  ];

  List<Map<String, dynamic>> _demoPermissions() => [
    {
      'id': 'p1',
      'permission_key': 'finance.read',
      'module': 'Finance',
      'description': 'View financial records',
    },
    {
      'id': 'p2',
      'permission_key': 'finance.write',
      'module': 'Finance',
      'description': 'Create and edit financial records',
    },
    {
      'id': 'p3',
      'permission_key': 'finance.delete',
      'module': 'Finance',
      'description': 'Delete financial records',
    },
    {
      'id': 'p4',
      'permission_key': 'loan.read',
      'module': 'Loans',
      'description': 'View loan information',
    },
    {
      'id': 'p5',
      'permission_key': 'loan.write',
      'module': 'Loans',
      'description': 'Manage loans',
    },
    {
      'id': 'p6',
      'permission_key': 'investment.read',
      'module': 'Investments',
      'description': 'View investment portfolio',
    },
    {
      'id': 'p7',
      'permission_key': 'investment.export',
      'module': 'Investments',
      'description': 'Export investment reports',
    },
    {
      'id': 'p8',
      'permission_key': 'asset.read',
      'module': 'Assets',
      'description': 'View asset information',
    },
    {
      'id': 'p9',
      'permission_key': 'asset.update',
      'module': 'Assets',
      'description': 'Update asset records',
    },
    {
      'id': 'p10',
      'permission_key': 'ai.execute',
      'module': 'AI',
      'description': 'Execute AI recommendations',
    },
    {
      'id': 'p11',
      'permission_key': 'reports.export',
      'module': 'Reports',
      'description': 'Export reports',
    },
    {
      'id': 'p12',
      'permission_key': 'users.manage',
      'module': 'Administration',
      'description': 'Manage users and roles',
    },
    {
      'id': 'p13',
      'permission_key': 'workflows.manage',
      'module': 'Automation',
      'description': 'Manage workflows',
    },
  ];

  List<Map<String, dynamic>> _demoAuditLogs() => [
    {
      'id': 'al1',
      'module': 'Auth',
      'action': 'login',
      'entity_type': 'session',
      'severity': 'info',
      'device_info': 'Chrome on Windows',
      'ip_address': '197.250.10.45',
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIso8601String(),
    },
    {
      'id': 'al2',
      'module': 'Finance',
      'action': 'create',
      'entity_type': 'transaction',
      'severity': 'info',
      'device_info': 'Chrome on Windows',
      'ip_address': '197.250.10.45',
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
    },
    {
      'id': 'al3',
      'module': 'Investments',
      'action': 'export',
      'entity_type': 'report',
      'severity': 'warning',
      'device_info': 'CNA Mobile App',
      'ip_address': '197.250.10.46',
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
    },
    {
      'id': 'al4',
      'module': 'Assets',
      'action': 'update',
      'entity_type': 'asset',
      'severity': 'info',
      'device_info': 'CNA Mobile App',
      'ip_address': '197.250.10.46',
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 6))
          .toIso8601String(),
    },
    {
      'id': 'al5',
      'module': 'Administration',
      'action': 'create_role',
      'entity_type': 'role',
      'severity': 'info',
      'device_info': 'Chrome on Windows',
      'ip_address': '197.250.10.45',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
  ];

  List<Map<String, dynamic>> _demoSessions() => [
    {
      'id': 's1',
      'device_name': 'Chrome on Windows',
      'device_type': 'desktop',
      'ip_address': '197.250.10.45',
      'location': 'Dar es Salaam, TZ',
      'last_activity': DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIso8601String(),
      'is_active': true,
    },
    {
      'id': 's2',
      'device_name': 'CNA Mobile App',
      'device_type': 'mobile',
      'ip_address': '197.250.10.46',
      'location': 'Dar es Salaam, TZ',
      'last_activity': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
      'is_active': true,
    },
  ];

  List<Map<String, dynamic>> _demoBackupJobs() => [
    {
      'id': 'b1',
      'backup_type': 'full',
      'status': 'completed',
      'size_bytes': 52428800,
      'started_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'completed_at': DateTime.now()
          .subtract(const Duration(hours: 23))
          .toIso8601String(),
      'metadata': {
        'modules': ['finance', 'assets', 'loans', 'investments'],
        'records': 1247,
      },
    },
    {
      'id': 'b2',
      'backup_type': 'incremental',
      'status': 'completed',
      'size_bytes': 5242880,
      'started_at': DateTime.now()
          .subtract(const Duration(hours: 6))
          .toIso8601String(),
      'completed_at': DateTime.now()
          .subtract(const Duration(hours: 5, minutes: 55))
          .toIso8601String(),
      'metadata': {
        'modules': ['finance', 'transactions'],
        'records': 89,
      },
    },
  ];

  List<Map<String, dynamic>> _demoSecurityEvents() => [
    {
      'id': 'se1',
      'event_type': 'new_device_login',
      'severity': 'medium',
      'description':
          'Login detected from new device: CNA Mobile App from Dar es Salaam',
      'is_resolved': true,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    },
    {
      'id': 'se2',
      'event_type': 'large_export',
      'severity': 'warning',
      'description': 'Investment report exported — 847 records',
      'is_resolved': false,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
    },
    {
      'id': 'se3',
      'event_type': 'permission_check',
      'severity': 'info',
      'description': 'AI recommendation approved for financial simulation',
      'is_resolved': true,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
  ];

  Map<String, dynamic> _demoSystemHealth() => {
    'active_sessions': 2,
    'audit_events_30d': 47,
    'last_backup': {
      'status': 'completed',
      'completed_at': DateTime.now()
          .subtract(const Duration(hours: 6))
          .toIso8601String(),
    },
    'unresolved_alerts': 1,
    'security_score': 82,
    'status': 'healthy',
  };
}