import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chug_record.dart';
import '../../services/firestore_service.dart';

/// One-time bridge for devices that still have chugs saved under the old
/// shared_preferences-based storage, from before the app moved to Firestore.
/// Delete this once no users have local-only data left to migrate.
const _kLegacyStorageKey = 'chug_records';

Future<List<ChugRecord>> readLegacyRecords() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kLegacyStorageKey);
  if (raw == null) return [];

  final list = jsonDecode(raw) as List<dynamic>;
  return list.map((e) {
    final json = e as Map<String, dynamic>;
    return ChugRecord(
      id: json['id'] as String?,
      funnelId: json['funnelId'] as String,
      name: json['name'] as String,
      liquid: json['liquid'] as String,
      quantityMl: json['quantityMl'] as int,
      durationMs: json['durationMs'] as int,
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );
  }).toList();
}

Future<void> importLegacyRecords(
  FirestoreService service,
  List<ChugRecord> records,
) async {
  await service.saveAll(records, preserveLoggedAt: true);

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kLegacyStorageKey);
}
