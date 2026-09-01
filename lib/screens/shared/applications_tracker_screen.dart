import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mockData/mock_applications.dart';
import '../../mockData/mock_courses.dart';
import '../../mockData/mock_opportunities.dart';
import '../../models/application.dart';
import '../../models/course.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/applications_swipe_hint_prefs_key.dart';
import '../../utils/no_orphan.dart';
import '../../utils/relative_time.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/badges.dart';
import '../../widgets/company_mark.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/prep_course_card.dart';
import '../../widgets/responsive_body.dart';

/// Shared "prep for this" bottom sheet — the momentum banner opens it scoped
/// to every role applied for, each card's own "Q&A" shortcut opens it scoped
/// to just that one role, so the sheet itself only exists once.
void _showPrepSheet(BuildContext context, List<Course> courses, {required String heading, required String subtitle}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(sheetContext).padding.bottom + AppSpacing.lg),
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
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(heading, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
            child: Text(
              noOrphan(subtitle),
              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5),
            ),
          ),
          ...courses.map((c) => PrepCourseCard(
                course: c,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/course/${c.id}');
                },
              )),
          PillButton(
            label: 'Browse all courses',
            variant: PillVariant.ghost,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              context.go('/tabs/explore');
            },
          ),
        ],
      ),
    ),
  );
}

/// Mirrors frontend/src/screens/ApplicationsTracker.tsx (ApplicationsTracker).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class ApplicationsTrackerScreen extends StatefulWidget {
  const ApplicationsTrackerScreen({super.key});

  @override
  State<ApplicationsTrackerScreen> createState() => _ApplicationsTrackerScreenState();
}

