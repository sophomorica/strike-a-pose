import 'package:flutter/material.dart';

class Sap {
  static const indigo = Color(0xFF3D2B6B);
  static const indigoDeep = Color(0xFF231743);
  static const indigoNight = Color(0xFF170F2E);
  static const plum = Color(0xFF5E2F6E);
  static const coral = Color(0xFFE85D4C);
  static const coralDeep = Color(0xFFB8412F);
  static const coralLight = Color(0xFFF28B7D);
  static const cream = Color(0xFFF7F1E3);
  static const paper = Color(0xFFFFFDF7);
  static const sun = Color(0xFFFFC845);
  static const sky = Color(0xFF4FB7F0);
  static const teal = Color(0xFF2EC4B6);
  static const bubblegum = Color(0xFFF7A8C8);
  static const magenta = Color(0xFFD6479B);
  static const sage = Color(0xFF7FAE8A);
  static const lavender = Color(0xFFB9A3E3);
  static const miss = Color(0xFFFF4F5E);
  static const close = Color(0xFFFFB938);
  static const match = Color(0xFF3DE88A);
  static const ink = Color(0xFF1B1230);

  static const display = 'Barlow Condensed';
  static const ui = 'Baloo 2';
  static const body = 'Nunito';
  static const marker = 'Permanent Marker';
}

Color avatarColor(String name) {
  return switch (name) {
    'sun' => Sap.sun,
    'sky' => Sap.sky,
    'sage' => Sap.sage,
    'lavender' => Sap.lavender,
    'bubblegum' => Sap.bubblegum,
    'teal' => Sap.teal,
    'coral' => Sap.coral,
    'cream' => Sap.cream,
    _ => Sap.sun,
  };
}

TextStyle displayStyle(double size, {Color color = Sap.cream, double height = 0.9}) {
  return TextStyle(
    fontFamily: Sap.display,
    fontWeight: FontWeight.w900,
    fontSize: size,
    height: height,
    color: color,
    letterSpacing: 0.4,
  );
}

TextStyle uiStyle(double size, {Color color = Sap.cream, FontWeight weight = FontWeight.w700}) {
  return TextStyle(
    fontFamily: Sap.ui,
    fontWeight: weight,
    fontSize: size,
    color: color,
    height: 1.1,
  );
}

TextStyle bodyStyle(double size, {Color color = Sap.cream}) {
  return TextStyle(
    fontFamily: Sap.body,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.25,
  );
}

ThemeData sapTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Sap.indigoNight,
    colorScheme: const ColorScheme.dark(
      primary: Sap.coral,
      surface: Sap.indigoDeep,
    ),
    fontFamily: Sap.body,
  );
}
