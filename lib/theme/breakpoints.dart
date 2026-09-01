/// Screen-width breakpoints — this app has zero responsive layout logic
/// otherwise, having only ever been built and checked at one phone width.
class AppBreakpoints {
  AppBreakpoints._();

  /// Material's own tablet threshold. Below this, [ResponsiveBody] (see
  /// widgets/responsive_body.dart) is a complete no-op — nothing here can
  /// regress the phone sizes this app was actually tested at.
  static const double tablet = 600;

  /// Cap for single-column screens once past [tablet] — sized around a
  /// comfortable "large phone" reading width rather than letting inputs
  /// and buttons (tuned at ~375px) stretch edge-to-edge on a full tablet.
  static const double maxContentWidth = 520;
}
