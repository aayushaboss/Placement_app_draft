import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../mockData/career_dna/career_dna_level1_data.dart';
import '../../../mockData/career_dna/career_dna_level2_data.dart';
import '../../../mockData/career_dna/career_dna_level3_data.dart';
import '../../../mockData/career_dna/career_dna_level4_data.dart';
import '../../../models/career_dna.dart';
import '../../../models/user.dart';
import '../../../services/career_dna_report_pdf.dart';
import '../../../state/app_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../widgets/back_chevron.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

/// Everything the shared render below needs, computed once per level from
/// that level's own (very differently-shaped) result object — Level 1 is
/// an archetype, Level 2 an interest headline, Level 3 a social profile,
/// Level 4 a workplace readiness read. Same screen shape for all four:
/// hero (name + opening sentence) → free narrative snapshot → (unlocked)
/// second paragraph → download/unlock → back/retake links.
class _ReportView {
  final String heroName;
  final String heroFirstSentence;
  final String snapshotHeading;
  final String bodyParagraph;
  final String? secondParagraph;
  const _ReportView({
    required this.heroName,
    required this.heroFirstSentence,
    required this.snapshotHeading,
    required this.bodyParagraph,
    this.secondParagraph,
  });
}

/// Per-level report — one file, two render branches (locked teaser /
/// unlocked full) per level, driven live by the single global
/// `reportUnlocked` flag rather than a second route, matching how
/// results_screen.dart itself branches loading-vs-loaded in one build().
/// All 5 levels are wired; Level 5 has its own dedicated final-synthesis
/// screen (career_dna_final_report_screen.dart) instead of this per-level
/// shape, since it combines every level rather than reporting just one.
class CareerDnaReportScreen extends StatelessWidget {
  final int level;
  const CareerDnaReportScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final profile = user?.careerDnaOrEmpty ?? const CareerDnaProfile();
    final unlocked = profile.reportUnlocked;
    final topInset = MediaQuery.of(context).padding.top;
    final who = _firstName(user?.name);

