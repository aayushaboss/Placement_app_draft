import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_courses.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/auto_carousel.dart';
import '../../widgets/content_card.dart';
import '../../widgets/course_carousel_section.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/responsive_body.dart';
import 'course_filter_screen.dart';

const _categories = ['Counseling', 'Technology', 'Design', 'Finance', 'Science', 'Placement'];

/// Mirrors frontend/src/screens/CoursesExplore.tsx (CoursesExplore).
/// School user's "Explore" tab — also the college "Courses" tab.
///
/// Naukri-style browse-by-topic, matching how the Home feed's job listings
/// are organized: one horizontally-scrolling carousel per category instead
/// of a single flat list gated behind a category-filter chip row. A typed
/// search still collapses to a flat ranked list, same as everywhere else a
/// search box sits above sectioned content.
class CoursesExploreScreen extends StatefulWidget {
  const CoursesExploreScreen({super.key});

  @override
  State<CoursesExploreScreen> createState() => _CoursesExploreScreenState();
}

class _CoursesExploreScreenState extends State<CoursesExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  // This screen is mounted at branch 1 for school (Browse tab) and branch 3
  // for college (Courses tab) — see BrowseTabScreen/TabsScaffold, which pick
  // the same branch index the same way. Remembered so dispose() unregisters
  // the exact branch this instance registered, not whichever segment the
  // user happens to be on by the time dispose runs.
  int? _registeredBranchIndex;

  CourseFilterSelection _filter = const CourseFilterSelection();

  Future<void> _openFilter() async {
    final result = await context.push<CourseFilterSelection>('/school/course-filter', extra: _filter);
    if (result != null) setState(() => _filter = result);
  }

  @override
  void initState() {
    super.initState();
    final isSchool = context.read<AppState>().user?.segment == Segment.school;
    _registeredBranchIndex = isSchool ? 1 : 3;
    ScrollToTopRegistry.register(_registeredBranchIndex!, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    if (_registeredBranchIndex != null) ScrollToTopRegistry.unregister(_registeredBranchIndex!);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // The title, credibility carousel, and search+filter row used to be
  // fixed siblings above the results — outside any scrollable, they never
  // moved no matter how far the results below were scrolled. Folded into
  // the same ListView as the results instead (as leading items), mirroring
  // how college_feed_screen.dart/school_home_screen.dart already solved
  // this identical problem: "they're just the first few items of the one
  // scrollable list, so they scroll away with everything else." No new
  // scroll-direction-tracking code needed — scrolling back up naturally
  // brings them back the same way it brings back any earlier list content.
  List<Widget> _headerItems(double topInset, bool isFiltering) => [
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, 0),
          child: Text('Courses', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AutoCarousel(
            height: 84,
            // Static, non-interactive trust cards — the dots were purely
            // decorative here (unlike Home's 2-card boost-tip carousel,
            // where they're the only signal a second card exists).
            showDots: false,
            cards: const [
              _CredibilityCard(
                icon: Ionicons.school_outline,
                title: 'NEP 2020 Aligned',
                caption: 'Courses mapped to the National Education Policy 2020.',
              ),
              _CredibilityCard(
                icon: Ionicons.ribbon_outline,
                title: 'Skill India Certified',
                caption: "Content aligned with Skill India's competency framework.",
              ),
              _CredibilityCard(
                icon: Ionicons.shield_checkmark_outline,
                title: 'NSDC Approved',
                caption: 'Backed by the National Skill Development Corporation.',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: PillInput(controller: _searchController, placeholder: 'Search courses', onChanged: (_) => setState(() {})),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _openFilter,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      // Plain circle, no border, offWhite fill in both states —
                      // matches every other standalone icon-only button in the
                      // app (header search/bell, the opportunity-detail
                      // bookmark/chat buttons). "Active" is signaled the same
                      // way the bookmark button does it — swap to the filled
                      // glyph + blue tint — rather than inverting the whole
                      // button's fill, which no other icon button here does.
                      decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                      child: Icon(
                        isFiltering ? Ionicons.options : Ionicons.options_outline,
                        size: 20,
                        color: isFiltering ? AppColors.blue : AppColors.ink,
                      ),
                    ),
                    // Same permanent blue dot as Home's filter icon — a
                    // standing reminder that Courses is scoped to the
                    // user's own picks, not a one-time nudge. (11, 12), not
                    // Home's (9, 10): this button is 44px, not 40px — see
                    // home_header.dart's own note that (11, 12) was this
                    // exact ratio's value before that icon shrank to 40px.
                    Positioned(
                      top: 11,
                      right: 12,
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
            ],
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final query = _searchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;
    final searchResults = isSearching ? mockCourses.where((c) => c.title.toLowerCase().contains(query)).toList() : const <Course>[];

    final user = context.watch<AppState>().user;
    final clusters = user?.aptitudeResults?.matches.map((m) => m.cluster).toList() ?? const <String>[];
    final recommended = clusters.isNotEmpty ? recommendedCourses(clusters) : const <Course>[];

    final isFiltering = !_filter.isEmpty;
    final filteredResults = isFiltering
        ? filterCoursesAdvanced(categories: _filter.categories, durationBuckets: _filter.durationBuckets)
        : const <Course>[];

    // Every state below renders as exactly one ListView — the previous
    // isFiltering branch used to nest a second, independently-scrolling
    // ListView inside a fixed "N courses found" row; that's flattened here
    // too, so there's never more than one scrollable region on this screen.
    late final List<Widget> bodyItems;
    if (isSearching) {
      bodyItems = [
        ..._headerItems(topInset, isFiltering),
        if (searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxl, AppSpacing.xl, 0),
            child: Center(
              child: Text('No courses match "$query".', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
            ),
          )
        else
          ...searchResults.map((c) => Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                child: ContentCard(
                  icon: categoryIcons[c.category],
                  tag: c.category,
                  title: c.title,
                  meta: [c.duration, '${c.modules} modules'],
                  linkLabel: 'View syllabus',
                  onTap: () => context.push('/course/${c.id}'),
                ),
              )),
      ];
    } else if (isFiltering) {
      bodyItems = [
        ..._headerItems(topInset, isFiltering),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${filteredResults.length} ${filteredResults.length == 1 ? 'course' : 'courses'} found',
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5, fontWeight: AppFontWeight.medium),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _filter = const CourseFilterSelection()),
                child: Text('Clear filters', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
              ),
            ],
          ),
        ),
        if (filteredResults.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxl, AppSpacing.xl, 0),
            child: Center(
              child: Text(
                'No courses match these filters.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.gray500),
              ),
            ),
          )
        else
          ...filteredResults.map((c) => Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                child: ContentCard(
                  icon: categoryIcons[c.category],
                  tag: c.category,
                  title: c.title,
                  meta: [c.duration, '${c.modules} modules'],
                  linkLabel: 'View syllabus',
                  onTap: () => context.push('/course/${c.id}'),
                ),
              )),
      ];
    } else {
      final carousels = [
        if (recommended.isNotEmpty) CourseCarouselSection(title: 'Recommended for you', courses: recommended),
        for (final category in _categories) CourseCarouselSection(title: category, courses: filterCourses(category)),
      ];
      bodyItems = [
        ..._headerItems(topInset, isFiltering),
        // AppSpacing.xl between each stacked carousel — same fix as
        // college_feed_screen.dart's _sections(), same reason: each
        // carousel's own built-in clearance (AppShadows.cardBuffer) is
        // sized to stop card shadows clipping, not to read as this app's
        // usual section-to-section rhythm.
        for (var i = 0; i < carousels.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xl),
          carousels[i],
        ],
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: bodyItems,
      )),
    );
  }
}

/// One trust-badge card in the credibility carousel above the search bar —
/// same tinted-box shell language as the nudge cards on Home
/// (AppColors.blueA10, AppRadius.lg), but with a plain leading icon circle
/// instead of a trailing nav button since there's nowhere for a claim like
/// "NEP 2020 Aligned" to navigate to.
class _CredibilityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  const _CredibilityCard({required this.icon, required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.blue),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5, fontWeight: AppFontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

