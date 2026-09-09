import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
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

/// Per-level report — no on-screen narrative "overview" any more (that
/// content — hero/snapshot/growth paragraphs — has been removed for every
/// level, per direct feedback). This screen now only ever shows one of
/// three lean states per level: not-ready-yet, ready-to-download (Level 1
/// always, Levels 2-4 once the existing single ₹51 payment has unlocked
/// everything), or locked-needs-payment (Levels 2-4 only, before paying).
/// The narrative-generation logic that used to live here (dimension-phrase
/// sentences, archetype heroes, etc.) still exists — it just moved
/// entirely into career_dna_report_pdf.dart, which still puts that detail
/// into the actual downloadable PDF; it's just not shown on this screen
/// before/instead of downloading any more.
/// Level 5 has its own dedicated final-synthesis screen
/// (career_dna_final_report_screen.dart) instead of this per-level shape,
/// since it combines every level rather than reporting just one.
class CareerDnaReportScreen extends StatelessWidget {
  final int level;
  const CareerDnaReportScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final profile = user?.careerDnaOrEmpty ?? const CareerDnaProfile();
    final topInset = MediaQuery.of(context).padding.top;

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

    final completed = _isLevelComplete(profile, level);
    final meta = careerDnaLevelMeta.firstWhere((m) => m.level == level);
    // Level 1 is always free — a lead-magnet, no paywall at all. Levels
    // 2-4 each require their own individual ₹51 payment now — no single
    // payment unlocks more than one level.
    final canDownload = completed && profile.isLevelReportUnlocked(level);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/career-dna'),
            const SizedBox(height: AppSpacing.lg),
            if (!completed)
              _NotReadyCard(level: level)
            else if (canDownload)
              _LevelReportReadyView(level: level, meta: meta)
            else
              _LevelReportLockedView(level: level, meta: meta),
          ],
        ),
      ),
    );
  }
}

/// Mirrors career_dna_landing_screen.dart's own identical private method —
/// no shared model helper exists for this today, kept consistent with that
/// existing convention rather than introducing a new one for just this file.
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
    default:
      return false;
  }
}

/// Level 1 (always), or Levels 2-4 once globally unlocked — a lean "your
/// report is ready" view: checkmark, title, file-info card, a per-level-
/// only PDF download (not the combined multi-level one), and a "Continue
/// to Level N+1" CTA. Safe to always show Continue here: this only ever
/// renders once level N is already complete, and unlocking is strictly
/// sequential, so level N+1 is guaranteed to already be unlocked.
class _LevelReportReadyView extends StatefulWidget {
  final int level;
  final CareerDnaLevelMeta meta;
  const _LevelReportReadyView({required this.level, required this.meta});

  @override
  State<_LevelReportReadyView> createState() => _LevelReportReadyViewState();
}

class _LevelReportReadyViewState extends State<_LevelReportReadyView> {
  bool _downloading = false;

  Future<void> _download(User user) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await buildCareerDnaLevelReportPdf(user, widget.level);
      final name = (user.name?.trim().isNotEmpty ?? false) ? user.name! : 'career_quiz';
      final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${safeName.isEmpty ? 'career_quiz' : safeName}_level${widget.level}_report.pdf',
      );
    } catch (e) {
      debugPrint('Career Quiz level report PDF generation failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("Couldn't generate the PDF"),
          duration: Duration(seconds: 4),
          persist: false,
        ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final nextLevel = widget.level + 1; // always <=5 — level 5 redirects before this widget ever builds

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
            child: const Icon(Ionicons.checkmark, size: 40, color: AppColors.blue),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(
              'Your ${widget.meta.title} report is ready',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 22, fontWeight: AppFontWeight.semibold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              noOrphan('Download your results below, or continue on to the next level.'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xl),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                  child: const Icon(Ionicons.document_text, size: 20, color: AppColors.blue),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.meta.title} Report',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('PDF · ready to download', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: PillButton(
              label: 'Download PDF',
              variant: PillVariant.secondary,
              icon: Ionicons.download_outline,
              loading: _downloading,
              onPressed: user == null ? null : () => _download(user),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: PillButton(
              label: 'Continue to Level $nextLevel',
              onPressed: () => context.push('/college/career-dna/level/$nextLevel/intro'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Levels 2-4, before that specific level's own payment has unlocked it —
/// no narrative teaser text at all (that's the whole point of the earlier
/// round's change), just a lean "here's what's waiting, unlock to see it"
/// prompt. Each level is paid for individually — this is not shared with
/// any other level's unlock state.
class _LevelReportLockedView extends StatelessWidget {
  final int level;
  final CareerDnaLevelMeta meta;
  const _LevelReportLockedView({required this.level, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
            child: const Icon(Ionicons.lock_closed, size: 34, color: AppColors.blue),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(
              'Your ${meta.title} report is ready',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 22, fontWeight: AppFontWeight.semibold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              noOrphan('Unlock it to see what your answers mean.'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: PillButton(
              label: 'Unlock — ₹51',
              icon: Ionicons.lock_open_outline,
              onPressed: () => context.push('/college/career-dna/level/$level/unlock'),
            ),
          ),
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
