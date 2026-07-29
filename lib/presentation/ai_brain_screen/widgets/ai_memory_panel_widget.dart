import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/ai_brain_service.dart';
import '../../../widgets/cna_shared_components.dart';

/// AI Memory Panel — view and manage long-term AI memory
class AiMemoryPanelWidget extends StatefulWidget {
  const AiMemoryPanelWidget({super.key});

  @override
  State<AiMemoryPanelWidget> createState() => _AiMemoryPanelWidgetState();
}

class _AiMemoryPanelWidgetState extends State<AiMemoryPanelWidget> {
  final _service = AiBrainService.instance;
  List<Map<String, dynamic>> _memory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemory();
  }

  Future<void> _loadMemory() async {
    setState(() => _isLoading = true);
    final memory = await _service.getMemory();
    setState(() {
      _memory = memory;
      _isLoading = false;
    });
  }

  Future<void> _deleteMemory(String id) async {
    await _service.deleteMemory(id);
    _loadMemory();
  }

  Color _getMemoryColor(String type) {
    switch (type) {
      case 'financial_goal':
        return const Color(0xFF10B981);
      case 'business_preference':
        return const Color(0xFF2D9CDB);
      case 'risk_profile':
        return const Color(0xFF8B5CF6);
      case 'reporting_style':
        return const Color(0xFFF59E0B);
      case 'user_preference':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF1A5F7A);
    }
  }

  String _getMemoryIcon(String type) {
    switch (type) {
      case 'financial_goal':
        return 'flag';
      case 'business_preference':
        return 'business_center';
      case 'risk_profile':
        return 'shield';
      case 'reporting_style':
        return 'description';
      case 'user_preference':
        return 'favorite';
      default:
        return 'memory';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CnaLoadingState(message: 'Loading memory...');
    }

    if (_memory.isEmpty) {
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
              iconName: 'memory',
              color: const Color(0xFF2D9CDB),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No Memory Stored',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The AI will learn your preferences as you interact with it.',
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
      children: _memory.map((mem) {
        final type = mem['memory_type'] as String? ?? 'general';
        final color = _getMemoryColor(type);
        final icon = _getMemoryIcon(type);
        final score = mem['importance_score'] as int? ?? 5;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type
                                .replaceAll('_', ' ')
                                .split(' ')
                                .map(
                                  (w) => w.isNotEmpty
                                      ? '${w[0].toUpperCase()}${w.substring(1)}'
                                      : w,
                                )
                                .join(' '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star,
                              size: 10,
                              color: i < (score / 2).round()
                                  ? const Color(0xFFF59E0B)
                                  : AppTheme.outlineLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mem['content'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.mutedLight,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteMemory(mem['id'] as String),
                child: CustomIconWidget(
                  iconName: 'delete_outline',
                  color: AppTheme.mutedLight,
                  size: 18,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
