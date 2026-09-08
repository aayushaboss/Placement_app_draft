import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

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

// Natural-language phrases per dimension, used only to build the prose
// summary below — never the raw dimension key/label, and never a number.
// Per direct feedback: showing a student "23% Learning Agility" reads as a
// harsh verdict, even though the underlying scoring is unchanged; the fix
// is to stop surfacing percentages at all, not to soften the number.
const _level1DimensionPhrases = {
  'leadershipInitiative': 'stepping up and taking initiative',
  'communicationConfidence': 'speaking up with confidence',
  'teamOrientation': 'working well with a team',
  'adaptability': 'adapting quickly to change',
  'decisionMaking': 'making clear decisions',
  'problemSolving': 'solving problems',
  'learningAgility': 'picking up new things fast',
  'resilience': 'bouncing back from setbacks',
  'socialOrientation': 'connecting with people',
  'ambitionGrowth': 'pushing yourself toward bigger goals',
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
              Text('Your Personality Snapshot', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
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
                child: Text(
                  noOrphan(_narrativeSummary(user?.name, level1.dimensionScores)),
                  style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5, height: 1.55),
                ),
              ),
              if (unlocked) ...[
                const SizedBox(height: AppSpacing.xl),
                // One short paragraph, not a growth-opportunity card plus a
                // separate "Possible Career Environments" heading and a row
                // of badge pills — per direct feedback that split read as
                // too much on screen. Same content, just folded into a
                // single brief summary: the growth note first, then the
                // environments as a plain sentence instead of tags.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Text(
                    noOrphan('${level1.archetype.growthAreaText} You could also thrive in places like ${_joinList(level1.archetype.environments)}.'),
                    style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5, height: 1.5),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _DownloadReportButton(),
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

  /// Builds the "Personality Snapshot" paragraph — the top 3 dimensions
  /// become plainly-named strengths, the bottom 2 become "still
  /// developing" growth notes, phrased from _level1DimensionPhrases.
  /// Deliberately never touches or displays the underlying numbers.
  String _narrativeSummary(String? name, Map<String, int> scores) {
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final strengths = sorted.take(3).map((e) => _level1DimensionPhrases[e.key] ?? e.key).toList();
    final growing = sorted.reversed.take(2).map((e) => _level1DimensionPhrases[e.key] ?? e.key).toList();
    final who = (name?.trim().isNotEmpty ?? false) ? name!.trim().split(' ').first : 'You';

    return '$who show${who == 'You' ? '' : 's'} real strength in ${_joinList(strengths)} — these come naturally and are genuinely worth leaning into. '
        'Right now, ${_joinList(growing)} ${growing.length > 1 ? 'are' : 'is'} still developing — with a bit of intentional practice, these are real opportunities to grow, not weaknesses holding you back.';
  }

  /// "A, B, C and D" — plain-English list for the environments sentence
  /// below, since these no longer render as separate badge tags.
  String _joinList(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
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
          // career_dna_level1_data.dart's naturalStyle strings). Uses
          // `body` (regular weight), not `bodyLg` (medium) — at 3-4
          // sentences long, medium weight read as too heavy/overwhelming
          // for a full paragraph, unlike the single short line it used to
          // be.
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(noOrphan(naturalStyle), style: AppTextStyles.body.copyWith(color: AppColors.whiteA70, fontSize: 14.5, height: 1.45)),
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
      label: 'Download report',
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
