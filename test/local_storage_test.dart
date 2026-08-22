import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sharfian_app/core/storage/local_storage.dart';

import 'helpers/secure_storage_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(mockSecureStorage);

  test('LocalStorage.init migrates a legacy admin token into secure storage and removes the plaintext copy', () async {
    SharedPreferences.setMockInitialValues({
      'sharfians_admin_token': 'legacy-token-123',
    });
    final prefs = await SharedPreferences.getInstance();

    await LocalStorage.init();

    expect(LocalStorage.getAdminToken(), 'legacy-token-123');
    expect(prefs.getString('sharfians_admin_token'), isNull);
  });

  test('LocalStorage save/get/clear round-trip for admin token', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();

    await LocalStorage.saveAdminToken('fresh-token-456');
    expect(LocalStorage.getAdminToken(), 'fresh-token-456');

    await LocalStorage.clearAdminSession();
    expect(LocalStorage.getAdminToken(), isNull);
  });

  test('LocalStorage save/get/clear round-trip for investor accounts + phone', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();

    await LocalStorage.saveInvestorAccounts([
      {'name': 'Test Investor', 'investor_id': 'SH-1'},
    ]);
    await LocalStorage.saveInvestorPhone('01700000000');

    expect(LocalStorage.getInvestorAccounts()!.first['name'], 'Test Investor');
    expect(LocalStorage.getInvestorPhone(), '01700000000');

    await LocalStorage.clearInvestorSession();
    expect(LocalStorage.getInvestorAccounts(), isNull);
    expect(LocalStorage.getInvestorPhone(), isNull);
  });
}
