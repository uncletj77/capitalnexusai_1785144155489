import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/accounting_engine.dart';
import '../services/enterprise_transaction_service.dart';
import '../services/master_asset_registry_service.dart';
import '../services/supabase_service.dart';

/// Enterprise Asset Repository
/// Manages the complete asset lifecycle through the Master Asset Registry.
/// Architecture: UI → Controller → AssetRepository → Services → DB
class AssetRepository {
  static AssetRepository? _instance;
  static AssetRepository get instance => _instance ??= AssetRepository._();
  AssetRepository._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ─── ASSET REGISTRY CRUD ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAssets({
    String? category,
    String? status,
    String? sourceModule,
    bool includeDisposed = false,
    int limit = 100,
    int offset = 0,
  }) async {
    final userId = _userId;
    if (userId == null) throw AssetException('User not authenticated');
    try {
      var query = _client
          .from('master_asset_registry')
          .select()
          .eq('user_id', userId);
      if (!includeDisposed) query = query.neq('asset_status', 'disposed');
      if (category != null) query = query.eq('asset_category', category);
      if (status != null) query = query.eq('asset_status', status);
      if (sourceModule != null) query = query.eq('source_module', sourceModule);
      return List<Map<String, dynamic>>.from(
        await query
            .order('current_value', ascending: false)
            .range(offset, offset + limit - 1),
      );
    } catch (e) {
      if (e is AssetException) rethrow;
      throw AssetException('Failed to fetch assets: $e');
    }
  }

  Future<Map<String, dynamic>?> getAssetById(String assetId) async {
    final userId = _userId;
    if (userId == null) throw AssetException('User not authenticated');
    try {
      return await _client
          .from('master_asset_registry')
          .select()
          .eq('id', assetId)
          .eq('user_id', userId)
          .single();
    } catch (e) {
      throw AssetException('Failed to fetch asset: $e');
    }
  }

  Future<Map<String, dynamic>> registerAsset({
    required String registryName,
    required String assetCategory,
    required String sourceModule,
    required double currentValue,
    String? assetSubcategory,
    String? sourceEntityId,
    String? sourceEntityName,
    double? acquisitionCost,
    DateTime? acquisitionDate,
    String? serialNumber,
    String? department,
    String? custodian,
    String? condition,
    String? depreciation_method,
    double? usefulLifeYears,
    double? salvageValue,
    String? notes,
    String currency = 'TZS',
  }) async {
    final userId = _userId;
    if (userId == null) throw AssetException('User not authenticated');
    if (registryName.trim().isEmpty)
      throw AssetException('Asset name is required');
    if (currentValue < 0)
      throw AssetException('Asset value cannot be negative');

    try {
      // Check for duplicate
      if (sourceEntityId != null) {
        final existing = await _client
            .from('master_asset_registry')
            .select('id')
            .eq('user_id', userId)
            .eq('source_module', sourceModule)
            .eq('source_entity_id', sourceEntityId)
            .maybeSingle();
        if (existing != null) {
          throw AssetException('Asset already registered for this entity');
        }
      }

      final acqCost = acquisitionCost ?? currentValue;
      final bookValue = currentValue;

      final asset = await _client
          .from('master_asset_registry')
          .insert({
            'user_id': userId,
            'registry_name': registryName.trim(),
            'asset_category': assetCategory,
            'asset_subcategory': assetSubcategory,
            'source_module': sourceModule,
            'source_entity_id': sourceEntityId,
            'source_entity_name': sourceEntityName,
            'current_value': currentValue,
            'acquisition_cost': acqCost,
            'book_value': bookValue,
            'market_value': currentValue,
            'acquisition_date': acquisitionDate?.toIso8601String().split(
              'T',
            )[0],
            'serial_number': serialNumber,
            'department': department,
            'custodian': custodian,
            'condition': condition ?? 'good',
            'depreciation_method': depreciation_method ?? 'straight_line',
            'useful_life_years': usefulLifeYears ?? 5,
            'salvage_value': salvageValue ?? 0,
            'asset_status': 'active',
            'is_auto_registered': false,
            'last_valuation_date': DateTime.now().toIso8601String().split(
              'T',
            )[0],
            'currency': currency,
            'notes': notes,
          })
          .select()
          .single();

      final assetId = asset['id'] as String;

      // Create depreciation schedule if applicable
      if ((usefulLifeYears ?? 0) > 0 && acqCost > 0) {
        await _createDepreciationSchedule(
          assetRegistryId: assetId,
          acquisitionCost: acqCost,
          salvageValue: salvageValue ?? 0,
          usefulLifeYears: usefulLifeYears ?? 5,
          method: depreciation_method ?? 'straight_line',
          startDate: acquisitionDate ?? DateTime.now(),
        );
      }

      // Create accounting entry for asset purchase
      if (acqCost > 0 && acquisitionDate != null) {
        try {
          await AccountingEngine.instance.recordAssetPurchase(
            amount: acqCost,
            assetName: registryName,
            date: acquisitionDate,
            sourceEntityId: assetId,
            currency: currency,
          );
        } catch (_) {}
      }

      // Create enterprise transaction
      try {
        await EnterpriseTransactionService.instance.createTransaction(
          type: 'asset_purchase',
          category: assetCategory,
          amount: acqCost,
          date: acquisitionDate ?? DateTime.now(),
          title: 'Asset Registered: $registryName',
          description: 'Asset registered in Master Asset Registry',
          currency: currency,
          status: 'completed',
        );
      } catch (_) {}

      await _logAudit(
        entityType: 'asset',
        entityId: assetId,
        action: 'create',
        description: 'Asset registered: $registryName',
        newValues: asset,
      );

      return asset;
    } catch (e) {
      if (e is AssetException) rethrow;
      throw AssetException('Failed to register asset: $e');
    }
  }

