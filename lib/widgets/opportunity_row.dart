import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'badges.dart';
import 'pill_button.dart';

/// Standalone job/internship card — a colored type tag up top, bold title,
/// an icon+text meta row (location, stipend, duration), then a footer with
/// a "View details" link and an Apply CTA. Each card is its own bordered,
/// rounded block with a gap to the next one, not a divided list row.
class OpportunityRow extends StatelessWidget {
  final String? tag;
  final String title;
  final String? subtitle;
  final List<String> meta;
  final VoidCallback? onTap;
  final bool saved;
  final bool applied;
  final VoidCallback? onToggleSave;
  final Key? testKey;
  final String? matchLabel;
  final String? deadlineLabel;
  final bool deadlineUrgent;

  /// When set, a footer row (View details / Apply) is shown below the card
  /// — omitted for compact reuse contexts (e.g. the detail page's Similar
  /// roles strip) where a second Apply CTA would be redundant.
  final VoidCallback? onApply;

  const OpportunityRow({
    super.key,
    // Accepted for backwards compatibility with existing call sites that
    // still pass a thumbnail URL — the card no longer renders an image.
    String? image,
    this.tag,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.onTap,
    this.saved = false,
    this.applied = false,
    this.onToggleSave,
    this.testKey,
    this.matchLabel,
    this.deadlineLabel,
    this.deadlineUrgent = false,
    this.onApply,
  });

  static const _metaIcons = [Ionicons.location_outline, Ionicons.cash_outline, Ionicons.time_outline];

  @override
  Widget build(BuildContext context) {
    final deadlineColor = deadlineUrgent ? AppColors.error : AppColors.gray500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: testKey,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag != null && tag!.isNotEmpty) AppTag(label: tag!, color: AppColors.blue, bg: AppColors.blueA10),
                  const Spacer(),
                  if (onToggleSave != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggleSave,
                      child: Icon(
                        saved ? Ionicons.bookmark : Ionicons.bookmark_outline,
                        size: 18,
                        color: saved ? AppColors.blue : AppColors.gray400,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 16),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 13),
                  ),
                ),
              if (meta.where((m) => m.trim().isNotEmpty).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < meta.length; i++)
                        if (meta[i].trim().isNotEmpty)
                          _MetaItem(icon: i < _metaIcons.length ? _metaIcons[i] : Ionicons.ellipse_outline, label: meta[i]),
                    ],
                  ),
                ),
              if (!applied && (matchLabel != null || deadlineLabel != null))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: 2,
                    children: [
                      if (matchLabel != null) _MetaItem(icon: Ionicons.star, label: matchLabel!, color: AppColors.blue),
                      if (deadlineLabel != null) _MetaItem(icon: Ionicons.time_outline, label: deadlineLabel!, color: deadlineColor),
                    ],
                  ),
                ),
              if (onApply != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View details',
                              style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Ionicons.arrow_forward, size: 13, color: AppColors.blue),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (applied)
                        PillButton(label: 'Applied', icon: Ionicons.checkmark_circle, variant: PillVariant.secondary, full: false, compact: true, disabled: true, onPressed: null)
                      else
                        PillButton(label: 'Apply', variant: PillVariant.secondary, full: false, compact: true, onPressed: onApply),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaItem({required this.icon, required this.label, this.color = AppColors.gray500});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption.copyWith(color: color, fontSize: 12.5, fontWeight: AppFontWeight.medium)),
      ],
    );
  }
}
