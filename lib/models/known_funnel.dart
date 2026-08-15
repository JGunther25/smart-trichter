import 'package:cloud_firestore/cloud_firestore.dart';

/// A funnel this app has connected to at least once, identified by its BLE
/// device address (document ID) with the name captured from the BLE
/// advertisement at connect time. Lets a funnel's leaderboard be browsed by
/// name without an active BLE connection.
class KnownFunnel {
  final String id;
  final String name;

  const KnownFunnel({required this.id, required this.name});

  factory KnownFunnel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return KnownFunnel(id: doc.id, name: doc.data()!['name'] as String);
  }
}
