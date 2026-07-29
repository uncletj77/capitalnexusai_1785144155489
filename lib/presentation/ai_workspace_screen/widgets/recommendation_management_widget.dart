import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/cna_shared_components.dart';
import '../../../services/cna_brain_enterprise_service.dart';

/// Recommendation Management System Widget
/// Full lifecycle: pending → accepted/declined/postponed/archived
class RecommendationManagementWidget extends StatefulWidget {
  const RecommendationManagementWidget({super.key});

  @override
  State<RecommendationManagementWidget> createState() =>
      _RecommendationManagementWidgetState();
}

class _RecommendationManagementWidgetState
    extends State<RecommendationManagementWidget>
    with SingleTickerProviderStateMixin {
  final _service = CnaBrainEnterpriseService.instance;
  late TabController _tabController;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pending = await _service.getRecommendationsWithHistory(
      status: 'pending',
    );
    final history = await _service.getRecommendationsWithHistory(
      status: null,
      limit: 30,
    );
    if (mounted) {
      setState(() {
        _pending = pending;
        _history = history.where((r) => r['status'] != 'pending').toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNew() async {
    setState(() => _isGenerating = true);
    await _service.generateEnterpriseRecommendations();
    await _loadData();
    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _takeAction(String id, String action) async {
    await _service.updateRecommendationAction(id, action);
    await _loadData();
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF2D9CDB);
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'warning':
        return const Color(0xFFEF4444);
      case 'opportunity':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF2D9CDB);
    }
  }

  String _categoryIcon(String category) {
    switch (category) {
      case 'warning':
        return 'warning';
      case 'opportunity':
        return 'lightbulb';
      default:
        return 'info';
    }
  }

  String _actionStatusLabel(String? status) {
    switch (status) {
      case 'accepted':
        return '✓ Accepted';
      case 'declined':
        return '✗ Declined';
      case 'postponed':
        return '⏸ Postponed';
      case 'completed':
        return '✓ Completed';
      case 'archived':
        return '📁 Archived';
      default:
        return status ?? 'Unknown';
    }
  }

  Color _actionStatusColor(String? status) {
    switch (status) {
      case 'accepted':
      case 'completed':
        return const Color(0xFF10B981);
      case 'declined':
        return const Color(0xFFEF4444);
      case 'postponed':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.mutedLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'recommend',
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
                      'Recommendation Engine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Evidence-based, personalized guidance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isGenerating ? null : _generateNew,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
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
        ),
        const SizedBox(height: 12),
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.outlineLight.withAlpha(40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.mutedLight,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Pending (${_pending.length})'),
              Tab(text: 'History (${_history.length})'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _isLoading
              ? const CnaLoadingState(message: 'Loading recommendations...')
              : TabBarView(
                  controller: _tabController,
                  children: [_buildPendingList(), _buildHistoryList()],
                ),
        ),
      ],
    );
  }

  Widget _buildPendingList() {
    if (_pending.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: [
              const CustomIconWidget(
                iconName: 'recommend',
                color: Color(0xFF10B981),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'No Pending Recommendations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap "Generate" to get AI-powered recommendations based on your financial data.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.mutedLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length,
      itemBuilder: (context, i) => _buildRecommendationCard(_pending[i], true),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: [
              const CustomIconWidget(
                iconName: 'history',
                color: Color(0xFF2D9CDB),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'No History Yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Accepted and declined recommendations will appear here.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.mutedLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, i) => _buildRecommendationCard(_history[i], false),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec, bool showActions) {
    final category = rec['category'] as String? ?? 'info';
    final priority = rec['priority'] as String? ?? 'medium';
    final catColor = _categoryColor(category);
    final priColor = _priorityColor(priority);
    final status = rec['status'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: catColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: catColor.withAlpha(8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: _categoryIcon(category),
                      color: catColor,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rec['title'] as String? ?? 'Recommendation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: priColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: priColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec['body'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.mutedLight,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((rec['estimated_impact'] as String?)?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const CustomIconWidget(
                        iconName: 'trending_up',
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rec['estimated_impact'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if ((rec['confidence_level'] as String?)?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const CustomIconWidget(
                        iconName: 'verified',
                        color: Color(0xFF2D9CDB),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Confidence: ${(rec['confidence_level'] as String).toUpperCase()}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFF2D9CDB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Actions or status
          if (showActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _takeAction(rec['id'] as String, 'accepted'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Accept',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          _takeAction(rec['id'] as String, 'postponed'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withAlpha(60),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Postpone',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _takeAction(rec['id'] as String, 'declined'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withAlpha(40),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Decline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _actionStatusColor(status).withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _actionStatusLabel(status),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _actionStatusColor(status),
                      ),
                    ),
                  ),
                  if (rec['action_taken_at'] != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(rec['action_taken_at'] as String),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
