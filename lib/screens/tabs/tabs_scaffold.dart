import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../college/college_feed_screen.dart';
import '../school/courses_explore_screen.dart';
import '../school/school_home_screen.dart';
import '../shared/applications_tracker_screen.dart';
import '../../widgets/responsive_body.dart';

/// Home tab body: SchoolHome for school segment, CollegeFeed otherwise.
/// Mirrors frontend/app/(tabs)/index.tsx.
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSchool = context.watch<AppState>().user?.segment == Segment.school;
    return isSchool ? const SchoolHomeScreen() : const CollegeFeedScreen();
  }
}

/// Browse tab body: CoursesExplore for school segment, ApplicationsTracker
/// otherwise. Mirrors frontend/app/(tabs)/browse.tsx.
class BrowseTabScreen extends StatelessWidget {
  const BrowseTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSchool = context.watch<AppState>().user?.segment == Segment.school;
    return isSchool ? const CoursesExploreScreen() : const ApplicationsTrackerScreen();
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int branchIndex;
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.branchIndex});
}

/// Bottom tab bar shell. Mirrors frontend/app/(tabs)/_layout.tsx.
/// The "Courses" tab shows course discovery for both segments — branch
/// index 3 (labeled Explore internally in the router) for college, branch
/// index 1 (BrowseTabScreen's own CoursesExploreScreen) for school, who
/// otherwise have no separate Applications tab to occupy that slot. Saved
/// opportunities moved off the tab bar entirely into a Profile row now that
/// this slot is Courses.
class TabsScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const TabsScaffold({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    final isSchool = context.watch<AppState>().user?.segment == Segment.school;

    // Tab-bar visual order is independent of each route's branchIndex, so
    // reordering here never needs router changes — just where each item
    // appears in this list. Order: Home, Applications (college-only) /
    // Sessions (school-only), Courses, Profile.
    //
    // College has no Bookings item — branch 2 (Sessions screen) is
    // reachable from Profile's "Bookings" row and Home's tappable Upcoming
    // Session card, which is enough for what's a secondary JTBD there.
    // School gets Sessions as a bottom-tab item in its own right — counseling
    // is co-equal with aptitude/courses as school's top job-to-be-done, so it
    // belongs in the main menu rather than tucked away in Profile.
    final items = <_TabItem>[
      const _TabItem(icon: Ionicons.home_outline, activeIcon: Ionicons.home, label: 'Home', branchIndex: 0),
      if (!isSchool) const _TabItem(icon: Ionicons.list_outline, activeIcon: Ionicons.list, label: 'Applications', branchIndex: 1),
      if (isSchool) const _TabItem(icon: Ionicons.calendar_outline, activeIcon: Ionicons.calendar, label: 'Sessions', branchIndex: 2),
      _TabItem(icon: Ionicons.flash_outline, activeIcon: Ionicons.flash, label: 'Courses', branchIndex: isSchool ? 1 : 3),
      const _TabItem(icon: Ionicons.person_outline, activeIcon: Ionicons.person, label: 'Profile', branchIndex: 4),
    ];

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              // Caps and centers just the tab row on tablet — otherwise 4
              // items stretched across ~768-1024px each get a lot of empty
              // space around a small centered icon+label, reading as sparse
              // rather than a deliberate wide layout.
              child: ResponsiveBody(child: Row(
                children: items.map((item) {
                  final active = shell.currentIndex == item.branchIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        // IndexedStack preserves each branch's state across
                        // switches (that's the point), so a snackbar shown
                        // on one tab would otherwise still be sitting there
                        // after switching away — the NavigatorObserver on
                        // GoRouter doesn't fire for this since it's a
                        // visibility change, not a push/pop.
                        ScaffoldMessenger.of(context).clearSnackBars();
                        final wasAlreadyActive = item.branchIndex == shell.currentIndex;
                        shell.goBranch(item.branchIndex, initialLocation: wasAlreadyActive);
                        // Re-tapping the tab you're already on pops its
                        // nested Navigator back to its root route (that's
                        // what initialLocation does above) but doesn't touch
                        // scroll position on its own — that screen's own
                        // ScrollController does the rest.
                        if (wasAlreadyActive) ScrollToTopRegistry.trigger(item.branchIndex);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(active ? item.activeIcon : item.icon, size: 24, color: active ? AppColors.blue : AppColors.gray400),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: AppTextStyles.label.copyWith(fontSize: 11, color: active ? AppColors.blue : AppColors.gray400),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )),
            ),
          ),
        ),
      ),
    );
  }
}
