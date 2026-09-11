import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Heading for a horizontal carousel row on the feeds — plain black title,
/// 16px, an optional grey count following it. Carries its own top divider +
/// clearance (Swiggy-style "what's on your mind?" section break) so every
/// carousel on the feed reads as a clearly separate block from the one
/// above it, not just a heading floating directly above a card row. This is
/// the single place that gap/divider lives — callers should NOT also add
/// their own inter-section SizedBox before a carousel, or the gap doubles.
class CarouselSectionHeading extends StatelessWidget {
  final String title;
  final int? count;

  const CarouselSectionHeading({super.key, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: AppFontWeight.semibold,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '($count)',
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
