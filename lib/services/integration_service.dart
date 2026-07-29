import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class IntegrationConnector {
  final String id;
  final String providerName;
  final String providerType;
  final String status;
  final Map<String, dynamic> configuration;
  final DateTime createdAt;

  IntegrationConnector({
    required this.id,
    required this.providerName,
    required this.providerType,
    required this.status,
    required this.configuration,
    required this.createdAt,
  });

  factory IntegrationConnector.fromMap(Map<String, dynamic> m) =>
      IntegrationConnector(
        id: m['id'] ?? '',
        providerName: m['provider_name'] ?? '',
        providerType: m['provider_type'] ?? '',
        status: m['status'] ?? 'inactive',
        configuration: (m['configuration'] as Map<String, dynamic>?) ?? {},
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'])
            : DateTime.now(),
      );

  String get statusLabel {
    switch (status) {
      case 'connected':
        return 'Connected';
      case 'configured':
        return 'Configured';
      case 'error':
        return 'Error';
      default:
        return 'Inactive';
    }
  }

  String get typeIcon {
    switch (providerType) {
      case 'banking':
        return 'account_balance';
      case 'mobile_money':
        return 'phone_android';
      case 'ai_provider':
        return 'psychology';
      case 'payment':
        return 'payment';
      case 'accounting':
        return 'calculate';
      case 'erp':
        return 'business';
      case 'hr':
        return 'people';
      default:
        return 'extension';
    }
  }
}

class ApiKeyEntry {
  final String id;
  final String providerName;
  final String keyReference;
  final String keyLabel;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;

  ApiKeyEntry({
    required this.id,
    required this.providerName,
    required this.keyReference,
    required this.keyLabel,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
  });

  factory ApiKeyEntry.fromMap(Map<String, dynamic> m) => ApiKeyEntry(
    id: m['id'] ?? '',
    providerName: m['provider_name'] ?? '',
    keyReference: m['key_reference'] ?? '',
    keyLabel: m['key_label'] ?? m['provider_name'] ?? '',
    isActive: m['is_active'] ?? true,
    expiresAt: m['expires_at'] != null
        ? DateTime.tryParse(m['expires_at'])
        : null,
    createdAt: m['created_at'] != null
        ? DateTime.parse(m['created_at'])
        : DateTime.now(),
  );
}

class IntegrationLog {
  final String id;
  final String? integrationId;
  final String requestType;
  final String status;
  final int durationMs;
  final int responseCode;
  final String? errorMessage;
  final DateTime createdAt;

  IntegrationLog({
    required this.id,
    this.integrationId,
    required this.requestType,
    required this.status,
    required this.durationMs,
    required this.responseCode,
    this.errorMessage,
    required this.createdAt,
  });

  factory IntegrationLog.fromMap(Map<String, dynamic> m) => IntegrationLog(
    id: m['id'] ?? '',
    integrationId: m['integration_id'],
    requestType: m['request_type'] ?? '',
    status: m['status'] ?? '',
    durationMs: m['duration_ms'] ?? 0,
    responseCode: m['response_code'] ?? 0,
    errorMessage: m['error_message'],
    createdAt: m['created_at'] != null
        ? DateTime.parse(m['created_at'])
        : DateTime.now(),
  );
}

class WebhookEvent {
  final String id;
  final String providerName;
  final String eventName;
  final Map<String, dynamic> payload;
  final bool processed;
  final DateTime createdAt;

  WebhookEvent({
    required this.id,
    required this.providerName,
    required this.eventName,
    required this.payload,
    required this.processed,
    required this.createdAt,
  });

  factory WebhookEvent.fromMap(Map<String, dynamic> m) => WebhookEvent(
    id: m['id'] ?? '',
    providerName: m['provider_name'] ?? '',
    eventName: m['event_name'] ?? '',
    payload: (m['payload'] as Map<String, dynamic>?) ?? {},
    processed: m['processed'] ?? false,
    createdAt: m['created_at'] != null
        ? DateTime.parse(m['created_at'])
        : DateTime.now(),
  );
}

