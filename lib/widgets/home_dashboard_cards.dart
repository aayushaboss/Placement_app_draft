import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../mockData/mock_profile_activity.dart';
import '../models/profile_readiness.dart';
import '../models/user.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/no_orphan.dart';
import 'auto_carousel.dart';
import 'badges.dart';
import 'progress_ring.dart';

/// Naukri-style top-of-home strip: three stat cards (profile status, search
/// appearances, recruiter actions), then one prioritized "boost your
/// profile" tip — the single most useful missing thing, not a wall of
/// suggestions at once.
///
/// Cards deliberately reuse the exact shell and Row(leading box + tag +
/// bold line + caption) layout of the school flow's "Resources for you"
/// article cards — same AppSpacing.sm padding, concentric outer radius
/// (AppRadius.md + AppSpacing.sm) + soft shadow, same leading-visual-then-text shape, stacked full-width instead
/// of a narrow horizontal carousel — just with a stat instead of a photo
/// and an article. One card family, not two competing looks.
class HomeDashboardCards extends StatelessWidget {
  final User? user;
  const HomeDashboardCards({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    final u = user!;
    // Same source the detail screens read — a card promising "14 search
    // appearances" that opens a screen showing a different number would be
    // exactly the kind of surface-level mismatch this was meant to fix.
    final searchAppearances = searchAppearancesFor(u).fold<int>(0, (a, b) => a + b.count);
    final recruiterActions = recruiterActionsFor(u).length;
    final percent = u.profileProgressPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Matches _DashboardCard's own fixed height (112) — that fits its
        // content column at the worst case (tag + 2-line title + 2-line
        // meta), not just the 84px leading visual. Plus AppShadows.cardBuffer
        // on each side — enough for AppShadows.card's blur to clear without
        // a hard clip, without being more buffer than the shadow actually
        // needs (an earlier AppSpacing.xxl/26 was, and read as dead space
        // above every card).
        //
        // The usual AppSpacing.xl (20) horizontal inset from the screen edge
        // is split between this outer Padding (AppSpacing.sm/6) and the
        // ListView's own leading/trailing content padding (AppSpacing.lg/14
        // below) instead of living entirely out here — a ListView clips its
        // children to its own box regardless of how much room an outer
        // Padding leaves around it, so with no padding of its own the first/
        // last card's shadow (which needs ~12px of clearance left/right,
        // same math as cardBuffer but for AppShadows.card's blurRadius with
        // zero x-offset) got hard-clipped at that edge. sm+lg still sums to
        // the same 20 total inset — same pattern already proven correct in
        // opportunity_carousel_section.dart's lane.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: SizedBox(
            height: 112 + AppShadows.cardBuffer * 2,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppShadows.cardBuffer, AppSpacing.lg, AppShadows.cardBuffer),
              scrollDirection: Axis.horizontal,
              children: [
                _DashboardCard(
                  // Always the Profile tab — that's where the completion
                  // dial + full checklist live now, so this is one stable
                  // destination regardless of what's missing, instead of a
                  // hidden jump to whichever item happened to be first.
                  onTap: () => context.go('/tabs/profile'),
                  leading: _LeadingVisual(child: ProgressRing(percent: percent)),
                  tag: 'Profile',
                  title: '$percent% complete',
                  meta: noOrphan('${u.profileCompletedCount}/${u.profileTotalCount} sections done · Tap to finish'),
                ),
                const SizedBox(width: AppSpacing.md),
                _DashboardCard(
                  onTap: () => context.push('/search-appearances'),
                  leading: const _LeadingVisual(child: Icon(Ionicons.eye_outline, size: 28, color: AppColors.blue)),
                  tag: 'Visibility',
                  title: '$searchAppearances searches',
                  meta: 'Last 14 days',
                ),
                const SizedBox(width: AppSpacing.md),
                _DashboardCard(
                  onTap: () => context.push('/recruiter-actions'),
                  leading: const _LeadingVisual(child: Icon(Ionicons.people_outline, size: 28, color: AppColors.blue)),
                  tag: 'Recruiters',
                  title: noOrphan('$recruiterActions recruiter actions'),
                  meta: 'Profile views',
                ),
              ],
            ),
          ),
        ),
        _BoostSection(user: u),
      ],
    );
  }
}

