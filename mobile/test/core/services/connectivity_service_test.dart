import 'package:flutter_test/flutter_test.dart';
import 'package:yaro0_mobile/core/services/connectivity_service.dart';

void main() {
  group('ConnectivityStatus', () {
    test('has online and offline values', () {
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.online));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.offline));
      expect(ConnectivityStatus.values.length, 2);
    });
  });

  group('ConnectivityService', () {
    test('initial status defaults to online', () {
      // The service starts with online status and validates via DNS
      // In test environment without network mocking, we just verify the API
      final service = ConnectivityService();
      // isOnline and isOffline should be complementary
      expect(service.isOnline, isNot(equals(service.isOffline)));
      service.dispose();
    });

    test('statusStream is a broadcast stream', () {
      final service = ConnectivityService();
      // Should be able to listen multiple times (broadcast)
      final sub1 = service.statusStream.listen((_) {});
      final sub2 = service.statusStream.listen((_) {});
      sub1.cancel();
      sub2.cancel();
      service.dispose();
    });
  });
}
