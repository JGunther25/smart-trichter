import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trichter/models/chug_record.dart';

void main() {
  group('ChugRecord', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('round-trip: all fields survive toFirestore -> fromFirestore',
        () async {
      final original = ChugRecord(
        funnelId: 'funnel-42',
        name: 'Alice',
        liquid: 'Beer',
        quantityMl: 500,
        durationMs: 3210,
        loggedAt: DateTime(2024, 6, 1, 12, 0, 0),
      );

      final ref =
          await fakeFirestore.collection('chugs').add(original.toFirestore());
      final doc = await ref.get();
      final restored = ChugRecord.fromFirestore(doc);

      expect(restored.id, ref.id);
      expect(restored.funnelId, original.funnelId);
      expect(restored.name, original.name);
      expect(restored.liquid, original.liquid);
      expect(restored.quantityMl, original.quantityMl);
      expect(restored.durationMs, original.durationMs);
    });

    test('durationMs survives round-trip as int', () async {
      const durationMs = 12345;
      final record = ChugRecord(
        funnelId: 'f1',
        name: 'Bob',
        liquid: 'Cider',
        quantityMl: 330,
        durationMs: durationMs,
        loggedAt: DateTime.now(),
      );

      final ref =
          await fakeFirestore.collection('chugs').add(record.toFirestore());
      final doc = await ref.get();
      final restored = ChugRecord.fromFirestore(doc);

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

    test('toFirestore uses FieldValue.serverTimestamp for loggedAt', () {
      final record = ChugRecord(
        funnelId: 'f1',
        name: 'Dave',
        liquid: 'Prosecco',
        quantityMl: 250,
        durationMs: 4000,
        loggedAt: DateTime.now(),
      );
      final map = record.toFirestore();
      expect(map['loggedAt'], isA<FieldValue>());
    });
  });
}
