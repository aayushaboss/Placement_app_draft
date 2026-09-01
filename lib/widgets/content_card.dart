import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'badges.dart';
import 'pill_button.dart';

/// Mirrors frontend/src/components/ContentCard.tsx.
///
/// A leading tinted icon mark next to the title, then a body that
/// deliberately reuses OpportunityRow's exact language (tag pill, bold
/// title, icon+text meta row, "View X →" link footer) — this is the same
/// card family as the job cards and CourseCarouselSection's course cards,
/// not a different design system with a photo bolted on.
class ContentCard extends StatelessWidget {
  final IconData? icon;
  final String? tag;
  final String title;
  final String? subtitle;
  final List<String> meta;
  final String linkLabel;
  final VoidCallback? onTap;
  final bool saved;
  final bool applied;
  final VoidCallback? onToggleSave;
  final Key? testKey;

  /// Personalized relevance badge (e.g. "Great fit", "72% match"). Optional —
  /// only opportunity cards with a signed-in user's roles/resume set this.
  final String? matchLabel;

  /// Application-deadline urgency badge (e.g. "2 days left"). Optional.
  final String? deadlineLabel;

  /// Styles [deadlineLabel] with the error color instead of warning when true.
  final bool deadlineUrgent;

  const ContentCard({
    super.key,
    this.icon,
    this.tag,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.linkLabel = 'View details',
    this.onTap,
    this.saved = false,
    this.applied = false,
    this.onToggleSave,
    this.testKey,
    this.matchLabel,
    this.deadlineLabel,
    this.deadlineUrgent = false,
  });

  static const _metaIcons = [Ionicons.time_outline, Ionicons.albums_outline, Ionicons.ribbon_outline];

  @override
  Widget build(BuildContext context) {
    final chips = meta.where((m) => m.trim().isNotEmpty).toList();
    final deadlineColor = deadlineUrgent ? AppColors.error : AppColors.gray500;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.white,
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.white,
        child: InkWell(
          key: testKey,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Icon(icon ?? Ionicons.book_outline, size: 22, color: AppColors.blue),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
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
                        ],
                      ),
                    ),
                  ],
                ),
                if (chips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: 4,
                      children: [
                        for (var i = 0; i < chips.length; i++)
                          _MetaItem(icon: i < _metaIcons.length ? _metaIcons[i] : Ionicons.ellipse_outline, label: chips[i]),
                      ],
                    ),
                  ),
                if (matchLabel != null || deadlineLabel != null)
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
                              linkLabel,
                              style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Ionicons.arrow_forward, size: 13, color: AppColors.blue),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (applied)
                        const PillButton(label: 'Applied', icon: Ionicons.checkmark_circle, variant: PillVariant.secondary, full: false, compact: true, disabled: true, onPressed: null),
                    ],
                  ),
                ),
              ],
            ),
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
