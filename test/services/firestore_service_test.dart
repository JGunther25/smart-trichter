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
  DateTime? loggedAt,
}) =>
    ChugRecord(
      funnelId: funnelId,
      name: name,
      liquid: liquid,
      quantityMl: quantityMl,
      durationMs: durationMs,
      loggedAt: loggedAt ?? DateTime.now(),
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

    test('saved record gets an id assigned', () async {
      await service.saveChug(_record());

      final results =
          await service.watchLeaderboard(funnelId: 'funnel-1').first;

      expect(results.first.id, isNotNull);
      expect(results.first.id, isNotEmpty);
    });

    test('saveAll writes every record in one batch', () async {
      await service.saveAll([
        _record(name: 'A', durationMs: 1000),
        _record(name: 'B', durationMs: 2000),
      ]);

      final results = await service.watchAllLeaderboard().first;

      expect(results, hasLength(2));
      expect(results.map((r) => r.name).toSet(), {'A', 'B'});
    });

    test('saveAll with preserveLoggedAt keeps original timestamps', () async {
      final loggedAt = DateTime(2024, 1, 1, 10, 30);
      await service.saveAll(
        [_record(loggedAt: loggedAt)],
        preserveLoggedAt: true,
      );

      final results = await service.watchAllLeaderboard().first;

      expect(results.first.loggedAt, loggedAt);
    });

    test('updateChug overwrites the editable fields', () async {
      await service.saveChug(_record(name: 'Alice', durationMs: 4000));
      final saved = await service.watchAllLeaderboard().first;

      await service.updateChug(
        ChugRecord(
          id: saved.first.id,
          funnelId: saved.first.funnelId,
          name: 'Alice Updated',
          liquid: 'Wine',
          quantityMl: 250,
          durationMs: 2500,
          loggedAt: saved.first.loggedAt,
        ),
      );

      final results = await service.watchAllLeaderboard().first;
      expect(results, hasLength(1));
      expect(results.first.name, 'Alice Updated');
      expect(results.first.liquid, 'Wine');
      expect(results.first.quantityMl, 250);
      expect(results.first.durationMs, 2500);
    });

    test('updateChug preserves the original loggedAt', () async {
      final loggedAt = DateTime(2024, 3, 1, 8, 0);
      await service
          .saveAll([_record(loggedAt: loggedAt)], preserveLoggedAt: true);
      final saved = await service.watchAllLeaderboard().first;

      await service.updateChug(
        ChugRecord(
          id: saved.first.id,
          funnelId: saved.first.funnelId,
          name: saved.first.name,
          liquid: saved.first.liquid,
          quantityMl: saved.first.quantityMl,
          durationMs: 9999,
          loggedAt: saved.first.loggedAt,
        ),
      );

      final results = await service.watchAllLeaderboard().first;
      expect(results.first.loggedAt, loggedAt);
    });

    test('deleteChug removes the record', () async {
      await service.saveChug(_record());
      final saved = await service.watchAllLeaderboard().first;

      await service.deleteChug(saved.first.id!);

      final results = await service.watchAllLeaderboard().first;
      expect(results, isEmpty);
    });
  });
}
