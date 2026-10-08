import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import '../shared/providers/theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use ref.read instead of ref.watch to prevent router recreation
    // The router's refreshListenable handles auth state changes via redirects
    final router = ref.read(routerProvider);

    // Set system UI overlay style to ensure content doesn't overlap with system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    return MaterialApp.router(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeProvider),
      routerConfig: router,
      builder: (context, child) {
        // Respect user text scaling while capping extreme values to keep layouts stable
        // Also ensure proper handling of system UI overlays
        final mediaQueryData = MediaQuery.of(context);
        
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: mediaQueryData.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          // SafeArea wrapper to ensure content doesn't go under system UI
          child: child!,
        );
      },
    );
  }
}
