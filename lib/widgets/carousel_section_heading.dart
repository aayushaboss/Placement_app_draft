import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Heading for a horizontal carousel row on the feeds — the section title in
/// all-caps, blue on a soft blue wash (the same colour language as the
/// status badges), but sized like a section heading (16px, matching the
/// Profile section-card titles) and only lightly squared so it reads as a
/// highlighted section marker, not a pill badge. An optional count follows
/// in plain grey.
class CarouselSectionHeading extends StatelessWidget {
  final String title;
  final int? count;

  const CarouselSectionHeading({super.key, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blueA10,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.blue,
                  fontSize: 16,
                  fontWeight: AppFontWeight.semibold,
                  letterSpacing: 0.4,
                ),
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
