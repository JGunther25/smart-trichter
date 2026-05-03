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

  factory ChugRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ChugRecord(
      id: doc.id,
      funnelId: data['funnelId'] as String,
      name: data['name'] as String,
      liquid: data['liquid'] as String,
      quantityMl: data['quantityMl'] as int,
      durationMs: data['durationMs'] as int,
      loggedAt: (data['loggedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'funnelId': funnelId,
        'name': name,
        'liquid': liquid,
        'quantityMl': quantityMl,
        'durationMs': durationMs,
        'loggedAt': FieldValue.serverTimestamp(),
      };
}
