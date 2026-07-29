import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/cna_shared_components.dart';
import '../../../services/cna_brain_enterprise_service.dart';

/// Executive Financial Command Center Widget
/// Generates comprehensive briefings from verified financial data
class ExecutiveCommandCenterWidget extends StatefulWidget {
  const ExecutiveCommandCenterWidget({super.key});

  @override
  State<ExecutiveCommandCenterWidget> createState() =>
      _ExecutiveCommandCenterWidgetState();
}

class _ExecutiveCommandCenterWidgetState
    extends State<ExecutiveCommandCenterWidget> {
  final _service = CnaBrainEnterpriseService.instance;
  Map<String, dynamic>? _briefingData;
  List<Map<String, dynamic>> _opportunities = [];
  List<Map<String, dynamic>> _auditTrail = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _showAuditTrail = false;

  @override
  void initState() {
    super.initState();
    _loadBriefing();
  }

  Future<void> _loadBriefing() async {
    setState(() => _isLoading = true);
    final briefing = await _service.generateExecutiveCommandBriefing();
    final opps = await _service.discoverOpportunities();
    if (mounted) {
      setState(() {
        _briefingData = briefing;
        _opportunities = opps;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshBriefing() async {
    setState(() => _isGenerating = true);
    final briefing = await _service.generateExecutiveCommandBriefing();
    final opps = await _service.discoverOpportunities();
    if (mounted) {
      setState(() {
        _briefingData = briefing;
        _opportunities = opps;
        _isGenerating = false;
      });
    }
  }

  Future<void> _loadAuditTrail() async {
    final trail = await _service.getAuditTrail();
    if (mounted) {
      setState(() {
        _auditTrail = trail;
        _showAuditTrail = true;
      });
    }
  }

  String _fmt(double value) {
    if (value >= 1000000000) {
      return 'TZS ${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    return 'TZS ${value.toStringAsFixed(0)}';
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
                    colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'dashboard_customize',
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
                      'Executive Command Center',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Live financial intelligence briefing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isGenerating ? null : _refreshBriefing,
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
                          'Refresh',
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
          const SizedBox(height: 16),

          if (_isLoading)
            const CnaLoadingState(message: 'Generating executive briefing...')
          else if (_briefingData == null || _briefingData!.containsKey('error'))
            _buildErrorState()
          else ...[
            _buildBriefingContent(_briefingData!),
            const SizedBox(height: 20),
            _buildOpportunitiesSection(),
            const SizedBox(height: 20),
            _buildAuditTrailSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildBriefingContent(Map<String, dynamic> data) {
    final netWorth = (data['net_worth'] as num?)?.toDouble() ?? 0;
    final totalCash = (data['total_cash'] as num?)?.toDouble() ?? 0;
    final income = (data['monthly_income'] as num?)?.toDouble() ?? 0;
    final expenses = (data['monthly_expenses'] as num?)?.toDouble() ?? 0;
    final netCashFlow = (data['net_cash_flow'] as num?)?.toDouble() ?? 0;
    final totalDebt = (data['total_debt'] as num?)?.toDouble() ?? 0;
    final overdueLoans = data['overdue_loans'] as int? ?? 0;
    final investmentValue = (data['investment_value'] as num?)?.toDouble() ?? 0;
    final assetValue = (data['asset_value'] as num?)?.toDouble() ?? 0;
    final businessCount = data['business_count'] as int? ?? 0;
    final goalCount = data['goal_count'] as int? ?? 0;
    final goalProgress = data['goal_progress_pct'] as String? ?? '0';
    final incomeChange = data['income_change_pct'] as String? ?? 'N/A';
    final expenseChange = data['expense_change_pct'] as String? ?? 'N/A';
    final investRoi = data['investment_roi_pct'] as String? ?? 'N/A';
    final newRisks = (data['new_risks'] as List?)?.cast<String>() ?? [];
    final newOpps = (data['new_opportunities'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Net Worth Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Worth',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white.withAlpha(180),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _fmt(netWorth),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildHeroStat(
                    'Cash',
                    _fmt(totalCash),
                    'account_balance_wallet',
                  ),
                  const SizedBox(width: 16),
                  _buildHeroStat(
                    'Assets',
                    _fmt(assetValue),
                    'real_estate_agent',
                  ),
                  const SizedBox(width: 16),
                  _buildHeroStat('Debt', _fmt(totalDebt), 'credit_card'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Performance
        Text(
          'Monthly Performance',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Income',
                _fmt(income),
                incomeChange != 'N/A' ? '$incomeChange%' : null,
                const Color(0xFF10B981),
                'trending_up',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Expenses',
                _fmt(expenses),
                expenseChange != 'N/A' ? '$expenseChange%' : null,
                const Color(0xFFEF4444),
                'trending_down',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Net Cash Flow',
                _fmt(netCashFlow),
                null,
                netCashFlow >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                netCashFlow >= 0 ? 'arrow_upward' : 'arrow_downward',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Investments',
                _fmt(investmentValue),
                investRoi != 'N/A' ? 'ROI: $investRoi%' : null,
                const Color(0xFF8B5CF6),
                'show_chart',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick stats row
        Row(
          children: [
            _buildQuickStat(
              'Businesses',
              '$businessCount',
              'business_center',
              const Color(0xFF2D9CDB),
            ),
            const SizedBox(width: 8),
            _buildQuickStat(
              'Goals',
              '$goalCount',
              'flag',
              const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildQuickStat(
              'Goal Progress',
              '$goalProgress%',
              'donut_large',
              const Color(0xFF8B5CF6),
            ),
            const SizedBox(width: 8),
            _buildQuickStat(
              'Overdue Loans',
              '$overdueLoans',
              'warning',
              overdueLoans > 0
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
          ],
        ),

        // Alerts
        if (newRisks.isNotEmpty || overdueLoans > 0) ...[
          const SizedBox(height: 16),
          Text(
            '⚠️ Priority Alerts',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 8),
          if (overdueLoans > 0)
            _buildAlertItem(
              '$overdueLoans overdue loan(s) require immediate attention',
              const Color(0xFFEF4444),
              'warning',
            ),
          ...newRisks.map(
            (r) => _buildAlertItem(r, const Color(0xFFEF4444), 'warning'),
          ),
        ],

        // Opportunities
        if (newOpps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '💡 Quick Wins',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 8),
          ...newOpps.map(
            (o) => _buildAlertItem(o, const Color(0xFF10B981), 'lightbulb'),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroStat(String label, String value, String icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: icon,
                color: Colors.white.withAlpha(180),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String? subtitle,
    Color color,
    String icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(iconName: icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.mutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, String icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          children: [
            CustomIconWidget(iconName: icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: AppTheme.mutedLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String text, Color color, String icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.onSurfaceLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunitiesSection() {
    if (_opportunities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opportunity Discovery',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        ..._opportunities
            .take(4)
            .map(
              (opp) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withAlpha(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CustomIconWidget(
                              iconName: 'lightbulb',
                              color: Color(0xFF10B981),
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opp['title'] as String? ?? 'Opportunity',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (opp['priority'] == 'high'
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFF59E0B))
                                    .withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (opp['priority'] as String? ?? 'medium')
                                .toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: opp['priority'] == 'high'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opp['description'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((opp['estimated_benefit'] as String?)?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 4),
                      Text(
                        '💰 ${opp['estimated_benefit']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildAuditTrailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showAuditTrail ? null : _loadAuditTrail,
          child: Row(
            children: [
              Text(
                'AI Audit Trail',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const Spacer(),
              if (!_showAuditTrail)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.outlineLight.withAlpha(60),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'View',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_showAuditTrail) ...[
          const SizedBox(height: 10),
          if (_auditTrail.isEmpty)
            Text(
              'No audit trail entries yet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.mutedLight,
              ),
            )
          else
            ..._auditTrail
                .take(10)
                .map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.outlineLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D9CDB),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (entry['activity_type'] as String? ?? '')
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2D9CDB),
                                ),
                              ),
                              if ((entry['result_summary'] as String?)
                                      ?.isNotEmpty ==
                                  true)
                                Text(
                                  entry['result_summary'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.mutedLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(entry['created_at'] as String? ?? ''),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ],
    );
  }

  Widget _buildErrorState() {
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
            iconName: 'dashboard_customize',
            color: Color(0xFF1A5F7A),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Add Financial Data',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add accounts, transactions, and assets to generate your executive briefing.',
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

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
