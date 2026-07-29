import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/cna_shared_components.dart';
import '../../../services/cna_brain_enterprise_service.dart';

/// Risk Scoring Dashboard Widget
/// Displays continuously updated risk scores for all financial areas
class RiskScoringDashboardWidget extends StatefulWidget {
  const RiskScoringDashboardWidget({super.key});

  @override
  State<RiskScoringDashboardWidget> createState() =>
      _RiskScoringDashboardWidgetState();
}

class _RiskScoringDashboardWidgetState
    extends State<RiskScoringDashboardWidget> {
  final _service = CnaBrainEnterpriseService.instance;
  List<Map<String, dynamic>> _scores = [];
  bool _isLoading = true;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() => _isLoading = true);
    final scores = await _service.calculateRiskScores();
    if (mounted) {
      setState(() {
        _scores = scores;
        _isLoading = false;
      });
    }
  }

  Future<void> _recalculate() async {
    setState(() => _isCalculating = true);
    final scores = await _service.calculateRiskScores();
    if (mounted) {
      setState(() {
        _scores = scores;
        _isCalculating = false;
      });
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 65) return const Color(0xFF2D9CDB);
    if (score >= 45) return const Color(0xFFF59E0B);
    if (score >= 25) return const Color(0xFFEF4444);
    return const Color(0xFF7F1D1D);
  }

  String _ratingLabel(String rating) {
    switch (rating) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'shield',
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risk Intelligence Engine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Continuously updated from verified financial data',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isCalculating ? null : _recalculate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withAlpha(40),
                    ),
                  ),
                  child: _isCalculating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CustomIconWidget(
                              iconName: 'refresh',
                              color: Color(0xFF8B5CF6),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recalculate',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const CnaLoadingState(message: 'Calculating risk scores...')
          else if (_scores.isEmpty)
            _buildEmptyState()
          else ...[
            // Overall score hero
            if (_scores.isNotEmpty) _buildOverallScoreHero(_scores.first),
            const SizedBox(height: 16),

            // Individual scores grid
            Text(
              'Risk Breakdown',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 10),
            ...(_scores.skip(1).map((score) => _buildScoreCard(score))),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallScoreHero(Map<String, dynamic> score) {
    final s = score['score'] as int? ?? 0;
    final color = _scoreColor(s);
    final rating = score['rating'] as String? ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(20), color.withAlpha(8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: score['icon'] as String? ?? 'favorite',
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
                      score['label'] as String? ?? 'Financial Health',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      _ratingLabel(rating),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$s',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                '/100',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s / 100,
              backgroundColor: color.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            score['explanation'] as String? ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.mutedLight,
              height: 1.4,
            ),
          ),
          // Tips
          if ((score['improvement_tips'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            ...(score['improvement_tips'] as List).map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: color,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tip.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.onSurfaceLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCard(Map<String, dynamic> score) {
    final s = score['score'] as int? ?? 0;
    final color = _scoreColor(s);
    final rating = score['rating'] as String? ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineLight),
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
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: score['icon'] as String? ?? 'info',
                    color: color,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  score['label'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_ratingLabel(rating)} · $s',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: s / 100,
              backgroundColor: color.withAlpha(15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
          if ((score['explanation'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              score['explanation'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.mutedLight,
                height: 1.4,
              ),
            ),
          ],
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
          const CustomIconWidget(
            iconName: 'shield',
            color: Color(0xFF8B5CF6),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No Risk Data Available',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add financial data to calculate risk scores.',
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