class ImportExportJob {
  final String id;
  final String jobType;
  final String status;
  final String? fileName;
  final String? fileFormat;
  final int recordCount;
  final int errorCount;
  final DateTime createdAt;
  final DateTime? completedAt;

  ImportExportJob({
    required this.id,
    required this.jobType,
    required this.status,
    this.fileName,
    this.fileFormat,
    required this.recordCount,
    required this.errorCount,
    required this.createdAt,
    this.completedAt,
  });

  factory ImportExportJob.fromMap(Map<String, dynamic> m) => ImportExportJob(
    id: m['id'] ?? '',
    jobType: m['job_type'] ?? '',
    status: m['status'] ?? 'pending',
    fileName: m['file_name'],
    fileFormat: m['file_format'],
    recordCount: m['record_count'] ?? 0,
    errorCount: m['error_count'] ?? 0,
    createdAt: m['created_at'] != null
        ? DateTime.parse(m['created_at'])
        : DateTime.now(),
    completedAt: m['completed_at'] != null
        ? DateTime.tryParse(m['completed_at'])
        : null,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT BUS
// ─────────────────────────────────────────────────────────────────────────────

class CnaEvent {
  final String eventType;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  CnaEvent({
    required this.eventType,
    required this.entityType,
    this.entityId,
    required this.payload,
  }) : timestamp = DateTime.now();
}

typedef CnaEventHandler = void Function(CnaEvent event);

class EventBus {
  static final EventBus _instance = EventBus._();
  static EventBus get instance => _instance;
  EventBus._();

  final Map<String, List<CnaEventHandler>> _subscribers = {};

  void subscribe(String eventType, CnaEventHandler handler) {
    _subscribers.putIfAbsent(eventType, () => []).add(handler);
  }

  void unsubscribe(String eventType, CnaEventHandler handler) {
    _subscribers[eventType]?.remove(handler);
  }

  void publish(CnaEvent event) {
    final handlers = _subscribers[event.eventType] ?? [];
    for (final handler in handlers) {
      try {
        handler(event);
      } catch (_) {}
    }
    // Also fire wildcard subscribers
    final wildcardHandlers = _subscribers['*'] ?? [];
    for (final handler in wildcardHandlers) {
      try {
        handler(event);
      } catch (_) {}
    }
  }

  // Standard CNA event types
  static const String financeTransactionCreated = 'Finance.TransactionCreated';
  static const String loanPaymentCompleted = 'Loan.PaymentCompleted';
  static const String assetCreated = 'Asset.Created';
  static const String businessUpdated = 'Business.Updated';
  static const String investmentReturnReceived = 'Investment.ReturnReceived';
  static const String forecastGenerated = 'Forecast.Generated';
  static const String aiRecommendationCreated = 'AI.RecommendationCreated';
  static const String workflowCompleted = 'Workflow.Completed';
  static const String integrationConnected = 'Integration.Connected';
  static const String webhookReceived = 'Webhook.Received';
  static const String importCompleted = 'Import.Completed';
  static const String exportCompleted = 'Export.Completed';
}

// ─────────────────────────────────────────────────────────────────────────────
// CONNECTOR INTERFACES
// ─────────────────────────────────────────────────────────────────────────────

abstract class BankConnectorInterface {
  Future<List<Map<String, dynamic>>> syncTransactions();
  Future<Map<String, dynamic>> checkBalance();
  Future<List<Map<String, dynamic>>> importStatements();
  Future<bool> verifyPayment(String reference);
}

abstract class MobileMoneyConnectorInterface {
  Future<Map<String, dynamic>> checkBalance();
  Future<bool> initiatePayment(double amount, String recipient, String ref);
  Future<Map<String, dynamic>> confirmTransaction(String transactionId);
  Future<List<Map<String, dynamic>>> syncIncomingTransactions();
}

abstract class AiProviderInterface {
  Future<String> chat(String prompt, {List<Map<String, dynamic>>? history});
  Future<List<double>> generateEmbedding(String text);
  Future<String> summarize(String content);
  Future<Map<String, dynamic>> structuredOutput(
    String prompt,
    Map<String, dynamic> schema,
  );
}

abstract class PaymentGatewayInterface {
  Future<Map<String, dynamic>> initiatePayment(
    double amount,
    String currency,
    String description,
  );
  Future<bool> validatePayment(String paymentId);
  Future<Map<String, dynamic>> confirmPayment(String paymentId);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class IntegrationService {
  static IntegrationService? _instance;
  static IntegrationService get instance =>
      _instance ??= IntegrationService._();
  IntegrationService._();

  SupabaseClient get _client => SupabaseService.client;

  // ── CONNECTOR ENGINE ──────────────────────────────────────────────────────

  Future<List<IntegrationConnector>> getIntegrations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _demoIntegrations();

      final res = await _client
          .from('integrations')
          .select()
          .eq('organization_id', userId)
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((e) => IntegrationConnector.fromMap(e))
          .toList();
      return list.isEmpty ? _demoIntegrations() : list;
    } catch (_) {
      return _demoIntegrations();
    }
  }

  Future<IntegrationConnector?> createIntegration({
    required String providerName,
    required String providerType,
    Map<String, dynamic>? configuration,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final res = await _client
          .from('integrations')
          .insert({
            'organization_id': userId,
            'provider_name': providerName,
            'provider_type': providerType,
            'status': 'inactive',
            'configuration': configuration ?? {},
          })
          .select()
          .single();

      final connector = IntegrationConnector.fromMap(res);
      EventBus.instance.publish(
        CnaEvent(
          eventType: EventBus.integrationConnected,
          entityType: 'integration',
          entityId: connector.id,
          payload: {'provider': providerName, 'type': providerType},
        ),
      );
      return connector;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateIntegrationStatus(String id, String status) async {
    try {
      await _client
          .from('integrations')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteIntegration(String id) async {
    try {
      await _client.from('integrations').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── API KEY MANAGER ───────────────────────────────────────────────────────

  Future<List<ApiKeyEntry>> getApiKeys() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _demoApiKeys();

      final res = await _client
          .from('api_keys')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (res as List).map((e) => ApiKeyEntry.fromMap(e)).toList();
      return list.isEmpty ? _demoApiKeys() : list;
    } catch (_) {
      return _demoApiKeys();
    }
  }

  Future<bool> addApiKey({
    required String providerName,
    required String keyReference,
    required String keyLabel,
    DateTime? expiresAt,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('api_keys').insert({
        'user_id': userId,
        'provider_name': providerName,
        'key_reference': 'enc:${keyReference.hashCode}',
        'key_label': keyLabel,
        'expires_at': expiresAt?.toIso8601String(),
        'is_active': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> revokeApiKey(String id) async {
    try {
      await _client.from('api_keys').update({'is_active': false}).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── INTEGRATION LOGS ──────────────────────────────────────────────────────

  Future<List<IntegrationLog>> getIntegrationLogs({int limit = 50}) async {
    try {
      final res = await _client
          .from('integration_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final list = (res as List).map((e) => IntegrationLog.fromMap(e)).toList();
      return list.isEmpty ? _demoLogs() : list;
    } catch (_) {
      return _demoLogs();
    }
  }

  Future<void> logIntegrationRequest({
    required String integrationId,
    required String requestType,
    required String status,
    required int durationMs,
    required int responseCode,
    String? errorMessage,
  }) async {
    try {
      await _client.from('integration_logs').insert({
        'integration_id': integrationId,
        'request_type': requestType,
        'status': status,
        'duration_ms': durationMs,
        'response_code': responseCode,
        'error_message': errorMessage,
      });
    } catch (_) {}
  }

  // ── WEBHOOK ENGINE ────────────────────────────────────────────────────────

  Future<List<WebhookEvent>> getWebhookEvents({bool? processed}) async {
    try {
      var query = _client
          .from('webhook_events')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final res = await query;
      final all = (res as List).map((e) => WebhookEvent.fromMap(e)).toList();
      final filtered = processed == null
          ? all
          : all.where((e) => e.processed == processed).toList();
      return filtered.isEmpty ? _demoWebhookEvents() : filtered;
    } catch (_) {
      return _demoWebhookEvents();
    }
  }

  Future<bool> processWebhookEvent(String id) async {
    try {
      await _client
          .from('webhook_events')
          .update({
            'processed': true,
            'processed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      EventBus.instance.publish(
        CnaEvent(
          eventType: EventBus.webhookReceived,
          entityType: 'webhook_event',
          entityId: id,
          payload: {'processed': true},
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> receiveWebhook({
    required String providerName,
    required String eventName,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _client.from('webhook_events').insert({
        'provider_name': providerName,
        'event_name': eventName,
        'payload': payload,
        'processed': false,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── IMPORT ENGINE ─────────────────────────────────────────────────────────

  Future<List<ImportExportJob>> getImportExportJobs() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _demoJobs();

      final res = await _client
          .from('import_export_jobs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((e) => ImportExportJob.fromMap(e))
          .toList();
      return list.isEmpty ? _demoJobs() : list;
    } catch (_) {
      return _demoJobs();
    }
  }

  Future<Map<String, dynamic>> previewImport({
    required String fileName,
    required String fileFormat,
    required List<Map<String, dynamic>> sampleRows,
  }) async {
    final columns = sampleRows.isNotEmpty ? sampleRows.first.keys.toList() : [];
    final issues = <String>[];

    // Validate required columns for transaction import
    if (fileName.toLowerCase().contains('transaction')) {
      final required = ['date', 'amount', 'description'];
      for (final col in required) {
        if (!columns.any((c) => c.toString().toLowerCase().contains(col))) {
          issues.add('Missing recommended column: $col');
        }
      }
    }

    return {
      'total_rows': sampleRows.length,
      'columns': columns,
      'sample': sampleRows.take(5).toList(),
      'validation_issues': issues,
      'can_import': issues.isEmpty,
    };
  }

  Future<ImportExportJob?> startImportJob({
    required String fileName,
    required String fileFormat,
    required int recordCount,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final res = await _client
          .from('import_export_jobs')
          .insert({
            'user_id': userId,
            'job_type': 'import',
            'status': 'processing',
            'file_name': fileName,
            'file_format': fileFormat,
            'record_count': recordCount,
          })
          .select()
          .single();

      EventBus.instance.publish(
        CnaEvent(
          eventType: EventBus.importCompleted,
          entityType: 'import_job',
          entityId: res['id'],
          payload: {'file': fileName, 'records': recordCount},
        ),
      );

      return ImportExportJob.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  // ── EXPORT ENGINE ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateExport({
    required String exportType,
    required String fileFormat,
    required String title,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {'status': 'error', 'message': 'Not authenticated'};
      }

      // Create export job record
      await _client.from('import_export_jobs').insert({
        'user_id': userId,
        'job_type': 'export',
        'status': 'completed',
        'file_name':
            '${exportType}_${DateTime.now().millisecondsSinceEpoch}.$fileFormat',
        'file_format': fileFormat,
        'record_count': 1,
        'completed_at': DateTime.now().toIso8601String(),
      });

      EventBus.instance.publish(
        CnaEvent(
          eventType: EventBus.exportCompleted,
          entityType: 'export_job',
          entityId: null,
          payload: {'type': exportType, 'format': fileFormat},
        ),
      );

      return {
        'status': 'success',
        'file_name': '$title.$fileFormat',
        'export_type': exportType,
        'format': fileFormat,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (_) {
      return {'status': 'error', 'message': 'Export failed'};
    }
  }

  // ── PROVIDER STATUS ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProviderStatus() async {
    final integrations = await getIntegrations();
    return integrations.map((i) {
      final lastSync = i.configuration['last_sync'];
      return {
        'provider': i.providerName,
        'type': i.providerType,
        'status': i.status,
        'last_sync': lastSync,
        'icon': i.typeIcon,
        'id': i.id,
      };
    }).toList();
  }

  // ── MARKETPLACE CATALOG ───────────────────────────────────────────────────

  List<Map<String, dynamic>> getMarketplaceCatalog() {
    return [
      {
        'name': 'Banking Integration',
        'type': 'banking',
        'description':
            'Sync bank accounts, import transactions, check balances',
        'icon': 'account_balance',
        'color': 0xFF1A5F7A,
        'providers': ['CRDB Bank', 'NMB Bank', 'Stanbic', 'Equity Bank'],
        'status': 'available',
      },
      {
        'name': 'Mobile Money',
        'type': 'mobile_money',
        'description': 'Connect M-Pesa, Airtel Money, Tigo Pesa, HaloPesa',
        'icon': 'phone_android',
        'color': 0xFF10B981,
        'providers': [
          'M-Pesa',
          'Airtel Money',
          'Tigo Pesa',
          'HaloPesa',
          'Mixx by Yas',
        ],
        'status': 'available',
      },
      {
        'name': 'AI Provider',
        'type': 'ai_provider',
        'description': 'Connect OpenAI, Gemini, Anthropic or local LLMs',
        'icon': 'psychology',
        'color': 0xFF8B5CF6,
        'providers': ['OpenAI GPT-4', 'Google Gemini', 'Anthropic Claude'],
        'status': 'available',
      },
      {
        'name': 'Payment Gateway',
        'type': 'payment',
        'description': 'Accept card payments, bank transfers, QR payments',
        'icon': 'payment',
        'color': 0xFFF59E0B,
        'providers': ['Stripe', 'Flutterwave', 'Pesapal', 'DPO Group'],
        'status': 'available',
      },
      {
        'name': 'Accounting Software',
        'type': 'accounting',
        'description': 'Sync with QuickBooks, Xero, Sage, or Tally',
        'icon': 'calculate',
        'color': 0xFF059669,
        'providers': ['QuickBooks', 'Xero', 'Sage', 'Tally'],
        'status': 'coming_soon',
      },
      {
        'name': 'ERP System',
        'type': 'erp',
        'description': 'Connect SAP, Oracle, Microsoft Dynamics',
        'icon': 'business',
        'color': 0xFF2D9CDB,
        'providers': ['SAP', 'Oracle ERP', 'Microsoft Dynamics'],
        'status': 'coming_soon',
      },
      {
        'name': 'HR System',
        'type': 'hr',
        'description': 'Sync employee data, payroll, attendance',
        'icon': 'people',
        'color': 0xFFEF4444,
        'providers': ['BambooHR', 'Workday', 'ADP'],
        'status': 'coming_soon',
      },
      {
        'name': 'POS System',
        'type': 'pos',
        'description': 'Connect point-of-sale systems for real-time sales data',
        'icon': 'point_of_sale',
        'color': 0xFF6366F1,
        'providers': ['Square', 'Lightspeed', 'Toast'],
        'status': 'coming_soon',
      },
    ];
  }

  // ── DEMO DATA FALLBACKS ───────────────────────────────────────────────────

  List<IntegrationConnector> _demoIntegrations() => [
    IntegrationConnector(
      id: 'demo-bank-1',
      providerName: 'Sample Bank',
      providerType: 'banking',
      status: 'connected',
      configuration: {
        'last_sync': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    IntegrationConnector(
      id: 'demo-mm-1',
      providerName: 'Sample Mobile Money',
      providerType: 'mobile_money',
      status: 'connected',
      configuration: {
        'provider': 'M-Pesa',
        'last_sync': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      },
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    IntegrationConnector(
      id: 'demo-ai-1',
      providerName: 'OpenAI',
      providerType: 'ai_provider',
      status: 'configured',
      configuration: {'model': 'gpt-4o'},
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    IntegrationConnector(
      id: 'demo-pay-1',
      providerName: 'Payment Gateway',
      providerType: 'payment',
      status: 'inactive',
      configuration: {},
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  List<ApiKeyEntry> _demoApiKeys() => [
    ApiKeyEntry(
      id: 'demo-key-1',
      providerName: 'OpenAI',
      keyReference: 'enc:openai_key_ref_001',
      keyLabel: 'OpenAI Production Key',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    ApiKeyEntry(
      id: 'demo-key-2',
      providerName: 'Sample Bank',
      keyReference: 'enc:bank_api_ref_002',
      keyLabel: 'Bank API Key',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ApiKeyEntry(
      id: 'demo-key-3',
      providerName: 'Sample Mobile Money',
      keyReference: 'enc:mm_api_ref_003',
      keyLabel: 'M-Pesa API Key',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
  ];

  List<IntegrationLog> _demoLogs() => [
    IntegrationLog(
      id: 'log-1',
      integrationId: 'demo-bank-1',
      requestType: 'account_sync',
      status: 'success',
      durationMs: 342,
      responseCode: 200,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    IntegrationLog(
      id: 'log-2',
      integrationId: 'demo-bank-1',
      requestType: 'transaction_import',
      status: 'success',
      durationMs: 1205,
      responseCode: 200,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    IntegrationLog(
      id: 'log-3',
      integrationId: 'demo-mm-1',
      requestType: 'balance_check',
      status: 'success',
      durationMs: 189,
      responseCode: 200,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    IntegrationLog(
      id: 'log-4',
      integrationId: 'demo-ai-1',
      requestType: 'chat_completion',
      status: 'success',
      durationMs: 2100,
      responseCode: 200,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    IntegrationLog(
      id: 'log-5',
      integrationId: 'demo-bank-1',
      requestType: 'account_sync',
      status: 'error',
      durationMs: 5000,
      responseCode: 503,
      errorMessage: 'Service temporarily unavailable',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  List<WebhookEvent> _demoWebhookEvents() => [
    WebhookEvent(
      id: 'wh-1',
      providerName: 'Sample Mobile Money',
      eventName: 'payment.received',
      payload: {'amount': 500000, 'currency': 'TZS', 'sender': '+255711111111'},
      processed: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    WebhookEvent(
      id: 'wh-2',
      providerName: 'Sample Bank',
      eventName: 'transaction.created',
      payload: {'amount': 2000000, 'type': 'credit', 'description': 'Salary'},
      processed: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    WebhookEvent(
      id: 'wh-3',
      providerName: 'Payment Gateway',
      eventName: 'payment.confirmed',
      payload: {'order_id': 'ORD-001', 'amount': 150000, 'status': 'confirmed'},
      processed: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  List<ImportExportJob> _demoJobs() => [
    ImportExportJob(
      id: 'job-1',
      jobType: 'import',
      status: 'completed',
      fileName: 'transactions_q1_2025.csv',
      fileFormat: 'csv',
      recordCount: 245,
      errorCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      completedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ImportExportJob(
      id: 'job-2',
      jobType: 'export',
      status: 'completed',
      fileName: 'executive_financial_report.json',
      fileFormat: 'json',
      recordCount: 1,
      errorCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      completedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ImportExportJob(
      id: 'job-3',
      jobType: 'import',
      status: 'completed',
      fileName: 'assets_inventory.xlsx',
      fileFormat: 'excel',
      recordCount: 18,
      errorCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      completedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ImportExportJob(
      id: 'job-4',
      jobType: 'export',
      status: 'pending',
      fileName: 'full_analytics_export.csv',
      fileFormat: 'csv',
      recordCount: 0,
      errorCount: 0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];
}