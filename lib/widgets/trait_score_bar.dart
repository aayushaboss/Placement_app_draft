import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// A scannable "Energy: 62% Introverted"-style horizontal trait bar — the
/// 16Personalities reference layout. Genuinely new: no horizontal
/// percent-bar widget existed anywhere in this codebase before Career DNA
/// (the closest precedents, results_screen.dart's plain percent text and
/// InsightDonutCard's ring chart, don't cover this shape). Built entirely
/// from existing tokens — no new colors.
class TraitScoreBar extends StatelessWidget {
  final String label;
  final int percent; // 0-100
  final String? caption; // one-line interpretive note, never a bare percentage

  const TraitScoreBar({super.key, required this.label, required this.percent, this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
            ),
            Text('$percent%', style: AppTextStyles.bodyLg.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.bold)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 10,
              width: double.infinity,
              color: AppColors.offWhite,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (percent / 100).clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(color: AppColors.blue),
                ),
              ),
            ),
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(caption!, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
          ),
      ],
    );
  }
}
