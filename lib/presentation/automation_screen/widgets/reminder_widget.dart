import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/automation_service.dart';

class ReminderWidget extends StatefulWidget {
  const ReminderWidget({super.key});

  @override
  State<ReminderWidget> createState() => _ReminderWidgetState();
}

class _ReminderWidgetState extends State<ReminderWidget> {
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final data = await AutomationService.instance.getReminders();
    if (mounted) {
      setState(() {
        _reminders = data;
        _isLoading = false;
      });
    }
  }

  String _formatDueDate(String? dueDateStr) {
    if (dueDateStr == null) return 'No date';
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return 'No date';
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 0) return 'Overdue';
    if (diff.inDays <= 7) return 'In ${diff.inDays} days';
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }

  Color _getDueDateColor(String? dueDateStr) {
    if (dueDateStr == null) return AppTheme.mutedLight;
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return AppTheme.mutedLight;
    final diff = dueDate.difference(DateTime.now());
    if (diff.inDays < 0) return const Color(0xFFEF4444);
    if (diff.inDays <= 3) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Future<void> _completeReminder(String id) async {
    await AutomationService.instance.completeReminder(id);
    _loadReminders();
  }

  Future<void> _showAddReminderDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
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
            'New Reminder',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                  await AutomationService.instance.createReminder(
                    title: titleController.text,
                    description: descController.text.isEmpty
                        ? null
                        : descController.text,
                    dueDate: selectedDate,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadReminders();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5F7A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Add',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reminders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            GestureDetector(
              onTap: _showAddReminderDialog,
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
                      'Add',
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
        const SizedBox(height: 10),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_reminders.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Center(
              child: Text(
                'No active reminders',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.mutedLight,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ...(_reminders.take(5).map((reminder) {
            final dueDateColor = _getDueDateColor(
              reminder['due_date'] as String?,
            );
            final dueDateLabel = _formatDueDate(
              reminder['due_date'] as String?,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _completeReminder(reminder['id'] as String),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: dueDateColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder['title'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (reminder['description'] != null &&
                            (reminder['description'] as String).isNotEmpty)
                          Text(
                            reminder['description'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.mutedLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: dueDateColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dueDateLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: dueDateColor,
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
}
