import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette
  static const Color violet50 = Color(0xFFF1EEFF);
  static const Color violet100 = Color(0xFFE1DBFF);
  static const Color violet300 = Color(0xFFB7A6FF);
  static const Color violet400 = Color(0xFF9A82FF);
  static const Color violet500 = Color(0xFF7C5CFC);
  static const Color violet600 = Color(0xFF6A45F0);
  static const Color violet700 = Color(0xFF5834D1);

  static const Color coral400 = Color(0xFFFF8A73);
  static const Color coral500 = Color(0xFFFF6B5E);
  static const Color coral600 = Color(0xFFF04B4B);

  static const Color lime400 = Color(0xFFC8F26A);
  static const Color lime500 = Color(0xFFAEEA3C);

  // Dark Theme Backgrounds
  static const Color darkBg950 = Color(0xFF090A0F);
  static const Color darkBg900 = Color(0xFF0F111A);
  static const Color darkBg800 = Color(0xFF161926);
  static const Color darkBg700 = Color(0xFF1E2235);

  // Dark Theme Glass
  static const Color darkGlass = Color(0x0FFFFFFF); // white with 0.06 alpha
  static const Color darkGlassBorder = Color(0x1AFFFFFF); // white with 0.10 alpha
  static const Color darkGlassHover = Color(0x1FFFFFFF); // white with 0.12 alpha

  // Dark Theme Inks
  static const Color darkInk100 = Color(0xFFF5F5F7);
  static const Color darkInk200 = Color(0xFFE2E4E9);
  static const Color darkInk300 = Color(0xFFA3A7B7);
  static const Color darkInk400 = Color(0xFF6B7280);
  static const Color darkInk500 = Color(0xFF4B5563);

  // Light Theme Backgrounds
  static const Color lightBg950 = Color(0xFFF8F9FC);
  static const Color lightBg900 = Color(0xFFFFFFFF);
  static const Color lightBg800 = Color(0xFFF1F3F9);
  static const Color lightBg700 = Color(0xFFE5E7EB);

  // Light Theme Glass
  static const Color lightGlass = Color(0xB3FFFFFF); // white with 0.70 alpha
  static const Color lightGlassBorder = Color(0x1A000000); // black with 0.10 alpha
  static const Color lightGlassHover = Color(0x0A000000); // black with 0.04 alpha

  // Light Theme Inks
  static const Color lightInk100 = Color(0xFF111827);
  static const Color lightInk200 = Color(0xFF1F2937);
  static const Color lightInk300 = Color(0xFF4B5563);
  static const Color lightInk400 = Color(0xFF6B7280);
  static const Color lightInk500 = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [violet500, coral500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pegasusGradient = LinearGradient(
    colors: [violet500, lime400],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0x667C5CFC), Color(0x4DFF6B5E), Color(0x33C8F26A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
