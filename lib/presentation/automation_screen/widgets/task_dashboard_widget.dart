import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/automation_service.dart';

class TaskDashboardWidget extends StatefulWidget {
  const TaskDashboardWidget({super.key});

  @override
  State<TaskDashboardWidget> createState() => _TaskDashboardWidgetState();
}

class _TaskDashboardWidgetState extends State<TaskDashboardWidget> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Completed', 'value': 'completed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final data = await AutomationService.instance.getTasks(
      statusFilter: _selectedFilter == 'all' ? null : _selectedFilter,
    );
    if (mounted) {
      setState(() {
        _tasks = data;
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return AppTheme.mutedLight;
    }
  }

  IconData _getTaskTypeIcon(String? taskType) {
    switch (taskType) {
      case 'finance':
        return Icons.account_balance_wallet;
      case 'asset':
        return Icons.real_estate_agent;
      case 'loan':
        return Icons.account_balance;
      case 'business':
        return Icons.business_center;
      case 'investment':
        return Icons.trending_up;
      case 'report':
        return Icons.summarize;
      default:
        return Icons.task_alt;
    }
  }

  bool _isOverdue(String? dueDateStr) {
    if (dueDateStr == null) return false;
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now());
  }

  String _formatDueDate(String? dueDateStr) {
    if (dueDateStr == null) return '';
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return '';
    final diff = dueDate.difference(DateTime.now());
    if (diff.inDays < 0) return 'Overdue';
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return 'Due tomorrow';
    return 'Due in ${diff.inDays}d';
  }

  Future<void> _completeTask(String taskId) async {
    await AutomationService.instance.completeTask(taskId);
    _loadTasks();
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';
    String selectedType = 'general';
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'New Task',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: ['high', 'medium', 'low']
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedPriority = v ?? 'medium'),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.outlineLight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'calendar_today',
                          color: AppTheme.mutedLight,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select due date',
                          style: GoogleFonts.plusJakartaSans(
                            color: selectedDate != null
                                ? AppTheme.onSurfaceLight
                                : AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                if (titleController.text.isNotEmpty) {
                  await AutomationService.instance.createTask(
                    title: titleController.text,
                    description: descController.text.isEmpty
                        ? null
                        : descController.text,
                    priority: selectedPriority,
                    taskType: selectedType,
                    dueDate: selectedDate,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadTasks();
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

  @override
  Widget build(BuildContext context) {
    final pendingCount = _tasks.where((t) => t['status'] == 'pending').length;
    final completedCount = _tasks
        .where((t) => t['status'] == 'completed')
        .length;
    final overdueCount = _tasks
        .where(
          (t) =>
              t['status'] == 'pending' && _isOverdue(t['due_date'] as String?),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          children: [
            _buildStatChip('Pending', pendingCount, const Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            _buildStatChip(
              'Completed',
              completedCount,
              const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildStatChip('Overdue', overdueCount, const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: 12),
        // Filter + Add row
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final isSelected = _selectedFilter == f['value'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = f['value'] as String);
                        _loadTasks();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A5F7A)
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1A5F7A)
                                : AppTheme.outlineLight,
                          ),
                        ),
                        child: Text(
                          f['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
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
              ),
            ),
            GestureDetector(
              onTap: _showAddTaskDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F7A).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1A5F7A).withAlpha(40),
                  ),
                ),
                child: CustomIconWidget(
                  iconName: 'add',
                  color: const Color(0xFF1A5F7A),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Center(
              child: Text(
                'No tasks found',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.mutedLight),
              ),
            ),
          )
        else
          ...(_tasks.map((task) {
            final priorityColor = _getPriorityColor(
              task['priority'] as String?,
            );
            final isCompleted = task['status'] == 'completed';
            final isOverdue =
                !isCompleted && _isOverdue(task['due_date'] as String?);
            final dueDateLabel = _formatDueDate(task['due_date'] as String?);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOverdue
                      ? const Color(0xFFEF4444).withAlpha(60)
                      : AppTheme.outlineLight,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: isCompleted
                        ? null
                        : () => _completeTask(task['id'] as String),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : priorityColor,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: priorityColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTaskTypeIcon(task['task_type'] as String?),
                      size: 16,
                      color: priorityColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? AppTheme.mutedLight
                                : AppTheme.onSurfaceLight,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dueDateLabel.isNotEmpty)
                          Text(
                            dueDateLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isOverdue
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.mutedLight,
                              fontWeight: isOverdue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (task['priority'] as String? ?? 'medium').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}