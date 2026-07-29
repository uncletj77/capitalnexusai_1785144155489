import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import 'widgets/assets_app_bar_widget.dart';
import 'widgets/assets_summary_widget.dart';
import 'widgets/assets_filter_widget.dart';
import 'widgets/asset_list_widget.dart';
import 'widgets/add_asset_fab_widget.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _selectedFilter = 0;

  final List<Map<String, dynamic>> _assetMaps = [
    {
      'id': 'a001',
      'name': 'NMB Bank Account',
      'category': 'current',
      'purchasePrice': 0.0,
      'currentValue': 45200000.0,
      'change': 0.0,
      'changePercent': 0.0,
      'location': 'Dar es Salaam',
      'dateAcquired': '2020-03-15',
      'iconName': 'account_balance',
      'isAppreciating': false,
      'semanticLabel': 'NMB bank account icon representing current cash asset',
    },
    {
      'id': 'a002',
      'name': 'Kijitonyama Land Plot',
      'category': 'fixed',
      'purchasePrice': 85000000.0,
      'currentValue': 142000000.0,
      'change': 57000000.0,
      'changePercent': 67.1,
      'location': 'Dar es Salaam',
      'dateAcquired': '2019-06-10',
      'iconName': 'landscape',
      'isAppreciating': true,
      'semanticLabel':
          'Land plot icon representing fixed real estate asset in Kijitonyama',
    },
    {
      'id': 'a003',
      'name': 'Toyota Hiace Bus',
      'category': 'depreciating',
      'purchasePrice': 65000000.0,
      'currentValue': 48000000.0,
      'change': -17000000.0,
      'changePercent': -26.2,
      'location': 'Dar es Salaam',
      'dateAcquired': '2021-01-20',
      'iconName': 'directions_bus',
      'isAppreciating': false,
      'semanticLabel': 'Bus icon representing Toyota Hiace transport asset',
    },
    {
      'id': 'a004',
      'name': 'Transport Business',
      'category': 'appreciating',
      'purchasePrice': 120000000.0,
      'currentValue': 228400000.0,
      'change': 108400000.0,
      'changePercent': 90.3,
      'location': 'Dar es Salaam',
      'dateAcquired': '2020-08-01',
      'iconName': 'business',
      'isAppreciating': true,
      'semanticLabel': 'Business icon representing transport company asset',
    },
    {
      'id': 'a005',
      'name': 'Pharmacy License',
      'category': 'intangible',
      'purchasePrice': 8000000.0,
      'currentValue': 15000000.0,
      'change': 7000000.0,
      'changePercent': 87.5,
      'location': 'Arusha',
      'dateAcquired': '2022-03-12',
      'iconName': 'local_pharmacy',
      'isAppreciating': true,
      'semanticLabel': 'Pharmacy icon representing intangible license asset',
    },
    {
      'id': 'a006',
      'name': 'Mbezi Beach Apartment',
      'category': 'fixed',
      'purchasePrice': 180000000.0,
      'currentValue': 245000000.0,
      'change': 65000000.0,
      'changePercent': 36.1,
      'location': 'Dar es Salaam',
      'dateAcquired': '2018-11-05',
      'iconName': 'apartment',
      'isAppreciating': true,
      'semanticLabel':
          'Apartment building icon representing Mbezi Beach property asset',
    },
    {
      'id': 'a007',
      'name': 'Dell Laptop & Equipment',
      'category': 'depreciating',
      'purchasePrice': 4500000.0,
      'currentValue': 2800000.0,
      'change': -1700000.0,
      'changePercent': -37.8,
      'location': 'Dar es Salaam',
      'dateAcquired': '2023-02-14',
      'iconName': 'computer',
      'isAppreciating': false,
      'semanticLabel':
          'Computer icon representing Dell laptop and equipment asset',
    },
    {
      'id': 'a008',
      'name': 'M-Pesa Float',
      'category': 'current',
      'purchasePrice': 0.0,
      'currentValue': 12500000.0,
      'change': 0.0,
      'changePercent': 0.0,
      'location': 'Dar es Salaam',
      'dateAcquired': '2023-01-01',
      'iconName': 'phone_android',
      'isAppreciating': false,
      'semanticLabel':
          'Mobile phone icon representing M-Pesa mobile money float',
    },
    {
      'id': 'a009',
      'name': 'Forex Investment (USD)',
      'category': 'appreciating',
      'purchasePrice': 30000000.0,
      'currentValue': 38500000.0,
      'change': 8500000.0,
      'changePercent': 28.3,
      'location': 'Online',
      'dateAcquired': '2024-05-20',
      'iconName': 'currency_exchange',
      'isAppreciating': true,
      'semanticLabel':
          'Currency exchange icon representing USD forex investment',
    },
  ];

  late List<AssetModel> _allAssets;
  List<AssetModel> _filteredAssets = [];

  @override
  void initState() {
    super.initState();
    _allAssets = _assetMaps.map(AssetModel.fromMap).toList();
    _filteredAssets = List.from(_allAssets);
  }

  void _onFilterChanged(int index) {
    // TODO: Replace with [Riverpod/Bloc] for production
    setState(() {
      _selectedFilter = index;
      const categories = [
        'all',
        'current',
        'fixed',
        'depreciating',
        'appreciating',
        'intangible',
      ];
      if (index == 0) {
        _filteredAssets = List.from(_allAssets);
      } else {
        _filteredAssets = _allAssets
            .where((a) => a.category == categories[index])
            .toList();
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
              child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
            ),
          ],
        ),
      ),
      floatingActionButton: const AddAssetFabWidget(),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
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
              onSelected: _onFilterChanged,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: AssetListWidget(assets: _filteredAssets),
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
                  onSelected: _onFilterChanged,
                  vertical: true,
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: AppTheme.outlineLight),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: AssetListWidget(
                  assets: _filteredAssets,
                  twoColumn: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AssetModel {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final double currentValue;
  final double change;
  final double changePercent;
  final String location;
  final String dateAcquired;
  final String iconName;
  final bool isAppreciating;
  final String semanticLabel;

  const AssetModel({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.currentValue,
    required this.change,
    required this.changePercent,
    required this.location,
    required this.dateAcquired,
    required this.iconName,
    required this.isAppreciating,
    required this.semanticLabel,
  });

  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      currentValue: (map['currentValue'] as num).toDouble(),
      change: (map['change'] as num).toDouble(),
      changePercent: (map['changePercent'] as num).toDouble(),
      location: map['location'] as String,
      dateAcquired: map['dateAcquired'] as String,
      iconName: map['iconName'] as String,
      isAppreciating: map['isAppreciating'] as bool,
      semanticLabel: map['semanticLabel'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'purchasePrice': purchasePrice,
    'currentValue': currentValue,
    'change': change,
    'changePercent': changePercent,
    'location': location,
    'dateAcquired': dateAcquired,
    'iconName': iconName,
    'isAppreciating': isAppreciating,
    'semanticLabel': semanticLabel,
  };
}
