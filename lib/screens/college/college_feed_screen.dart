import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_applications.dart';
import '../../mockData/mock_bookings.dart';
import '../../mockData/mock_courses.dart';
import '../../mockData/mock_opportunities.dart';
import '../../mockData/related_roles.dart';
import '../../models/booking.dart';
import '../../models/job_preferences.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../models/user.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/course_carousel_section.dart';
import '../../widgets/fomo_notification_card.dart';
import '../../widgets/home_dashboard_cards.dart';
import '../../widgets/home_header.dart';
import '../../widgets/opportunity_carousel_section.dart';
import '../../widgets/opportunity_row.dart';
import '../../widgets/responsive_body.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Mirrors frontend/src/screens/CollegeFeed.tsx (CollegeFeed).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class CollegeFeedScreen extends StatefulWidget {
  const CollegeFeedScreen({super.key});

  @override
  State<CollegeFeedScreen> createState() => _CollegeFeedScreenState();
}

class _CollegeFeedScreenState extends State<CollegeFeedScreen> {
  String _type = 'All';
  List<Opportunity> _opps = [];
  List<Booking> _bookings = [];
  bool _loading = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Branch index 0 (Home) — see router.dart's StatefulShellRoute.
    ScrollToTopRegistry.register(0, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowFomoSheet(context, isSchool: false);
    });
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(0);
    _scrollController.dispose();
    super.dispose();
  }

  static String _typeForGoal(String? goal) {
    switch (goal) {
      case 'internship':
        return 'Internship';
      case 'job':
        return 'Full-time';
      default:
        return 'All';
    }
  }

  void _load() {
    final user = context.read<AppState>().user;
    // Pre-filter to whatever the user told onboarding (or the filter
    // screen) they were looking for — choosing "Full-time" and landing on
    // a feed still showing internships (unfiltered) undoes the point of
    // asking. Recomputed fresh on every _load() call (not cached in
    // initState) so returning from the filter screen picks up a changed
    // goal without needing separate reactive plumbing.
    _type = _typeForGoal(user?.goal);
    final prefs = user?.preferences;
    final appliedIds = listApplications().map((a) => a.opportunityId).toSet();
    // Already-applied postings belong on the Applications tab, not the
    // discovery feed — showing them here (with seed demo applications
    // attached from before the user even signed up) reads as "I already
    // applied to this?" confusion on a feed meant for finding something new.
    final results = filterOpportunities(
      type: _type == 'All' ? null : _type,
      workMode: prefs?.workMode,
      employmentType: prefs?.employmentType,
      locations: prefs?.cities,
    ).where((o) => !appliedIds.contains(o.id)).toList();
    // Most-relevant-first, matching the user's selected roles/resume —
    // ties keep the original (curated) order via a stable sort.
    results.sort(
      (a, b) => b.matchScoreFor(user).compareTo(a.matchScoreFor(user)),
    );
    setState(() {
      _opps = results;
      _bookings = listBookings();
      _loading = false;
    });
  }

  String _prettyDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${_weekdayShort[d.weekday - 1]}, ${_monthShort[d.month - 1]} ${d.day}';
    } catch (_) {
      return date;
    }
  }

  Future<void> _onRefresh() async => _load();

  // Reads _load() again on return (rather than making _type/preferences
  // reactive via context.watch) since the filter screen saves straight to
  // AppState and pops — a fresh imperative reload picks up whatever
  // changed without needing separate reactive plumbing duplicating what
  // _load() already does on every call.
  Future<void> _openFilter() async {
    await context.push('/college/opportunity-filter');
    if (mounted) _load();
  }

  // Clears only the facets that actually gate the flat-list view (work
  // mode / employment type / cities) — Category/Goal are edited from the
  // same filter screen but aren't part of "filtering" here (see build()'s
  // isFiltering comment), so they're deliberately left untouched.
  Future<void> _clearFilters() async {
    await context.read<AppState>().updateProfile((current) => current.copyWith(preferences: const JobPreferences()));
    _load();
  }

  static const _sectionCap = 10;

  /// Naukri-style "browse by topic" instead of one long vertical scroll,
  /// which stops being usable once there are hundreds of postings — a
  /// top-matches row, then one row per role the user picked as interested
  /// during onboarding, then (for a student who picked few roles) a small
  /// number of "related field" rows backfilled from [relatedRoles], then a
  /// course-recommendation row to close the scroll. Only used when there's
  /// no active search — a typed query collapses back to a flat ranked
  /// list, matching how search results read everywhere else.
  ///
  /// The related-field backfill exists because picking just 1-2 roles used
  /// to leave the feed thin (profile-matches + 1-2 role rows, then a single
  /// unstructured "Explore more roles" dump of literally everything else).
  /// A student who hasn't told us much yet isn't well served by "only show
  /// what they said they want" — they often don't fully know yet, so
  /// nearby fields are worth surfacing, just clearly labeled as related
  /// rather than mixed in unsorted. The budget below is derived from how
  /// many role-specific rows already rendered, so a broadly-interested
  /// student who already picked several roles doesn't get padded further.
  static const _targetCarouselCount = 4;

  List<Widget> _sections(List<Opportunity> opps, AppState appState, User? user) {
    final roles = user?.roles ?? const <String>[];
    final sections = <Widget>[];
    final shownOpps = <Opportunity>[];

    void addSection(String title, List<Opportunity> items, {String? category}) {
      if (items.isEmpty) return;
      final capped = items.take(_sectionCap).toList();
      shownOpps.addAll(capped);
      sections.add(OpportunityCarouselSection(
        title: title,
        opportunities: capped,
        matchLabel: (o) => o.matchLabelFor(user),
        isApplied: (o) => isOpportunityApplied(o.id),
        onTapCard: (o) => context.push('/opportunity/${o.id}'),
        onApply: (o) => startApplyFlow(context, o, onApplied: () => setState(() {})),
        onViewAll: () => context.push(Uri(
          path: '/opportunities',
          queryParameters: {'title': title, if (category != null) 'category': category},
        ).toString()),
      ));
    }

    final topMatches = List.of(opps)..sort((a, b) => b.matchScoreFor(user).compareTo(a.matchScoreFor(user)));
    addSection('Jobs based on your profile', topMatches);

    for (final role in roles) {
      final inRole = opps.where((o) => o.category.toLowerCase() == role.toLowerCase()).toList();
      addSection('$role roles for you', inRole, category: role);
    }

    final relatedBudget = (_targetCarouselCount - 1 - roles.length).clamp(0, 3);
    if (roles.isNotEmpty && relatedBudget > 0) {
      final ownRoles = roles.map((r) => r.toLowerCase()).toSet();
      final addedRelated = <String>{};
      for (final role in roles) {
        for (final candidate in relatedRoles[role] ?? const <String>[]) {
          final key = candidate.toLowerCase();
          if (ownRoles.contains(key) || addedRelated.contains(key)) continue;
          if (addedRelated.length >= relatedBudget) break;
          addedRelated.add(key);
          final inCategory = opps.where((o) => o.category.toLowerCase() == key).toList();
          addSection('Related to $candidate', inCategory, category: candidate);
        }
        if (addedRelated.length >= relatedBudget) break;
      }
    }

    // Closes the scroll instead of just stopping — courses tied to
    // whatever the student actually saw above (via each opportunity's own
    // curated prepCourses), not a fragile category-string match against
    // Course.category, which uses a different vocabulary entirely.
    final upskillCourses = prepCoursesForOpportunities(shownOpps);
    if (upskillCourses.isNotEmpty) {
      sections.add(CourseCarouselSection(
        title: 'Boost your chances',
        courses: upskillCourses,
        onViewAll: () => context.go('/tabs/explore'),
      ));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final appState = context.watch<AppState>();
    // Work mode / employment type / preferred cities have no home in the
    // sectioned carousel view below, unlike Category/Goal (which already
    // reshape it via _sections()'s per-role rows and _load()'s own type
    // filter) — so only these three facets trigger the flat-list swap.
    // Category alone can't sensibly trigger it: User.roles has no separate
    // "unfiltered" state to compare against (it's always "whatever the
    // user is currently interested in"), so treating it as a filter flag
    // would mean this almost never shows the sectioned view at all for any
    // onboarded user.
    final prefs = user?.preferences;
    final isFiltering = prefs != null && (prefs.workMode != null || prefs.employmentType != null || prefs.cities.isNotEmpty);

    // Only the slim top bar (avatar/greeting/bell) stays pinned, matching
    // Naukri's own home scroll — search, the stat-card strip, and the type
    // filters used to sit outside the scroll area entirely, which meant
    // that whole block (near half the screen) stayed fixed no matter how
    // far you scrolled the listings below. Now they're just the first few
    // items of the one scrollable list, so they scroll away with everything
    // else.
    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            HomeHeader(
              name: user?.name,
              photoUrl: user?.photoUrl,
              subtitle: 'Find your next role',
              onAvatarTap: () => context.go('/tabs/profile'),
              onBellTap: () => context.push('/notifications'),
              onSearchTap: () => context.push('/search'),
              onFilterTap: _openFilter,
              isFiltering: isFiltering,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.blue),
                    )
                  : RefreshIndicator(
                      color: AppColors.blue,
                      onRefresh: _onRefresh,
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: AppSpacing.xxxl + AppSpacing.xl),
                        children: [
                          // Search moved to its own dedicated screen (see
                          // search_screen.dart, reached via the header's
                          // icon) — no inline bar taking up feed space here.
                          //
                          // No leading spacer here — HomeHeader's own bottom
                          // padding now supplies the gap under it directly
                          // (a shared fix, since school_home_screen.dart had
                          // the same header with no spacer of its own at
                          // all). If no booking, HomeDashboardCards is next
                          // and its own leading shadow buffer
                          // (AppShadows.cardBuffer) supplies its gap instead.
                          // Bookings is no longer its own bottom tab (only
                          // reachable from Profile now), so a booked
                          // placement session needs a reminder here too —
                          // otherwise it's effectively invisible until the
                          // day of.
                          if (_bookings.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () => context.go('/tabs/sessions'),
                              child: Container(
                                // No bottom margin — HomeDashboardCards' own
                                // leading shadow buffer (AppShadows.cardBuffer)
                                // already provides the gap to here; adding
                                // one on top of the other read as a
                                // noticeably looser gap than every other
                                // section-to-section gap on this screen.
                                margin: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 0),
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.offWhite,
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                  border: const Border(left: BorderSide(color: AppColors.blue, width: 4)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                      child: const Icon(Ionicons.videocam, size: 22, color: AppColors.blue),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('UPCOMING SESSION', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 11, fontWeight: AppFontWeight.medium, letterSpacing: 0.8)),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              _bookings.first.kind == 'placement' ? (_bookings.first.sessionType ?? 'Placement session') : 'Counseling with ${_bookings.first.counselor}',
                                              style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 15, fontWeight: AppFontWeight.bold),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '${_prettyDate(_bookings.first.date)} • ${_bookings.first.time} • ${_bookings.first.mode == 'online' ? 'Online' : 'Offline'}',
                                              style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_bookings.isEmpty) ...[
                            GestureDetector(
                              onTap: () => context.push('/booking?kind=placement'),
                              child: Container(
                                // No bottom margin — same reasoning as the
                                // booked-state card above: HomeDashboardCards'
                                // own leading shadow buffer supplies the gap
                                // to here on its own.
                                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Talk to a placement expert', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 18, fontWeight: AppFontWeight.bold)),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(noOrphan('1:1 guidance to land your next role.'), style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Ionicons.arrow_forward_circle, size: 34, color: AppColors.yellow),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          HomeDashboardCards(user: user),
                          if (_opps.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                              child: Column(
                                children: [
                                  const Icon(
                                    Ionicons.briefcase_outline,
                                    size: 40,
                                    color: AppColors.gray400,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No opportunities match your filters.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.gray500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isFiltering) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    GestureDetector(
                                      onTap: _clearFilters,
                                      child: Text('Clear filters', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else if (isFiltering)
                            Padding(
                              padding: const EdgeInsets.only(top: AppShadows.cardBuffer),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${_opps.length} ${_opps.length == 1 ? 'opportunity' : 'opportunities'} found',
                                            style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5, fontWeight: AppFontWeight.medium),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _clearFilters,
                                          child: Text('Clear filters', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                                    child: Column(
                                      children: [
                                        for (final o in _opps)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                                            child: OpportunityRow(
                                              tag: o.type,
                                              title: o.title,
                                              subtitle: o.company,
                                              meta: [o.location, o.stipend, o.duration],
                                              matchLabel: o.matchLabelFor(user),
                                              deadlineLabel: o.deadlineLabel,
                                              deadlineUrgent: o.deadlineIsUrgent,
                                              saved: appState.isOpportunitySaved(o.id),
                                              onToggleSave: () => appState.toggleSavedOpportunity(o.id),
                                              onTap: () => context.push('/opportunity/${o.id}'),
                                              onApply: () => startApplyFlow(context, o, onApplied: () => setState(() {})),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              // Unlike the other section gaps on this page,
                              // nothing upstream supplies this one for free
                              // — HomeDashboardCards' own trailing shadow
                              // buffer only covers the gap *before* its
                              // nudge banner (_BoostTip), not after it, and
                              // the banner itself has no shadow of its own
                              // to lean on. Needs an explicit gap, matching
                              // the same AppShadows.cardBuffer used
                              // everywhere else on the page.
                              padding: const EdgeInsets.only(top: AppShadows.cardBuffer),
                              child: Column(children: _sections(_opps, appState, user)),
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
