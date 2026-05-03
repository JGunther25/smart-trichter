import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chug_record.dart';
import '../../services/service_providers.dart';
import '../ble/ble_providers.dart';

final selectedLiquidProvider = StateProvider<String?>((ref) => null);
final selectedQuantityProvider = StateProvider<int?>((ref) => null);

final leaderboardProvider = StreamProvider<List<ChugRecord>>((ref) {
  final serviceAsync = ref.watch(localStorageServiceProvider);
  return serviceAsync.when(
    data: (service) {
      final funnelId = ref.watch(connectedDeviceIdProvider);
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
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
