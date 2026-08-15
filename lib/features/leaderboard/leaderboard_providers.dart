import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chug_record.dart';
import '../../models/known_funnel.dart';
import '../../services/service_providers.dart';
import '../ble/ble_providers.dart';

final selectedLiquidProvider = StateProvider<String?>((ref) => null);
final selectedQuantityProvider = StateProvider<int?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

/// A funnel picked from the "browse funnels" search screen to view its
/// leaderboard without an active BLE connection. Ignored whenever a funnel
/// is actually connected — [connectedDeviceIdProvider] always wins.
final browsingFunnelProvider = StateProvider<KnownFunnel?>((ref) => null);

/// All funnels ever connected to (from Firestore), for the "browse funnels"
/// search screen.
final knownFunnelsProvider = StreamProvider<List<KnownFunnel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchKnownFunnels();
});

final leaderboardProvider = StreamProvider<List<ChugRecord>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final funnelId = ref.watch(connectedDeviceIdProvider) ??
      ref.watch(browsingFunnelProvider)?.id;
  final liquid = ref.watch(selectedLiquidProvider);
  final quantity = ref.watch(selectedQuantityProvider);

  if (funnelId != null) {
    return service.watchLeaderboard(
      funnelId: funnelId,
      liquid: liquid,
      quantityMl: quantity,
    );
  }
  return service.watchAllLeaderboard(liquid: liquid, quantityMl: quantity);
});

/// [leaderboardProvider] further filtered by [searchQueryProvider] (matched
/// against [ChugRecord.name], case-insensitive). Kept as a separate
/// client-side pass rather than a query param on [FirestoreService] — it's
/// a live search-as-you-type filter, not a persisted leaderboard filter.
///
/// A full, exact name match (e.g. "Tom") narrows to only that name's
/// entries rather than also pulling in others that merely contain it as a
/// substring (e.g. "Tommy") — a still-being-typed query without an exact
/// match falls back to substring matching so results appear as you type.
final filteredLeaderboardProvider = Provider<AsyncValue<List<ChugRecord>>>((
  ref,
) {
  final leaderboard = ref.watch(leaderboardProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return leaderboard;

  return leaderboard.whenData((rows) {
    final exactMatches =
        rows.where((r) => r.name.trim().toLowerCase() == query).toList();
    if (exactMatches.isNotEmpty) return exactMatches;
    return rows.where((r) => r.name.toLowerCase().contains(query)).toList();
  });
});
