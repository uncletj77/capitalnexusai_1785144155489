import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/ai_brain_service.dart';
import '../../../widgets/cna_shared_components.dart';

/// AI Insight Dashboard — warnings, opportunities, recommendations
class AiInsightDashboardWidget extends StatefulWidget {
  const AiInsightDashboardWidget({super.key});

  @override
  State<AiInsightDashboardWidget> createState() =>
      _AiInsightDashboardWidgetState();
}

class _AiInsightDashboardWidgetState extends State<AiInsightDashboardWidget> {
  final _service = AiBrainService.instance;
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _insights = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final recs = await _service.getRecommendations();
      setState(() {
        _recommendations = recs;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateInsights() async {
    setState(() => _isGenerating = true);
    try {
      final insights = await _service.generateInsights();
      setState(() {
        _insights = insights;
        _isGenerating = false;
      });
    } catch (_) {
      setState(() => _isGenerating = false);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'warning':
        return const Color(0xFFEF4444);
      case 'opportunity':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF2D9CDB);
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'warning':
        return 'warning';
      case 'opportunity':
        return 'lightbulb';
      default:
        return 'info';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Insights Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insight Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Powered by CNA Brain Engine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isGenerating ? null : _generateInsights,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Generate',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Cards
          Row(
            children: [
              _buildSummaryCard(
                'Recommendations',
                _recommendations
                    .where((r) => r['status'] == 'pending')
                    .length
                    .toString(),
                'pending',
                const Color(0xFFF59E0B),
                'notifications_active',
              ),
              const SizedBox(width: 10),
              _buildSummaryCard(
                'Opportunities',
                _recommendations
                    .where((r) => r['category'] == 'investment_opportunity')
                    .length
                    .toString(),
                'found',
                const Color(0xFF10B981),
                'lightbulb',
              ),
              const SizedBox(width: 10),
              _buildSummaryCard(
                'Warnings',
                _recommendations
                    .where(
                      (r) =>
                          r['priority'] == 'high' ||
                          r['priority'] == 'critical',
                    )
                    .length
                    .toString(),
                'active',
                const Color(0xFFEF4444),
                'warning',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // AI-Generated Insights (if available)
          if (_insights.isNotEmpty) ...[
            Text(
              'Live AI Analysis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 10),
            ..._insights.map((insight) {
              final category = insight['category'] as String? ?? 'info';
              final color = _getCategoryColor(category);
              final icon = _getCategoryIcon(category);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withAlpha(8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(50)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: icon,
                          color: color,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight['title'] as String? ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            insight['body'] as String? ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.mutedLight,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Stored Recommendations
          Text(
            'AI Recommendations',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 10),

          if (_isLoading)
            const CnaLoadingState(fullScreen: false)
          else if (_recommendations.isEmpty)
            _buildEmptyState()
          else
            ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    String sublabel,
    Color color,
    String icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomIconWidget(iconName: icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              sublabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.mutedLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final priority = rec['priority'] as String? ?? 'medium';
    Color color;
    switch (priority) {
      case 'critical':
        color = const Color(0xFFEF4444);
        break;
      case 'high':
        color = const Color(0xFFF59E0B);
        break;
      case 'medium':
        color = const Color(0xFF2D9CDB);
        break;
      default:
        color = const Color(0xFF10B981);
    }

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
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rec['category'] as String? ?? 'Recommendation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rec['recommendation'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.mutedLight,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            iconName: 'psychology',
            color: const Color(0xFF2D9CDB),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No Recommendations Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Generate" to get AI-powered insights based on your financial data.',
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
}
