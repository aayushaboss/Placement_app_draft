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
import '../../../utils/scroll_to_top_registry.dart';
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

// Alternating horizontal position per node (center/right/center-left/left/
// center-right) — the zigzag is what reads as "a path to walk," per the
// Duolingo-style reference, without needing a literal drawn connector line.
const _pathXAlign = [0.0, 0.55, -0.2, -0.55, 0.2];

/// Landing / level-map screen — the tab root for the 6th branch
/// (`/tabs/career-dna`). A Duolingo-style path: a header banner naming only
/// the ONE level currently being worked on (not a repeated list of every
/// level's own title), then a vertical zigzag of 5 circular nodes standing
/// in for the old flat list of level cards.
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
    // A completed level's node opens straight to its report — routing
    // through the intro screen again would only ever offer "Start Level N"
    // there, reading as an invitation to retake it rather than review what
    // was already earned. (A genuine retake is still one tap away from the
    // report screen itself.)
    context.push(completed ? '/college/career-dna/level/$level/report' : '/college/career-dna/level/$level/intro');
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
    final allComplete = profile.allLevelsComplete;
    // The one level the header banner names — the first not-yet-completed
    // one (which, by sequential unlocking, is always the unlocked one to
    // work on next). Mirrors Duolingo's own "just the current unit" header,
    // rather than repeating every level's full title on screen at once.
    final currentMeta = allComplete ? null : careerDnaLevelMeta.firstWhere((m) => !_isLevelComplete(profile, m.level));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentMeta != null) ...[
                    Text('LEVEL ${currentMeta.level}', style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 13, fontWeight: AppFontWeight.medium, letterSpacing: 1.4)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(currentMeta.title, style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 26, fontWeight: AppFontWeight.semibold)),
                    ),
                  ] else ...[
                    Text('CAREER QUIZ', style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 13, fontWeight: AppFontWeight.medium, letterSpacing: 1.4)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text('All 5 levels complete!', style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 26, fontWeight: AppFontWeight.semibold)),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _introChips
                            .map((c) => Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(right: c == _introChips.last ? 0 : AppSpacing.sm),
                                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
                                    decoration: BoxDecoration(color: AppColors.whiteA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(c.icon, size: 18, color: AppColors.white),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          c.text,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.caption.copyWith(color: AppColors.white, fontSize: 11, fontWeight: AppFontWeight.medium),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Generous vertical rhythm between nodes (xxxl, not the old
            // list's tight md gaps) is what makes this read as "spacious"
            // rather than a dense list — the zigzag alignment does the rest.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxl, AppSpacing.xl, 0),
              child: Column(
                children: [
                  for (final meta in careerDnaLevelMeta)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                      child: _PathNode(
                        meta: meta,
                        xAlign: _pathXAlign[(meta.level - 1) % _pathXAlign.length],
                        unlocked: user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1),
                        completed: _isLevelComplete(profile, meta.level),
                        isCurrent: currentMeta?.level == meta.level,
                        onTap: () => _openLevel(
                          context,
                          meta.level,
                          user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1),
                          _isLevelComplete(profile, meta.level),
                        ),
                      ),
                    ),
                  if (allComplete)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: GestureDetector(
                        onTap: () => context.push('/college/career-dna/final-report'),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
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
          ],
        ),
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  final CareerDnaLevelMeta meta;
  final double xAlign;
  final bool unlocked;
  final bool completed;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PathNode({
    required this.meta,
    required this.xAlign,
    required this.unlocked,
    required this.completed,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !unlocked;
    final size = isCurrent ? 68.0 : 56.0;

    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? AppColors.success : (locked ? AppColors.gray100 : AppColors.blue),
        shape: BoxShape.circle,
        boxShadow: locked ? null : AppShadows.card,
      ),
      child: Icon(
        completed ? Ionicons.checkmark : (locked ? Ionicons.lock_closed : Ionicons.star),
        size: isCurrent ? 30 : 24,
        color: locked ? AppColors.gray400 : (completed ? AppColors.white : AppColors.yellow),
      ),
    );

    // Current level's node gets a lighter ring around it (target-style,
    // matching the reference) so it visually reads as "you are here"
    // without needing a separate label every time.
    if (isCurrent) {
      circle = Container(
        width: size + 14,
        height: size + 14,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
        child: circle,
      );
    }

    return Align(
      alignment: Alignment(xAlign, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: locked ? 0.5 : 1.0,
          child: Column(
            children: [
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text('START', style: AppTextStyles.label.copyWith(color: AppColors.ink, fontSize: 11, fontWeight: AppFontWeight.bold, letterSpacing: 0.6)),
                ),
              circle,
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Level ${meta.level}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
