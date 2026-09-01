import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Mirrors frontend/src/components/ui.tsx PillButton.
///
/// [outlineWhite] is the odd one out — not in the original mirror. Added
/// because [secondary] (white fill, blue border/text) was being reused on
/// screens with a solid `AppColors.blue` Scaffold background (the
/// post-booking confirmation screen, the aptitude intro screen, the
/// onboarding landing screen) — there, a solid white-filled button sits
/// right next to (or above) the solid yellow [primary] button and reads as
/// equally prominent, not clearly secondary. [outlineWhite] is transparent
/// with a white border and white text/icon — recedes against a colored
/// background the way [secondary] already recedes against a white one.
enum PillVariant { primary, secondary, ghost, dark, outlineWhite }

class PillButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final bool loading;
  final bool disabled;
  final IconData? icon;

  /// Overrides [icon] when set — for brand marks (Google/Gmail) that need
  /// their real multi-color logo instead of a single-color IconData glyph.
  final Widget? iconWidget;
  final bool full;
  final Key? testKey;

  /// Smaller footprint for tight spaces (e.g. a card footer's Apply CTA)
  /// — same visual language, just a shorter/tighter build of the same button
  /// rather than a bespoke small-button widget.
  final bool compact;

  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PillVariant.primary,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.iconWidget,
    this.full = true,
    this.testKey,
    this.compact = false,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  bool get _isDisabled => widget.disabled || widget.loading;

  Color get _bg {
    switch (widget.variant) {
      case PillVariant.primary:
        return AppColors.yellow;
      case PillVariant.secondary:
        return AppColors.white;
      case PillVariant.dark:
        return AppColors.blue;
      case PillVariant.ghost:
      case PillVariant.outlineWhite:
        return Colors.transparent;
    }
  }

  Color get _fg {
    switch (widget.variant) {
      case PillVariant.primary:
        return AppColors.ink;
      case PillVariant.secondary:
        return AppColors.blue;
      case PillVariant.dark:
        return AppColors.white;
      case PillVariant.ghost:
        return AppColors.blue;
      case PillVariant.outlineWhite:
        return AppColors.white;
    }
  }

  void _handleTap() {
    if (_isDisabled) return;
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.loading
        ? SizedBox(
            width: widget.compact ? 16 : 20,
            height: widget.compact ? 16 : 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.iconWidget != null) ...[
                SizedBox(
                  width: widget.compact ? 16 : 20,
                  height: widget.compact ? 16 : 20,
                  child: widget.iconWidget,
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.compact ? 16 : 20, color: _fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: widget.compact
                    ? AppTextStyles.body.copyWith(fontWeight: AppFontWeight.medium, color: _fg, fontSize: 13)
                    : AppTextStyles.bodyLg.copyWith(fontWeight: AppFontWeight.medium, color: _fg),
              ),
            ],
          );

    return GestureDetector(
      key: widget.testKey,
      onTapDown: _isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: _isDisabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: _isDisabled ? null : () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed && !_isDisabled ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _isDisabled ? 0.5 : (_pressed ? 0.92 : 1.0),
          duration: const Duration(milliseconds: 100),
          child: Container(
            // 44, not the old 46 — Naukri's primary buttons measured 38px;
            // splitting the difference keeps a comfortable tap target while
            // trimming the visible bulk.
            height: widget.compact ? 32 : AppSpacing.xxxl + AppSpacing.xs,
            width: widget.full ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? AppSpacing.md : AppSpacing.xl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: switch (widget.variant) {
                PillVariant.secondary => Border.all(color: AppColors.blue, width: 1.5),
                PillVariant.outlineWhite => Border.all(color: AppColors.white, width: 1.5),
                _ => null,
              },
              boxShadow: widget.variant == PillVariant.primary ? AppShadows.yellow : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
