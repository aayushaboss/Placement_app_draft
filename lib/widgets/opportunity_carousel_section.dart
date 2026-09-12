import 'package:flutter/material.dart';

import '../models/opportunity.dart';
import '../models/opportunity_match.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import 'carousel_section_heading.dart';
import 'opportunity_carousel_card.dart';

/// One horizontally-scrolling "topic" row on the browse feed — title, a
/// count, then a fixed-height ListView of [OpportunityCarouselCard]s.
/// Naukri-style browse-by-topic instead of one long vertical scroll, which
/// stops working once there are more than a screenful of postings.
/// [onViewAll] is unused — kept as a no-op accepted param so existing call
/// sites don't need to change; there's no "View all" affordance any more.
class OpportunityCarouselSection extends StatelessWidget {
  final String title;
  final List<Opportunity> opportunities;
  final VoidCallback? onViewAll;
  final String? Function(Opportunity) matchLabel;
  final bool Function(Opportunity) isApplied;
  final void Function(Opportunity) onTapCard;
  final void Function(Opportunity) onApply;
  final bool Function(Opportunity)? isSaved;
  final void Function(Opportunity)? onToggleSave;

  const OpportunityCarouselSection({
    super.key,
    required this.title,
    required this.opportunities,
    required this.matchLabel,
    required this.isApplied,
    required this.onTapCard,
    required this.onApply,
    this.onViewAll,
    this.isSaved,
    this.onToggleSave,
  });

  /// Cards shown in this lane — the rest are reachable via the full list
  /// screen (see onTapCard's caller for that route).
  static const _visibleCap = 5;

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) return const SizedBox.shrink();

    final visible = opportunities.take(_visibleCap).toList();

    // No outer bottom padding — the carousel's own bottom shadow buffer
    // (AppSpacing.xxl, from the Row's vertical padding below) already
    // supplies the gap to whatever comes next. This section used to add
    // AppSpacing.xl on top of that too, stacking to a ~46px gap between
    // one carousel and the next — more than double every other
    // section-to-section gap on the screen once title-to-card and other
    // spots were tightened to the same "buffer alone is the gap" rule.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSectionHeading(title: title, count: opportunities.length),
        // No explicit gap here — the carousel's own top padding below is
        // the gap, and it's also the shadow-safety buffer for
        // AppShadows.card (see AppShadows.cardBuffer).
        //
        // The outer AppSpacing.xl margin is deliberately split between
        // this outer Padding (AppSpacing.sm) and the ListView's own
        // start/end content padding (AppSpacing.lg) rather than living
        // entirely on one side, the way the vertical buffer does — an
        // outer-only margin narrows the ListView's viewport so its
        // edge-clip lines up with the first/last card's own edge with
        // zero room to spare, which is fine for AppShadows.card's subtle
        // 10%-alpha blur but visibly hard-cuts the "Apply" button's
        // AppShadows.yellow shadow (40% alpha, so its tail is still
        // plainly visible at the same nominal blurRadius distance that
        // fully hid the card shadow's tail). Splitting it keeps the first
        // card's visible position unchanged (sm + lg == the old xl) while
        // giving the ListView's own content padding room for that
        // brighter shadow to actually fade before the clip.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: SizedBox(
            height: 222 + AppShadows.cardBuffer * 2,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppShadows.cardBuffer, AppSpacing.lg, AppShadows.cardBuffer),
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final o = visible[i];
                final applied = isApplied(o);
                return OpportunityCarouselCard(
                  title: o.title,
                  company: o.company,
                  location: o.location,
                  stipend: o.stipend,
                  matchLabel: applied ? null : matchLabel(o),
                  deadlineLabel: applied ? null : o.deadlineLabel,
                  deadlineUrgent: o.deadlineIsUrgent,
                  applied: applied,
                  saved: isSaved?.call(o) ?? false,
                  onTap: () => onTapCard(o),
                  onApply: () => onApply(o),
                  onToggleSave: onToggleSave == null ? null : () => onToggleSave!(o),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
