import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Mirrors frontend/src/components/brand.tsx.

/// Stylized swept-wing / paper-plane mark used across splash, headers, empty states.
class WingLogo extends StatelessWidget {
  final double size;
  final Color color;

  const WingLogo({super.key, this.size = 64, this.color = AppColors.yellow});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WingLogoPainter(color: color),
    );
  }
}

class _WingLogoPainter extends CustomPainter {
  final Color color;
  _WingLogoPainter({required this.color});

  // viewBox 0 0 100 100
  static const _p1 = [Offset(10, 78), Offset(90, 20), Offset(52, 54)];
  static const _p2 = [Offset(10, 78), Offset(52, 54), Offset(40, 68)];
  static const _p3 = [Offset(52, 54), Offset(90, 20), Offset(60, 60)];

  Path _polygon(List<Offset> points, double sx, double sy) {
    final path = Path()..moveTo(points[0].dx * sx, points[0].dy * sy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx * sx, p.dy * sy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 100;

    canvas.drawPath(_polygon(_p1, sx, sy), Paint()..color = color);
    canvas.drawPath(_polygon(_p2, sx, sy), Paint()..color = AppColors.white.withValues(alpha: 0.9));
    canvas.drawPath(_polygon(_p3, sx, sy), Paint()..color = color.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _WingLogoPainter oldDelegate) => oldDelegate.color != color;
}

/// Wordmark: AEROSTAR + EDGE badge.
class Wordmark extends StatelessWidget {
  final Color color;
  final Color accent;
  final double size;

  const Wordmark({
    super.key,
    this.color = AppColors.white,
    this.accent = AppColors.yellow,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AEROSTAR',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontWeight: AppFontWeight.semibold,
            letterSpacing: 1.5,
            fontSize: size,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Text(
            'EDGE',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontWeight: AppFontWeight.semibold,
              letterSpacing: 1,
              fontSize: size * 0.5,
              color: AppColors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

/// Decorative diagonal wing overlay for card image headers.
class WingOverlay extends StatelessWidget {
  final double height;

  const WingOverlay({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(painter: _WingOverlayPainter()),
      ),
    );
  }
}

class _WingOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 400x200, preserveAspectRatio="none" — stretch independently on x/y.
    final sx = size.width / 400;
    final sy = size.height / 200;
    Offset o(double x, double y) => Offset(x * sx, y * sy);

    final poly1 = Path()
      ..moveTo(o(0, 200).dx, o(0, 200).dy)
      ..lineTo(o(400, 0).dx, o(400, 0).dy)
      ..lineTo(o(400, 60).dx, o(400, 60).dy)
      ..lineTo(o(120, 200).dx, o(120, 200).dy)
      ..close();
    canvas.drawPath(poly1, Paint()..color = AppColors.blue.withValues(alpha: 0.55));

    final poly2 = Path()
      ..moveTo(o(0, 200).dx, o(0, 200).dy)
      ..lineTo(o(260, 80).dx, o(260, 80).dy)
      ..lineTo(o(400, 80).dx, o(400, 80).dy)
      ..lineTo(o(400, 200).dx, o(400, 200).dy)
      ..close();
    canvas.drawPath(poly2, Paint()..color = AppColors.blueDeep.withValues(alpha: 0.35));

    final tri = Path()
      ..moveTo(o(240, 40).dx, o(240, 40).dy)
      ..lineTo(o(360, 20).dx, o(360, 20).dy)
      ..lineTo(o(300, 70).dx, o(300, 70).dy)
      ..close();
    canvas.drawPath(tri, Paint()..color = AppColors.yellow.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _WingOverlayPainter oldDelegate) => false;
}
