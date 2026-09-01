import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../mockData/mock_applications.dart';
import '../models/opportunity.dart';
import '../models/profile_readiness.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/no_orphan.dart';
import '../widgets/app_chip.dart';
import '../widgets/pill_button.dart';

/// Single source of truth for "what happens when someone taps Apply" — the
/// job card footer button and the opportunity detail page's Apply bar both
/// call this, so the two surfaces can never drift into different flows.
///
/// [onApplied] lets the caller refresh its own view (e.g. flip a card to
/// show the "Applied" badge) once the application actually goes through.
Future<void> startApplyFlow(
  BuildContext context,
  Opportunity opportunity, {
  VoidCallback? onApplied,
}) async {
  final alreadyApplied = listApplications().any((a) => a.opportunityId == opportunity.id);
  if (alreadyApplied) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You've already applied — check Applications for updates.")),
    );
    return;
  }

  final user = context.read<AppState>().user;
  if (user == null || !user.canApply) {
    _showApplyGateSheet(context, user, opportunity);
    return;
  }

  _showScreeningSheet(context, opportunity, onApplied);
}

void _showApplyGateSheet(BuildContext context, User? user, Opportunity opportunity) {
  final missing = user == null
      ? const <String>['Resume']
      : user.missingForApply.map((i) => i.title).toList();
  final primaryRoute = user == null
      ? '/college/resume'
      : (user.missingForApply.isNotEmpty ? user.missingForApply.first.route : '/college/resume');
  final steps = missing.isEmpty ? 2 : missing.length;
  final headline = steps == 1 ? '1 step left to apply' : '$steps steps left to apply';

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xs,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Text(headline, textAlign: TextAlign.left, style: AppTextStyles.h2.copyWith(color: AppColors.ink)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              noOrphan("A couple quick things before you apply."),
              textAlign: TextAlign.left,
              style: AppTextStyles.body.copyWith(color: AppColors.gray500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: missing
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(Ionicons.alert_circle_outline, size: 20, color: AppColors.blue),
                          const SizedBox(width: AppSpacing.md),
                          Text(m, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: PillButton(
              label: primaryRoute.contains('resume') ? 'Upload resume' : 'Finish profile',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                // Resume is the only gate step that leads straight back into
                // applying — thread the opportunity through so finishing the
                // upload submits this application automatically instead of
                // dropping the user on a generic screen to start over.
                final target = primaryRoute == '/college/resume' ? '$primaryRoute?applyFor=${opportunity.id}' : primaryRoute;
                context.push(target);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Not now',
            variant: PillVariant.ghost,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    ),
  );
}

void _showScreeningSheet(BuildContext context, Opportunity opportunity, VoidCallback? onApplied) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => _ScreeningSheet(opportunity: opportunity, onApplied: onApplied),
  );
}

void _showSuccessSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            child: Text('Application submitted!', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 22, fontWeight: AppFontWeight.semibold)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              noOrphan("Track every update in the Applications tab."),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: PillButton(
              label: 'View my applications',
              onPressed: () {
                // Resolve the router from sheetContext *before* popping,
                // not the outer `context` — this function is called with
                // the *screening* sheet's own context, which is already
                // popped and defunct by the time this success sheet opens,
                // so go_router can't resolve a route through it at all.
                // sheetContext belongs to this sheet's own still-live
                // subtree; resolving the router first (rather than calling
                // sheetContext.go after popping) sidesteps any question of
                // whether sheetContext is still valid post-pop.
                final router = GoRouter.of(sheetContext);
                Navigator.of(sheetContext).pop();
                // Route through the Applications tab itself, not straight
                // to this one application — a user testing this couldn't
                // find where updates would show up later, because the old
                // flow skipped past the tab entirely.
                router.go('/tabs/browse');
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Pre-apply screening sheet — Naukri's "just a couple minutes" pattern:
/// a couple of company-voice questions with tappable quick-answer badges
/// (search-suggest style, reusing [AppChip]) plus a free-text fallback so
/// nobody's ever blocked by an option that doesn't fit, then an optional
/// note to the recruiter.
class _ScreeningSheet extends StatefulWidget {
  final Opportunity opportunity;
  final VoidCallback? onApplied;
  const _ScreeningSheet({required this.opportunity, this.onApplied});

  @override
  State<_ScreeningSheet> createState() => _ScreeningSheetState();
}

class _ScreeningSheetState extends State<_ScreeningSheet> {
  late final List<TextEditingController> _answerControllers;
  late final TextEditingController _noteController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _answerControllers = List.generate(widget.opportunity.screeningQuestions.length, (_) => TextEditingController());
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final answers = <String, String>{};
    for (var i = 0; i < widget.opportunity.screeningQuestions.length; i++) {
      final value = _answerControllers[i].text.trim();
      if (value.isNotEmpty) answers[widget.opportunity.screeningQuestions[i]] = value;
    }
    final note = _noteController.text.trim();
    createApplication(
      widget.opportunity.id,
      note: note.isEmpty ? null : note,
      screeningAnswers: answers.isEmpty ? null : answers,
    );
    HapticFeedback.heavyImpact();
    final parentContext = context;
    if (!parentContext.mounted) return;
    Navigator.of(parentContext).pop();
    widget.onApplied?.call();
    if (!parentContext.mounted) return;
    _showSuccessSheet(parentContext);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.opportunity;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (sheetContext, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.xxl,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text('Just a minute before you apply', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 20)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  noOrphan('${o.company} would like to know a bit more.'),
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                ),
              ),
              for (var i = 0; i < o.screeningQuestions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.screeningQuestions[i], style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 15)),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: (i < o.screeningQuestionOptions.length ? o.screeningQuestionOptions[i] : const <String>[])
                              .map((opt) => AppChip(
                                    label: opt,
                                    selected: _answerControllers[i].text == opt,
                                    onPressed: () => setState(() => _answerControllers[i].text = opt),
                                  ))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: TextField(
                          controller: _answerControllers[i],
                          onChanged: (_) => setState(() {}),
                          maxLength: 200,
                          style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            counterText: '',
                            hintText: 'Or type your own answer',
                            hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.blue)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text('Note to recruiter (optional)', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 15)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 3,
                    maxLength: 300,
                    style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'e.g. Available to start immediately',
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: PillButton(label: 'Send Application', onPressed: _send, loading: _sending),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
