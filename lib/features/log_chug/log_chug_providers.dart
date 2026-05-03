import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_providers.dart';

/// Holds the duration (ms) of a chug waiting to be logged.
/// null means no pending chug. The leaderboard screen watches this
/// and opens the log-chug sheet when it becomes non-null.
final pendingChugDurationProvider = StateProvider<int?>((ref) => null);

/// Listens to the BLE chug stream and writes incoming durations to
/// pendingChugDurationProvider. Keep alive at app level by watching
/// this provider from a top-level widget.
final chugDurationListenerProvider = Provider.autoDispose((ref) {
  ref.listen<AsyncValue<int>>(chugDurationProvider, (_, next) {
    next.whenData(
        (ms) => ref.read(pendingChugDurationProvider.notifier).state = ms);
  });
});
