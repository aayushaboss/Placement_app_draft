import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

/// The "you reached a success state" micro-interaction after finishing a
/// level — reuses booking_confirmed_screen.dart's exact elastic-scale
/// checkmark mechanism, staged into two beats: the checkmark lands first,
/// then the title + teaser fade/slide in ~150ms later.
class CareerDnaSuccessScreen extends StatefulWidget {
  final int level;
  const CareerDnaSuccessScreen({super.key, required this.level});

  @override
  State<CareerDnaSuccessScreen> createState() => _CareerDnaSuccessScreenState();
}

class _CareerDnaSuccessScreenState extends State<CareerDnaSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _checkScale = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _contentOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _contentSlide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CareerDnaLevelMeta get _meta => careerDnaLevelMeta.firstWhere((m) => m.level == widget.level);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isLastLevel = widget.level == 5;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: ResponsiveBody(child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _checkScale,
                          child: Container(
                            width: isLastLevel ? 130 : 110,
                            height: isLastLevel ? 130 : 110,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle, boxShadow: AppShadows.yellow),
                            child: Icon(isLastLevel ? Ionicons.trophy : Ionicons.checkmark, size: isLastLevel ? 62 : 56, color: AppColors.blue),
                          ),
                        ),
                        FadeTransition(
                          opacity: _contentOpacity,
                          child: SlideTransition(
                            position: _contentSlide,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                                  child: Text(
                                    'Level ${meta.level} complete!',
                                    style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 28, fontWeight: AppFontWeight.semibold),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    noOrphan(isLastLevel
                                        ? "You've finished the whole Career Quiz journey."
                                        : 'Nicely done — your ${meta.title} results are ready.'),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, fontSize: 15),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: AppSpacing.xxl),
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                        child: const Icon(Ionicons.document_text_outline, size: 18, color: AppColors.blue),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Your micro analysis is ready', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                widget.level < 5 ? 'Unlock the full detailed report anytime.' : 'Your final results are ready.',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, bottomInset + AppSpacing.lg),
                child: Column(
                  children: [
                    PillButton(
                      label: 'See your report',
                      onPressed: () {
                        context.go('/college/career-dna/level/${widget.level}/report');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PillButton(
                      label: isLastLevel ? 'Back to Career Quiz' : 'Back to levels',
                      variant: PillVariant.outlineWhite,
                      onPressed: () => context.go('/tabs/career-dna'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
