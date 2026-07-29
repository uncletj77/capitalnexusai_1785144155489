import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/automation_service.dart';

class WorkflowBuilderWidget extends StatefulWidget {
  const WorkflowBuilderWidget({super.key});

  @override
  State<WorkflowBuilderWidget> createState() => _WorkflowBuilderWidgetState();
}

class _WorkflowBuilderWidgetState extends State<WorkflowBuilderWidget> {
  List<Map<String, dynamic>> _workflows = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _triggerTemplates = [
    {
      'label': 'Loan Due',
      'value': 'loan_due',
      'icon': 'account_balance',
      'color': const Color(0xFF1A5F7A),
    },
    {
      'label': 'Revenue Drop',
      'value': 'revenue_drop',
      'icon': 'trending_down',
      'color': const Color(0xFFEF4444),
    },
    {
      'label': 'Goal Achieved',
      'value': 'goal_achieved',
      'icon': 'emoji_events',
      'color': const Color(0xFF10B981),
    },
    {
      'label': 'Budget Exceeded',
      'value': 'budget_exceeded',
      'icon': 'money_off',
      'color': const Color(0xFFF59E0B),
    },
    {
      'label': 'Asset Maintenance',
      'value': 'asset_maintenance',
      'icon': 'build',
      'color': const Color(0xFF2D9CDB),
    },
    {
      'label': 'Investment Alert',
      'value': 'investment_alert',
      'icon': 'trending_up',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
  }

  Future<void> _loadWorkflows() async {
    final data = await AutomationService.instance.getWorkflows();
    if (mounted) {
      setState(() {
        _workflows = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleWorkflow(String id, bool current) async {
    await AutomationService.instance.toggleWorkflow(id, !current);
    _loadWorkflows();
  }

  Future<void> _deleteWorkflow(String id) async {
    await AutomationService.instance.deleteWorkflow(id);
    _loadWorkflows();
  }

  Future<void> _showCreateWorkflowDialog() async {
    final nameController = TextEditingController();
    String selectedTrigger = 'loan_due';
    bool notifyUser = true;
    bool createTask = false;
    bool generateReport = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Create Workflow',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Workflow Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Trigger',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _triggerTemplates.map((t) {
                    final isSelected = selectedTrigger == t['value'];
                    final color = t['color'] as Color;
                    return GestureDetector(
                      onTap: () => setDialogState(
                        () => selectedTrigger = t['value'] as String,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? color : color.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 12,
                              color: isSelected ? Colors.white : color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t['label'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  'Actions',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 8),
                _buildActionToggle(
                  'Notify User',
                  notifyUser,
                  (v) => setDialogState(() => notifyUser = v),
                ),
                _buildActionToggle(
                  'Create Task',
                  createTask,
                  (v) => setDialogState(() => createTask = v),
                ),
                _buildActionToggle(
                  'Generate Report',
                  generateReport,
                  (v) => setDialogState(() => generateReport = v),
                ),
              ],
            ),
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
                if (nameController.text.isNotEmpty) {
                  await AutomationService.instance.createWorkflow(
                    name: nameController.text,
                    triggerType: selectedTrigger,
                    action: {
                      'notify_user': notifyUser,
                      'create_task': createTask,
                      'generate_report': generateReport,
                    },
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadWorkflows();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5F7A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Create',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF1A5F7A),
          ),
        ],
      ),
    );
  }

  Color _getTriggerColor(String? triggerType) {
    final template = _triggerTemplates.firstWhere(
      (t) => t['value'] == triggerType,
      orElse: () => {'color': const Color(0xFF1A5F7A)},
    );
    return template['color'] as Color;
  }

  String _getTriggerLabel(String? triggerType) {
    final template = _triggerTemplates.firstWhere(
      (t) => t['value'] == triggerType,
      orElse: () => {'label': triggerType ?? 'Unknown'},
    );
    return template['label'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Automation Workflows',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            GestureDetector(
              onTap: _showCreateWorkflowDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F7A).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1A5F7A).withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'add',
                      color: const Color(0xFF1A5F7A),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'New',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A5F7A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Flow diagram hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trigger → Condition → Action → Notification',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_workflows.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Center(
              child: Text(
                'No workflows yet. Create your first automation.',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.mutedLight),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...(_workflows.map((workflow) {
            final triggerColor = _getTriggerColor(
              workflow['trigger_type'] as String?,
            );
            final isEnabled = workflow['enabled'] as bool? ?? true;
            final action = workflow['action'] as Map<String, dynamic>? ?? {};
            final actionCount = action.values.where((v) => v == true).length;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isEnabled
                      ? triggerColor.withAlpha(40)
                      : AppTheme.outlineLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: triggerColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.bolt,
                            color: triggerColor,
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
                              workflow['name'] as String? ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurfaceLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Trigger: ${_getTriggerLabel(workflow['trigger_type'] as String?)} • $actionCount action${actionCount != 1 ? 's' : ''}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.mutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isEnabled,
                        onChanged: (v) => _toggleWorkflow(
                          workflow['id'] as String,
                          isEnabled,
                        ),
                        activeThumbColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (action['notify_user'] == true)
                        _buildActionChip('Notify', const Color(0xFF2D9CDB)),
                      if (action['create_task'] == true)
                        _buildActionChip('Task', const Color(0xFF8B5CF6)),
                      if (action['generate_report'] == true)
                        _buildActionChip('Report', const Color(0xFFF59E0B)),
                      if (action['ask_ai'] == true)
                        _buildActionChip('AI', const Color(0xFF1A5F7A)),
                      if (action['congratulate'] == true)
                        _buildActionChip('Celebrate', const Color(0xFF10B981)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _deleteWorkflow(workflow['id'] as String),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })),
      ],
    );
  }

  Widget _buildActionChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}