import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/career_dna.dart';
import '../../../state/app_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/back_chevron.dart';
import '../../../widgets/badges.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

const _confidenceLabels = {
  'high': 'High confidence',
  'moderate': 'Moderate confidence',
  'exploratory': 'Exploratory',
};

/// The final combined "Career DNA" synthesis — reachable only once all 5
/// levels are complete. Same locked-teaser/unlocked-full branch as the
/// per-level report screen (free teaser = top direction name only; the
/// ranked breakdown, roles, strengths/development areas and next-steps
/// roadmap are gated behind the same global `reportUnlocked` flag).
/// Level 5's own scoring isn't authored yet (Phase B) — until then this
/// renders a real, honest "still building the synthesis" state rather than
/// a fake result, once all 5 levels are actually complete.
class CareerDnaFinalReportScreen extends StatelessWidget {
  const CareerDnaFinalReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final profile = user?.careerDnaOrEmpty ?? const CareerDnaProfile();
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/career-dna'),
            const SizedBox(height: AppSpacing.lg),
            if (!profile.allLevelsComplete)
              _NotDoneYetCard(completed: profile.completedLevelCount)
            else if (profile.level5 == null)
              const _StillBuildingCard()
            else
              _SynthesisContent(result: profile.level5!, unlocked: profile.reportUnlocked),
          ],
        ),
      ),
    );
  }
}

class _NotDoneYetCard extends StatelessWidget {
  final int completed;
  const _NotDoneYetCard({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            const Icon(Ionicons.hourglass_outline, size: 36, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.md),
            Text('$completed of 5 levels complete', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold)),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('Finish every level to see your combined results.', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: PillButton(label: 'Back to levels', full: false, onPressed: () => context.go('/tabs/career-dna')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StillBuildingCard extends StatelessWidget {
  const _StillBuildingCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            const Icon(Ionicons.construct_outline, size: 36, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.md),
            Text("We're still putting your combined synthesis together.", textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          ],
        ),
      ),
    );
  }
}

class _SynthesisContent extends StatelessWidget {
  final CareerDnaLevel5Result result;
  final bool unlocked;
  const _SynthesisContent({required this.result, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final directions = unlocked ? result.topDirections : result.topDirections.take(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR FINAL RESULT', style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 12, letterSpacing: 1.4)),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(result.topDirections.first.name, style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 26, fontWeight: AppFontWeight.semibold)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(_confidenceLabels[result.confidenceTier] ?? '', style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Top Career Directions', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
        const SizedBox(height: AppSpacing.md),
        for (final d in directions)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
            child: Row(
              children: [
                Expanded(child: Text(d.name, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium))),
                Text('${d.fitPercent}%', style: AppTextStyles.h3.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.bold)),
              ],
            ),
          ),
        if (!unlocked)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Ionicons.lock_closed, size: 22, color: AppColors.blue),
                const SizedBox(height: AppSpacing.sm),
                Text('See all 5 directions, your top roles, and next steps', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
                  child: Text('Unlock your full report to see the complete picture.', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5)),
                ),
                PillButton(label: 'Unlock — ₹51', icon: Ionicons.lock_open_outline, onPressed: () => context.push('/college/career-dna/unlock')),
              ],
            ),
          )
        else ...[
          Text('Top Job Roles', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: result.topRoles.map((r) => AppTag(label: '${r.name} · ${r.fitPercent}%')).toList()),
          const SizedBox(height: AppSpacing.xl),
          Text('Your Career Strengths', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: result.careerStrengths.map((s) => AppTag(label: s, color: AppColors.success, bg: AppColors.successA10)).toList()),
          const SizedBox(height: AppSpacing.xl),
          Text('Growth Opportunities', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: result.developmentAreas.map((s) => AppTag(label: s, color: AppColors.gray500, bg: AppColors.offWhite)).toList()),
          const SizedBox(height: AppSpacing.xl),
          Text('Your Roadmap', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
            child: Column(
              children: [
                for (var i = 0; i < result.nextSteps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == result.nextSteps.length - 1 ? 0 : AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                          child: Text('${i + 1}', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.bold)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(result.nextSteps[i], style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
