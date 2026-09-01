import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/opportunity.dart';
import '../models/opportunity_match.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'opportunity_carousel_card.dart';

/// One horizontally-scrolling "topic" row on the browse feed — title, a
/// count, a "View all" link, then a fixed-height ListView of
/// [OpportunityCarouselCard]s. Naukri-style browse-by-topic instead of one
/// long vertical scroll, which stops working once there are more than a
/// screenful of postings.
class OpportunityCarouselSection extends StatelessWidget {
  final String title;
  final List<Opportunity> opportunities;
  final VoidCallback? onViewAll;
  final String? Function(Opportunity) matchLabel;
  final bool Function(Opportunity) isApplied;
  final void Function(Opportunity) onTapCard;
  final void Function(Opportunity) onApply;

  const OpportunityCarouselSection({
    super.key,
    required this.title,
    required this.opportunities,
    required this.matchLabel,
    required this.isApplied,
    required this.onTapCard,
    required this.onApply,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) return const SizedBox.shrink();

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.ink,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '  (${opportunities.length})',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.gray400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onViewAll,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.blue,
                            fontSize: 13,
                            fontWeight: AppFontWeight.medium,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Ionicons.chevron_forward,
                          size: 14,
                          color: AppColors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
              itemCount: opportunities.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final o = opportunities[i];
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
                  onTap: () => onTapCard(o),
                  onApply: () => onApply(o),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
