import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../widgets/back_chevron.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

class _MetaItem {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});
}

/// Per-level intro — mirrors aptitude_intro_screen.dart's meta-chip row, but
/// deliberately shorter than the landing screen's own 3-bullet intro (that
/// fuller reassurance is shown once, there) — this carries only the one
/// level-specific "no right or wrong answers" line plus what this level
/// measures, so it reads as level-specific framing, not a repeated block.
class CareerDnaLevelIntroScreen extends StatelessWidget {
  final int level;
  const CareerDnaLevelIntroScreen({super.key, required this.level});

  CareerDnaLevelMeta get _meta => careerDnaLevelMeta.firstWhere((m) => m.level == level);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final metaChips = [
      _MetaItem(icon: Ionicons.time_outline, label: meta.estTime),
      _MetaItem(icon: Ionicons.help_circle_outline, label: '${meta.questionCount} questions'),
      const _MetaItem(icon: Ionicons.gift_outline, label: 'Micro analysis'),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: ResponsiveBody(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackChevron(fallbackRoute: '/tabs/career-dna'),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      height: AppSpacing.xxxl * 4 + AppSpacing.sm,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.whiteA10, borderRadius: BorderRadius.circular(AppRadius.xl)),
                      child: Icon(meta.icon, size: 72, color: AppColors.yellow),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: Text(
                        'Level ${meta.level}',
                        style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 13, fontWeight: AppFontWeight.medium, letterSpacing: 1.4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        meta.title,
                        style: AppTextStyles.h1.copyWith(color: AppColors.white, height: 1.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        noOrphan(meta.whatThisMeasures),
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, height: 1.4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(color: AppColors.whiteA10, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Text(
                          noOrphan(meta.noRightWrongCopy),
                          style: AppTextStyles.body.copyWith(color: AppColors.white, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxl),
                      child: Row(
                        children: metaChips
                            .map(
                              (m) => Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(right: m == metaChips.last ? 0 : AppSpacing.md),
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xs),
                                  decoration: BoxDecoration(color: AppColors.whiteA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
                                  child: Column(
                                    children: [
                                      Icon(m.icon, size: 20, color: AppColors.white),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        m.label,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.label.copyWith(color: AppColors.white, fontWeight: AppFontWeight.medium),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.lg),
              child: PillButton(
                label: 'Start Level ${meta.level}',
                icon: Ionicons.play,
                onPressed: () => context.push('/college/career-dna/level/${meta.level}/quiz'),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
