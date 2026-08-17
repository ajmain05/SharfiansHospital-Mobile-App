import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/push_notification_service.dart';

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
    );
  }
}
