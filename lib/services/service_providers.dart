import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>(
  (_) => FirestoreService(),
);
