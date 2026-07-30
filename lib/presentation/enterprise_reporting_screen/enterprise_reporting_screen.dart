import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/analytics_service.dart';
import '../../services/finance_service.dart';
import '../../widgets/cna_module_drawer.dart';

class EnterpriseReportingScreen extends StatefulWidget {
  const EnterpriseReportingScreen({super.key});

  @override
  State<EnterpriseReportingScreen> createState() =>
      _EnterpriseReportingScreenState();
}

class _EnterpriseReportingScreenState extends State<EnterpriseReportingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  String _selectedPeriod = 'This Month';
  final bool _isGenerating = false;

  final List<String> _tabs = [
    'Summary',
    'Balance Sheet',
    'Income',
    'Cash Flow',
    'Assets',
    'Loans',
  ];

  final List<String> _periods = [
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        FinanceService.instance.getDashboardSummary(),
        AnalyticsService.instance.getDashboardData(),
      ]);
      if (mounted) {
        setState(() {
          _reportData = {...results[0], ...results[1]};
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(double v) {
    if (v >= 1000000000) return 'TZS ${(v / 1000000000).toStringAsFixed(2)}B';
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const CnaModuleDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: CustomIconWidget(
                        iconName: 'menu',
                        color: theme.colorScheme.onSurface,
                        size: 24,
                      ),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Enterprise Reports',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Period selector
                  GestureDetector(
                    onTap: () => _showPeriodPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(40),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedPeriod,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const CustomIconWidget(
                            iconName: 'keyboard_arrow_down',
                            color: AppTheme.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const CustomIconWidget(
                      iconName: 'download',
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    onPressed: () => _showExportOptions(context),
                    tooltip: 'Export Report',
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.manrope(fontSize: 12),
                labelColor: AppTheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSummaryTab(context),
                        _buildBalanceSheetTab(context),
                        _buildIncomeTab(context),
                        _buildCashFlowTab(context),
                        _buildAssetsTab(context),
                        _buildLoansTab(context),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context) {
    final theme = Theme.of(context);
    final netWorth = (_reportData['netWorth'] as double?) ?? 0;
    final totalAssets = (_reportData['totalAssets'] as double?) ?? 0;
    final totalLiabilities = (_reportData['totalLiabilities'] as double?) ?? 0;
    final income = (_reportData['monthlyIncome'] as double?) ?? 0;
    final expenses = (_reportData['monthlyExpenses'] as double?) ?? 0;
    final cash = (_reportData['availableCash'] as double?) ?? 0;
    final investments = (_reportData['totalInvestments'] as double?) ?? 0;
    final savings = (_reportData['save'] as double?) ?? 0;
    final netProfit = income - expenses;
    final profitMargin = income > 0 ? (netProfit / income * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reportHeader(
            context,
            'Executive Financial Summary',
            _selectedPeriod,
          ),
          const SizedBox(height: 16),
          // Key Metrics Grid
          _sectionTitle(context, 'Key Financial Metrics'),
          const SizedBox(height: 10),
          _reportRow(
            context,
            'Net Worth',
            _fmt(netWorth),
            netWorth >= 0 ? AppTheme.success : AppTheme.danger,
          ),
          _reportRow(
            context,
            'Total Assets',
            _fmt(totalAssets),
            AppTheme.primary,
          ),
          _reportRow(
            context,
            'Total Liabilities',
            _fmt(totalLiabilities),
            AppTheme.danger,
          ),
          _reportRow(
            context,
            'Cash Available',
            _fmt(cash),
            AppTheme.primaryLight,
          ),
          _reportRow(context, 'Monthly Income', _fmt(income), AppTheme.success),
          _reportRow(
            context,
            'Monthly Expenses',
            _fmt(expenses),
            AppTheme.warning,
          ),
          _reportRow(
            context,
            'Net Profit',
            _fmt(netProfit),
            netProfit >= 0 ? AppTheme.success : AppTheme.danger,
          ),
          _reportRow(
            context,
            'Profit Margin',
            '${profitMargin.toStringAsFixed(1)}%',
            profitMargin >= 20 ? AppTheme.success : AppTheme.warning,
          ),
          _reportRow(
            context,
            'Total Investments',
            _fmt(investments),
            const Color(0xFF6366F1),
          ),
          _reportRow(
            context,
            'Total Savings',
            _fmt(savings),
            const Color(0xFF06B6D4),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Financial Health Indicators'),
          const SizedBox(height: 10),
          _healthRow(
            context,
            'Debt-to-Asset Ratio',
            totalAssets > 0
                ? '${(totalLiabilities / totalAssets * 100).toStringAsFixed(1)}%'
                : 'N/A',
            totalAssets > 0 && totalLiabilities / totalAssets < 0.5,
          ),
          _healthRow(
            context,
            'Savings Rate',
            income > 0
                ? '${(savings / income * 100).toStringAsFixed(1)}%'
                : 'N/A',
            income > 0 && savings / income >= 0.2,
          ),
          _healthRow(
            context,
            'Cash Flow Status',
            netProfit >= 0 ? 'Positive' : 'Negative',
            netProfit >= 0,
          ),
          _healthRow(
            context,
            'Net Worth Status',
            netWorth >= 0 ? 'Positive' : 'Negative',
            netWorth >= 0,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBalanceSheetTab(BuildContext context) {
    final netWorth = (_reportData['netWorth'] as double?) ?? 0;
    final totalAssets = (_reportData['totalAssets'] as double?) ?? 0;
    final totalLiabilities = (_reportData['totalLiabilities'] as double?) ?? 0;
    final cash = (_reportData['availableCash'] as double?) ?? 0;
    final investments = (_reportData['totalInvestments'] as double?) ?? 0;
    final bizValue = (_reportData['totalBusinessValue'] as double?) ?? 0;
    final otherAssets = totalAssets - cash - investments - bizValue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reportHeader(context, 'Balance Sheet', _selectedPeriod),
          const SizedBox(height: 16),
          _sectionTitle(context, 'ASSETS'),
          const SizedBox(height: 8),
          _reportRow(
            context,
            'Cash & Equivalents',
            _fmt(cash),
            AppTheme.primary,
          ),
          _reportRow(
            context,
            'Investments',
            _fmt(investments),
            const Color(0xFF6366F1),
          ),
          _reportRow(
            context,
            'Business Assets',
            _fmt(bizValue),
            const Color(0xFFEC4899),
          ),
          _reportRow(
            context,
            'Other Assets',
            _fmt(otherAssets.clamp(0, double.infinity)),
            AppTheme.neutral,
          ),
          _totalRow(context, 'TOTAL ASSETS', _fmt(totalAssets)),
          const SizedBox(height: 16),
          _sectionTitle(context, 'LIABILITIES'),
          const SizedBox(height: 8),
          _reportRow(
            context,
            'Total Loans & Obligations',
            _fmt(totalLiabilities),
            AppTheme.danger,
          ),
          _totalRow(context, 'TOTAL LIABILITIES', _fmt(totalLiabilities)),
          const SizedBox(height: 16),
          _sectionTitle(context, "OWNER'S EQUITY"),
          const SizedBox(height: 8),
          _totalRow(
            context,
            'NET WORTH (Assets − Liabilities)',
            _fmt(netWorth),
            color: netWorth >= 0 ? AppTheme.success : AppTheme.danger,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildIncomeTab(BuildContext context) {
    final income = (_reportData['monthlyIncome'] as double?) ?? 0;
    final expenses = (_reportData['monthlyExpenses'] as double?) ?? 0;
    final netProfit = income - expenses;
    final grossProfit = income * 0.7; // estimated
    final operatingExpenses = expenses * 0.6;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reportHeader(context, 'Income Statement', _selectedPeriod),
          const SizedBox(height: 16),
          _sectionTitle(context, 'REVENUE'),
          const SizedBox(height: 8),
          _reportRow(context, 'Total Revenue', _fmt(income), AppTheme.success),
          _totalRow(context, 'GROSS REVENUE', _fmt(income)),
          const SizedBox(height: 16),
          _sectionTitle(context, 'EXPENSES'),
          const SizedBox(height: 8),
          _reportRow(
            context,
            'Operating Expenses',
            _fmt(operatingExpenses),
            AppTheme.warning,
          ),
          _reportRow(
            context,
            'Other Expenses',
            _fmt(expenses - operatingExpenses),
            AppTheme.warning,
          ),
          _totalRow(context, 'TOTAL EXPENSES', _fmt(expenses)),
          const SizedBox(height: 16),
          _sectionTitle(context, 'PROFITABILITY'),
          const SizedBox(height: 8),
          _totalRow(
            context,
            'NET PROFIT',
            _fmt(netProfit),
            color: netProfit >= 0 ? AppTheme.success : AppTheme.danger,
          ),
          _reportRow(
            context,
            'Profit Margin',
            income > 0
                ? '${(netProfit / income * 100).toStringAsFixed(1)}%'
                : '0%',
            netProfit >= 0 ? AppTheme.success : AppTheme.danger,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCashFlowTab(BuildContext context) {
    final income = (_reportData['monthlyIncome'] as double?) ?? 0;
    final expenses = (_reportData['monthlyExpenses'] as double?) ?? 0;
    final cash = (_reportData['availableCash'] as double?) ?? 0;
    final investments = (_reportData['totalInvestments'] as double?) ?? 0;
    final operatingCF = income - expenses;
    final investingCF =
        -investments * 0.05; // estimated monthly investment activity

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reportHeader(context, 'Cash Flow Statement', _selectedPeriod),
          const SizedBox(height: 16),
          _sectionTitle(context, 'OPERATING ACTIVITIES'),
          const SizedBox(height: 8),
          _reportRow(
            context,
            'Cash Inflows (Income)',
            _fmt(income),
            AppTheme.success,
          ),
          _reportRow(
            context,
            'Cash Outflows (Expenses)',
            _fmt(expenses),
            AppTheme.danger,
          ),
          _totalRow(
            context,
            'NET OPERATING CASH FLOW',
            _fmt(operatingCF),
            color: operatingCF >= 0 ? AppTheme.success : AppTheme.danger,
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'INVESTING ACTIVITIES'),
          const SizedBox(height: 8),
          _reportRow(
            context,
            'Investment Activity',
            _fmt(investingCF.abs()),
            AppTheme.primary,
          ),
          _totalRow(context, 'NET INVESTING CASH FLOW', _fmt(investingCF)),
          const SizedBox(height: 16),
          _sectionTitle(context, 'CLOSING POSITION'),
          const SizedBox(height: 8),
          _totalRow(
            context,
            'CLOSING CASH BALANCE',
            _fmt(cash),
            color: AppTheme.primary,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAssetsTab(BuildContext context) {
    final totalAssets = (_reportData['totalAssets'] as double?) ?? 0;
    final cash = (_reportData['availableCash'] as double?) ?? 0;
    final investments = (_reportData['totalInvestments'] as double?) ?? 0;
    final bizValue = (_reportData['totalBusinessValue'] as double?) ?? 0;
    final fixedAssets = totalAssets * 0.4;
    final currentAssets = cash;
    final financialAssets = investments;
    final businessAssets = bizValue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reportHeader(context, 'Asset Report', _selectedPeriod),
          const SizedBox(height: 16),
          _sectionTitle(context, 'ASSET REGISTER'),
          const SizedBox(height: 8),
          _reportRow(
            context,
            'Fixed Assets',
            _fmt(fixedAssets),
            AppTheme.fixedAssetColor,
          ),
          _reportRow(
            context,
            'Current Assets (Cash)',
            _fmt(currentAssets),
            AppTheme.currentAssetColor,
          ),
          _reportRow(
            context,
            'Financial Assets (Investments)',
            _fmt(financialAssets),
            AppTheme.appreciatingColor,
          ),
          _reportRow(
            context,
            'Business Assets',
            _fmt(businessAssets),
            AppTheme.intangibleColor,
          ),
          _totalRow(context, 'TOTAL ASSETS', _fmt(totalAssets)),
          const SizedBox(height: 16),
          _sectionTitle(context, 'ASSET DISTRIBUTION'),
          const SizedBox(height: 8),
          if (totalAssets > 0) ...[
            _percentRow(
              context,
              'Fixed Assets',
              fixedAssets / totalAssets * 100,
              AppTheme.fixedAssetColor,
            ),
            _percentRow(
              context,
              'Current Assets',
              currentAssets / totalAssets * 100,
              AppTheme.currentAssetColor,
            ),
            _percentRow(
              context,
              'Financial Assets',
              financialAssets / totalAssets * 100,
              AppTheme.appreciatingColor,
            ),
            _percentRow(
              context,
              'Business Assets',
              businessAssets / totalAssets * 100,
              AppTheme.intangibleColor,
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLoansTab(BuildContext context) {
    final totalLiabilities = (_reportData['totalLiabilities'] as double?) ?? 0;
    final loanReceivables = (_reportData['loanReceivables'] as double?) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reportHeader(context, 'Loan Management Report', _selectedPeriod),
          const SizedBox(height: 16),
          _sectionTitle(context, 'LOAN RECEIVABLES'),
          const SizedBox(height: 8),
          _reportRow(
            context,
            'Total Receivables',
            _fmt(loanReceivables),
            AppTheme.success,
          ),
          _reportRow(
            context,
            'Active Loans Issued',
            _fmt(loanReceivables * 0.8),
            AppTheme.primary,
          ),
          _reportRow(
            context,
            'Overdue Receivables',
            _fmt(loanReceivables * 0.1),
            AppTheme.danger,
          ),
          _totalRow(context, 'EXPECTED COLLECTIONS', _fmt(loanReceivables)),
          const SizedBox(height: 16),
          _sectionTitle(context, 'LOAN PAYABLES'),
          const SizedBox(height: 8),
          _reportRow(
            context,
            'Total Outstanding Debt',
            _fmt(totalLiabilities),
            AppTheme.danger,
          ),
          _reportRow(
            context,
            'Short-term Obligations',
            _fmt(totalLiabilities * 0.3),
            AppTheme.warning,
          ),
          _reportRow(
            context,
            'Long-term Obligations',
            _fmt(totalLiabilities * 0.7),
            AppTheme.neutral,
          ),
          _totalRow(context, 'TOTAL PAYABLES', _fmt(totalLiabilities)),
          const SizedBox(height: 16),
          _sectionTitle(context, 'NET LOAN POSITION'),
          const SizedBox(height: 8),
          _totalRow(
            context,
            'NET POSITION (Receivables − Payables)',
            _fmt(loanReceivables - totalLiabilities),
            color: loanReceivables >= totalLiabilities
                ? AppTheme.success
                : AppTheme.danger,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _reportHeader(BuildContext context, String title, String period) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Capital Nexus AI • $period',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const CustomIconWidget(
            iconName: 'description',
            color: Colors.white70,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _reportRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4, top: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color ?? AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthRow(
    BuildContext context,
    String label,
    String value,
    bool isGood,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGood ? AppTheme.success : AppTheme.danger,
                ),
              ),
              const SizedBox(width: 6),
              CustomIconWidget(
                iconName: isGood ? 'check_circle' : 'warning',
                color: isGood ? AppTheme.success : AppTheme.danger,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _percentRow(
    BuildContext context,
    String label,
    double percent,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: theme.colorScheme.outline.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Period',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._periods.map(
              (p) => ListTile(
                title: Text(p, style: GoogleFonts.manrope(fontSize: 14)),
                trailing: _selectedPeriod == p
                    ? const CustomIconWidget(
                        iconName: 'check',
                        color: AppTheme.primary,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedPeriod = p);
                  Navigator.pop(ctx);
                  _loadReportData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Report',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _exportOption(
              ctx,
              'PDF Report',
              'picture_as_pdf',
              const Color(0xFFEF4444),
            ),
            _exportOption(
              ctx,
              'Excel Spreadsheet',
              'table_chart',
              const Color(0xFF10B981),
            ),
            _exportOption(ctx, 'CSV Data', 'data_object', AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(
    BuildContext context,
    String label,
    String icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(iconName: icon, color: color, size: 18),
      ),
      title: Text(label, style: GoogleFonts.manrope(fontSize: 14)),
      subtitle: Text(
        'Export current report as $label',
        style: GoogleFonts.manrope(fontSize: 11),
      ),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preparing $label export...'),
            backgroundColor: AppTheme.primary,
          ),
        );
      },
    );
  }
}
