import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/push_notification_service.dart';

// See app_router.dart's dialogNavigatorKey doc comment: this Navigator wraps
// GoRouter's entire output as a single page, so anything shown on it (e.g.
// the app-update dialog) is completely unaffected by GoRouter's own route
// transitions.
Route<dynamic> _dialogHostRoute(RouteSettings settings, Widget child) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}

class SharfianApp extends ConsumerStatefulWidget {
  const SharfianApp({super.key});

  @override
  ConsumerState<SharfianApp> createState() => _SharfianAppState();
}

class _SharfianAppState extends ConsumerState<SharfianApp> {
  @override
  void initState() {
    super.initState();
    // Initialize push notifications after the widget is mounted so permission dialogs don't block main()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Sharfians Hospital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) => Navigator(
        key: dialogNavigatorKey,
        onGenerateRoute: (settings) => _dialogHostRoute(settings, child!),
      ),
    );
  }
}
