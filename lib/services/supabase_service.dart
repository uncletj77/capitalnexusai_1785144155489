import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  // Real Supabase project credentials
  // defaultValue is the actual project URL/key — used when env var is missing or contains placeholder
  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _envKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Resolved URL: use env var only if it looks like a real Supabase URL
  static String get supabaseUrl {
    if (_envUrl.isNotEmpty &&
        _envUrl.contains('supabase.co') &&
        !_envUrl.contains('dummy')) {
      return _envUrl;
    }
    return 'https://fcctcgkmfcsxfoadesuj.supabase.co';
  }

  // Resolved key: use env var only if it looks like a real JWT (starts with eyJ)
  static String get supabaseAnonKey {
    if (_envKey.isNotEmpty &&
        _envKey.startsWith('eyJ') &&
        !_envKey.contains('dummy')) {
      return _envKey;
    }
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZjY3RjZ2ttZmNzeGZvYWRlc3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5OTk3MzMsImV4cCI6MjEwMDU3NTczM30.bpEL0z6vcKgP4rRPIe0sTd5XWLxm8eZmOAY93FH6tLo';
  }

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    final url = supabaseUrl;
    final key = supabaseAnonKey;

    if (url.isEmpty || key.isEmpty) {
      debugPrint(
        '[SupabaseService] ERROR: SUPABASE_URL or SUPABASE_ANON_KEY is empty.',
      );
      return;
    }

    try {
      await Supabase.initialize(url: url, anonKey: key);
      _initialized = true;
      debugPrint('[SupabaseService] Initialized successfully with: $url');
    } catch (e) {
      debugPrint('[SupabaseService] Initialization failed: $e');
    }
  }

  // Get Supabase client — safe accessor
  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'SupabaseService is not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return Supabase.instance.client;
  }

  // Instance accessor (kept for backward compatibility)
  SupabaseClient get instanceClient => Supabase.instance.client;
}
