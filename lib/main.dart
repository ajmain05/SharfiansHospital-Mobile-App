import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/l10n/bundled_translations.dart';
import 'core/storage/local_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/push_notification_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  await BundledTranslations.load();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService().init();
  } catch (e) {
    debugPrint('Firebase initialization failed. Please run flutterfire configure: $e');
  }

  runApp(const ProviderScope(child: SharfianApp()));
}
