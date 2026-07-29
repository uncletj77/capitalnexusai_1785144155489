import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class EmployeeManagementScreen extends StatefulWidget {
  final Map<String, dynamic>? business;
  const EmployeeManagementScreen({super.key, this.business});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _branches = [];
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      String? bizId = widget.business?['id'] as String?;
      if (bizId == null) {
        final biz = await _client
            .from('businesses')
            .select('id')
            .eq('owner_id', userId)
            .limit(1)
            .maybeSingle();
        bizId = biz?['id'] as String?;
      }
      if (bizId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait(<Future<dynamic>>[
        _client
            .from('business_employees')
            .select()
            .eq('business_id', bizId)
            .order('full_name'),
        _client.from('business_departments').select().eq('business_id', bizId),
        _client.from('business_branches').select().eq('business_id', bizId),
      ]);

      setState(() {
        _employees = List<Map<String, dynamic>>.from(results[0]);
        _departments = List<Map<String, dynamic>>.from(results[1]);
        _branches = List<Map<String, dynamic>>.from(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _employees.where((e) {
      final matchStatus =
          _filterStatus == 'all' || e['emp_status'] == _filterStatus;
      final matchSearch =
          _searchQuery.isEmpty ||
          (e['full_name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (e['position'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchStatus && matchSearch;
    }).toList();
  }

  double get _totalPayroll => _employees
      .where((e) => e['emp_status'] == 'active')
      .fold(0.0, (s, e) => s + (e['salary'] as num? ?? 0).toDouble());

  String _fmt(double v) {
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  String? _deptName(String? deptId) => deptId == null
      ? null
      : _departments.firstWhere(
              (d) => d['id'] == deptId,
              orElse: () => {},
            )['name']
            as String?;
  String? _branchName(String? branchId) => branchId == null
      ? null
      : _branches.firstWhere(
              (b) => b['id'] == branchId,
              orElse: () => {},
            )['name']
            as String?;

  void _showAddEmployeeSheet([Map<String, dynamic>? existing]) {
    final nameCtrl = TextEditingController(text: existing?['full_name'] ?? '');
    final posCtrl = TextEditingController(text: existing?['position'] ?? '');
    final salaryCtrl = TextEditingController(
      text: existing?['salary']?.toString() ?? '',
    );
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final codeCtrl = TextEditingController(
      text: existing?['employee_code'] ?? '',
    );
    String selectedStatus = existing?['emp_status'] ?? 'active';
    String? selectedDept = existing?['department_id'] as String?;
    String? selectedBranch = existing?['branch_id'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing != null ? 'Edit Employee' : 'Add Employee',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sheetField('Full Name *', nameCtrl),
                  const SizedBox(height: 10),
                  _sheetField('Position / Role *', posCtrl),
                  const SizedBox(height: 10),
                  _sheetField('Employee Code', codeCtrl, hint: 'e.g. EMP001'),
                  const SizedBox(height: 10),
                  _sheetField(
                    'Monthly Salary (TZS)',
                    salaryCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _sheetField(
                    'Email',
                    emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  _sheetField(
                    'Phone',
                    phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  if (_departments.isNotEmpty) ...[
                    Text(
                      'Department',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDept,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.outlineLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.outlineLight),
                        ),
                      ),
                      hint: Text(
                        'Select department',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._departments.map(
                          (d) => DropdownMenuItem(
                            value: d['id'] as String,
                            child: Text(d['name'] as String),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => selectedDept = v),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_branches.isNotEmpty) ...[
                    Text(
                      'Branch',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBranch,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.outlineLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.outlineLight),
                        ),
                      ),
                      hint: Text(
                        'Select branch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._branches.map(
                          (b) => DropdownMenuItem(
                            value: b['id'] as String,
                            child: Text(b['name'] as String),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => selectedBranch = v),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Status',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    children: ['active', 'on_leave', 'terminated'].map((s) {
                      final isSelected = selectedStatus == s;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedStatus = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.outlineLight,
                            ),
                          ),
                          child: Text(
                            s.replaceAll('_', ' '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (existing != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await _client
                                  .from('business_employees')
                                  .delete()
                                  .eq('id', existing['id'] as String);
                              if (mounted) {
                                Navigator.pop(ctx);
                                _loadData();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: AppTheme.error),
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                posCtrl.text.trim().isEmpty) {
                              return;
                            }
                            final bizId =
                                widget.business?['id'] as String? ??
                                (await _client
                                        .from('businesses')
                                        .select('id')
                                        .eq(
                                          'owner_id',
                                          _client.auth.currentUser!.id,
                                        )
                                        .limit(1)
                                        .maybeSingle())?['id']
                                    as String?;
                            if (bizId == null) return;
                            final data = {
                              'business_id': bizId,
                              'full_name': nameCtrl.text.trim(),
                              'position': posCtrl.text.trim(),
                              'employee_code': codeCtrl.text.trim().isEmpty
                                  ? null
                                  : codeCtrl.text.trim(),
                              'salary': double.tryParse(salaryCtrl.text) ?? 0,
                              'email': emailCtrl.text.trim().isEmpty
                                  ? null
                                  : emailCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim(),
                              'emp_status': selectedStatus,
                              'department_id': selectedDept,
                              'branch_id': selectedBranch,
                            };
                            if (existing != null) {
                              await _client
                                  .from('business_employees')
                                  .update(data)
                                  .eq('id', existing['id'] as String);
                            } else {
                              await _client
                                  .from('business_employees')
                                  .insert(data);
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              _loadData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            existing != null ? 'Update' : 'Add Employee',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedLight,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.mutedLight.withAlpha(120),
            ),
            filled: true,
            fillColor: AppTheme.backgroundLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = _employees
        .where((e) => e['emp_status'] == 'active')
        .length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        title: Text(
          'Employee Management',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddEmployeeSheet(),
            icon: const Icon(Icons.person_add, color: AppTheme.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryBar(activeCount),
                _buildSearchAndFilter(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CustomIconWidget(
                                  iconName: 'people',
                                  color: AppTheme.mutedLight,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No employees found',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddEmployeeSheet(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: Text(
                                    'Add Employee',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _buildEmployeeCard(filtered[i]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBar(int activeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surfaceLight,
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              'Total Staff',
              '${_employees.length}',
              AppTheme.primary,
            ),
          ),
          Expanded(
            child: _summaryItem('Active', '$activeCount', AppTheme.success),
          ),
          Expanded(
            child: _summaryItem(
              'Monthly Payroll',
              _fmt(_totalPayroll),
              AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppTheme.mutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search employees...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.mutedLight,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppTheme.mutedLight,
              ),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outlineLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'active', 'on_leave', 'terminated'].map((s) {
                final isSelected = _filterStatus == s;
                return GestureDetector(
                  onTap: () => setState(() => _filterStatus = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.outlineLight,
                      ),
                    ),
                    child: Text(
                      s == 'all' ? 'All' : s.replaceAll('_', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.mutedLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    final status = emp['emp_status'] as String? ?? 'active';
    final statusColors = {
      'active': AppTheme.success,
      'on_leave': AppTheme.warning,
      'terminated': AppTheme.error,
    };
    final color = statusColors[status] ?? AppTheme.mutedLight;
    final salary = (emp['salary'] as num? ?? 0).toDouble();
    final dept = _deptName(emp['department_id'] as String?);
    final branch = _branchName(emp['branch_id'] as String?);

    return GestureDetector(
      onTap: () => _showAddEmployeeSheet(emp),
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
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (emp['full_name'] as String).substring(0, 1).toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
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
                    emp['full_name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  Text(
                    emp['position'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  if (dept != null || branch != null)
                    Text(
                      '${dept ?? ''}${dept != null && branch != null ? ' • ' : ''}${branch ?? ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.mutedLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(salary),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  '/month',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}