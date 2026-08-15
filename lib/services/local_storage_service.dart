import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chug_record.dart';

const _kStorageKey = 'chug_records';

class LocalStorageService {
  final SharedPreferences _prefs;
  final _controller = StreamController<List<ChugRecord>>.broadcast();

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  List<ChugRecord> _loadAll() {
    final raw = _prefs.getString(_kStorageKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ChugRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<ChugRecord> records) async {
    await _prefs.setString(
      _kStorageKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
    _controller.add(records);
  }

  Future<void> saveChug(ChugRecord record) async {
    final records = _loadAll();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    records.add(record.copyWith(id: id));
    await _persist(records);
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

  /// Chronological history (most recent first), optionally filtered by
  /// funnel, liquid, and calendar day (compared in local time).
  Stream<List<ChugRecord>> watchHistory({
    String? funnelId,
    String? liquid,
    DateTime? date,
  }) =>
      _filteredStream(
        funnelId: funnelId,
        liquid: liquid,
        date: date,
        sortByDuration: false,
      );

  Stream<List<ChugRecord>> _filteredStream({
    String? funnelId,
    String? liquid,
    int? quantityMl,
    DateTime? date,
    bool sortByDuration = true,
  }) {
    List<ChugRecord> filter(List<ChugRecord> all) {
      var result = all;
      if (funnelId != null) {
        result = result.where((r) => r.funnelId == funnelId).toList();
      }
      if (liquid != null) {
        result = result.where((r) => r.liquid == liquid).toList();
      }
      if (quantityMl != null) {
        result = result.where((r) => r.quantityMl == quantityMl).toList();
      }
      if (date != null) {
        result = result.where((r) {
          final local = r.loggedAt.toLocal();
          return local.year == date.year &&
              local.month == date.month &&
              local.day == date.day;
        }).toList();
      }
      result = List.of(result);
      if (sortByDuration) {
        result.sort((a, b) => a.durationMs.compareTo(b.durationMs));
      } else {
        result.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      }
      return result;
    }

    // Emit current state immediately, then re-emit on every save.
    final initial = Stream.value(_loadAll());
    final updates = _controller.stream;
    return initial.asyncExpand((first) => updates.startWith(first)).map(filter);
  }

  void dispose() => _controller.close();
}

extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
