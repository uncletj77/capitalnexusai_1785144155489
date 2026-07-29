import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/automation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/ai_assistant_feed_widget.dart';
import './widgets/reminder_widget.dart';
import './widgets/task_dashboard_widget.dart';
import './widgets/workflow_builder_widget.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _workflowLogs = [];

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'AI Feed', 'icon': 'psychology'},
    {'label': 'Tasks', 'icon': 'task_alt'},
    {'label': 'Reminders', 'icon': 'alarm'},
    {'label': 'Workflows', 'icon': 'bolt'},
    {'label': 'Logs', 'icon': 'history'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final data = await AutomationService.instance.getWorkflowLogs();
    if (mounted) setState(() => _workflowLogs = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automation Engine',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            Text(
              'Smart Assistant & Workflows',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
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
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1A5F7A),
          unselectedLabelColor: AppTheme.mutedLight,
          indicatorColor: const Color(0xFF1A5F7A),
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          tabs: _tabs
              .map(
                (tab) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: tab['icon'] as String,
                        size: 14,
                        color: AppTheme.mutedLight,
                      ),
                      const SizedBox(width: 5),
                      Text(tab['label'] as String),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: AI Assistant Feed
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: const AiAssistantFeedWidget(),
          ),
          // Tab 2: Task Dashboard
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: const TaskDashboardWidget(),
          ),
          // Tab 3: Reminders
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: const ReminderWidget(),
          ),
          // Tab 4: Workflow Builder
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: const WorkflowBuilderWidget(),
          ),
          // Tab 5: Workflow Logs
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return _workflowLogs.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: AppTheme.mutedLight),
                const SizedBox(height: 12),
                Text(
                  'No workflow logs yet',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _workflowLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final log = _workflowLogs[i];
              final status = log['status'] as String? ?? 'unknown';
              final isCompleted = status == 'completed';
              final result = log['result'] as Map<String, dynamic>? ?? {};
              final executionTime = log['execution_time'] as String?;
              final dt = executionTime != null
                  ? DateTime.tryParse(executionTime)
                  : null;
              final timeLabel = dt != null
                  ? '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                  : '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF10B981).withAlpha(40)
                        : const Color(0xFFEF4444).withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF10B981).withAlpha(15)
                            : const Color(0xFFEF4444).withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workflow ${status.toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                          if (result.isNotEmpty)
                            Text(
                              result.entries
                                  .where((e) => e.value == true)
                                  .map((e) => e.key.replaceAll('_', ' '))
                                  .join(' • '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.mutedLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