class _ApplicationsTrackerScreenState extends State<ApplicationsTrackerScreen> {
  List<Application> _apps = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Branch index 1 (college's Browse/Applications tab) — this screen is
    // college-only, see BrowseTabScreen.
    ScrollToTopRegistry.register(1, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _load();
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(1);
    _scrollController.dispose();
    super.dispose();
  }

  void _load() {
    // TODO: replace with real API call
    setState(() => _apps = listApplications());
  }

  Future<void> _onRefresh() async => _load();

  void _removeApplication(Application a) {
    // Soft delete — the entry moves to Recently Deleted rather than
    // vanishing outright, so this SnackBar's Undo is now just the fast
    // path for the immediate "oops"; the trash icon in the header above is
    // the longer-lived backstop if this toast is missed. Both call the
    // same restoreApplication(id).
    removeApplication(a.id);
    setState(() => _apps = listApplications());
    // Removing more than one card back-to-back otherwise queues a fresh
    // SnackBar behind whichever one is still showing (ScaffoldMessenger's
    // default) instead of replacing it — each 4s toast waits for the last
    // to finish, which reads as one that never goes away. Clear first so
    // the newest removal always replaces, never queues.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${a.opportunity.title}'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.yellow,
            onPressed: () {
              restoreApplication(a.id);
              setState(() => _apps = listApplications());
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // 2 columns at tablet width — same reasoning as opportunity_list_screen:
    // a plain wider single-column cap would leave a thin card stretched
    // down the middle instead of actually using the extra room.
    final columns = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet ? 2 : 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: 720, child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Applications', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                    child: Text(
                      '${_apps.length} active application${_apps.length != 1 ? 's' : ''}',
                      textAlign: TextAlign.left,
                      style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                    ),
                  ),
                ],
              ),
            ),
            // Sits above the list itself, not inside its ListView — a
            // sibling in this outer Column so it stays pinned above both
            // the single-column and grid layouts below without needing to
            // be duplicated into each, and collapses to zero height once
            // shown (no permanently reserved space).
            const _SwipeHintBanner(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue,
                onRefresh: _onRefresh,
                child: _apps.isEmpty
                    ? ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                            child: Column(
                              children: [
                                Container(
                                  width: AppSpacing.xxxl + AppSpacing.xl,
                                  height: AppSpacing.xxxl + AppSpacing.xl,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                  child: const Icon(Ionicons.paper_plane_outline, size: AppSpacing.xxl + AppSpacing.xs / 2, color: AppColors.blue),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.md),
                                  child: Text('No applications yet', style: AppTextStyles.h3.copyWith(color: AppColors.ink)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    "Explore opportunities and apply — they'll show up here.",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                                  child: PillButton(
                                    label: 'Explore opportunities',
                                    full: false,
                                    onPressed: () => context.go('/tabs'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxxl),
                        children: [
                          if (columns == 1)
                            ..._apps.asMap().entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: _ApplicationCard(app: entry.value, onRemove: () => _removeApplication(entry.value)),
                                ))
                          else
                            for (var row = 0; row < (_apps.length / columns).ceil(); row++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (var i = 0; i < columns; i++) ...[
                                        if (i > 0) const SizedBox(width: AppSpacing.lg),
                                        Expanded(
                                          child: row * columns + i < _apps.length
                                              ? _ApplicationCard(
                                                  app: _apps[row * columns + i],
                                                  onRemove: () => _removeApplication(_apps[row * columns + i]),
                                                )
                                              : const SizedBox(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

/// One-time "swipe a card left to delete it" hint — this screen's cards use
/// a standard Dismissible, but nothing on-screen ever told a first-time
/// visitor that gesture exists. Auto-fades on its own timer rather than
/// needing a second swipe-to-dismiss gesture of its own — asking someone to
/// swipe away a hint *about* swiping is circular, and a timer guarantees it
/// clears even for someone who never touches the list at all. Shown once
/// per install via [applicationsSwipeHintShownPrefsKey], mirroring
/// maybeShowFomoSheet's own SharedPreferences-gated "seen once" pattern.
class _SwipeHintBanner extends StatefulWidget {
  const _SwipeHintBanner();

  @override
  State<_SwipeHintBanner> createState() => _SwipeHintBannerState();
}

class _SwipeHintBannerState extends State<_SwipeHintBanner> {
  bool _visible = false;
  bool _faded = false;

  @override
  void initState() {
    super.initState();
    _maybeShow();
  }

  Future<void> _maybeShow() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(applicationsSwipeHintShownPrefsKey) ?? false) return;
    if (!mounted) return;
    setState(() => _visible = true);
    await prefs.setBool(applicationsSwipeHintShownPrefsKey, true);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() => _faded = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
      child: AnimatedOpacity(
        opacity: _faded ? 0 : 1,
        duration: Duration(milliseconds: _faded ? 400 : 300),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          // Plain white + a soft shadow, not a border — reads as a toast
          // floating just above the page rather than a call-to-action
          // chip. The earlier all-gray/offWhite version had no shadow or
          // border at all, so the pill's own shape barely registered
          // against this screen's plain white background; a real white
          // fill lifted off the page by AppShadows.soft (rather than a
          // color accent) gives it definition while keeping the simple
          // white-card/gray-text toast look.
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Ionicons.arrow_back_outline, size: 14, color: AppColors.gray500),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Swipe a card left to delete it',
                style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12.5, fontWeight: AppFontWeight.medium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One application card — extracted from the tracker's build method so it
/// can be reused per-cell in both the single-column list (phone) and the
/// 2-column grid (tablet) without duplicating the swipe-to-remove/tap
/// structure.
///
/// Naukri's own tracker card packs in more than a status pill: a recruiter
/// activity signal, a shortcut to similar roles, and inline "prep for this
/// interview" actions. A bare title/company/status card was leaving all of
/// that on the table, so this reuses the same shell but adds those rows —
/// every card, same format, regardless of status.
class _ApplicationCard extends StatelessWidget {
  final Application app;
  final VoidCallback onRemove;
  const _ApplicationCard({required this.app, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final a = app;
    final opportunity = getOpportunityById(a.opportunityId);

    return Dismissible(
      key: ValueKey(a.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: const Icon(Ionicons.trash_outline, color: AppColors.white, size: 22),
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
          onTap: () => context.push('/application/${a.id}'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // Concentric with CompanyMark's own AppRadius.md corner sitting
            // AppSpacing.lg inside it, not an unrelated token.
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CompanyMark(company: a.opportunity.company, size: 52),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a.opportunity.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14.5, fontWeight: AppFontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(a.opportunity.company, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      // Expanded + ellipsis, not a bare Text — "Better luck
                      // next time!" is long enough that on a narrow phone
                      // this date and the status badge could otherwise
                      // collide instead of one of them visibly giving way.
                      Expanded(
                        child: Text(
                          'Applied ${relativeTimeLabel(DateTime.tryParse(a.createdAt) ?? DateTime.now())}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12, fontWeight: AppFontWeight.medium),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge(status: a.status),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                  // Three real tap targets, given actual chip weight (a
                  // bounded neutral pill) instead of bare icon+text — next
                  // to a tinted status badge, that neutral fill is what
                  // keeps "this is an action" visually distinct from "this
                  // is a status," instead of the two competing for the
                  // same visual weight. Replaces the old "Recruiter active"
                  // line (a decorative-only mock signal, not shown or
                  // linked anywhere else) and "Prep for this interview"
                  // caption (added a text row without adding information —
                  // Mock/Q&A are self-explanatory next to their icons).
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _actionChip(
                        icon: Ionicons.copy_outline,
                        label: 'Similar',
                        onTap: () => context.push(Uri(
                          path: '/opportunities',
                          queryParameters: {'title': 'Similar roles', if (opportunity != null) 'category': opportunity.category},
                        ).toString()),
                      ),
                      _actionChip(
                        icon: Ionicons.mic_outline,
                        label: 'Mock',
                        onTap: () => context.push('/booking?kind=placement'),
                      ),
                      _actionChip(
                        icon: Ionicons.book_outline,
                        label: 'Prep',
                        onTap: () => _showPrepSheet(
                          context,
                          prepCoursesForOpportunities(opportunity != null ? [opportunity] : const []),
                          heading: 'Prep for this interview',
                          subtitle: 'Aerostar Edge picks for the ${a.opportunity.title} role.',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.blue),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.semibold)),
          ],
        ),
      ),
    );
  }
}

