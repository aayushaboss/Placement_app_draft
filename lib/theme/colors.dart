import 'package:flutter/material.dart';

/// Aerostar Edge design tokens — brand match to aerostaredge.com.
/// Mirrors frontend/src/theme.ts `colors` exactly.
class AppColors {
  AppColors._();

  // brand
  static const blue = Color(0xFF0A2FFF);
  static const blueDark = Color(0xFF0722B8);
  static const blueDeep = Color(0xFF061A8C);
  static const yellow = Color(0xFFFFC72C);
  static const yellowDark = Color(0xFFE6B316);

  // surfaces
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF5F5F7);
  static const gray100 = Color(0xFFE5E5EA);
  static const gray200 = Color(0xFFD1D1D6);
  static const gray400 = Color(0xFFA1A1AA);
  static const gray500 = Color(0xFF71717A);
  static const ink = Color(0xFF1C1C1E);

  // status
  // Material Design green 500 — softer and warmer than the previous
  // icy/minty iOS system green, while staying a widely-recognized
  // "success" green rather than an off-brand pick.
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);
  static const info = Color(0xFF0A2FFF);

  static const border = Color(0xFFE5E5EA);

  // translucent
  static const whiteA10 = Color(0x1AFFFFFF);
  static const whiteA15 = Color(0x26FFFFFF);
  static const whiteA20 = Color(0x33FFFFFF);
  static const whiteA70 = Color(0xB3FFFFFF);
  static const blueA10 = Color(0x1A0A2FFF);
  static const successA10 = Color(0x1A4CAF50);
  static const warningA15 = Color(0x24FF9500);
  static const errorA10 = Color(0x1FFF3B30);
  static const gray500A15 = Color(0x2471717A);
}
