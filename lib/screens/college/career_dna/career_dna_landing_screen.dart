import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../models/career_dna.dart';
import '../../../models/user.dart';
import '../../../state/app_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../utils/scroll_to_top_registry.dart';
import '../../../widgets/progress_ring.dart';
import '../../../widgets/responsive_body.dart';

class _IntroChip {
  final IconData icon;
  final String text;
  const _IntroChip({required this.icon, required this.text});
}

// Short fragments, not sentences — per direct feedback that the original
// full-sentence bullets read as too much to read before even starting.
const _introChips = [
  _IntroChip(icon: Ionicons.happy_outline, text: 'No wrong answers'),
  _IntroChip(icon: Ionicons.briefcase_outline, text: 'Jobs that fit you'),
  _IntroChip(icon: Ionicons.compass_outline, text: 'Real career clarity'),
];

/// Landing / level-map screen — the tab root for the 6th branch
/// (`/tabs/career-dna`). Shown once at the start of the whole journey (the
/// 3 reassuring bullets below), then doubles as the level map on every
/// later visit — 5 level cards, locked ones dimmed and non-tappable.
class CareerDnaLandingScreen extends StatefulWidget {
  const CareerDnaLandingScreen({super.key});

  @override
  State<CareerDnaLandingScreen> createState() => _CareerDnaLandingScreenState();
}

class _CareerDnaLandingScreenState extends State<CareerDnaLandingScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Branch index 5 (Career Quiz) — see router.dart's StatefulShellRoute.
    ScrollToTopRegistry.register(5, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(5);
    _scrollController.dispose();
    super.dispose();
  }

  void _openLevel(BuildContext context, int level, bool unlocked, bool completed) {
    if (!unlocked) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.selectionClick();
    // A completed level's card opens straight to its report — routing
    // through the intro screen again would only ever offer "Start Level N"
    // there, reading as an invitation to retake it rather than review what
    // was already earned.
    context.push(completed ? '/college/career-dna/level/$level/report' : '/college/career-dna/level/$level/intro');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;

    // This whole feature is college-only. The tab is already hidden for a
    // school account (tabs_scaffold.dart), but nothing else stops a stale
    // deep link from reaching this route directly — bounce back to Home
    // rather than rendering a screen built for a segment that has no
    // Career DNA data at all.
    if (user?.segment == Segment.school) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/tabs');
      });
      return const SizedBox.shrink();
    }

    final profile = user?.careerDnaOrEmpty ?? const CareerDnaProfile();
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            // A big badge-style icon reads as "the start of something," the
            // way a game's own title screen does — the old version went
            // straight from a plain text title into a paragraph of bullets,
            // which read as a page to read rather than something to begin.
            Center(
              child: Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle, boxShadow: AppShadows.card),
                child: const Icon(Ionicons.rocket, size: 38, color: AppColors.yellow),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Career Quiz', style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            noOrphan('Discover what fits you.'),
                            style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ProgressRing(percent: (profile.completedLevelCount * 100 / 5).round(), size: 52),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Row(
                children: _introChips
                    .map((c) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: c == _introChips.last ? 0 : AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
                            decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
                            child: Column(
                              children: [
                                Icon(c.icon, size: 18, color: AppColors.blue),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  c.text,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 11, fontWeight: AppFontWeight.medium),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
              child: Text('5 Levels to Unlock', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
            ),
            for (final meta in careerDnaLevelMeta)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _LevelCard(
                  meta: meta,
                  unlocked: user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1),
                  completed: _isLevelComplete(profile, meta.level),
                  onTap: () => _openLevel(
                    context,
                    meta.level,
                    user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1),
                    _isLevelComplete(profile, meta.level),
                  ),
                ),
              ),
            if (profile.allLevelsComplete)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => context.push('/college/career-dna/final-report'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        const Icon(Ionicons.star, size: 22, color: AppColors.yellow),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('See your full results', style: AppTextStyles.bodyLg.copyWith(color: AppColors.white, fontWeight: AppFontWeight.semibold)),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Every level, combined into one result.', style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.whiteA70),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isLevelComplete(CareerDnaProfile p, int level) {
    switch (level) {
      case 1:
        return p.level1 != null;
      case 2:
        return p.level2 != null;
      case 3:
        return p.level3 != null;
      case 4:
        return p.level4 != null;
      case 5:
        return p.level5 != null;
      default:
        return false;
    }
  }
}

class _LevelCard extends StatelessWidget {
  final CareerDnaLevelMeta meta;
  final bool unlocked;
  final bool completed;
  final VoidCallback onTap;

  const _LevelCard({required this.meta, required this.unlocked, required this.completed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dimmed = !unlocked;
    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: dimmed ? AppShadows.soft : AppShadows.card),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completed ? AppColors.successA10 : AppColors.blueA10,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed ? Ionicons.checkmark : (dimmed ? Ionicons.lock_closed_outline : meta.icon),
                  size: 20,
                  color: completed ? AppColors.success : AppColors.blue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level ${meta.level} · ${meta.title}',
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 14.5, fontWeight: AppFontWeight.medium),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        completed ? 'Completed' : (dimmed ? 'Complete Level ${meta.level - 1} to unlock' : '${meta.questionCount} questions · ${meta.estTime}'),
                        style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (!dimmed) const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}
