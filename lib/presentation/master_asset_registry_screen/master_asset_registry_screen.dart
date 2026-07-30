import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/master_asset_registry_service.dart';
import '../../widgets/cna_shared_components.dart';

class MasterAssetRegistryScreen extends StatefulWidget {
  const MasterAssetRegistryScreen({super.key});

  @override
  State<MasterAssetRegistryScreen> createState() =>
      _MasterAssetRegistryScreenState();
}

class _MasterAssetRegistryScreenState extends State<MasterAssetRegistryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isAutoRegistering = false;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _assets = [];
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'key': 'all', 'label': 'All', 'icon': 'grid_view'},
    {'key': 'real_estate', 'label': 'Real Estate', 'icon': 'home'},
    {'key': 'vehicle', 'label': 'Vehicles', 'icon': 'directions_car'},
    {'key': 'financial', 'label': 'Financial', 'icon': 'trending_up'},
    {'key': 'business', 'label': 'Business', 'icon': 'business_center'},
    {'key': 'current', 'label': 'Cash', 'icon': 'account_balance'},
    {'key': 'receivable', 'label': 'Receivables', 'icon': 'payments'},
    {'key': 'equipment', 'label': 'Equipment', 'icon': 'build'},
    {'key': 'digital', 'label': 'Digital', 'icon': 'computer'},
    {'key': 'precious', 'label': 'Precious', 'icon': 'diamond'},
  ];

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
    final results = await Future.wait([
      MasterAssetRegistryService.instance.getRegistrySummary(),
      MasterAssetRegistryService.instance.getRegistryAssets(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      ),
    ]);
    if (mounted) {
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _assets = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  Future<void> _runAutoRegistration() async {
    setState(() => _isAutoRegistering = true);
    final count = await MasterAssetRegistryService.instance
        .autoRegisterAllAssets();
    if (mounted) {
      setState(() => _isAutoRegistering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-registered $count assets from all modules'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return 'TSh ${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  Color _categoryColor(String category) {
    const colors = {
      'real_estate': Color(0xFF10B981),
      'vehicle': Color(0xFF3B82F6),
      'financial': Color(0xFF8B5CF6),
      'business': Color(0xFFF59E0B),
      'current': Color(0xFF1A5F7A),
      'receivable': Color(0xFF06B6D4),
      'equipment': Color(0xFF6B7280),
      'digital': Color(0xFFEC4899),
      'precious': Color(0xFFD97706),
      'fixed': Color(0xFF374151),
    };
    return colors[category] ?? AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalValue = (_summary['total_value'] as num?)?.toDouble() ?? 0;
    final assetCount = (_summary['asset_count'] as num?)?.toInt() ?? 0;
    final categories = (_summary['categories'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outlineLight),
                      ),
                      child: const Center(
                        child: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master Asset Registry',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$assetCount assets • ${_formatAmount(totalValue)} total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _isAutoRegistering ? null : _runAutoRegistration,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _isAutoRegistering
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                  strokeWidth: 2,
                                ),
                              )
                            : const CustomIconWidget(
                                iconName: 'sync',
                                color: AppTheme.primary,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Total value banner
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Asset Value',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatAmount(totalValue),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$assetCount registered assets',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _isAutoRegistering
                                ? null
                                : _runAutoRegistration,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CustomIconWidget(
                                    iconName: 'sync',
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Auto-Register',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Category filter
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat['key'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat['key'] as String);
                      _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.outlineLight,
                        ),
                      ),
                      child: Text(
                        cat['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.mutedLight,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.mutedLight,
                indicator: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                tabs: const [
                  Tab(text: 'Registry'),
                  Tab(text: 'Categories'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const CnaLoadingState(message: 'Loading asset registry...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRegistryTab(theme),
                        _buildCategoriesTab(theme, categories),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistryTab(ThemeData theme) {
    if (_assets.isEmpty) {
      return CnaEmptyState(
        iconName: 'inventory_2',
        title: 'No Assets Registered',
        description:
            'Tap Auto-Register to scan and register all qualifying assets from your financial modules.',
        ctaLabel: 'Auto-Register Now',
        onCta: _runAutoRegistration,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _assets.length,
      itemBuilder: (ctx, i) {
        final asset = _assets[i];
        final value = (asset['current_value'] as num?)?.toDouble() ?? 0;
        final cost = (asset['acquisition_cost'] as num?)?.toDouble() ?? 0;
        final gain = value - cost;
        final category = asset['asset_category'] as String? ?? 'other';
        final color = _categoryColor(category);
        final isAutoRegistered = asset['is_auto_registered'] as bool? ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: _categoryIcon(category),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            asset['registry_name'] as String? ?? 'Asset',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAutoRegistered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AUTO',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${(asset['source_module'] as String? ?? '').replaceAll('_', ' ')} • ${(asset['asset_subcategory'] as String? ?? category).replaceAll('_', ' ')}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(value),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (cost > 0)
                    Text(
                      '${gain >= 0 ? '+' : ''}${_formatAmount(gain)}',
                      style: TextStyle(
                        color: gain >= 0 ? AppTheme.success : AppTheme.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab(ThemeData theme, Map<String, dynamic> categories) {
    if (categories.isEmpty) {
      return const CnaEmptyState(
        iconName: 'category',
        title: 'No Categories',
        description: 'Auto-register assets to see category breakdown.',
      );
    }
    final entries = categories.entries.toList()
      ..sort(
        (a, b) => ((b.value['value'] as double?) ?? 0).compareTo(
          (a.value['value'] as double?) ?? 0,
        ),
      );
    final totalValue = (_summary['total_value'] as num?)?.toDouble() ?? 1;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        final catData = entry.value as Map<String, dynamic>;
        final value = (catData['value'] as double?) ?? 0;
        final count = (catData['count'] as int?) ?? 0;
        final label = catData['label'] as String? ?? entry.key;
        final color = _categoryColor(entry.key);
        final pct = totalValue > 0 ? value / totalValue : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: _categoryIcon(entry.key),
                        color: color,
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
                          label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$count asset${count != 1 ? 's' : ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(value),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: color.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _categoryIcon(String category) {
    const icons = {
      'real_estate': 'home',
      'vehicle': 'directions_car',
      'financial': 'trending_up',
      'business': 'business_center',
      'current': 'account_balance',
      'receivable': 'payments',
      'equipment': 'build',
      'digital': 'computer',
      'precious': 'diamond',
      'agriculture': 'agriculture',
      'fixed': 'inventory_2',
    };
    return icons[category] ?? 'inventory_2';
  }
}
