import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() => runApp(const StrideApp());

class StrideApp extends StatelessWidget {
  const StrideApp({super.key});

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F7A5C), brightness: b),
      );

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Stride',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const DashboardScreen(),
      );
}
