import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import './providers/language_provider.dart';
import './providers/theme_provider.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set GoRouter option before runApp
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // Enable clean path-based URLs on Flutter Web (removes the /#/ hash prefix)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize Supabase
  await SupabaseService.initialize();

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - only on mobile, not web
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final LanguageProvider _languageProvider = LanguageProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onProviderChange);
    _languageProvider.addListener(_onProviderChange);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onProviderChange);
    _languageProvider.removeListener(_onProviderChange);
    _themeProvider.dispose();
    _languageProvider.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return ThemeProviderInheritedWidget(
          themeProvider: _themeProvider,
          languageProvider: _languageProvider,
          child: MaterialApp.router(
            title: 'Capital Nexus AI',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeProvider.themeMode,
            locale: _languageProvider.locale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('sw', 'TZ'),
              Locale('fr', 'FR'),
              Locale('ar', 'SA'),
            ],
            // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.0)),
                child: child!,
              );
            },
            // 🚨 END CRITICAL SECTION
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
          ),
        );
      },
    );
  }
}

/// InheritedWidget to provide ThemeProvider and LanguageProvider down the tree
class ThemeProviderInheritedWidget extends InheritedWidget {
  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;

  const ThemeProviderInheritedWidget({
    super.key,
    required this.themeProvider,
    required this.languageProvider,
    required super.child,
  });

  static ThemeProviderInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeProviderInheritedWidget>();
  }

  @override
  bool updateShouldNotify(ThemeProviderInheritedWidget oldWidget) {
    return themeProvider.themeMode != oldWidget.themeProvider.themeMode ||
        languageProvider.language != oldWidget.languageProvider.language;
  }
}
