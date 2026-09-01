import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Mirrors frontend/src/components/ui.tsx IconBadgeRow.
class IconBadgeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool onBlue;

  const IconBadgeRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onBlue ? AppColors.whiteA15 : AppColors.yellow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: onBlue ? AppColors.white : AppColors.blue,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: AppFontWeight.medium,
                    color: onBlue ? AppColors.white : AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: onBlue ? AppColors.whiteA70 : AppColors.gray500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors frontend/src/components/ui.tsx StatItem.
class StatItem extends StatelessWidget {
  final String value;
  final String label;

  const StatItem({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.h1.copyWith(
            color: AppColors.yellow,
            fontSize: 30,
            fontWeight: AppFontWeight.semibold,
            letterSpacing: -0.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: AppFontWeight.medium,
            ),
          ),
        ),
      ],
    );
  }
}

/// Status values stay as-is internally (matching, counting, gating) — this
/// only softens what's shown on screen. "Rejected" reads as a personal
/// verdict at a glance, especially seeing it repeatedly; "Not selected"
/// says the same thing without the sting.
String applicationStatusLabel(String status) =>
    status == 'Rejected' ? 'Better luck next time!' : status;

/// Mirrors frontend/src/components/ui.tsx StatusBadge STATUS_COLORS + component.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  // Interview/Offer used to be solid-fill-with-white-text — the exact
  // visual signature PillButton/AppChip use for an actual button
  // elsewhere in this app, so the badge read as tappable even though it's
  // pure status display. Softened to the same tinted-pill language as the
  // other three statuses so all five read consistently as status, not as
  // five buttons with two odd ones out.
  static const Map<String, (Color, Color)> _statusColors = {
    'Applied': (AppColors.blueA10, AppColors.blue),
    'In Review': (AppColors.warningA15, AppColors.warning),
    'Interview': (AppColors.blueA10, AppColors.blue),
    'Offer': (AppColors.successA10, AppColors.success),
    'Rejected': (AppColors.gray500A15, AppColors.gray500),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors[status] ?? _statusColors['Applied']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        applicationStatusLabel(status),
        style: AppTextStyles.caption.copyWith(
          fontSize: 12,
          fontWeight: AppFontWeight.medium,
          color: fg,
        ),
      ),
    );
  }
}

/// Mirrors frontend/src/components/ui.tsx Tag. Named AppTag for consistency with AppChip.
class AppTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  /// Optional leading glyph — e.g. for a small trust/credential badge row.
  /// Null by default so every existing call site (none of which pass one)
  /// renders exactly as before.
  final IconData? icon;

  const AppTag({
    super.key,
    required this.label,
    this.color = AppColors.blue,
    this.bg = AppColors.blueA10,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTextStyles.caption.copyWith(
        fontSize: 11,
        fontWeight: AppFontWeight.medium,
        letterSpacing: 0.3,
        color: color,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                text,
              ],
            ),
    );
  }
}
