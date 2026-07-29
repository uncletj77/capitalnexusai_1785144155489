import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashboard_app_bar_widget.dart';
import 'widgets/hero_balance_widget.dart';
import 'widgets/period_filter_widget.dart';
import 'widgets/overview_card_widget.dart';
import 'widgets/metric_grid_widget.dart';
import 'widgets/account_cards_widget.dart';
import 'widgets/promo_banner_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _selectedPeriod = 2; // 0=Day, 1=Week, 2=Month, 3=Year
  bool _showBanner = true;

  final Map<String, dynamic> _financialData = {
    'netWorth': 650000000.0,
    'totalAssets': 850000000.0,
    'totalLiabilities': 200000000.0,
    'availableCash': 45200000.0,
    'monthlyIncome': 28500000.0,
    'monthlyExpenses': 12300000.0,
    'totalInvestments': 185000000.0,
    'totalBusinessValue': 320000000.0,
    'spend': 12300000.0,
    'save': 8500000.0,
    'invest': 5200000.0,
    'borrowCount': 3,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: isTablet ? _buildTabletLayout(theme) : _buildPhoneLayout(theme),
      ),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: DashboardAppBarWidget()),
        SliverToBoxAdapter(
          child: HeroBalanceWidget(
            netWorth: _financialData['netWorth'],
            totalAssets: _financialData['totalAssets'],
            totalLiabilities: _financialData['totalLiabilities'],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: PeriodFilterWidget(
              selectedIndex: _selectedPeriod,
              onSelected: (i) => setState(() => _selectedPeriod = i),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OverviewCardWidget(selectedPeriod: _selectedPeriod),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: MetricGridWidget(data: _financialData),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AccountCardsWidget(),
          ),
        ),
        if (_showBanner)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: PromoBannerWidget(
                onDismiss: () => setState(() => _showBanner = false),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: DashboardAppBarWidget()),
              SliverToBoxAdapter(
                child: HeroBalanceWidget(
                  netWorth: _financialData['netWorth'],
                  totalAssets: _financialData['totalAssets'],
                  totalLiabilities: _financialData['totalLiabilities'],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: PeriodFilterWidget(
                    selectedIndex: _selectedPeriod,
                    onSelected: (i) => setState(() => _selectedPeriod = i),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: OverviewCardWidget(selectedPeriod: _selectedPeriod),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        Container(width: 1, color: AppTheme.outlineLight),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                MetricGridWidget(data: _financialData),
                const SizedBox(height: 16),
                AccountCardsWidget(),
                if (_showBanner) ...[
                  const SizedBox(height: 16),
                  PromoBannerWidget(
                    onDismiss: () => setState(() => _showBanner = false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
