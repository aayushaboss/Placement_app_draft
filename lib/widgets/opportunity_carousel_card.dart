import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/opportunity_match.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'badges.dart';
import 'company_mark.dart';
import 'pill_button.dart';

/// Fixed-width job card for a horizontal carousel row — the same
/// information as [OpportunityRow] (role, company, location, stipend,
/// urgency), just reflowed for a Naukri-style "scroll sideways within a
/// topic" browse pattern instead of one long vertical feed.
///
/// [height] is fixed (carousel cards in one row need to line up), but
/// unlike the old design this no longer uses a `Spacer` to push the button
/// to the bottom — every card always renders the same four blocks (header /
/// meta / one status chip / CTA), so natural content height is already
/// consistent card to card. The one status chip is exactly one of: the
/// applied badge, the match/deadline chips, or (when neither applies) the
/// opportunity's own type as a neutral fallback — never blank space.
///
/// What actually keeps every card's button at the same y-position isn't the
/// fixed [height] alone — it's [_titleHeight] reserving identical space for
/// a 1-line and a 2-line title, so everything below it (divider, meta,
/// chip, button) starts at the same offset regardless of title length. A
/// `Spacer` would "fix" alignment too, but it's exactly the mechanism the
/// previous version of this card used to hide the real bug (an applied
/// card with no chips just grew empty space instead of shrinking) — not
/// bringing that back.
class OpportunityCarouselCard extends StatelessWidget {
  static const double width = 250;

  // Real headroom, not a tight fit — this card's own history already
  // learned this lesson once (height bumped 222 → 262 → 290 after the
  // 2-line-title + tags-row combination kept overflowing a "just barely
  // fits" budget). Computed baseline is ~206 (padding 16×2 + header 56 +
  // divider 17 + meta 18 + chip row ~23 + button 44, with 8dp gaps between
  // blocks); this leaves comfortable slack above that instead of repeating
  // the same near-miss.
  static const double height = 240;

  // 2 lines at the title's own 15px/1.25 line-height (≈18.75px/line) —
  // reserved unconditionally so a 1-line title leaves identical space
  // below it as a 2-line one, which is what actually aligns every card's
  // button in the same row (see the class doc comment above).
  static const double _titleHeight = 38;

  final String title;
  final String company;
  final String location;
  final String stipend;
  final String? matchLabel;
  final String? deadlineLabel;
  final bool deadlineUrgent;
  final bool applied;
  final bool saved;

  /// Fallback status-chip text (e.g. "Internship") shown when there's no
  /// match score, no deadline, and it isn't applied.
  final String? tag;

  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSave;

  const OpportunityCarouselCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.stipend,
    this.matchLabel,
    this.deadlineLabel,
    this.deadlineUrgent = false,
    this.applied = false,
    this.saved = false,
    this.tag,
    this.onTap,
    this.onApply,
    this.onToggleSave,
  });

  Widget _statusChip() {
    if (applied) {
      return const AppTag(label: 'Applied', icon: Ionicons.checkmark_circle, color: AppColors.blue, bg: AppColors.blueA10, compact: true);
    }
    final chips = <Widget>[
      if (matchLabel != null)
        Tooltip(
          message: matchExplanation,
          triggerMode: TooltipTriggerMode.tap,
          child: AppTag(label: matchLabel!, color: AppColors.blue, bg: AppColors.blueA10, icon: Ionicons.information_circle_outline, compact: true),
        ),
      if (deadlineLabel != null)
        AppTag(
          label: deadlineLabel!,
          color: deadlineUrgent ? AppColors.error : AppColors.gray500,
          bg: deadlineUrgent ? AppColors.errorA10 : AppColors.gray500A15,
          compact: true,
        ),
    ];
    if (chips.isEmpty && tag != null && tag!.isNotEmpty) {
      chips.add(AppTag(label: tag!, color: AppColors.gray500, bg: AppColors.gray500A15, compact: true));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: chips);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title, $company',
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          // Visible on keyboard focus — see opportunity_row.dart's own note.
          focusColor: AppColors.blueA10,
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanyMark(company: company, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: _titleHeight,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 15, height: 1.25),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onToggleSave != null)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onToggleSave,
                          child: Icon(
                            saved ? Ionicons.bookmark : Ionicons.bookmark_outline,
                            size: 20,
                            color: saved ? AppColors.blue : AppColors.gray400,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                Row(
                    children: [
                      const Icon(Ionicons.location_outline, size: 14, color: AppColors.gray500),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        stipend,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.semibold),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _statusChip(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: applied
                      ? const PillButton(
                          label: 'Applied',
                          icon: Ionicons.checkmark_circle,
                          variant: PillVariant.secondary,
                          disabled: true,
                          onPressed: null,
                        )
                      : PillButton(label: 'Apply', variant: PillVariant.secondary, onPressed: onApply),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
