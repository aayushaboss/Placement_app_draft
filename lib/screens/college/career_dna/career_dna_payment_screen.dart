import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../state/app_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../widgets/back_chevron.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

/// Level 5's payment unlocks the combined synthesis (directions/roles/
/// roadmap), so its included-items list reads differently from a plain
/// per-level trait report — every other level shares the same generic list.
const _level5Items = [
  'Your full combined career synthesis',
  'All 5 top career directions and job roles',
  'Your personalized next-steps roadmap',
];
List<String> _includedItemsFor(String title) => [
      'Full detailed report for $title',
      "Your complete trait breakdown, not just the top scores",
    ];

/// Mocked/simulated payment — no real gateway anywhere in this codebase
/// (confirmed via exploration), so this mirrors AppState.mockGoogleSignIn's
/// own idiom: a full pushed route (not a sheet, so the processing state can
/// cleanly use PopScope(canPop: false) like resume_builder_quiz_screen.dart's
/// _BuildingView already does), an artificial delay, and an always-succeeds
/// outcome via AppState.mockUnlockCareerDnaLevel(level). Each level (2-5)
/// is paid for individually — Level 1 never reaches this screen, it's free.
class CareerDnaPaymentScreen extends StatefulWidget {
  final int level;
  const CareerDnaPaymentScreen({super.key, required this.level});

  @override
  State<CareerDnaPaymentScreen> createState() => _CareerDnaPaymentScreenState();
}

class _CareerDnaPaymentScreenState extends State<CareerDnaPaymentScreen> {
  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();
    await context.read<AppState>().mockUnlockCareerDnaLevel(widget.level);
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    // Replaces this screen (not a push) so backing out of the now-unlocked
    // report page can't land the user back on a "Pay ₹51" button for
    // something they already paid for. Goes straight back to that same
    // level's own report route — now unlocked, it renders the ready-to-
    // download view directly (level 5 redirects to the final-report screen
    // from there, same as every other entry point into that route).
    context.pushReplacement('/college/career-dna/level/${widget.level}/report');
  }

  @override
  Widget build(BuildContext context) {
    final meta = careerDnaLevelMeta.firstWhere((m) => m.level == widget.level);
    final isFinal = widget.level == 5;
    final items = isFinal ? _level5Items : _includedItemsFor(meta.title);

    if (_processing) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.blue,
          body: ResponsiveBody(child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 3)),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Text('Processing your payment…', textAlign: TextAlign.center, style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: AppFontWeight.medium)),
                  ),
                ],
              ),
            ),
          )),
        ),
      );
    }

    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/career-dna'),
            const SizedBox(height: AppSpacing.lg),
            Text('Unlock your ${meta.title} report', style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                noOrphan(isFinal
                    ? 'A one-time payment unlocks your full combined Career DNA synthesis.'
                    : "A one-time payment unlocks this level's full report."),
                style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${meta.title} Report', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold))),
                        Text('₹51', style: AppTextStyles.h2.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.bold)),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(color: AppColors.border, height: 1)),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Ionicons.checkmark_circle, size: 16, color: AppColors.success),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(item, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 12, height: 1.35))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Ionicons.information_circle_outline, size: 16, color: AppColors.gray400),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      noOrphan('Demo payment — no real charge. This is a prototype build.'),
                      style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: PillButton(label: 'Pay ₹51', icon: Ionicons.card_outline, onPressed: _pay),
            ),
          ],
        ),
      ),
    );
  }
}