    // Level 5's result is a cross-test synthesis, not a per-level report —
    // its own screen (career_dna_final_report_screen.dart) is what knows
    // how to render it. Both call sites that link here (the success
    // screen's "See your report", the landing screen's node tap) already
    // route level 5 to that screen instead — this is just a defensive
    // catch-all for a stale deep link landing here directly.
    if (level == 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/college/career-dna/final-report');
      });
      return const SizedBox.shrink();
    }

    final view = _buildView(level, profile, who);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/career-dna'),
            const SizedBox(height: AppSpacing.lg),
            if (view == null)
              _NotReadyCard(level: level)
            else ...[
              // Hero shows only the opening sentence (~3 lines) — the rest
              // of the body continues below it, instead of the hero
              // holding a whole paragraph on its own. Per direct feedback:
              // three separate paragraph-in-a-box sections in a row (hero,
              // snapshot, growth) all making a similar "you're good at X"
              // point read as repetitive — this consolidates everything
              // below the hero into one flowing body instead of several
              // near-identical boxed paragraphs.
              _ArchetypeHero(name: view.heroName, firstSentence: view.heroFirstSentence),
              const SizedBox(height: AppSpacing.xl),
              Text(view.snapshotHeading, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              // A prose summary, not a scored scorecard — no percentage is
              // shown anywhere on this screen. Naming a student's weaker
              // dimensions as a bare number ("23% Learning Agility") reads
              // as a harsh, discouraging verdict; this instead names a few
              // real strengths plainly and frames the rest as still-
              // developing, worth building on rather than a deficiency.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noOrphan(view.bodyParagraph),
                      style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5, height: 1.55),
                    ),
                    if (unlocked && view.secondParagraph != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        noOrphan(view.secondParagraph!),
                        style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5, height: 1.55),
                      ),
                    ],
                  ],
                ),
              ),
              if (unlocked) ...[
                const SizedBox(height: AppSpacing.xl),
                const _DownloadReportButton(),
              ] else ...[
                const SizedBox(height: AppSpacing.xl),
                _UnlockCard(onUnlock: () => context.push('/college/career-dna/unlock')),
              ],
              // Two link-style exits, stacked: back to the level map (the
              // BackChevron above technically does this too via its
              // fallbackRoute, but a chevron alone doesn't read as clearly
              // as "go back to Career Quiz" — this makes it explicit), then
              // retake. Retake mirrors results_screen.dart's own "Retake
              // test" link exactly (same style, same "go straight to the
              // quiz, skip the intro" behavior) — re-submitting simply
              // overwrites this level's saved result, same as aptitude's
              // retake already does.
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: GestureDetector(
                    onTap: () => context.go('/tabs/career-dna'),
                    child: Text(
                      'Back to Career Quiz',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.blue,
                        fontSize: 14,
                        fontWeight: AppFontWeight.medium,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/college/career-dna/level/$level/quiz'),
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
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

  /// Dispatches to each level's own result shape — returns null when that
  /// level hasn't been completed yet (renders _NotReadyCard instead).
  _ReportView? _buildView(int level, CareerDnaProfile profile, String? who) {
    String heading(String noun) => who != null ? "$who's $noun" : 'Your $noun';

    switch (level) {
      case 1:
        final r = profile.level1;
        if (r == null) return null;
        return _ReportView(
          heroName: r.archetype.name,
          heroFirstSentence: _firstSentence(r.archetype.naturalStyle),
          snapshotHeading: heading('Personality Snapshot'),
          // The second sentence deliberately opens with "Looking at how you
          // actually answered" — the hero describes the archetype in
          // general (shared by everyone classified the same way); this is
          // what's specific to *this* student's own answers, so it reads
          // as a new, personal layer rather than restating the hero.
          bodyParagraph: '${_restOfSentences(r.archetype.naturalStyle)} ${_narrativeFromScores(r.dimensionScores, careerDnaLevel1DimensionPhrases)}',
          secondParagraph: '${r.archetype.growthAreaText} You could also thrive in places like ${_joinList(r.archetype.environments)}.',
        );
      case 2:
        final r = profile.level2;
        if (r == null) return null;
        return _ReportView(
          heroName: r.headlineText,
          heroFirstSentence: careerDnaLevel2HeroSentence(r.headlineText),
          snapshotHeading: heading('Interest Snapshot'),
          bodyParagraph: _narrativeFromScores(r.dimensionScores, careerDnaLevel2DimensionPhrases),
          secondParagraph: 'Worth exploring: ${r.careerExplorationChain.join(' → ')}.',
        );
      case 3:
        final r = profile.level3;
        if (r == null) return null;
        return _ReportView(
          heroName: r.profile.name,
          heroFirstSentence: r.profile.naturalStrength,
          snapshotHeading: heading('Teamwork Snapshot'),
          bodyParagraph: _narrativeFromScores(r.dimensionScores, careerDnaLevel3DimensionPhrases),
          secondParagraph: '${r.profile.watchOut} You could also thrive in places like ${_joinList(r.profile.environments)}.',
        );
      case 4:
        final r = profile.level4;
        if (r == null) return null;
        final bandCopy = careerDnaWorkplaceReadinessBandCopy[r.band] ?? '';
        return _ReportView(
          heroName: r.workStyleTitle,
          heroFirstSentence: r.workStyleText,
          snapshotHeading: heading('Workplace Snapshot'),
          bodyParagraph: '$bandCopy ${_narrativeFromScores(r.dimensionScores, careerDnaLevel4DimensionPhrases)}',
          secondParagraph: '${r.developmentAreaTitle} — ${r.developmentAreaText}',
        );
      default:
        return null;
    }
  }

  /// Builds the "Snapshot" paragraph shared by all 4 per-level reports —
  /// the top 3 dimensions become plainly-named strengths, the bottom 2
  /// become "still developing" growth notes, phrased from the level's own
  /// dimension-phrase map. Deliberately never touches or displays the
  /// underlying numbers. Stays in second person throughout ("you"),
  /// matching the hero's own voice — an earlier version switched to the
  /// student's name mid-paragraph ("Aayusha shows..."), which read as two
  /// different narrators rather than one continuous, personal read.
  String _narrativeFromScores(Map<String, int> scores, Map<String, String> phrases) {
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final strengths = sorted.take(3).map((e) => phrases[e.key] ?? e.key).toList();
    final growing = sorted.reversed.take(2).map((e) => phrases[e.key] ?? e.key).toList();

    return 'Looking at how you actually answered, your standout strengths are ${_joinList(strengths)} — these come through clearly and are genuinely worth leaning into. '
        "You're still growing into ${_joinList(growing)} — with a bit of intentional practice, that's real room to build, not something holding you back.";
  }

  /// First name only, for the personalized section heading — null (falls
  /// back to "Your") when there's no name to work with.
  String? _firstName(String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.split(' ').first;
  }

  /// "A, B, C and D" — plain-English list for the environments sentence
  /// below, since these no longer render as separate badge tags.
  String _joinList(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  /// The opening sentence only — shown in the hero, so it reads as a short
  /// ~3-line teaser instead of the full 3-4 sentence paragraph.
  String _firstSentence(String text) {
    final match = RegExp(r'^.*?[.!?](?=\s|$)').firstMatch(text);
    return match?.group(0) ?? text;
  }

  /// Everything after that opening sentence — continues as the lead-in to
  /// the body paragraph below, so the full naturalStyle text still appears
  /// in full, just not all crammed into the hero.
  String _restOfSentences(String text) {
    final first = _firstSentence(text);
    return text.substring(first.length).trim();
  }
}

class _ArchetypeHero extends StatelessWidget {
  final String name;
  final String firstSentence;
  const _ArchetypeHero({required this.name, required this.firstSentence});

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
          // Just the opening line (~3 rows) — the rest of this same
          // archetype paragraph continues below as the lead-in to the
          // Personality Snapshot body text, instead of the hero holding
          // the whole 3-4 sentence description on its own. Uses `body`
          // (regular weight), not `bodyLg` (medium) — read too heavy for a
          // full paragraph in an earlier version of this hero.
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(noOrphan(firstSentence), style: AppTextStyles.body.copyWith(color: AppColors.whiteA70, fontSize: 14.5, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

/// A standing "Download report" entry point on the unlocked report itself —
/// not just a one-time screen shown right after paying (career_dna_report_
/// ready_screen.dart), so the PDF is reachable any time this screen is
/// revisited later, not only in the moment right after checkout.
class _DownloadReportButton extends StatefulWidget {
  const _DownloadReportButton();

  @override
  State<_DownloadReportButton> createState() => _DownloadReportButtonState();
}

class _DownloadReportButtonState extends State<_DownloadReportButton> {
  bool _downloading = false;

  Future<void> _download(User user) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await buildCareerDnaReportPdf(user);
      final name = (user.name?.trim().isNotEmpty ?? false) ? user.name! : 'career_quiz';
      final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
      await Printing.sharePdf(bytes: bytes, filename: '${safeName.isEmpty ? 'career_quiz' : safeName}_career_quiz_report.pdf');
    } catch (e) {
      debugPrint('Career Quiz report PDF generation failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text("Couldn't generate the PDF"),
          duration: const Duration(seconds: 4),
          persist: false,
        ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    return PillButton(
      label: 'Download full report',
      variant: PillVariant.secondary,
      icon: Ionicons.download_outline,
      loading: _downloading,
      onPressed: user == null ? null : () => _download(user),
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
