import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_applications.dart';
import '../../mockData/mock_bookings.dart';
import '../../mockData/mock_courses.dart';
import '../../mockData/mock_notifications.dart';
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
import '../../utils/group_by_category.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/auto_carousel.dart';
import '../../widgets/course_carousel_section.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fomo_notification_card.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/opportunity_carousel_section.dart';
import '../../widgets/opportunity_row.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/skeleton_loader.dart';

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
  int _lastSeenDataVersion = -1;

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
    // Already-applied postings stay in the feed (shown with a disabled
    // "Applied ✓" button, per direct feedback) rather than being filtered
    // out — vanishing on apply read as "did that work?".
    final results = filterOpportunities(
      type: _type == 'All' ? null : _type,
      workMode: prefs?.workMode,
      employmentType: prefs?.employmentType,
      locations: prefs?.cities,
    ).toList();
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
      // AppSpacing.xl between stacked carousels, not just each one's own
      // built-in shadow-clearance (AppShadows.cardBuffer, 16px, tuned to
      // stop card shadows clipping — not a design rhythm) — otherwise
      // several carousels back to back read as "stacked together" against
      // the rest of the app's AppSpacing.xl section-to-section gap.
      if (sections.isNotEmpty) sections.add(const SizedBox(height: AppSpacing.xl));
      sections.add(OpportunityCarouselSection(
        title: title,
        opportunities: capped,
        matchLabel: (o) => o.matchLabelFor(user),
        isApplied: (o) => isOpportunityApplied(o.id),
        isSaved: (o) => appState.isOpportunitySaved(o.id),
        onTapCard: (o) => context.push('/opportunity/${o.id}'),
        onApply: (o) => startApplyFlow(context, o, onApplied: () => setState(() {})),
        onToggleSave: (o) => appState.toggleSavedOpportunity(o.id),
        onViewAll: () => context.push(Uri(
          path: '/opportunities',
          queryParameters: {'title': title, if (category != null) 'category': category},
        ).toString()),
      ));
    }

    // Fallback for the (post-onboarding, shouldn't-happen) no-roles case —
    // without it the feed would have no job sections at all.
    if (roles.isEmpty) {
      addSection('Jobs for you', opps);
    }

    for (final role in roles) {
      final inRole = opps.where((o) => o.category.toLowerCase() == role.toLowerCase()).toList();
      addSection('$role jobs', inRole, category: role);
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
      if (sections.isNotEmpty) sections.add(const SizedBox(height: AppSpacing.xl));
      sections.add(CourseCarouselSection(
        // Explicitly says "courses" — "Boost your chances" gave no signal
        // this section was a different content type from the job carousels
        // right above it, and with an identical card shell, that left the
        // heading as the only thing that could have disambiguated it.
        title: 'Courses to boost your profile',
        courses: upskillCourses,
        onViewAll: () => context.go('/tabs/explore'),
      ));
    }

    return sections;
  }

  Widget _oppRow(BuildContext context, AppState appState, User? user, Opportunity o) {
    return OpportunityRow(
      tag: o.type,
      title: o.title,
      subtitle: o.company,
      meta: [o.location, o.stipend, o.duration],
      matchLabel: o.matchLabelFor(user),
      deadlineLabel: o.deadlineLabel,
      deadlineUrgent: o.deadlineIsUrgent,
      saved: appState.isOpportunitySaved(o.id),
      applied: isOpportunityApplied(o.id),
      onToggleSave: () => appState.toggleSavedOpportunity(o.id),
      onTap: () => context.push('/opportunity/${o.id}'),
      onApply: () => startApplyFlow(context, o, onApplied: () => setState(() {})),
    );
  }

  // Groups the isFiltering flat list by category whenever it spans more
  // than one — unlike the unfiltered view above (already one carousel per
  // selected role), this filter (work mode/employment type/city) never
  // scopes _opps by category at all, so it can freely interleave Software/
  // Design/Data/etc. results with nothing to browse just one category in
  // one continuous run. No explicit "selected categories" list exists on
  // this filter path (unlike Courses'), so groups are ordered by first
  // appearance in _opps instead.
  List<Widget> _groupedOppRows(BuildContext context, AppState appState, User? user, List<Opportunity> opps) {
    final categories = {for (final o in opps) o.category}.toList();
    if (categories.length <= 1) {
      return [for (final o in opps) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: _oppRow(context, appState, user, o))];
    }
    final grouped = groupByCategory<Opportunity>(opps, (o) => o.category);
    return [
      for (final entry in grouped.entries) ...[
        // top: lg matches courses_explore_screen.dart's _categoryHeading
        // vertical rhythm exactly — no horizontal value needed here (unlike
        // that self-contained version) since this heading already sits
        // inside the same horizontal-xl Padding the cards do.
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Text('${entry.key} (${entry.value.length})', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 15)),
        ),
        for (final o in entry.value) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: _oppRow(context, appState, user, o)),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final appState = context.watch<AppState>();
    // A booking made/cancelled on the Sessions screen (or an application
    // deleted on the Applications tab), both kept alive in the background,
    // otherwise wouldn't update this screen's Upcoming Session card or
    // Applied badges until a manual pull-to-refresh.
    if (appState.dataVersion != _lastSeenDataVersion) {
      _lastSeenDataVersion = appState.dataVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
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
    // _bookings is sorted ascending by real date/time, but nothing
    // previously excluded a session whose date had already passed — a
    // lapsed booking could sit in this "upcoming" slot indefinitely.
    final now = DateTime.now();
    final upcoming = _bookings.cast<Booking?>().firstWhere(
          (b) {
            final dt = parseBookingDateTime(b!.date, b.time);
            return dt == null || dt.isAfter(now);
          },
          orElse: () => null,
        );

    // The slim top bar (avatar/greeting/bell) plus a single pinned search
    // bar + filter row stay fixed above the scroll; everything else scrolls.
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
              unread: appState.hasUnreadNotifications(
                mockNotifications.map((n) => n.id).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
              child: Row(
                children: [
                  const Expanded(child: HomeSearchBar()),
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    button: true,
                    label: 'Filter',
                    child: GestureDetector(
                      onTap: _openFilter,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                            child: Icon(
                              isFiltering ? Ionicons.options : Ionicons.options_outline,
                              size: 20,
                              color: isFiltering ? AppColors.blue : AppColors.ink,
                            ),
                          ),
                          if (isFiltering)
                            Positioned(
                              top: 10,
                              right: 11,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: AppColors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.offWhite, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? ListView(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          child: SkeletonBox(width: 180, height: 18),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 222 + AppShadows.cardBuffer * 2,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppShadows.cardBuffer, AppSpacing.lg, AppShadows.cardBuffer),
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            children: const [
                              SkeletonCarouselCard(),
                              SizedBox(width: AppSpacing.md),
                              SkeletonCarouselCard(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      color: AppColors.blue,
                      onRefresh: _onRefresh,
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: AppSpacing.xxxl + AppSpacing.xl),
                        children: [
                          // The search bar + filter row is pinned above this
                          // list (a Column sibling), not a scroll item.
                          // Bookings is no longer its own bottom tab (only
                          // reachable from Profile now), so a booked
                          // placement session needs a reminder here too —
                          // otherwise it's effectively invisible until the
                          // day of.
                          if (upcoming != null) ...[
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
                                              upcoming.kind == 'placement' ? (upcoming.sessionType ?? 'Placement session') : 'Counseling with ${upcoming.counselor}',
                                              style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 15, fontWeight: AppFontWeight.bold),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '${_prettyDate(upcoming.date)} • ${upcoming.time} • ${upcoming.mode == 'online' ? 'Online' : 'Offline'}',
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
                          if (upcoming == null) ...[
                            // Auto-swiping 2-card carousel — card 1 is the
                            // original standing "book a session" CTA, card 2
                            // hooks users into the free Level 1 Career Quiz
                            // test. Both cards now share one exact shape
                            // (title, 1 line if it fits; subtitle, up to 2
                            // lines) so a card's content can never overflow
                            // the carousel's fixed page height — the
                            // previous card 2 (a 3-line title+subtitle+
                            // italic-tagline stack) could exceed it at
                            // narrow widths, which clipped its last line and
                            // read as a broken/misaligned card. `alignment:
                            // centerLeft` on each Container vertically
                            // centers whatever content height actually
                            // renders within the fixed page, so a shorter
                            // render (e.g. a 1-line title) doesn't look
                            // pinned to the top with dead space below it.
                            // Both titles go through noOrphan() — without
                            // it, a wrapped title could strand a single
                            // word alone on its own line.
                            AutoCarousel(
                              // Sleek — just enough for a 2-line title + a
                              // 2-line body with tight vertical padding.
                              // alignment.centerLeft on each card keeps
                              // shorter content vertically centred.
                              height: 112,
                              cards: [
                                GestureDetector(
                                  onTap: () => context.push('/booking?kind=placement'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(noOrphan('Talk to a placement expert'), style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 16, fontWeight: AppFontWeight.bold)),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(noOrphan('1:1 guidance to land your next role.'), style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 13)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // A distinct semantic icon per card (was
                                        // the same generic arrow on both, which
                                        // made the two cards read as identical).
                                        const Icon(Ionicons.chatbubble_ellipses, size: 32, color: AppColors.yellow),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/tabs/career-dna'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Direct about the outcome (getting
                                              // noticed) with the concrete
                                              // mechanic in the body — the free
                                              // test is attached to the resume
                                              // recruiters see.
                                              Text(noOrphan('Get recruiters to notice you'), style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 16, fontWeight: AppFontWeight.bold)),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  noOrphan('Free 10-min test, attached to your resume for recruiters.'),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 13, height: 1.3),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Ionicons.eye, size: 32, color: AppColors.yellow),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_opps.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(top: AppSpacing.xxxl),
                              child: EmptyState(
                                icon: Ionicons.briefcase_outline,
                                title: 'No opportunities match your filters',
                                subtitle: 'Try widening your search or clearing a filter to see more.',
                                buttonLabel: isFiltering ? 'Clear filters' : null,
                                onButtonTap: isFiltering ? _clearFilters : null,
                              ),
                            )
                          else if (isFiltering)
                            Padding(
                              // Same fix as the unfiltered branch below —
                              // AppSpacing.xl, matching the gap above
                              // HomeDashboardCards' nudge banner.
                              padding: const EdgeInsets.only(top: AppSpacing.xl),
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
                                      // Column defaults to centering its
                                      // children — harmless for the
                                      // full-width OpportunityRow cards, but
                                      // it was silently centering the plain
                                      // Text category headings too, unlike
                                      // Courses' equivalent (a direct
                                      // ListView child, naturally
                                      // left-aligned). .start matches that.
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _groupedOppRows(context, appState, user, _opps),
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
                              // to lean on. AppSpacing.xl, not
                              // AppShadows.cardBuffer — matches the gap
                              // _BoostSection puts *above* that same banner,
                              // so it reads as equidistant from the cards on
                              // both sides instead of 4px tighter below.
                              padding: const EdgeInsets.only(top: AppSpacing.xl),
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
