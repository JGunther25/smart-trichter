import 'package:cloud_firestore/cloud_firestore.dart';

class ChugRecord {
  final String? id;
  final String funnelId;
  final String name;
  final String liquid;
  final int quantityMl;
  final int durationMs;
  final DateTime loggedAt;

  const ChugRecord({
    this.id,
    required this.funnelId,
    required this.name,
    required this.liquid,
    required this.quantityMl,
    required this.durationMs,
    required this.loggedAt,
  });

  factory ChugRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChugRecord(
      id: doc.id,
      funnelId: data['funnelId'] as String,
      name: data['name'] as String,
      liquid: data['liquid'] as String,
      quantityMl: data['quantityMl'] as int,
      durationMs: data['durationMs'] as int,
      // The server timestamp hasn't resolved yet on the optimistic local
      // snapshot returned right after saveChug() — fall back to now.
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// [preserveLoggedAt] backfills the record's real historical timestamp
  /// instead of stamping it with the server's current time — used only by
  /// the legacy local-data import.
  Map<String, dynamic> toFirestore({bool preserveLoggedAt = false}) => {
        'funnelId': funnelId,
        'name': name,
        'liquid': liquid,
        'quantityMl': quantityMl,
        'durationMs': durationMs,
        'loggedAt': preserveLoggedAt
            ? Timestamp.fromDate(loggedAt)
            : FieldValue.serverTimestamp(),
      };
}
