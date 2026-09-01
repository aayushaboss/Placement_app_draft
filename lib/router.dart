import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/college/goals_screen.dart';
import 'screens/college/opportunity_category_picker_screen.dart';
import 'screens/college/opportunity_detail_screen.dart';
import 'screens/college/opportunity_filter_screen.dart';
import 'screens/college/opportunity_list_screen.dart';
import 'screens/college/recently_deleted_applications_screen.dart';
import 'screens/college/resume_builder_quiz_screen.dart';
import 'screens/college/resume_screen.dart';
import 'screens/college/search_screen.dart';
import 'screens/onboarding/landing_screen.dart';
import 'screens/onboarding/language_full_list_screen.dart';
import 'screens/onboarding/language_select_screen.dart';
import 'screens/onboarding/micro_profile_screen.dart';
import 'screens/school/aptitude_intro_screen.dart';
import 'screens/school/aptitude_screen.dart';
import 'screens/school/course_category_picker_screen.dart';
import 'screens/school/course_filter_screen.dart';
import 'screens/school/courses_explore_screen.dart';
import 'screens/school/results_screen.dart';
import 'screens/shared/application_detail_screen.dart';
import 'screens/shared/booking_confirmed_screen.dart';
import 'screens/shared/booking_screen.dart';
import 'screens/shared/course_detail_screen.dart';
import 'screens/shared/notifications_screen.dart';
import 'screens/shared/profile_edit_screen.dart';
import 'screens/shared/profile_screen.dart';
import 'screens/shared/recruiter_actions_screen.dart';
import 'screens/shared/saved_screen.dart';
import 'screens/shared/search_appearances_screen.dart';
import 'screens/shared/sessions_screen.dart';
import 'screens/shared/skill_story_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tabs/tabs_scaffold.dart';
import 'snackbar_observer.dart';
import 'state/app_state.dart';
import 'widgets/placeholder_screen.dart';

/// Auth-entry screens — reachable while signed out, and the destination a
/// signed-in user should be bounced *away* from once fully onboarded.
const _authEntryRoutes = {'/onboarding', '/onboarding/profile', '/auth/login', '/auth/otp'};

