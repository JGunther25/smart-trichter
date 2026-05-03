import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chug_record.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db}) : _db = db ?? _defaultDb();

  static FirebaseFirestore _defaultDb() {
    final db = FirebaseFirestore.instance;
    db.settings = const Settings(persistenceEnabled: true);
    return db;
  }

  Future<void> saveChug(ChugRecord record) =>
      _db.collection('chugs').add(record.toFirestore());

  Stream<List<ChugRecord>> watchLeaderboard({
    required String funnelId,
    String? liquid,
    int? quantityMl,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('chugs')
        .where('funnelId', isEqualTo: funnelId)
        .orderBy('durationMs');
    if (liquid != null) q = q.where('liquid', isEqualTo: liquid);
    if (quantityMl != null) q = q.where('quantityMl', isEqualTo: quantityMl);
    return q.snapshots().map(
          (s) => s.docs.map(ChugRecord.fromFirestore).toList(),
        );
  }

  Stream<List<ChugRecord>> watchAllLeaderboard({
    String? liquid,
    int? quantityMl,
  }) {
    Query<Map<String, dynamic>> q =
        _db.collection('chugs').orderBy('durationMs');
    if (liquid != null) q = q.where('liquid', isEqualTo: liquid);
    if (quantityMl != null) q = q.where('quantityMl', isEqualTo: quantityMl);
    return q.snapshots().map(
          (s) => s.docs.map(ChugRecord.fromFirestore).toList(),
        );
  }
}
