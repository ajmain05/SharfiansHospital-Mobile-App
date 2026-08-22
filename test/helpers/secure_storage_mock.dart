import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fakes the flutter_secure_storage platform channel with an in-memory map,
/// so tests can exercise real read/write/delete calls without a real
/// keychain/keystore. Call this once per test (or in setUp) before any code
/// touches FlutterSecureStorage.
void mockSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    switch (call.method) {
      case 'read':
        return store[call.arguments['key']];
      case 'write':
        store[call.arguments['key']] = call.arguments['value'];
        return null;
      case 'delete':
        store.remove(call.arguments['key']);
        return null;
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return store.containsKey(call.arguments['key']);
      case 'readAll':
        return store;
      default:
        return null;
    }
  });
}