/// Single source of truth for app navigation. Replaces the interim
/// Navigator.push + resolveRoute pattern used while screens were converted
/// one at a time (Step 3).
GoRouter buildRouter(AppState appState, GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: appState,
    observers: [SnackBarDismissObserver(scaffoldMessengerKey)],
    redirect: (context, state) {
      // Bootstrap hasn't resolved yet — splash owns navigation until then.
      if (appState.loading) return null;

      final path = state.matchedLocation;
      if (path == '/splash') return null;

      final user = appState.user;
      final isAuthEntry = _authEntryRoutes.contains(path);

      // Fully onboarded users shouldn't land back on the sign-in screens —
      // e.g. a bookmark, shared link, or browser back button pointed at '/'.
      if (user != null && user.onboardingComplete && isAuthEntry) {
        return '/tabs';
      }

      // Forces a language choice before anything else, for a signed-out
      // visitor who hasn't made one yet. Deliberately NOT folded into
      // _authEntryRoutes: that set also drives the "bounce a fully onboarded
      // signed-in user away" rule above — adding this route to it would make
      // Profile's edit-mode entry point (a signed-in, onboarded user pushing
      // this route to change their language) immediately redirect to /tabs
      // before the screen ever renders.
      //
      // startsWith, not a plain ==, so /language-select/other (the "Other"
      // row's full-list sub-screen) is exempt too — matching on the exact
      // path alone let this rule catch that push right back to
      // /language-select the instant it fired, an infinite-feeling loop
      // that just looked like tapping "Other" did nothing.
      final isLanguageSelectRoute = path.startsWith('/language-select');
      if (user == null && appState.appLanguage == null && !isLanguageSelectRoute) {
        return '/language-select';
      }

      // Anything else requires a signed-in user — a signed-out visitor
      // pasting a deep link (e.g. /tabs, /college/goals) gets sent to the
      // start of onboarding instead of rendering a screen with no user.
      if (user == null && !isLanguageSelectRoute && !isAuthEntry) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/language-select',
        builder: (context, state) => LanguageSelectScreen(isEditMode: state.uri.queryParameters['edit'] == '1'),
      ),
      GoRoute(path: '/language-select/other', builder: (context, state) => const LanguageFullListScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/onboarding/profile', builder: (context, state) => const MicroProfileScreen()),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => LoginScreen(
          returning: state.uri.queryParameters['returning'] == '1',
          startOnEmail: state.uri.queryParameters['mode'] == 'email',
        ),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => OtpScreen(
          identifier: state.uri.queryParameters['identifier'] ?? '',
          returning: state.uri.queryParameters['returning'] == '1',
        ),
      ),
      GoRoute(path: '/school/aptitude-intro', builder: (context, state) => const AptitudeIntroScreen()),
      GoRoute(path: '/school/aptitude', builder: (context, state) => const AptitudeScreen()),
      GoRoute(path: '/school/results', builder: (context, state) => ResultsScreen(initialCluster: state.uri.queryParameters['cluster'])),
      GoRoute(
        path: '/school/course-filter',
        builder: (context, state) => CourseFilterScreen(initial: state.extra as CourseFilterSelection? ?? const CourseFilterSelection()),
      ),
      GoRoute(
        path: '/school/course-category-picker',
        builder: (context, state) => CourseCategoryPickerScreen(initialSelected: (state.extra as List<String>?) ?? const []),
      ),
      GoRoute(
        path: '/college/resume',
        builder: (context, state) => ResumeScreen(applyForOpportunityId: state.uri.queryParameters['applyFor']),
      ),
      GoRoute(
        path: '/college/resume/build',
        // Keyed on the step param so navigating between steps (e.g. from
        // "Add to profile") always mounts a fresh screen instead of
        // silently no-op'ing when the widget is already on-screen.
        builder: (context, state) => ResumeBuilderQuizScreen(
          key: ValueKey('resume-build-${state.uri.queryParameters['step'] ?? '0'}'),
          applyForOpportunityId: state.uri.queryParameters['applyFor'],
          initialStep: int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/college/goals', builder: (context, state) => const GoalsScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(
        path: '/booking',
        builder: (context, state) => BookingScreen(
          kind: state.uri.queryParameters['kind'] ?? 'counseling',
          bookingId: state.uri.queryParameters['bookingId'],
          initialDate: state.uri.queryParameters['date'],
          initialTime: state.uri.queryParameters['time'],
          initialMode: state.uri.queryParameters['mode'],
          initialSessionType: state.uri.queryParameters['sessionType'],
        ),
      ),
      GoRoute(
        path: '/booking-confirmed',
        builder: (context, state) => BookingConfirmedScreen(
          kind: state.uri.queryParameters['kind'] ?? 'counseling',
          date: state.uri.queryParameters['date'] ?? '',
          time: state.uri.queryParameters['time'] ?? '',
          mode: state.uri.queryParameters['mode'] ?? 'online',
          counselor: state.uri.queryParameters['counselor'] ?? '',
          sessionType: state.uri.queryParameters['sessionType'] ?? '',
          venueName: state.uri.queryParameters['venueName'] ?? '',
          venueAddress: state.uri.queryParameters['venueAddress'] ?? '',
        ),
      ),
      GoRoute(path: '/opportunity/:id', builder: (context, state) => OpportunityDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(
        path: '/opportunities',
        builder: (context, state) => OpportunityListScreen(
          title: state.uri.queryParameters['title'] ?? 'Opportunities',
          category: state.uri.queryParameters['category'],
          ids: state.uri.queryParameters['ids']?.split(','),
        ),
      ),
      GoRoute(path: '/application/:id', builder: (context, state) => ApplicationDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/applications/recently-deleted', builder: (context, state) => const RecentlyDeletedApplicationsScreen()),
      GoRoute(path: '/course/:id', builder: (context, state) => CourseDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => ProfileEditScreen(
          returnTo: state.uri.queryParameters['returnTo'],
          scrollToSection: state.uri.queryParameters['section'],
        ),
      ),
      GoRoute(path: '/college/opportunity-filter', builder: (context, state) => const OpportunityFilterScreen()),
      GoRoute(
        path: '/college/opportunity-category-picker',
        builder: (context, state) => OpportunityCategoryPickerScreen(initialSelected: (state.extra as List<String>?) ?? const []),
      ),
      GoRoute(path: '/search-appearances', builder: (context, state) => const SearchAppearancesScreen()),
      GoRoute(path: '/recruiter-actions', builder: (context, state) => const RecruiterActionsScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
      // '/support' (SupportScreen, in screens/shared/support_screen.dart) is
      // on hold — built from a naukri/internshala reference, not yet backed
      // by real company content, so the route and its Profile-menu entry are
      // pulled until there's real copy to put behind it. The screen file
      // itself is left in place, unrouted, so it's a quick re-add later.
      GoRoute(path: '/story/:id', builder: (context, state) => SkillStoryScreen(id: state.pathParameters['id']!)),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TabsScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/tabs', builder: (context, state) => const HomeTabScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/browse', builder: (context, state) => const BrowseTabScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/sessions', builder: (context, state) => const SessionsScreen())]),
          // College-only branch (hidden from the tab bar for school users,
          // see TabsScaffold) — course discovery, replacing what used to be
          // a dedicated "Saved" tab. Saved opportunities are still reachable,
          // just demoted to a Profile row instead of a primary tab slot.
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/explore', builder: (context, state) => const CoursesExploreScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tabs/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
    errorBuilder: (context, state) => PlaceholderScreen(routeName: state.uri.toString()),
  );
}
