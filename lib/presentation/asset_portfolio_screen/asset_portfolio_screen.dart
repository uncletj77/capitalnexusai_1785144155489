import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AssetPortfolioScreen extends StatefulWidget {
  const AssetPortfolioScreen({super.key});

  @override
  State<AssetPortfolioScreen> createState() => _AssetPortfolioScreenState();
}

class _AssetPortfolioScreenState extends State<AssetPortfolioScreen> {
  final _client = SupabaseService.client;
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allAssets = [];
  List<Map<String, dynamic>> _filtered = [];
  String _selectedCategory = 'all';
  String _sortBy = 'value_desc';

  final _categories = [
    {'key': 'all', 'label': 'All'},
    {'key': 'fixed', 'label': 'Fixed'},
    {'key': 'current', 'label': 'Current'},
    {'key': 'permanent_strategic', 'label': 'Strategic'},
    {'key': 'temporary', 'label': 'Temporary'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final res = await _client
          .from('assets')
          .select()
          .eq('user_id', userId)
          .neq('asset_status', 'disposed');
      setState(() {
        _allAssets = List<Map<String, dynamic>>.from(res);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_allAssets);

    // Category filter
    if (_selectedCategory != 'all') {
      list = list
          .where((a) => a['asset_category'] == _selectedCategory)
          .toList();
    }

    // Search
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (a) =>
                (a['asset_name'] as String? ?? '').toLowerCase().contains(q) ||
                (a['region'] as String? ?? '').toLowerCase().contains(q) ||
                (a['asset_type'] as String? ?? '').toLowerCase().contains(q),
          )
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'value_desc':
        list.sort(
          (a, b) =>
              (b['current_value'] as num).compareTo(a['current_value'] as num),
        );
        break;
      case 'value_asc':
        list.sort(
          (a, b) =>
              (a['current_value'] as num).compareTo(b['current_value'] as num),
        );
        break;
      case 'name_asc':
        list.sort(
          (a, b) =>
              (a['asset_name'] as String).compareTo(b['asset_name'] as String),
        );
        break;
      case 'income_desc':
        list.sort(
          (a, b) => (b['monthly_income'] as num).compareTo(
            a['monthly_income'] as num,
          ),
        );
        break;
    }

    setState(() => _filtered = list);
  }

  String _fmtTZS(double v) {
    if (v >= 1000000000) return 'TSh ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'fixed':
        return AppTheme.fixedAssetColor;
      case 'current':
        return AppTheme.currentAssetColor;
      case 'permanent_strategic':
        return AppTheme.appreciatingColor;
      case 'temporary':
        return AppTheme.depreciatingColor;
      default:
        return AppTheme.primary;
    }
  }

  String _assetIcon(String type) {
    switch (type) {
      case 'land':
        return 'landscape';
      case 'building':
        return 'apartment';
      case 'vehicle':
        return 'directions_bus';
      case 'business':
        return 'business';
      case 'investment':
        return 'trending_up';
      case 'equipment':
        return 'computer';
      default:
        return 'real_estate_agent';
    }
  }

  double get _totalValue =>
      _filtered.fold(0.0, (s, a) => s + (a['current_value'] as num).toDouble());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.onSurfaceLight,
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Asset Portfolio',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.onSurfaceLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const CustomIconWidget(
              iconName: 'sort',
              color: AppTheme.primary,
              size: 22,
            ),
            onSelected: (v) {
              setState(() => _sortBy = v);
              _applyFilters();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'value_desc',
                child: Text('Highest Value'),
              ),
              const PopupMenuItem(
                value: 'value_asc',
                child: Text('Lowest Value'),
              ),
              const PopupMenuItem(value: 'name_asc', child: Text('Name A-Z')),
              const PopupMenuItem(
                value: 'income_desc',
                child: Text('Highest Income'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search assets...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.mutedLight,
                    size: 18,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.outlineLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.outlineLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Category filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat['key'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat['key']!);
                    _applyFilters();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.outlineLight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat['label']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.mutedLight,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Summary bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filtered.length} assets',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Total: ${_fmtTZS(_totalValue)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Asset list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomIconWidget(
                          iconName: 'account_balance_wallet_outlined',
                          color: AppTheme.mutedLight,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No assets found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAssets,
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final a = _filtered[i];
                        final cat = a['asset_category'] as String? ?? 'fixed';
                        final type = a['asset_type'] as String? ?? 'other';
                        final cv = (a['current_value'] as num).toDouble();
                        final pv = (a['purchase_price'] as num).toDouble();
                        final gain = cv - pv;
                        final income = (a['monthly_income'] as num).toDouble();
                        final isUp = gain >= 0;

                        return GestureDetector(
                          onTap: () => context.push(
                            AppRoutes.assetDetailsScreen,
                            extra: a,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border(
                                left: BorderSide(
                                  color: _catColor(cat),
                                  width: 3,
                                ),
                                top: const BorderSide(
                                  color: AppTheme.outlineLight,
                                ),
                                right: const BorderSide(
                                  color: AppTheme.outlineLight,
                                ),
                                bottom: const BorderSide(
                                  color: AppTheme.outlineLight,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _catColor(cat).withAlpha(26),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: CustomIconWidget(
                                      iconName: _assetIcon(type),
                                      color: _catColor(cat),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a['asset_name'] as String? ?? '',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: AppTheme.onSurfaceLight,
                                              fontWeight: FontWeight.w700,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            a['region'] as String? ?? '',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.mutedLight,
                                                  fontSize: 11,
                                                ),
                                          ),
                                          if (income > 0) ...[
                                            const SizedBox(width: 6),
                                            const CustomIconWidget(
                                              iconName: 'trending_up',
                                              color: AppTheme.success,
                                              size: 11,
                                            ),
                                            Text(
                                              ' ${_fmtTZS(income)}/mo',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    color: AppTheme.success,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _fmtTZS(cv),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: AppTheme.onSurfaceLight,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (pv > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUp
                                              ? AppTheme.successContainer
                                              : AppTheme.errorContainer,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Text(
                                          '${isUp ? '+' : ''}${((gain / pv) * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: isUp
                                                ? AppTheme.success
                                                : AppTheme.error,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.addAssetScreen);
          _loadAssets();
        },
        backgroundColor: AppTheme.primary,
        child: const CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
