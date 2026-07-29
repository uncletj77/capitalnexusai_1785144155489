import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/automation_service.dart';

class AiAssistantFeedWidget extends StatefulWidget {
  const AiAssistantFeedWidget({super.key});

  @override
  State<AiAssistantFeedWidget> createState() => _AiAssistantFeedWidgetState();
}

class _AiAssistantFeedWidgetState extends State<AiAssistantFeedWidget> {
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _suggestedActions = [];
  final Set<String> _dismissedIds = {};
  final Set<String> _approvedActionIds = {};

  @override
  void initState() {
    super.initState();
    _recommendations = AutomationService.instance.getProactiveRecommendations();
    _suggestedActions = AutomationService.instance.getSuggestedActions();
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'warning':
        return const Color(0xFFEF4444);
      case 'alert':
        return const Color(0xFFF59E0B);
      case 'insight':
        return const Color(0xFF2D9CDB);
      case 'suggestion':
        return const Color(0xFF8B5CF6);
      case 'opportunity':
        return const Color(0xFF10B981);
      case 'success':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF1A5F7A);
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'loan':
        return const Color(0xFF1A5F7A);
      case 'asset':
        return const Color(0xFF2D9CDB);
      case 'finance':
        return const Color(0xFF10B981);
      case 'investment':
        return const Color(0xFF8B5CF6);
      case 'goal':
        return const Color(0xFF059669);
      case 'report':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF1A5F7A);
    }
  }

  Future<void> _handleActionApproval(
    Map<String, dynamic> action,
    bool approved,
  ) async {
    if (approved) {
      setState(() => _approvedActionIds.add(action['id'] as String));
      await AutomationService.instance.createNotification(
        title: 'Action Approved: ${action['title']}',
        message: 'The AI action has been approved and queued for execution.',
        notificationType: 'ai',
        priority: 'normal',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Action approved and queued',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() => _dismissedIds.add(action['id'] as String));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecs = _recommendations
        .where((r) => !_dismissedIds.contains(r['id']))
        .toList();
    final visibleActions = _suggestedActions
        .where((a) => !_dismissedIds.contains(a['id']))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Proactive Recommendations
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.psychology, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Recommendations',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5F7A).withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${visibleRecs.length} active',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A5F7A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleRecs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Center(
              child: Text(
                'All recommendations reviewed',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.mutedLight),
              ),
            ),
          )
        else
          ...visibleRecs.map((rec) {
            final typeColor = _getTypeColor(rec['type'] as String?);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: typeColor.withAlpha(40)),
                boxShadow: [
                  BoxShadow(
                    color: typeColor.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                          color: typeColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: rec['icon'] as String? ?? 'info',
                            color: typeColor,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rec['title'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                          () => _dismissedIds.add(rec['id'] as String),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rec['message'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.mutedLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (rec['type'] as String? ?? 'info').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await AutomationService.instance.createTask(
                            title: rec['action'] as String? ?? 'Review',
                            description: rec['message'] as String?,
                            priority: rec['priority'] as String? ?? 'medium',
                            taskType: rec['category'] as String? ?? 'general',
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Task created',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rec['action'] as String? ?? 'Take Action',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 20),

        // Approval Workflow Section
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withAlpha(40),
                ),
              ),
              child: const Center(
                child: Icon(Icons.approval, color: Color(0xFF8B5CF6), size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Suggested Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...visibleActions.map((action) {
          final isApproved = _approvedActionIds.contains(
            action['id'] as String,
          );
          final requiresApproval = action['requiresApproval'] as bool? ?? false;
          final catColor = _getCategoryColor(action['category'] as String?);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isApproved
                  ? const Color(0xFF10B981).withAlpha(10)
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isApproved
                    ? const Color(0xFF10B981).withAlpha(60)
                    : AppTheme.outlineLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: action['icon'] as String? ?? 'task_alt',
                      color: catColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              action['title'] as String? ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (requiresApproval)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'APPROVAL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        action['description'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.mutedLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Approved',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _handleActionApproval(action, false),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _handleActionApproval(action, true),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}