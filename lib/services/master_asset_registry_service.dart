import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// Master Asset Registry Service — REPAIRED
/// Auto-detects and registers all qualifying assets from every module.
/// Fixes: businesses uses owner_id, investments uses owner_id.
class MasterAssetRegistryService {
  static MasterAssetRegistryService? _instance;
  static MasterAssetRegistryService get instance =>
      _instance ??= MasterAssetRegistryService._();
  MasterAssetRegistryService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── REGISTRY CRUD ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRegistryAssets({
    String? category,
    String? sourceModule,
    String? status,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('master_asset_registry')
          .select()
          .eq('user_id', userId);
      if (category != null) query = query.eq('asset_category', category);
      if (sourceModule != null) query = query.eq('source_module', sourceModule);
      if (status != null) {
        query = query.eq('asset_status', status);
      } else {
        query = query.neq('asset_status', 'disposed');
      }
      return List<Map<String, dynamic>>.from(
        await query.order('current_value', ascending: false),
      );
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getRegistrySummary() async {
    final userId = _userId;
    if (userId == null) {
      return {'total_value': 0.0, 'asset_count': 0, 'categories': {}};
    }
    try {
      final assets = await getRegistryAssets();
      double totalValue = 0;
      final categories = <String, Map<String, dynamic>>{};

      for (final asset in assets) {
        final value = (asset['current_value'] as num?)?.toDouble() ?? 0;
        totalValue += value;
        final cat = asset['asset_category'] as String? ?? 'other';
        categories.putIfAbsent(
          cat,
          () => {'count': 0, 'value': 0.0, 'label': _categoryLabel(cat)},
        );
        categories[cat]!['count'] = (categories[cat]!['count'] as int) + 1;
        categories[cat]!['value'] =
            (categories[cat]!['value'] as double) + value;
      }

      return {
        'total_value': totalValue,
        'asset_count': assets.length,
        'categories': categories,
        'assets': assets,
      };
    } catch (_) {
      return {'total_value': 0.0, 'asset_count': 0, 'categories': {}};
    }
  }

  // ─── AUTO-REGISTRATION (REPAIRED) ────────────────────────────────────────

  Future<int> autoRegisterAllAssets() async {
    final userId = _userId;
    if (userId == null) return 0;
    int registered = 0;

    registered += await _registerFromAssets(userId);
    registered += await _registerFromInvestments(userId);
    registered += await _registerFromBusinesses(userId);
    registered += await _registerFromAccounts(userId);
    registered += await _registerFromLoansReceivable(userId);

    return registered;
  }

  Future<int> _registerFromAssets(String userId) async {
    int count = 0;
    try {
      final assets = await _client
          .from('assets')
          .select()
          .eq('user_id', userId)
          .neq('asset_status', 'disposed');

      for (final asset in assets) {
        final assetId = asset['id'] as String;
        final existing = await _client
            .from('master_asset_registry')
            .select('id')
            .eq('user_id', userId)
            .eq('source_module', 'assets')
            .eq('source_entity_id', assetId)
            .maybeSingle();

        if (existing == null) {
          await _client.from('master_asset_registry').insert({
            'user_id': userId,
            'asset_id': assetId,
            'registry_name': asset['asset_name'] ?? 'Asset',
            'asset_category': _mapAssetCategory(asset['asset_type'] as String?),
            'asset_subcategory': asset['asset_type'],
            'source_module': 'assets',
            'source_entity_id': assetId,
            'source_entity_name': asset['asset_name'],
            'current_value': asset['current_value'] ?? 0,
            'acquisition_cost': asset['purchase_price'] ?? 0,
            'acquisition_date': asset['purchase_date'],
            'asset_status': asset['asset_status'] ?? 'active',
            'is_auto_registered': true,
            'last_valuation_date': DateTime.now().toIso8601String().split(
              'T',
            )[0],
          });
          count++;
        } else {
          await _client
              .from('master_asset_registry')
              .update({
                'current_value': asset['current_value'] ?? 0,
                'asset_status': asset['asset_status'] ?? 'active',
                'updated_at': DateTime.now().toIso8601String(),
                'last_valuation_date': DateTime.now().toIso8601String().split(
                  'T',
                )[0],
              })
              .eq('id', existing['id'] as String);
        }
      }
    } catch (_) {}
    return count;
  }

  Future<int> _registerFromInvestments(String userId) async {
    int count = 0;
    try {
      // Investments uses owner_id — query by owner_id
      final investments = await _client
          .from('investments')
          .select()
          .eq('owner_id', userId)
          .neq('status', 'closed');

      for (final inv in investments) {
        final invId = inv['id'] as String;
        final existing = await _client
            .from('master_asset_registry')
            .select('id')
            .eq('user_id', userId)
            .eq('source_module', 'investments')
            .eq('source_entity_id', invId)
            .maybeSingle();

        final currentValue =
            (inv['current_value'] as num?)?.toDouble() ??
            (inv['initial_value'] as num?)?.toDouble() ??
            (inv['amount_invested'] as num?)?.toDouble() ??
            0;

        if (existing == null) {
          await _client.from('master_asset_registry').insert({
            'user_id': userId,
            'registry_name':
                inv['name'] ?? inv['investment_name'] ?? 'Investment',
            'asset_category': 'financial',
            'asset_subcategory':
                inv['category'] ?? inv['investment_type'] ?? 'investment',
            'source_module': 'investments',
            'source_entity_id': invId,
            'source_entity_name': inv['name'] ?? inv['investment_name'],
            'current_value': currentValue,
            'acquisition_cost':
                inv['initial_value'] ?? inv['amount_invested'] ?? 0,
            'acquisition_date': inv['investment_date'] ?? inv['start_date'],
            'asset_status': 'active',
            'linked_investment_id': invId,
            'is_auto_registered': true,
            'last_valuation_date': DateTime.now().toIso8601String().split(
              'T',
            )[0],
          });
          count++;
        } else {
          await _client
              .from('master_asset_registry')
              .update({
                'current_value': currentValue,
                'updated_at': DateTime.now().toIso8601String(),
                'last_valuation_date': DateTime.now().toIso8601String().split(
                  'T',
                )[0],
              })
              .eq('id', existing['id'] as String);
        }
      }
    } catch (_) {}
    return count;
  }

  Future<int> _registerFromBusinesses(String userId) async {
    int count = 0;
    try {
      // Businesses uses owner_id — query by owner_id
      final businesses = await _client
          .from('businesses')
          .select()
          .eq('owner_id', userId)
          .eq('is_active', true);

      for (final biz in businesses) {
        final bizId = biz['id'] as String;
        final existing = await _client
            .from('master_asset_registry')
            .select('id')
            .eq('user_id', userId)
            .eq('source_module', 'businesses')
            .eq('source_entity_id', bizId)
            .maybeSingle();

        final value =
            (biz['business_value'] as num?)?.toDouble() ??
            (biz['initial_capital'] as num?)?.toDouble() ??
            0;

        if (existing == null) {
          await _client.from('master_asset_registry').insert({
            'user_id': userId,
            'registry_name': biz['name'] ?? biz['business_name'] ?? 'Business',
            'asset_category': 'business',
            'asset_subcategory': biz['business_type'] ?? 'business',
            'source_module': 'businesses',
            'source_entity_id': bizId,
            'source_entity_name': biz['name'] ?? biz['business_name'],
            'current_value': value,
            'acquisition_cost': biz['initial_capital'] ?? 0,
            'asset_status': 'active',
            'linked_business_id': bizId,
            'is_auto_registered': true,
            'last_valuation_date': DateTime.now().toIso8601String().split(
              'T',
            )[0],
          });
          count++;
        } else {
          await _client
              .from('master_asset_registry')
              .update({
                'current_value': value,
                'updated_at': DateTime.now().toIso8601String(),
                'last_valuation_date': DateTime.now().toIso8601String().split(
                  'T',
                )[0],
              })
              .eq('id', existing['id'] as String);
        }
      }
    } catch (_) {}
    return count;
  }

  Future<int> _registerFromAccounts(String userId) async {
    int count = 0;
    try {
      final accounts = await _client
          .from('financial_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('is_archived', false)
          .inFilter('account_category', ['savings', 'investment']);

      for (final acc in accounts) {
        final accId = acc['id'] as String;
        final existing = await _client
            .from('master_asset_registry')
            .select('id')
            .eq('user_id', userId)
            .eq('source_module', 'accounts')
            .eq('source_entity_id', accId)
            .maybeSingle();

        final balance = (acc['balance'] as num?)?.toDouble() ?? 0;

        if (existing == null) {
          await _client.from('master_asset_registry').insert({
            'user_id': userId,
            'registry_name': acc['account_name'] ?? 'Account',
            'asset_category': 'current',
            'asset_subcategory': acc['account_category'] ?? 'savings',
            'source_module': 'accounts',
            'source_entity_id': accId,
            'source_entity_name': acc['account_name'],
            'current_value': balance,
            'acquisition_cost': acc['initial_balance'] ?? 0,
            'asset_status': 'active',
            'is_auto_registered': true,
            'last_valuation_date': DateTime.now().toIso8601String().split(
              'T',
            )[0],
          });
          count++;
        } else {
          await _client
              .from('master_asset_registry')
              .update({
                'current_value': balance,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existing['id'] as String);
        }
      }
    } catch (_) {}
    return count;
  }

  Future<int> _registerFromLoansReceivable(String userId) async {
    int count = 0;
    try {
      final loans = await _client
          .from('loans_receivable')
          .select()
          .eq('user_id', userId)
          .neq('status', 'fully_repaid');

      for (final loan in loans) {
        final loanId = loan['id'] as String;
        final existing = await _client
            .from('master_asset_registry')
            .select('id')
            .eq('user_id', userId)
            .eq('source_module', 'loans_receivable')
            .eq('source_entity_id', loanId)
            .maybeSingle();

        final balance =
            (loan['outstanding_balance'] as num?)?.toDouble() ??
            (loan['principal_amount'] as num?)?.toDouble() ??
            0;

        if (existing == null) {
          await _client.from('master_asset_registry').insert({
            'user_id': userId,
            'registry_name': 'Loan to ${loan['borrower_name'] ?? 'Borrower'}',
            'asset_category': 'receivable',
            'asset_subcategory': 'loan_receivable',
            'source_module': 'loans_receivable',
            'source_entity_id': loanId,
            'source_entity_name': loan['borrower_name'],
            'current_value': balance,
            'acquisition_cost': loan['principal_amount'] ?? 0,
            'asset_status': 'active',
            'is_auto_registered': true,
            'last_valuation_date': DateTime.now().toIso8601String().split(
              'T',
            )[0],
          });
          count++;
        } else {
          await _client
              .from('master_asset_registry')
              .update({
                'current_value': balance,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existing['id'] as String);
        }
      }
    } catch (_) {}
    return count;
  }

  // ─── ASSET MANAGEMENT ────────────────────────────────────────────────────

  Future<bool> updateRegistryAsset(
    String assetId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('master_asset_registry')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', assetId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> archiveRegistryAsset(String assetId) async {
    return updateRegistryAsset(assetId, {'asset_status': 'archived'});
  }

  Future<bool> deleteRegistryAsset(String assetId) async {
    try {
      await _client.from('master_asset_registry').delete().eq('id', assetId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  String _mapAssetCategory(String? assetType) {
    if (assetType == null) return 'other';
    switch (assetType.toLowerCase()) {
      case 'vehicle':
      case 'car':
      case 'truck':
      case 'motorcycle':
        return 'vehicle';
      case 'real_estate':
      case 'property':
      case 'land':
      case 'building':
        return 'real_estate';
      case 'equipment':
      case 'machinery':
        return 'equipment';
      case 'digital':
      case 'cryptocurrency':
      case 'nft':
        return 'digital';
      case 'precious_metal':
      case 'gold':
      case 'silver':
        return 'precious';
      case 'investment':
      case 'stocks':
      case 'bonds':
        return 'financial';
      case 'cash':
      case 'savings':
        return 'current';
      default:
        return 'other';
    }
  }

  String _categoryLabel(String category) {
    const labels = {
      'real_estate': 'Real Estate',
      'vehicle': 'Vehicles',
      'financial': 'Financial',
      'business': 'Businesses',
      'current': 'Cash & Savings',
      'receivable': 'Receivables',
      'equipment': 'Equipment',
      'digital': 'Digital Assets',
      'precious': 'Precious Assets',
      'other': 'Other Assets',
    };
    return labels[category] ?? category;
  }
}
