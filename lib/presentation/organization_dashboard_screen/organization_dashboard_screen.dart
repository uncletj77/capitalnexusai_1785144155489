import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  const OrganizationDashboardScreen({super.key});

  @override
  State<OrganizationDashboardScreen> createState() =>
      _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState
    extends State<OrganizationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _organization;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _permissions = [];
  String? _errorMessage;

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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please sign in to manage your organization.';
        });
        return;
      }

      // Get organization owned by user
      final orgData = await client
          .from('organizations')
          .select()
          .eq('owner_id', userId)
          .maybeSingle();

      if (orgData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No organization found. Create one to get started.';
        });
        return;
      }

      final orgId = orgData['id'] as String;

      // Fetch each dataset separately to avoid join failures
      final membersRaw = await client
          .from('organization_members')
          .select()
          .eq('organization_id', orgId);

      final departments = await client
          .from('departments')
          .select()
          .eq('organization_id', orgId);

      final roles = await client
          .from('roles')
          .select()
          .eq('organization_id', orgId);

      final permissions = await client
          .from('permissions')
          .select()
          .order('module')
          .limit(50);

      // Enrich members with profile data
      final members = <Map<String, dynamic>>[];
      for (final m in membersRaw) {
        final memberId = m['user_id'] as String?;
        Map<String, dynamic>? profile;
        if (memberId != null) {
          try {
            profile = await client
                .from('user_profiles')
                .select('full_name, email, profile_photo_url')
                .eq('id', memberId)
                .maybeSingle();
          } catch (_) {}
        }
        final roleId = m['role_id'] as String?;
        Map<String, dynamic>? role;
        if (roleId != null) {
          try {
            role = (roles as List).cast<Map<String, dynamic>>().firstWhere(
              (r) => r['id'] == roleId,
              orElse: () => <String, dynamic>{},
            );
          } catch (_) {}
        }
        final deptId = m['department_id'] as String?;
        Map<String, dynamic>? dept;
        if (deptId != null) {
          try {
            dept = (departments as List)
                .cast<Map<String, dynamic>>()
                .firstWhere(
                  (d) => d['id'] == deptId,
                  orElse: () => <String, dynamic>{},
                );
          } catch (_) {}
        }
        members.add({
          ...m,
          'user_profiles': profile,
          'roles': role,
          'departments': dept,
        });
      }

      setState(() {
        _organization = orgData;
        _members = members;
        _departments = List<Map<String, dynamic>>.from(departments);
        _roles = List<Map<String, dynamic>>.from(roles);
        _permissions = List<Map<String, dynamic>>.from(permissions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load organization data. Tap refresh to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_organization != null) _buildOrgCard(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMembersTab(),
                        _buildDepartmentsTab(),
                        _buildRolesTab(),
                        _buildPermissionsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _organization != null
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              backgroundColor: AppTheme.primary,
              child: const CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 24,
              ),
            )
          : null,
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
                  'Organization',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  'Manage your organization',
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

  Widget _buildOrgCard() {
    final org = _organization!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'corporate_fare',
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org['name'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${org['industry'] ?? ''} · ${org['city'] ?? ''}, ${org['country'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildOrgStat('${_members.length}', 'Members'),
                    const SizedBox(width: 16),
                    _buildOrgStat('${_departments.length}', 'Depts'),
                    const SizedBox(width: 16),
                    _buildOrgStat('${_roles.length}', 'Roles'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.mutedLight,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Members'),
          Tab(text: 'Departments'),
          Tab(text: 'Roles'),
          Tab(text: 'Permissions'),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return _buildEmptyState(
        'No members yet',
        'group',
        'Invite team members to get started',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, i) {
        final member = _members[i];
        final profile = member['user_profiles'] as Map<String, dynamic>?;
        final role = member['roles'] as Map<String, dynamic>?;
        final dept = member['departments'] as Map<String, dynamic>?;
        final name = profile?['full_name'] as String? ?? 'Unknown';
        final email = profile?['email'] as String? ?? '';
        final roleName = role?['name'] as String? ?? 'Member';
        final deptName = dept?['name'] as String? ?? '';

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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
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
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (deptName.isNotEmpty)
                      Text(
                        deptName,
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
                  color: _getRoleColor(roleName).withAlpha(15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _getRoleColor(roleName).withAlpha(60),
                  ),
                ),
                child: Text(
                  roleName,
                  style: GoogleFonts.plusJakartaSans(
                    color: _getRoleColor(roleName),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepartmentsTab() {
    if (_departments.isEmpty) {
      return _buildEmptyState(
        'No departments yet',
        'business',
        'Create departments to organize your team',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _departments.length,
      itemBuilder: (context, i) {
        final dept = _departments[i];
        final memberCount = _members
            .where((m) => m['department_id'] == dept['id'])
            .length;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
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
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'business',
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept['name'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    if ((dept['description'] as String?)?.isNotEmpty == true)
                      Text(
                        dept['description'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.mutedLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '$memberCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      'members',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRolesTab() {
    if (_roles.isEmpty) {
      return _buildEmptyState(
        'No roles defined',
        'manage_accounts',
        'Create roles to manage access control',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _roles.length,
      itemBuilder: (context, i) {
        final role = _roles[i];
        final roleName = role['name'] as String? ?? '';
        final color = _getRoleColor(roleName);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
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
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: _getRoleIcon(roleName),
                    color: color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    if ((role['description'] as String?)?.isNotEmpty == true)
                      Text(
                        role['description'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.mutedLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (role['is_system_role'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'System',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionsTab() {
    // Group permissions by module
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final perm in _permissions) {
      final module = perm['module'] as String? ?? 'other';
      grouped.putIfAbsent(module, () => []).add(perm);
    }

    if (grouped.isEmpty) {
      return _buildEmptyState(
        'No permissions defined',
        'lock',
        'Permissions control what users can do',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: _getModuleIcon(entry.key),
                          color: AppTheme.primary,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.outlineLight),
              ...entry.value.map((perm) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          perm['description'] as String? ??
                              perm['action'] as String? ??
                              '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          perm['action'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.mutedLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
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
      }).toList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomIconWidget(
              iconName: 'corporate_fare',
              color: AppTheme.mutedLight,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.mutedLight,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showCreateOrgDialog,
              child: const Text('Create Organization'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String icon, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.mutedLight,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onSurfaceLight,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.mutedLight,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    final tabIndex = _tabController.index;
    switch (tabIndex) {
      case 0:
        _showInviteMemberDialog();
        break;
      case 1:
        _showCreateDeptDialog();
        break;
      case 2:
        _showCreateRoleDialog();
        break;
      default:
        break;
    }
  }

  void _showCreateOrgDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Create Organization',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Organization Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final client = Supabase.instance.client;
                final userId = client.auth.currentUser?.id;
                await client.from('organizations').insert({
                  'name': nameCtrl.text.trim(),
                  'owner_id': userId,
                });
                _loadData();
              } catch (_) {}
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showInviteMemberDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite member feature coming soon')),
    );
  }

  void _showCreateDeptDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'New Department',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Department Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.from('departments').insert({
                  'organization_id': _organization!['id'],
                  'name': nameCtrl.text.trim(),
                });
                _loadData();
              } catch (_) {}
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'New Role',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Role Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.from('roles').insert({
                  'organization_id': _organization!['id'],
                  'name': nameCtrl.text.trim(),
                });
                _loadData();
              } catch (_) {}
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'owner':
        return const Color(0xFFF59E0B);
      case 'administrator':
      case 'admin':
        return AppTheme.error;
      case 'manager':
        return const Color(0xFF8B5CF6);
      case 'accountant':
        return AppTheme.primaryLight;
      case 'employee':
        return const Color(0xFF10B981);
      default:
        return AppTheme.mutedLight;
    }
  }

  String _getRoleIcon(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'owner':
        return 'star';
      case 'administrator':
      case 'admin':
        return 'admin_panel_settings';
      case 'manager':
        return 'manage_accounts';
      case 'accountant':
        return 'account_balance';
      case 'employee':
        return 'person';
      default:
        return 'badge';
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
      case 'investments':
        return 'show_chart';
      case 'loans':
        return 'credit_score';
      case 'reports':
        return 'bar_chart';
      case 'settings':
        return 'settings';
      case 'users':
        return 'group';
      case 'ai':
        return 'psychology';
      default:
        return 'lock';
    }
  }
}
