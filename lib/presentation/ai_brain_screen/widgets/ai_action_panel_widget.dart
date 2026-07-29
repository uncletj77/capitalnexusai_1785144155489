import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/cna_shared_components.dart';

/// AI Action Panel — approve, reject, or modify AI-suggested actions
class AiActionPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final Function(String id) onApprove;
  final Function(String id) onReject;
  final bool isLoading;

  const AiActionPanelWidget({
    super.key,
    required this.actions,
    required this.onApprove,
    required this.onReject,
    this.isLoading = false,
  });

  String _getActionIcon(String actionType) {
    switch (actionType) {
      case 'create_budget':
        return 'account_balance_wallet';
      case 'schedule_maintenance':
        return 'build';
      case 'review_expense':
        return 'receipt_long';
      case 'compare_investments':
        return 'compare_arrows';
      case 'generate_report':
        return 'description';
      default:
        return 'auto_fix_high';
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'create_budget':
        return const Color(0xFF10B981);
      case 'schedule_maintenance':
        return const Color(0xFFF59E0B);
      case 'review_expense':
        return const Color(0xFF2D9CDB);
      case 'compare_investments':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF1A5F7A);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CnaLoadingState(fullScreen: false);
    }

    if (actions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: const Color(0xFF10B981),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No Pending Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All AI-suggested actions have been reviewed.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.mutedLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: actions.map((action) {
        final actionType = action['action_type'] as String? ?? 'action';
        final color = _getActionColor(actionType);
        final icon = _getActionIcon(actionType);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: icon,
                          color: color,
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
                            'AI Suggested Action',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          Text(
                            actionType
                                .replaceAll('_', ' ')
                                .split(' ')
                                .map(
                                  (w) => w.isNotEmpty
                                      ? '${w[0].toUpperCase()}${w.substring(1)}'
                                      : w,
                                )
                                .join(' '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
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
                        color: const Color(0xFFF59E0B).withAlpha(20),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'PENDING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Description
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action['description'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.onSurfaceLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onApprove(action['id'] as String),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A5F7A),
                                    Color(0xFF2D9CDB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'check',
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Approve',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onReject(action['id'] as String),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withAlpha(12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withAlpha(60),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'close',
                                    color: const Color(0xFFEF4444),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reject',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
