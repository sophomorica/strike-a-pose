import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';

const _background = Color(0xFF141210);
const _ink = Color(0xFFF4EFE6);
const _strike = Color(0xFFE23D28);
const _strikeInk = Color(0xFF141210);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const StrikeApp());
}

class StrikeApp extends StatelessWidget {
  const StrikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strike a Pose',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: _strike,
          onPrimary: _strikeInk,
          secondary: _strike,
          onSecondary: _strikeInk,
          error: Color(0xFFE26D5A),
          onError: _strikeInk,
          surface: _background,
          onSurface: _ink,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _ink),
          bodyMedium: TextStyle(color: _ink),
          titleLarge: TextStyle(color: _ink),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _strike,
            foregroundColor: _strikeInk,
            minimumSize: const Size.fromHeight(56),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
