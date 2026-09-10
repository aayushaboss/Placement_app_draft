import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Heading for a horizontal carousel row on the feeds — the section title in
/// blue, 16px to match the Profile section-card titles. No fill: the blue
/// colour alone (the only blue text on the feed) carries the "highlight",
/// without a band on every heading making a multi-carousel feed feel busy.
/// An optional count follows in grey.
class CarouselSectionHeading extends StatelessWidget {
  final String title;
  final int? count;

  const CarouselSectionHeading({super.key, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
                color: AppColors.blue,
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
    );
  }
}
