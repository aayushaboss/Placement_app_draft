import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../widgets/back_chevron.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

const _includedItems = [
  'Full detailed report for every level (1-5)',
  'Your complete trait breakdown, not just the top scores',
  'Your final combined results, synthesized across all 5 levels',
  'Top career directions and job roles matched to you',
];

/// Mocked/simulated payment — no real gateway anywhere in this codebase
/// (confirmed via exploration), so this mirrors AppState.mockGoogleSignIn's
/// own idiom: a full pushed route (not a sheet, so the processing state can
/// cleanly use PopScope(canPop: false) like resume_builder_quiz_screen.dart's
/// _BuildingView already does), an artificial delay, and an always-succeeds
/// outcome via AppState.mockUnlockCareerDnaReport().
class CareerDnaPaymentScreen extends StatefulWidget {
  const CareerDnaPaymentScreen({super.key});

  @override
  State<CareerDnaPaymentScreen> createState() => _CareerDnaPaymentScreenState();
}

class _CareerDnaPaymentScreenState extends State<CareerDnaPaymentScreen> {
  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();
    await context.read<AppState>().mockUnlockCareerDnaReport();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Unlock your full report', style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                noOrphan('A one-time payment unlocks your complete Career Quiz results.'),
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
                        Text('Full Career Quiz Report', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold)),
                        Text('₹51', style: AppTextStyles.h2.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.bold)),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(color: AppColors.border, height: 1)),
                    for (final item in _includedItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Ionicons.checkmark_circle, size: 16, color: AppColors.success),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(item, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5, height: 1.35))),
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
