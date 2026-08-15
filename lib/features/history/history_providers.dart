import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chug_record.dart';
import '../../services/service_providers.dart';
import '../ble/ble_providers.dart';

final historyLiquidFilterProvider = StateProvider<String?>((ref) => null);
final historyDateFilterProvider = StateProvider<DateTime?>((ref) => null);

final historyProvider = StreamProvider<List<ChugRecord>>((ref) {
  final serviceAsync = ref.watch(localStorageServiceProvider);
  return serviceAsync.when(
    data: (service) {
      final funnelId = ref.watch(connectedDeviceIdProvider);
      final liquid = ref.watch(historyLiquidFilterProvider);
      final date = ref.watch(historyDateFilterProvider);

      return service.watchHistory(
        funnelId: funnelId,
        liquid: liquid,
        date: date,
      );
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
