import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chug_record.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _chugs;

  FirestoreService({FirebaseFirestore? db})
      : _chugs = (db ?? _defaultDb()).collection('chugs');

  static FirebaseFirestore _defaultDb() {
    final db = FirebaseFirestore.instance;
    db.settings = const Settings(persistenceEnabled: true);
    return db;
  }

  Future<void> saveChug(ChugRecord record) => _chugs.add(record.toFirestore());

  /// Updates an existing record's editable fields, preserving its original
  /// [ChugRecord.loggedAt] rather than re-stamping the server's current time.
  Future<void> updateChug(ChugRecord record) =>
      _chugs.doc(record.id!).update(record.toFirestore(preserveLoggedAt: true));

  Future<void> deleteChug(String id) => _chugs.doc(id).delete();

  /// Writes many records in one atomic batch. Used by the legacy local-data
  /// import — [preserveLoggedAt] keeps each record's original timestamp
  /// instead of stamping it with the server's current time.
  Future<void> saveAll(
    List<ChugRecord> records, {
    bool preserveLoggedAt = false,
  }) async {
    final batch = _chugs.firestore.batch();
    for (final record in records) {
      batch.set(
          _chugs.doc(), record.toFirestore(preserveLoggedAt: preserveLoggedAt));
    }
    await batch.commit();
  }

  Stream<List<ChugRecord>> watchLeaderboard({
    required String funnelId,
    String? liquid,
    int? quantityMl,
  }) =>
      _filteredStream(
          funnelId: funnelId, liquid: liquid, quantityMl: quantityMl);

  Stream<List<ChugRecord>> watchAllLeaderboard({
    String? liquid,
    int? quantityMl,
  }) =>
      _filteredStream(liquid: liquid, quantityMl: quantityMl);

  /// A single unfiltered listener with filtering/sorting done client-side —
  /// avoids needing a Firestore composite index per filter combination,
  /// which isn't worth the complexity for this small collection.
  Stream<List<ChugRecord>> _filteredStream({
    String? funnelId,
    String? liquid,
    int? quantityMl,
  }) {
    return _chugs.snapshots().map((snapshot) {
      var result = snapshot.docs.map(ChugRecord.fromFirestore).toList();
      if (funnelId != null) {
        result = result.where((r) => r.funnelId == funnelId).toList();
      }
      if (liquid != null) {
        result = result.where((r) => r.liquid == liquid).toList();
      }
      if (quantityMl != null) {
        result = result.where((r) => r.quantityMl == quantityMl).toList();
      }
      result.sort((a, b) => a.durationMs.compareTo(b.durationMs));
      return result;
    });
  }
}
