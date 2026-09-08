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
import '../../../utils/no_orphan.dart';
import '../../../widgets/back_chevron.dart';
import '../../../widgets/badges.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';
import '../../../widgets/trait_score_bar.dart';

const _level1DimensionLabels = {
  'leadershipInitiative': 'Leadership & Initiative',
  'communicationConfidence': 'Communication & Confidence',
  'teamOrientation': 'Team Orientation',
  'adaptability': 'Adaptability',
  'decisionMaking': 'Decision Making',
  'problemSolving': 'Problem Solving',
  'learningAgility': 'Learning Agility',
  'resilience': 'Resilience',
  'socialOrientation': 'Social Orientation',
  'ambitionGrowth': 'Ambition & Growth',
};

/// Per-level report — one file, two render branches (locked teaser /
/// unlocked full), driven live by the single global `reportUnlocked` flag
/// rather than a second route, matching how results_screen.dart itself
/// branches loading-vs-loaded in one build(). Phase A wires real content
/// for Level 1 only; Levels 2-5 render a short "coming soon" placeholder
/// here until their own data files land (Phase B) — the screen shape
/// itself needs no change when they do.
class CareerDnaReportScreen extends StatelessWidget {
  final int level;
  const CareerDnaReportScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final profile = user?.careerDnaOrEmpty ?? const CareerDnaProfile();
    final unlocked = profile.reportUnlocked;
    final topInset = MediaQuery.of(context).padding.top;

    final level1 = level == 1 ? profile.level1 : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/career-dna'),
            const SizedBox(height: AppSpacing.lg),
            if (level1 == null)
              _NotReadyCard(level: level)
            else ...[
              _ArchetypeHero(name: level1.archetype.name, naturalStyle: level1.archetype.naturalStyle),
              const SizedBox(height: AppSpacing.xl),
              Text('Your Personality Scores', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              // Every trait bar is free — the paywall gates interpretation
              // (what your scores mean, what to do about them) not the raw
              // scores themselves, so the free report is genuinely
              // substantial (a full scannable scorecard) rather than a
              // 2-bar teaser with everything else locked away.
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                child: Column(
                  children: [
                    for (final entry in _topDimensions(level1.dimensionScores, 10))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: TraitScoreBar(
                          label: _level1DimensionLabels[entry.key] ?? entry.key,
                          percent: entry.value,
                        ),
                      ),
                  ],
                ),
              ),
              if (unlocked) ...[
                const SizedBox(height: AppSpacing.xl),
                _GrowthCard(title: level1.archetype.growthAreaTitle, text: level1.archetype.growthAreaText),
                const SizedBox(height: AppSpacing.xl),
                Text('Possible Career Environments', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: level1.archetype.environments.map((e) => AppTag(label: e)).toList(),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xl),
                _UnlockCard(onUnlock: () => context.push('/college/career-dna/unlock')),
              ],
              // Mirrors results_screen.dart's own "Retake test" link
              // exactly (same style, same "go straight to the quiz, skip
              // the intro" behavior) — re-submitting simply overwrites this
              // level's saved result, same as aptitude's retake already does.
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/college/career-dna/level/$level/quiz'),
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Text(
                      'Retake this level',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.gray400,
                        fontSize: 14,
                        fontWeight: AppFontWeight.medium,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, int>> _topDimensions(Map<String, int> scores, int count) {
    final entries = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(count).toList();
  }
}

class _ArchetypeHero extends StatelessWidget {
  final String name;
  final String naturalStyle;
  const _ArchetypeHero({required this.name, required this.naturalStyle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR RESULT', style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 12, letterSpacing: 1.4)),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(name.toUpperCase(), style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 28, fontWeight: AppFontWeight.semibold)),
          ),
          // This paragraph is now the home for the "detailed persona"
          // description — the strength words that used to render as a row
          // of chips below are woven into this prose instead (see
          // career_dna_level1_data.dart's naturalStyle strings).
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(noOrphan(naturalStyle), style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, fontSize: 14.5, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  final String title;
  final String text;
  const _GrowthCard({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Ionicons.trending_up, size: 20, color: AppColors.blue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Growth Opportunity — $title', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 14.5)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(noOrphan(text), style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final VoidCallback onUnlock;
  const _UnlockCard({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Ionicons.lock_closed, size: 22, color: AppColors.blue),
          const SizedBox(height: AppSpacing.sm),
          Text('See what your scores mean', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
            child: Text(
              noOrphan('Your growth opportunities, career environments, and your final combined result once all 5 levels are done — one payment unlocks all of it.'),
              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5, height: 1.4),
            ),
          ),
          PillButton(label: 'Unlock', icon: Ionicons.lock_open_outline, onPressed: onUnlock),
        ],
      ),
    );
  }
}

class _NotReadyCard extends StatelessWidget {
  final int level;
  const _NotReadyCard({required this.level});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            const Icon(Ionicons.hourglass_outline, size: 36, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.md),
            Text('This level isn\'t available yet.', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          ],
        ),
      ),
    );
  }
}
