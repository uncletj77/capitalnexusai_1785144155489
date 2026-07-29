import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';
import './widgets/add_asset_fab_widget.dart';
import './widgets/assets_app_bar_widget.dart';
import './widgets/assets_filter_widget.dart';
import './widgets/assets_summary_widget.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _client = SupabaseService.client;
  bool _isLoading = true;
  String? _error;

  List<AssetModel> _allAssets = [];
  List<AssetModel> _filteredAssets = [];
  int _selectedFilter = 0;

  static const _filterCategories = [
    'all',
    'fixed',
    'current',
    'permanent_strategic',
    'temporary',
  ];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated. Please log in.';
        });
        return;
      }

      final res = await _client
          .from('assets')
          .select()
          .eq('user_id', userId)
          .neq('asset_status', 'disposed')
          .order('created_at', ascending: false);

      final assets = (res as List)
          .map((a) => AssetModel.fromSupabase(a as Map<String, dynamic>))
          .toList();

      setState(() {
        _allAssets = assets;
        _isLoading = false;
      });
      _applyFilter(_selectedFilter);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load assets: ${e.toString()}';
      });
    }
  }

  void _applyFilter(int index) {
    setState(() {
      _selectedFilter = index;
      if (index == 0) {
        _filteredAssets = List.from(_allAssets);
      } else {
        final cat = _filterCategories[index];
        _filteredAssets = _allAssets.where((a) => a.category == cat).toList();
      }
    });
  }

  double get _totalValue =>
      _filteredAssets.fold(0, (sum, a) => sum + a.currentValue);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AssetsAppBarWidget(),
            Expanded(
              child: _isLoading
                  ? const CnaLoadingState(message: 'Loading assets...')
                  : _error != null
                  ? CnaErrorState(message: _error!, onRetry: _loadAssets)
                  : RefreshIndicator(
                      onRefresh: _loadAssets,
                      child: isTablet
                          ? _buildTabletLayout()
                          : _buildPhoneLayout(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: AddAssetFabWidget(onAssetAdded: _loadAssets),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AssetsSummaryWidget(
              totalValue: _totalValue,
              count: _filteredAssets.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: AssetsFilterWidget(
              selectedIndex: _selectedFilter,
              onSelected: _applyFilter,
            ),
          ),
        ),
        if (_filteredAssets.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: _buildAssetList(),
          ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AssetsSummaryWidget(
                  totalValue: _totalValue,
                  count: _filteredAssets.length,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AssetsFilterWidget(
                  selectedIndex: _selectedFilter,
                  onSelected: _applyFilter,
                  vertical: true,
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: AppTheme.outlineLight),
        Expanded(
          child: _filteredAssets.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      sliver: _buildAssetList(twoColumn: true),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'account_balance_wallet',
                  color: AppTheme.primary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Assets Yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your asset portfolio.\nTap the + button to add your first asset.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.mutedLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverGrid _buildAssetList({bool twoColumn = false}) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _AssetCard(
          asset: _filteredAssets[i],
          onTap: () => _openAssetDetails(_filteredAssets[i]),
        ),
        childCount: _filteredAssets.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: twoColumn ? 2 : 1,
        childAspectRatio: twoColumn ? 1.4 : 3.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
    );
  }

  void _openAssetDetails(AssetModel asset) {
    context.push(AppRoutes.assetDetailsScreen, extra: asset.toMap());
  }
}

// ─── Asset Card Widget ────────────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onTap;

  const _AssetCard({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAppreciating = asset.currentValue >= asset.purchasePrice;
    final change = asset.currentValue - asset.purchasePrice;
    final changePercent = asset.purchasePrice > 0
        ? (change / asset.purchasePrice) * 100
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outlineLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: asset.iconName,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    asset.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    asset.category.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatAmount(asset.currentValue),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                if (asset.purchasePrice > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAppreciating
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 10,
                        color: isAppreciating
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                      Text(
                        '${changePercent.abs().toStringAsFixed(1)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isAppreciating
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
}

// ─── Asset Model ──────────────────────────────────────────────────────────────
class AssetModel {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final double currentValue;
  final String location;
  final String dateAcquired;
  final String iconName;
  final String semanticLabel;
  final String assetType;
  final String status;

  const AssetModel({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.currentValue,
    required this.location,
    required this.dateAcquired,
    required this.iconName,
    required this.semanticLabel,
    required this.assetType,
    required this.status,
  });

  /// Build from Supabase row
  factory AssetModel.fromSupabase(Map<String, dynamic> row) {
    return AssetModel(
      id: row['id'] as String,
      name: row['asset_name'] as String? ?? 'Unnamed Asset',
      category: row['asset_category'] as String? ?? 'fixed',
      purchasePrice: (row['purchase_price'] as num?)?.toDouble() ?? 0,
      currentValue: (row['current_value'] as num?)?.toDouble() ?? 0,
      location: [
        row['region'],
        row['country'],
      ].where((v) => v != null && (v as String).isNotEmpty).join(', '),
      dateAcquired: row['purchase_date'] as String? ?? '',
      iconName: _iconForType(row['asset_type'] as String? ?? 'other'),
      semanticLabel: '${row['asset_name']} asset icon',
      assetType: row['asset_type'] as String? ?? 'other',
      status: row['asset_status'] as String? ?? 'active',
    );
  }

  static String _iconForType(String type) {
    switch (type) {
      case 'land':
        return 'landscape';
      case 'building':
        return 'apartment';
      case 'vehicle':
        return 'directions_car';
      case 'machinery':
        return 'precision_manufacturing';
      case 'equipment':
        return 'build';
      case 'inventory':
        return 'inventory_2';
      case 'cash':
        return 'account_balance_wallet';
      case 'receivable':
        return 'receipt_long';
      case 'investment':
        return 'trending_up';
      case 'business':
        return 'business';
      case 'intangible':
        return 'lightbulb';
      default:
        return 'category';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'asset_name': name,
    'asset_category': category,
    'purchase_price': purchasePrice,
    'current_value': currentValue,
    'location': location,
    'purchase_date': dateAcquired,
    'iconName': iconName,
    'semanticLabel': semanticLabel,
    'asset_type': assetType,
    'asset_status': status,
  };
}