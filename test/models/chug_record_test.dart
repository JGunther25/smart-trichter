import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trichter/models/chug_record.dart';

void main() {
  group('ChugRecord', () {
    test('round-trip: all fields survive toJson -> fromJson', () {
      final original = ChugRecord(
        id: 'abc-123',
        funnelId: 'funnel-42',
        name: 'Alice',
        liquid: 'Beer',
        quantityMl: 500,
        durationMs: 3210,
        loggedAt: DateTime(2024, 6, 1, 12, 0, 0),
      );

      final restored = ChugRecord.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.funnelId, original.funnelId);
      expect(restored.name, original.name);
      expect(restored.liquid, original.liquid);
      expect(restored.quantityMl, original.quantityMl);
      expect(restored.durationMs, original.durationMs);
      expect(restored.loggedAt, original.loggedAt);
    });

    test('durationMs survives round-trip as int', () {
      const durationMs = 12345;
      final record = ChugRecord(
        funnelId: 'f1',
        name: 'Bob',
        liquid: 'Cider',
        quantityMl: 330,
        durationMs: durationMs,
        loggedAt: DateTime.now(),
      );

      final restored = ChugRecord.fromJson(record.toJson());

      expect(restored.durationMs, isA<int>());
      expect(restored.durationMs, durationMs);
    });

    test('id is null before saving', () {
      final record = ChugRecord(
        funnelId: 'f1',
        name: 'Carol',
        liquid: 'Wine',
        quantityMl: 250,
        durationMs: 5000,
        loggedAt: DateTime.now(),
      );
      expect(record.id, isNull);
    });

    test('copyWith assigns a new id', () {
      final record = ChugRecord(
        funnelId: 'f1',
        name: 'Dave',
        liquid: 'Prosecco',
        quantityMl: 250,
        durationMs: 4000,
        loggedAt: DateTime.now(),
      );
      final withId = record.copyWith(id: 'new-id');

      expect(withId.id, 'new-id');
      expect(withId.funnelId, record.funnelId);
      expect(withId.durationMs, record.durationMs);
    });
  });
}
