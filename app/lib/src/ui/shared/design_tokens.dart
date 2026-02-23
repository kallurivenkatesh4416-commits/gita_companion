import 'package:flutter/material.dart';

/// Immutable design tokens for the Sacred Glass UI layer.
///
/// Keep framework-agnostic — do NOT import AppTheme here.
/// Import this file wherever blur/fill/motion values are needed.
abstract final class GlassTokens {
  // ── Blur sigmas ───────────────────────────────────────────────────────────
  static const double blurAppBar   = 20.0;
  static const double blurNavBar   = 30.0;
  static const double blurCard     = 12.0;
  static const double blurFestival =  8.0;

  // ── Fill alphas (0–1) ─────────────────────────────────────────────────────
  static const double fillAppBar   = 0.08;
  static const double fillNavBar   = 0.10;
  static const double fillCard     = 0.15;
  static const double fillFestival = 0.12;

  // ── Border ────────────────────────────────────────────────────────────────
  static const double borderWidth  = 0.5;
  /// White hairline — for light glass panels
  static const Color  borderLight  = Color(0x40FFFFFF); // white @ 25 %
  /// Champagne-gold hairline — for scrolled app bar
  static const Color  borderGold   = Color(0x66C9A84C); // gold  @ 40 %
}

abstract final class DesignColors {
  // Saffron scale
  static const Color saffron500 = Color(0xFFFF6B35); // Deep Saffron (hero accent)
  static const Color saffron200 = Color(0xFFFFD4B4); // Pale saffron

  // Champagne Gold scale
  static const Color gold500    = Color(0xFFC9A84C); // Champagne Gold
  static const Color gold200    = Color(0xFFF5E3A2); // Pale gold / glass shimmer

  // Charcoal (dark glass layer)
  static const Color charcoal800 = Color(0xFF1C1F26);
  static const Color charcoal600 = Color(0xFF2E3340);

  // Parchment
  static const Color parchment   = Color(0xFFF8EDD8);

  // ── Festival palette ──────────────────────────────────────────────────────
  static const Map<String, Color> festival = {
    'diwali'             : Color(0xFFFF9800),
    'holi'               : Color(0xFFE91E63),
    'maha_shivaratri'    : Color(0xFF5C6BC0),
    'navratri'           : Color(0xFFFF7043),
    'ganesh_chaturthi'   : Color(0xFFFF6B35),
    'krishna_janmashtami': Color(0xFF1E88E5),
    'ram_navami'         : Color(0xFF43A047),
    'hanuman_jayanti'    : Color(0xFFFF8F00),
    'akshaya_tritiya'    : Color(0xFFC9A84C),
    'rath_yatra'         : Color(0xFFF57C00),
    'guru_purnima'       : Color(0xFF7E57C2),
    'raksha_bandhan'     : Color(0xFF8E24AA),
    'onam'               : Color(0xFF00897B),
    'makar_sankranti'    : Color(0xFFFFA726),
    'pongal'             : Color(0xFF7CB342),
    'gita_jayanti'       : Color(0xFF9C7A2B),
    'dussehra'           : Color(0xFFE53935),
    'kartik_purnima'     : Color(0xFF26A69A),
    'default'            : Color(0xFFC9A84C),
  };
}

abstract final class MotionTokens {
  static const Duration fast     = Duration(milliseconds: 150);
  static const Duration medium   = Duration(milliseconds: 300);
  static const Duration open     = Duration(milliseconds: 400);

  static const Curve easeOut     = Curves.easeOut;
  static const Curve standard    = Curves.easeInOut;
  static const Curve emphasized  = Curves.easeInOutCubicEmphasized;
}