  Future<Map<String, dynamic>> updateAsset(
    String assetId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _userId;
    if (userId == null) throw AssetException('User not authenticated');
    try {
      final oldAsset = await getAssetById(assetId);
      final updated = await _client
          .from('master_asset_registry')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
            'last_valuation_date': DateTime.now().toIso8601String().split(
              'T',
            )[0],
          })
          .eq('id', assetId)
          .eq('user_id', userId)
          .select()
          .single();

      await _logAudit(
        entityType: 'asset',
        entityId: assetId,
        action: 'update',
        description: 'Asset updated',
        oldValues: oldAsset,
        newValues: updated,
      );

      return updated;
    } catch (e) {
      if (e is AssetException) rethrow;
      throw AssetException('Failed to update asset: $e');
    }
  }

  Future<bool> archiveAsset(String assetId) async {
    final userId = _userId;
    if (userId == null) throw AssetException('User not authenticated');
    try {
      await _client
          .from('master_asset_registry')
          .update({
            'asset_status': 'inactive',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assetId)
          .eq('user_id', userId);

      await _logAudit(
        entityType: 'asset',
        entityId: assetId,
        action: 'archive',
        description: 'Asset archived',
      );
      return true;
    } catch (e) {
      throw AssetException('Failed to archive asset: $e');
    }
  }

  Future<bool> restoreAsset(String assetId) async {
    final userId = _userId;
    if (userId == null) throw AssetException('User not authenticated');
    try {
      await _client
          .from('master_asset_registry')
          .update({
            'asset_status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assetId)
          .eq('user_id', userId);

      await _logAudit(
        entityType: 'asset',
        entityId: assetId,
        action: 'restore',
        description: 'Asset restored',
      );
      return true;
    } catch (e) {
      throw AssetException('Failed to restore asset: $e');
    }
  }

  // ─── ASSET DISPOSAL ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> disposeAsset({
    required String assetId,
    required String disposalType,
    required DateTime disposalDate,
    double disposalProceeds = 0,
    String? description,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw AssetException('User not authenticated');
    try {
      final asset = await getAssetById(assetId);
      final bookValue =
          (asset?['book_value'] as num?)?.toDouble() ??
          (asset?['current_value'] as num?)?.toDouble() ??
          0;
      final gainLoss = disposalProceeds - bookValue;

      // Create disposal record
      final disposal = await _client
          .from('asset_disposal_records')
          .insert({
            'user_id': userId,
            'asset_registry_id': assetId,
            'disposal_type': disposalType,
            'disposal_date': disposalDate.toIso8601String().split('T')[0],
            'book_value_at_disposal': bookValue,
            'disposal_proceeds': disposalProceeds,
            'gain_loss': gainLoss,
            'description': description,
            'notes': notes,
          })
          .select()
          .single();

      // Update asset status
      await _client
          .from('master_asset_registry')
          .update({
            'asset_status': 'disposed',
            'disposal_date': disposalDate.toIso8601String().split('T')[0],
            'disposal_type': disposalType,
            'current_value': 0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assetId)
          .eq('user_id', userId);

      // Create accounting entry
      try {
        if (disposalProceeds > 0) {
          await AccountingEngine.instance.createJournalEntry(
            description: 'Asset Disposal: ${asset?['registry_name']}',
            journalDate: disposalDate,
            journalType: 'automatic',
            sourceModule: 'assets',
            sourceEntityId: assetId,
            autoPost: true,
            lines: [
              JournalLine(
                accountCode: '1000',
                accountName: 'Cash/Bank',
                debitAmount: disposalProceeds,
                creditAmount: 0,
              ),
              if (gainLoss < 0)
                JournalLine(
                  accountCode: '5300',
                  accountName: 'Loss on Asset Disposal',
                  debitAmount: gainLoss.abs(),
                  creditAmount: 0,
                ),
              JournalLine(
                accountCode: '1510',
                accountName: 'Accumulated Depreciation',
                debitAmount:
                    (asset?['accumulated_depreciation'] as num?)?.toDouble() ??
                    0,
                creditAmount: 0,
              ),
              JournalLine(
                accountCode: '1500',
                accountName: 'Fixed Assets',
                debitAmount: 0,
                creditAmount:
                    (asset?['acquisition_cost'] as num?)?.toDouble() ??
                    bookValue,
              ),
              if (gainLoss > 0)
                JournalLine(
                  accountCode: '4100',
                  accountName: 'Gain on Asset Disposal',
                  debitAmount: 0,
                  creditAmount: gainLoss,
                ),
            ],
          );
        }
      } catch (_) {}

      // Create enterprise transaction
      try {
        await EnterpriseTransactionService.instance.createTransaction(
          type: 'asset_sale',
          category: asset?['asset_category'] ?? 'other',
          amount: disposalProceeds,
          date: disposalDate,
          title: 'Asset Disposal: ${asset?['registry_name']}',
          description: 'Asset disposed via $disposalType',
          currency: asset?['currency'] ?? 'TZS',
          status: 'completed',
        );
      } catch (_) {}

      await _logAudit(
        entityType: 'asset',
        entityId: assetId,
        action: 'delete',
        description: 'Asset disposed: $disposalType',
        oldValues: asset,
      );

      return disposal;
    } catch (e) {
      if (e is AssetException) rethrow;
      throw AssetException('Failed to dispose asset: $e');
    }
  }

  // ─── DEPRECIATION ─────────────────────────────────────────────────────────

  Future<void> _createDepreciationSchedule({
    required String assetRegistryId,
    required double acquisitionCost,
    required double salvageValue,
    required double usefulLifeYears,
    required String method,
    required DateTime startDate,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final depResult = await _client.rpc(
        'calculate_depreciation',
        params: {
          'p_acquisition_cost': acquisitionCost,
          'p_salvage_value': salvageValue,
          'p_useful_life_years': usefulLifeYears,
          'p_method': method,
        },
      );

      if (depResult != null && (depResult as List).isNotEmpty) {
        final dep = depResult.first;
        final endDate = DateTime(
          startDate.year + usefulLifeYears.toInt(),
          startDate.month,
          startDate.day,
        );

        await _client.from('asset_depreciation_schedules').insert({
          'user_id': userId,
          'asset_registry_id': assetRegistryId,
          'depreciation_method': method,
          'acquisition_cost': acquisitionCost,
          'salvage_value': salvageValue,
          'useful_life_years': usefulLifeYears,
          'depreciation_rate': dep['depreciation_rate'] ?? 0,
          'annual_depreciation': dep['annual_depreciation'] ?? 0,
          'monthly_depreciation': dep['monthly_depreciation'] ?? 0,
          'accumulated_depreciation': 0,
          'current_book_value': acquisitionCost - salvageValue,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'next_depreciation_date': DateTime(
            startDate.year,
            startDate.month + 1,
            startDate.day,
          ).toIso8601String().split('T')[0],
        });
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getDepreciationSchedules({
    String? assetRegistryId,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('asset_depreciation_schedules')
          .select()
          .eq('user_id', userId);
      if (assetRegistryId != null) {
        query = query.eq('asset_registry_id', assetRegistryId);
      }
      return List<Map<String, dynamic>>.from(
        await query.order('created_at', ascending: false),
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> postMonthlyDepreciation(String scheduleId) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      final schedule = await _client
          .from('asset_depreciation_schedules')
          .select()
          .eq('id', scheduleId)
          .eq('user_id', userId)
          .single();

      final monthlyDep =
          (schedule['monthly_depreciation'] as num?)?.toDouble() ?? 0;
      if (monthlyDep <= 0) return false;

      final accumulatedBefore =
          (schedule['accumulated_depreciation'] as num?)?.toDouble() ?? 0;
      final bookValueBefore =
          (schedule['current_book_value'] as num?)?.toDouble() ?? 0;
      final accumulatedAfter = accumulatedBefore + monthlyDep;
      final bookValueAfter = (bookValueBefore - monthlyDep).clamp(
        0.0,
        double.infinity,
      );

      final today = DateTime.now();
      final periodStart = DateTime(today.year, today.month, 1);
      final periodEnd = DateTime(today.year, today.month + 1, 0);

      // Get asset name
      final assetId = schedule['asset_registry_id'] as String?;
      String assetName = 'Asset';
      if (assetId != null) {
        try {
          final asset = await _client
              .from('master_asset_registry')
              .select('registry_name')
              .eq('id', assetId)
              .single();
          assetName = asset['registry_name'] ?? 'Asset';
        } catch (_) {}
      }

      // Create accounting entry
      Map<String, dynamic>? journalEntry;
      try {
        journalEntry = await AccountingEngine.instance.recordDepreciation(
          amount: monthlyDep,
          assetName: assetName,
          date: today,
          assetRegistryId: assetId,
        );
      } catch (_) {}

      // Record posting
      await _client.from('asset_depreciation_postings').insert({
        'user_id': userId,
        'schedule_id': scheduleId,
        'asset_registry_id': assetId,
        'posting_date': today.toIso8601String().split('T')[0],
        'period_start': periodStart.toIso8601String().split('T')[0],
        'period_end': periodEnd.toIso8601String().split('T')[0],
        'depreciation_amount': monthlyDep,
        'accumulated_before': accumulatedBefore,
        'accumulated_after': accumulatedAfter,
        'book_value_before': bookValueBefore,
        'book_value_after': bookValueAfter,
        'journal_entry_id': journalEntry?['id'],
      });

      // Update schedule
      await _client
          .from('asset_depreciation_schedules')
          .update({
            'accumulated_depreciation': accumulatedAfter,
            'current_book_value': bookValueAfter,
            'last_depreciation_date': today.toIso8601String().split('T')[0],
            'next_depreciation_date': DateTime(
              today.year,
              today.month + 1,
              1,
            ).toIso8601String().split('T')[0],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', scheduleId);

      // Update asset registry
      if (assetId != null) {
        await _client
            .from('master_asset_registry')
            .update({
              'accumulated_depreciation': accumulatedAfter,
              'book_value': bookValueAfter,
              'current_value': bookValueAfter,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', assetId);
      }

      return true;
    } catch (e) {
      throw AssetException('Failed to post depreciation: $e');
    }
  }

  // ─── MAINTENANCE ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMaintenanceRecords({
    String? assetRegistryId,
  }) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      var query = _client
          .from('asset_maintenance_records')
          .select()
          .eq('user_id', userId);
      if (assetRegistryId != null) {
        query = query.eq('asset_registry_id', assetRegistryId);
      }
      return List<Map<String, dynamic>>.from(
        await query.order('maintenance_date', ascending: false),
      );
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> recordMaintenance({
    required String assetRegistryId,
    required String maintenanceType,
    required String title,
    required DateTime maintenanceDate,
    double cost = 0,
    String? description,
    String? vendor,
    DateTime? nextMaintenanceDate,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw AssetException('User not authenticated');
    try {
      final record = await _client
          .from('asset_maintenance_records')
          .insert({
            'user_id': userId,
            'asset_registry_id': assetRegistryId,
            'maintenance_type': maintenanceType,
            'title': title,
            'description': description,
            'maintenance_date': maintenanceDate.toIso8601String().split('T')[0],
            'next_maintenance_date': nextMaintenanceDate
                ?.toIso8601String()
                .split('T')[0],
            'cost': cost,
            'vendor': vendor,
            'status': 'completed',
            'notes': notes,
          })
          .select()
          .single();

      // Create expense transaction for maintenance cost
      if (cost > 0) {
        try {
          await EnterpriseTransactionService.instance.createTransaction(
            type: 'expense',
            category: 'maintenance',
            amount: cost,
            date: maintenanceDate,
            title: 'Maintenance: $title',
            description: description,
            status: 'completed',
          );
        } catch (_) {}
      }

      return record;
    } catch (e) {
      if (e is AssetException) rethrow;
      throw AssetException('Failed to record maintenance: $e');
    }
  }

  // ─── AUTO-REGISTRATION ────────────────────────────────────────────────────

  Future<int> autoRegisterAllAssets() async {
    return MasterAssetRegistryService.instance.autoRegisterAllAssets();
  }

  // ─── AUDIT ────────────────────────────────────────────────────────────────

  Future<void> _logAudit({
    required String entityType,
    required String entityId,
    required String action,
    String? description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client.from('financial_audit_trail').insert({
        'user_id': userId,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'description': description,
        'old_values': oldValues,
        'new_values': newValues,
        'performed_by': userId,
        'performed_at': DateTime.now().toIso8601String(),
        'source_module': 'assets',
      });
    } catch (_) {}
  }
}

class AssetException implements Exception {
  final String message;
  const AssetException(this.message);

  @override
  String toString() => 'AssetException: $message';
}