/// 84x84, radius 12 — the same footprint the article-card thumbnail image
/// occupies, just holding a tinted icon/ring instead of a photo.
class _LeadingVisual extends StatelessWidget {
  final Widget child;
  const _LeadingVisual({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: child,
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget leading;
  final String tag;
  final String title;
  final String meta;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.leading,
    required this.tag,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
        child: Container(
          width: 268,
          // Fixed, not content-driven — every card in the row gets the
          // exact same footprint regardless of whether its title happens
          // to wrap to 1 or 2 lines, so they read as one consistent family
          // instead of each shaped by its own content. Any leftover room
          // on a shorter card just sits as trailing space below the meta
          // line, not wedged between the title and meta themselves (which
          // is what a fixed-height *title* box did instead — technically
          // aligned the meta row across cards, but at the cost of a big
          // dead gap under any one-line title).
          height: 112,
          // Uniform on all 4 sides — was previously lg/sm/sm/sm (left
          // bigger than the rest) on the theory that centering the 84-tall
          // leading icon in a 100-tall row already left lg of clearance
          // above/below it, so a matching lg on the left would make all
          // three visually equal. That math was off (the real clearance
          // was 8, not lg's 14), which is exactly why the left inset still
          // read as noticeably wider than top/right/bottom. A single
          // padding value removes the guesswork entirely.
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            // .start, not the default .center — centering both children
            // against the row's full height meant the icon (a fixed 84x84
            // box) always looked right, but the text column's top offset
            // shifted card to card depending on whether its 1- or 2-line
            // meta made the whole block taller or shorter. Pinning both to
            // the top instead — with no per-child offset on either one —
            // means leading and the text column start from the exact same
            // y, which is just the card's own uniform padding above, on
            // every card, with nothing to keep in sync between them.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTag(label: tag),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.bold, height: 1.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One resolved nudge — message + how to act on it. [checklistId] is the
/// underlying `profileChecklist` item id when this came from that list
/// (null for the hardcoded photo case), so `_BoostSection` can tell whether
/// this nudge is *already* the resume prompt before deciding whether to add
/// a second, separate resume card next to it (see `_BoostSection`).
typedef _BoostTipData = ({String message, String cta, String route, IconData icon, String? checklistId});

// Icon per profileChecklist item id — matches the icon already assigned to
// that same section's row on the Profile tab, so the nudge and the
// checklist read as one consistent system.
const _boostIcons = {
  'resume': Ionicons.document_text_outline,
  'goals': Ionicons.flag_outline,
  'employment': Ionicons.briefcase_outline,
  'languages': Ionicons.globe_outline,
  'itSkills': Ionicons.code_slash_outline,
  'video': Ionicons.videocam_outline,
  'preferences': Ionicons.options_outline,
};

/// The single most useful missing profile thing — a photo beats a generic
/// nudge, since it's the one line item Naukri's own reference screenshot
/// led with ("Build trust among recruiters by adding a photo"). Null means
/// there's genuinely nothing left to nudge about.
_BoostTipData? _resolveBoostTip(User user) {
  if (!user.hasPhoto) {
    // Not a profileChecklist item (no Profile-tab row of its own — it's
    // edited inline inside Basic details), so it stays a hardcoded
    // first-priority nudge rather than coming from the checklist below.
    return (
      message: 'Build trust among recruiters by adding a photo.',
      cta: 'Add photo',
      route: '/profile-edit',
      icon: Ionicons.camera,
      checklistId: null,
    );
  }
  // Driven by the same profileChecklist the Profile tab's dial reads —
  // previously this was its own separate hasResume/else-languages chain,
  // which meant an already-complete profile still got told to "Add
  // languages" forever. 'basic' is excluded since it's already covered by
  // the apply-gate sheet if it's ever truly incomplete.
  final missing = user.profileChecklist.where((i) => !i.done && i.id != 'basic').toList();
  if (missing.isEmpty) return null;
  final item = missing.first;
  return (
    message: item.subtitle,
    cta: 'Add ${item.title.toLowerCase()}',
    route: item.route,
    icon: _boostIcons[item.id] ?? Ionicons.add_circle_outline,
    checklistId: item.id,
  );
}

/// Decides what the boost-nudge area actually shows: nothing, one static
/// card, or an auto-swiping two-card carousel — never two cards that say
/// almost the same thing. A resume card only gets added alongside the
/// resolved tip when that tip *isn't itself* already the resume prompt
/// (i.e. `_resolveBoostTip` already surfaced resume as the top missing
/// checklist item) — otherwise a user with a photo but no resume would see
/// "Paste or build your resume" and "No resume yet? Build one from scratch
/// here." side by side, which reads as a bug, not a feature.
class _BoostSection extends StatelessWidget {
  final User user;
  const _BoostSection({required this.user});

  static const _resumeTip = (
    message: 'No resume yet? Build one from scratch here.',
    cta: 'Build resume',
    route: '/college/resume',
    icon: Ionicons.document_text_outline,
  );

  @override
  Widget build(BuildContext context) {
    final tip = _resolveBoostTip(user);
    final showResumeCard = !user.hasResume && tip?.checklistId != 'resume';

    if (tip == null && !showResumeCard) return const SizedBox.shrink();

    if (!showResumeCard) {
      // tip is non-null here: the only way to reach !showResumeCard with a
      // null tip would require hasResume to already be true (resume is a
      // requiredForApply checklist item, so an empty `missing` list implies
      // it's done) — which makes showResumeCard false regardless, so this
      // branch is only ever taken with tip != null.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: _BoostTipCard(message: tip!.message, cta: tip.cta, route: tip.route, icon: tip.icon),
      );
    }

    final resumeCard = _BoostTipCard(message: _resumeTip.message, cta: _resumeTip.cta, route: _resumeTip.route, icon: _resumeTip.icon);
    if (tip == null) return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl), child: resumeCard);

    return AutoCarousel(
      height: 80,
      cards: [
        _BoostTipCard(message: tip.message, cta: tip.cta, route: tip.route, icon: tip.icon),
        resumeCard,
      ],
    );
  }
}

/// Pure presentational nudge card — tinted box, one line of copy, a
/// circular icon-button on the right that navigates on tap. Used standalone
/// when only one nudge applies, or as a `PageView` child inside
/// `_BoostCarousel` when two do.
class _BoostTipCard extends StatelessWidget {
  final String message;
  final String cta;
  final String route;
  final IconData icon;
  const _BoostTipCard({required this.message, required this.cta, required this.route, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.blueA10,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              noOrphan(message),
              style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.medium, height: 1.3),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Icon-only, not a text pill — this exact solid-blue pill button
          // style wasn't reused anywhere else in the app, so an icon
          // carries the action fine given the message text right next to
          // it already spells it out. Semantics keeps the original label
          // available to screen readers even though it's no longer painted.
          //
          // Solid blue fill, white icon — reverted back to this per direct
          // feedback after a brief attempt at a white/blue-ring treatment
          // (meant to avoid reading as an already-selected AppChip). The
          // icon glyph itself never changed across this app's whole build
          // history; only this fill/color choice did, and the original is
          // preferred.
          Semantics(
            button: true,
            label: cta,
            child: GestureDetector(
              onTap: () => context.push(route),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

