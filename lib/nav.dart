import 'models/profile_readiness.dart';
import 'models/user.dart';

/// Single source of truth for where a user should land based on onboarding
/// progress. Mirrors frontend/src/nav.ts routeForUser.
///
/// Segment is no longer its own screen/step — it's asked on the profile
/// screen alongside college/class details, so `segment == null` is the
/// signal that the profile screen hasn't been finished yet (name/city can
/// already be set at this point from the mocked Google sign-in, so they
/// can't be used as the "still needs onboarding" check).
String routeForUser(User? user) {
  if (user == null) return '/onboarding';
  if (user.segment == null) return '/onboarding/profile';
  if (!user.onboardingComplete) {
    // School users finish required profile data on the profile screen, then
    // home. College users pick goals/roles next, then upload a resume —
    // the three-step flow this function has to resume mid-way on reload.
    if (user.segment == Segment.school) return '/tabs';
    if (user.goal == null) return '/college/goals';
    if (!user.hasResume) return '/college/resume';
    return '/tabs';
  }
  return '/tabs';
}
