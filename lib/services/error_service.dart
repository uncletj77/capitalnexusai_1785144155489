import 'package:flutter/material.dart';

/// Centralized error handling framework for CNA.
/// All modules should use this service for consistent error management.
class ErrorService {
  static ErrorService? _instance;
  static ErrorService get instance => _instance ??= ErrorService._();
  ErrorService._();

  final List<CnaError> _errorLog = [];
  final List<void Function(CnaError)> _listeners = [];

  /// Subscribe to error events
  void addListener(void Function(CnaError) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(CnaError) listener) {
    _listeners.remove(listener);
  }

  /// Log and broadcast an error
  CnaError handle(
    dynamic error, {
    String? module,
    String? operation,
    StackTrace? stackTrace,
    bool silent = false,
  }) {
    final cnaError = CnaError(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: _extractMessage(error),
      module: module ?? 'unknown',
      operation: operation,
      originalError: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _errorLog.add(cnaError);
    if (_errorLog.length > 200) _errorLog.removeAt(0);

    if (!silent) {
      debugPrint('[CNA Error] [${cnaError.module}] ${cnaError.message}');
      for (final listener in _listeners) {
        listener(cnaError);
      }
    }

    return cnaError;
  }

  /// Get user-friendly message for display
  String userMessage(dynamic error) {
    final msg = _extractMessage(error).toLowerCase();
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (msg.contains('permission') ||
        msg.contains('unauthorized') ||
        msg.contains('403')) {
      return 'You do not have permission to perform this action.';
    }
    if (msg.contains('not found') || msg.contains('404')) {
      return 'The requested resource was not found.';
    }
    if (msg.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (msg.contains('duplicate') || msg.contains('unique')) {
      return 'This record already exists.';
    }
    return 'Something went wrong. Please try again.';
  }

  List<CnaError> get recentErrors =>
      List.unmodifiable(_errorLog.reversed.take(50).toList());

  void clearLog() => _errorLog.clear();

  String _extractMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    if (error is String) return error;
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}

class CnaError {
  final String id;
  final String message;
  final String module;
  final String? operation;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  const CnaError({
    required this.id,
    required this.message,
    required this.module,
    this.operation,
    this.originalError,
    this.stackTrace,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'message': message,
    'module': module,
    'operation': operation,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Mixin for easy error handling in services
mixin CnaErrorHandler {
  String get serviceName;

  CnaError handleError(
    dynamic error, {
    String? operation,
    StackTrace? stackTrace,
  }) {
    return ErrorService.instance.handle(
      error,
      module: serviceName,
      operation: operation,
      stackTrace: stackTrace,
    );
  }

  String userMessage(dynamic error) => ErrorService.instance.userMessage(error);
}
