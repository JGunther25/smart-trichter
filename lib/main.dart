import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint(
      'Firebase not configured. Run `flutterfire configure` to set up Firebase. Error: $e',
    );
  }

  runApp(const ProviderScope(child: App()));
}
