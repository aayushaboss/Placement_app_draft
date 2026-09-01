/// Mirrors frontend/src/theme.ts `spacing`.
/// Tightened from the original scale (was xs4/sm8/md12/lg16/xl24/xxl32/xxxl48)
/// — the wider values read as too much dead air per screen compared to
/// reference apps (Flo, LinkedIn), which fit noticeably more per fold.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double xxl = 26;
  static const double xxxl = 40;
}

/// Mirrors frontend/src/theme.ts `radius`.
class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}
