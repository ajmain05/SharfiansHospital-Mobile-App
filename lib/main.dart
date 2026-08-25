import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/l10n/bundled_translations.dart';
import 'core/storage/local_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed. Please run flutterfire configure: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // These three are independent of each other — running them concurrently
  // instead of one-by-one shortens the gap before the first Flutter frame
  // paints, since the native launch screen stays up the whole time.
  await Future.wait([
    LocalStorage.init(),
    BundledTranslations.load(),
    _initFirebase(),
  ]);

  runApp(const ProviderScope(child: SharfianApp()));
}
