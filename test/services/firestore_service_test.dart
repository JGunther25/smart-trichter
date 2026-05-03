import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trichter/models/chug_record.dart';
import 'package:smart_trichter/services/firestore_service.dart';

ChugRecord _record({
  String funnelId = 'funnel-1',
  String liquid = 'Beer',
  int quantityMl = 500,
  int durationMs = 3000,
  String name = 'Alice',
}) =>
    ChugRecord(
      funnelId: funnelId,
      name: name,
      liquid: liquid,
      quantityMl: quantityMl,
      durationMs: durationMs,
      loggedAt: DateTime.now(),
    );

void main() {
  group('FirestoreService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = FirestoreService(db: fakeFirestore);
    });

    test('saveChug then watchLeaderboard returns the saved record', () async {
      final record = _record(durationMs: 4200);
      await service.saveChug(record);

      final results =
          await service.watchLeaderboard(funnelId: 'funnel-1').first;

      expect(results, hasLength(1));
      expect(results.first.durationMs, 4200);
      expect(results.first.name, 'Alice');
      expect(results.first.funnelId, 'funnel-1');
    });

    test('watchLeaderboard orders by durationMs ascending', () async {
      await service.saveChug(_record(durationMs: 9000));
      await service.saveChug(_record(durationMs: 1000));
      await service.saveChug(_record(durationMs: 5000));

      final results =
          await service.watchLeaderboard(funnelId: 'funnel-1').first;

      expect(results.map((r) => r.durationMs).toList(), [1000, 5000, 9000]);
    });

    test('liquid filter returns only matching records', () async {
      await service.saveChug(_record(liquid: 'Beer'));
      await service.saveChug(_record(liquid: 'Wine'));

      final results = await service
          .watchLeaderboard(funnelId: 'funnel-1', liquid: 'Beer')
          .first;

      expect(results, hasLength(1));
      expect(results.first.liquid, 'Beer');
    });

    test('quantityMl filter returns only matching records', () async {
      await service.saveChug(_record(quantityMl: 500));
      await service.saveChug(_record(quantityMl: 330));

      final results = await service
          .watchLeaderboard(funnelId: 'funnel-1', quantityMl: 500)
          .first;

      expect(results, hasLength(1));
      expect(results.first.quantityMl, 500);
    });

    test('watchAllLeaderboard returns records from all funnels', () async {
      await service.saveChug(_record(funnelId: 'funnel-1'));
      await service.saveChug(_record(funnelId: 'funnel-2'));

      final results = await service.watchAllLeaderboard().first;

      expect(results, hasLength(2));
    });

    test('watchAllLeaderboard liquid filter works across funnels', () async {
      await service.saveChug(_record(funnelId: 'funnel-1', liquid: 'Beer'));
      await service.saveChug(_record(funnelId: 'funnel-2', liquid: 'Wine'));

      final results = await service.watchAllLeaderboard(liquid: 'Wine').first;

      expect(results, hasLength(1));
      expect(results.first.liquid, 'Wine');
    });
  });
}
