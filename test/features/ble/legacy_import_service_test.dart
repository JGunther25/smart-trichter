import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_trichter/features/ble/legacy_import_service.dart';
import 'package:smart_trichter/services/firestore_service.dart';

void main() {
  group('legacy import', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('readLegacyRecords returns empty list when nothing stored', () async {
      expect(await readLegacyRecords(), isEmpty);
    });

    test('readLegacyRecords parses the stored JSON list', () async {
      SharedPreferences.setMockInitialValues({
        'chug_records': jsonEncode([
          {
            'id': 'abc',
            'funnelId': 'funnel-1',
            'name': 'Alice',
            'liquid': 'Beer',
            'quantityMl': 500,
            'durationMs': 3210,
            'loggedAt': '2024-06-01T12:00:00.000Z',
          },
        ]),
      });

      final records = await readLegacyRecords();

      expect(records, hasLength(1));
      expect(records.first.name, 'Alice');
      expect(records.first.durationMs, 3210);
    });

    test('importLegacyRecords writes to Firestore and clears local storage',
        () async {
      SharedPreferences.setMockInitialValues({
        'chug_records': jsonEncode([
          {
            'id': 'abc',
            'funnelId': 'funnel-1',
            'name': 'Alice',
            'liquid': 'Beer',
            'quantityMl': 500,
            'durationMs': 3210,
            'loggedAt': '2024-06-01T12:00:00.000Z',
          },
        ]),
      });
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FirestoreService(db: fakeFirestore);

      final records = await readLegacyRecords();
      await importLegacyRecords(service, records);

      final imported = await service.watchAllLeaderboard().first;
      expect(imported, hasLength(1));
      expect(imported.first.name, 'Alice');
      expect(
        imported.first.loggedAt.isAtSameMomentAs(
          DateTime.parse('2024-06-01T12:00:00.000Z'),
        ),
        isTrue,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chug_records'), isNull);
    });
  });
}
