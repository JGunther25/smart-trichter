import 'package:flutter/material.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.amber,
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 2,
  ),
  cardTheme: const CardThemeData(
    elevation: 1,
    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    filled: true,
  ),
  chipTheme: const ChipThemeData(
    showCheckmark: false,
  ),
);
