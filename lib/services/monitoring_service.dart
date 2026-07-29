import 'package:flutter/foundation.dart';

/// Centralized monitoring service for CNA.
/// Tracks API performance, AI usage, security events, background jobs, and integration failures.
class MonitoringService {
  static MonitoringService? _instance;
  static MonitoringService get instance => _instance ??= MonitoringService._();
  MonitoringService._();

  final List<MonitoringEvent> _events = [];
  final Map<String, _ApiMetric> _apiMetrics = {};
  final Map<String, int> _moduleUsage = {};
  int _aiRequestCount = 0;
  int _failedLoginCount = 0;
  int _integrationFailures = 0;

  // ─── Event Tracking ───────────────────────────────────────────────────────

  void trackEvent(
    MonitoringEventType type,
    String module, {
    String? description,
    Map<String, dynamic>? metadata,
    MonitoringSeverity severity = MonitoringSeverity.info,
  }) {
    final event = MonitoringEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      module: module,
      description: description,
      metadata: metadata,
      severity: severity,
      timestamp: DateTime.now(),
    );

    _events.add(event);
    if (_events.length > 500) _events.removeAt(0);

    _moduleUsage[module] = (_moduleUsage[module] ?? 0) + 1;

    if (type == MonitoringEventType.aiRequest) _aiRequestCount++;
    if (type == MonitoringEventType.failedLogin) _failedLoginCount++;
    if (type == MonitoringEventType.integrationFailure) _integrationFailures++;

    if (severity == MonitoringSeverity.critical ||
        severity == MonitoringSeverity.error) {
      debugPrint(
        '[CNA Monitor] [$module] ${severity.name.toUpperCase()}: $description',
      );
    }
  }

  // ─── API Performance ──────────────────────────────────────────────────────

  void trackApiCall(String endpoint, int durationMs, int statusCode) {
    final metric = _apiMetrics[endpoint] ?? _ApiMetric(endpoint: endpoint);
    metric.totalCalls++;
    metric.totalDurationMs += durationMs;
    if (statusCode >= 400) metric.errorCount++;
    metric.lastCalledAt = DateTime.now();
    _apiMetrics[endpoint] = metric;
  }

  // ─── Security Events ──────────────────────────────────────────────────────

  void trackSecurityEvent(String event, {String? userId, String? ipAddress}) {
    trackEvent(
      MonitoringEventType.securityEvent,
      'security',
      description: event,
      metadata: {'userId': userId, 'ipAddress': ipAddress},
      severity: MonitoringSeverity.warning,
    );
  }

  void trackFailedLogin(String? email) {
    _failedLoginCount++;
    trackEvent(
      MonitoringEventType.failedLogin,
      'auth',
      description: 'Failed login attempt',
      metadata: {'email': email},
      severity: MonitoringSeverity.warning,
    );
  }

  // ─── System Health ────────────────────────────────────────────────────────

  SystemHealthReport getHealthReport() {
    final apiMetricsList = _apiMetrics.values.toList();
    final avgResponseMs = apiMetricsList.isEmpty
        ? 0
        : apiMetricsList.fold(
                0,
                (sum, m) =>
                    sum +
                    (m.totalCalls > 0 ? m.totalDurationMs ~/ m.totalCalls : 0),
              ) ~/
              apiMetricsList.length;

    final errorRate = apiMetricsList.isEmpty
        ? 0.0
        : apiMetricsList.fold(0, (sum, m) => sum + m.errorCount) /
              apiMetricsList.fold(1, (sum, m) => sum + m.totalCalls);

    int score = 100;
    if (avgResponseMs > 2000) {
      score -= 20;
    } else if (avgResponseMs > 1000)
      score -= 10;
    if (errorRate > 0.1) {
      score -= 30;
    } else if (errorRate > 0.05)
      score -= 15;
    if (_failedLoginCount > 10) score -= 20;
    if (_integrationFailures > 5) score -= 10;

    return SystemHealthReport(
      score: score.clamp(0, 100),
      avgApiResponseMs: avgResponseMs,
      apiErrorRate: errorRate,
      totalApiCalls: apiMetricsList.fold(0, (sum, m) => sum + m.totalCalls),
      aiRequestCount: _aiRequestCount,
      failedLoginCount: _failedLoginCount,
      integrationFailures: _integrationFailures,
      activeModules: _moduleUsage.keys.toList(),
      recentEvents: _events.reversed.take(20).toList(),
      generatedAt: DateTime.now(),
    );
  }

  List<MonitoringEvent> getEventsByType(MonitoringEventType type) =>
      _events.where((e) => e.type == type).toList();

  List<MonitoringEvent> getEventsByModule(String module) =>
      _events.where((e) => e.module == module).toList();

  List<MonitoringEvent> getCriticalEvents() => _events
      .where(
        (e) =>
            e.severity == MonitoringSeverity.critical ||
            e.severity == MonitoringSeverity.error,
      )
      .toList();

  Map<String, int> get moduleUsage => Map.unmodifiable(_moduleUsage);

  void reset() {
    _events.clear();
    _apiMetrics.clear();
    _moduleUsage.clear();
    _aiRequestCount = 0;
    _failedLoginCount = 0;
    _integrationFailures = 0;
  }
}

class _ApiMetric {
  final String endpoint;
  int totalCalls = 0;
  int totalDurationMs = 0;
  int errorCount = 0;
  DateTime? lastCalledAt;

  _ApiMetric({required this.endpoint});
}

enum MonitoringEventType {
  apiCall,
  aiRequest,
  failedLogin,
  securityEvent,
  integrationFailure,
  workflowExecution,
  backgroundJob,
  dataExport,
  permissionEscalation,
  systemError,
  userAction,
}

enum MonitoringSeverity { info, warning, error, critical }

class MonitoringEvent {
  final String id;
  final MonitoringEventType type;
  final String module;
  final String? description;
  final Map<String, dynamic>? metadata;
  final MonitoringSeverity severity;
  final DateTime timestamp;

  const MonitoringEvent({
    required this.id,
    required this.type,
    required this.module,
    this.description,
    this.metadata,
    required this.severity,
    required this.timestamp,
  });
}

class SystemHealthReport {
  final int score;
  final int avgApiResponseMs;
  final double apiErrorRate;
  final int totalApiCalls;
  final int aiRequestCount;
  final int failedLoginCount;
  final int integrationFailures;
  final List<String> activeModules;
  final List<MonitoringEvent> recentEvents;
  final DateTime generatedAt;

  const SystemHealthReport({
    required this.score,
    required this.avgApiResponseMs,
    required this.apiErrorRate,
    required this.totalApiCalls,
    required this.aiRequestCount,
    required this.failedLoginCount,
    required this.integrationFailures,
    required this.activeModules,
    required this.recentEvents,
    required this.generatedAt,
  });

  String get healthLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Attention';
  }
}
