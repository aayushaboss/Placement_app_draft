import 'package:flutter/material.dart';

/// Sole UI typeface — no other font is used anywhere in this app.
const String kFontFamily = 'Poppins';

/// Mirrors frontend/src/theme.ts `font` (numeric weights used with Poppins).
class AppFontWeight {
  AppFontWeight._();

  static const black = FontWeight.w900;
  static const extrabold = FontWeight.w800;
  // w600, not w700 — dialed back one notch app-wide so bold text (screen
  // titles, section headings, card titles) doesn't read as visually heavy.
  // Flutter/CSS weights only exist in steps of 100, so "one step lighter"
  // lands exactly on the same value as `semibold` below — bold and
  // semibold text now render at the same weight, distinguished by size
  // alone rather than size-plus-weight. Both stay clearly heavier than
  // `medium`/`regular`, which is what actually keeps bold text reading as
  // distinct from ordinary body copy.
  static const bold = FontWeight.w600;
  static const semibold = FontWeight.w600;
  static const medium = FontWeight.w500;
  static const regular = FontWeight.w400;
}

/// Mirrors frontend/src/theme.ts `type` scale.
/// Weights trimmed a third time after auditing internshala.com's mobile
/// site directly: their job-card title (the single most prominent text on
/// the card) is regular 400, company name is medium 500, meta text is
/// regular 400, and the heaviest weight found anywhere on the page —
/// including what stands in for a page heading — was semibold 600. Bold
/// and up essentially don't appear. Ours leaned much heavier (extrabold
/// titles, bold everywhere) which is what read as "thick" — so every
/// weight here drops a step or two, keeping bold/extrabold for the rare
/// cases that still need real emphasis rather than as the default.
class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 26,
    fontWeight: AppFontWeight.bold,
    letterSpacing: -0.5,
  );
  static const h1 = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 22,
    fontWeight: AppFontWeight.bold,
    letterSpacing: -0.4,
  );
  static const h2 = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 18,
    fontWeight: AppFontWeight.semibold,
    letterSpacing: -0.2,
  );
  static const h3 = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16,
    fontWeight: AppFontWeight.semibold,
  );
  static const bodyLg = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14,
    fontWeight: AppFontWeight.medium,
  );
  static const body = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14,
    fontWeight: AppFontWeight.regular,
  );
  static const label = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12,
    fontWeight: AppFontWeight.medium,
  );
  static const caption = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12,
    fontWeight: AppFontWeight.regular,
  );
}
