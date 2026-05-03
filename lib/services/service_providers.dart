import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_storage_service.dart';

final localStorageServiceProvider = FutureProvider(
  (_) => LocalStorageService.create(),
);
