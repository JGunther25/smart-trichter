import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_trichter/models/chug_record.dart';
import 'package:smart_trichter/services/local_storage_service.dart';

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
  group('LocalStorageService', () {
    late LocalStorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = await LocalStorageService.create();
    });

    tearDown(() => service.dispose());

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

    test('watchHistory orders by loggedAt descending', () async {
      final now = DateTime.now();
      await service.saveChug(_record(
          name: 'A', loggedAt: now.subtract(const Duration(minutes: 2))));
      await service.saveChug(_record(name: 'B', loggedAt: now));
      await service.saveChug(_record(
          name: 'C', loggedAt: now.subtract(const Duration(minutes: 1))));

      final results = await service.watchHistory(funnelId: 'funnel-1').first;

      expect(results.map((r) => r.name).toList(), ['B', 'C', 'A']);
    });

    test('watchHistory date filter returns only records on that day', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      await service.saveChug(_record(name: 'Today', loggedAt: today));
      await service.saveChug(_record(name: 'Yesterday', loggedAt: yesterday));

      final results =
          await service.watchHistory(funnelId: 'funnel-1', date: today).first;

      expect(results, hasLength(1));
      expect(results.first.name, 'Today');
    });

    test('watchHistory liquid filter works', () async {
      await service.saveChug(_record(liquid: 'Beer'));
      await service.saveChug(_record(liquid: 'Wine'));

      final results = await service
          .watchHistory(funnelId: 'funnel-1', liquid: 'Wine')
          .first;

      expect(results, hasLength(1));
      expect(results.first.liquid, 'Wine');
    });
  });
}
