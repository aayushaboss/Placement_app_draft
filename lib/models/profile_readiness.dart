import 'user.dart';

/// Post-onboarding profile checklist item for college apply readiness.
class ProfileChecklistItem {
  final String id;
  final String title;
  final String subtitle;
  final bool requiredForApply;
  final bool done;
  final String route;

  const ProfileChecklistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.requiredForApply,
    required this.done,
    required this.route,
  });
}

/// Pure readiness helpers for college profile completion + apply gate.
extension ProfileReadiness on User {
  /// Segment-aware, deliberately mirroring micro_profile_screen.dart's own
  /// `_canContinue` — a single blanket "name/city/college/course/year all
  /// required" check used to be unsatisfiable for whole segments, since
  /// onboarding never even asks some of those fields depending on segment
  /// (or, for Working, qualification): School asks currentClass+board
  /// instead of college/course/year entirely; Working only asks
  /// college/course when the qualification is Diploma/Graduate/Postgraduate,
  /// and never asks year at all; PG asks college/course but not year (only
  /// UG asks all three). Without this, e.g. a School user or a Working user
  /// with a sub-Diploma qualification could never show as "done" no matter
  /// what they filled in.
  bool get hasBasicInfo {
    final n = name?.trim() ?? '';
    final c = city?.trim() ?? '';
    if (n.isEmpty || c.isEmpty || segment == null) return false;
    switch (segment!) {
      case Segment.school:
        return (currentClass?.trim().isNotEmpty ?? false) && (board?.trim().isNotEmpty ?? false);
      case Segment.working:
        final q = highestQualification?.trim() ?? '';
        if (q.isEmpty) return false;
        // Mirrors micro_profile_screen.dart's _educatedQualifications —
        // keep both in sync if that set ever changes.
        final educated = {'Diploma', 'Graduate', 'Postgraduate'}.contains(q);
        return !educated || ((college?.trim().isNotEmpty ?? false) && (course?.trim().isNotEmpty ?? false));
      case Segment.ug:
      case Segment.pg:
        final hasCollegeCourse = (college?.trim().isNotEmpty ?? false) && (course?.trim().isNotEmpty ?? false);
        final yearOk = segment == Segment.pg || (year?.trim().isNotEmpty ?? false);
        return hasCollegeCourse && yearOk;
    }
  }

  bool get hasResume {
    final r = resume;
    if (r == null) return false;
    return r.name.trim().isNotEmpty || r.skills.isNotEmpty || r.education.isNotEmpty || r.projects.isNotEmpty;
  }

  bool get hasPhoto => (photoUrl?.trim() ?? '').isNotEmpty;

  bool get hasGoals {
    final g = goal?.trim() ?? '';
    final r = roles;
    return g.isNotEmpty && r != null && r.isNotEmpty;
  }

  bool get hasVideoIntro => (videoIntroUrl?.trim() ?? '').isNotEmpty;

  bool get hasPreferences => !(preferences?.isEmpty ?? true);

  /// Hard unlock for job applications. Basic info used to gate this too,
  /// but it required 5 fields (name/city/college/course/year) with no
  /// visual indication on the edit screen of which were still missing —
  /// a user could look fully filled-in and still be stuck. Resume is the
  /// one thing that actually needs to exist before applying.
  bool get canApply => hasResume;

  /// Every item here that isn't `basic`/`resume` is `requiredForApply: false`
  /// — [missingForApply]/[applyStepsRemaining] filter on that flag, so
  /// growing this list to cover the full Profile tab (not just the apply
  /// gate's 2 required fields) can never change what the apply gate itself
  /// requires. School users only ever see `basic` — the other 3 sections
  /// don't exist on their Profile tab (see profile_screen.dart's `isSchool`
  /// gates), so scoring them against a checklist they have no UI to
  /// complete would strand their percent below 100 forever.
  List<ProfileChecklistItem> get profileChecklist {
    final basic = ProfileChecklistItem(
      id: 'basic',
      title: 'Basic info',
      subtitle: 'Name, city, college, course, year',
      requiredForApply: false,
      done: hasBasicInfo,
      route: '/profile-edit',
    );
    if (segment == Segment.school) return [basic];

    return [
      basic,
      ProfileChecklistItem(
        id: 'resume',
        title: 'Resume',
        subtitle: 'Paste or build your resume',
        requiredForApply: true,
        done: hasResume,
        route: '/college/resume',
      ),
      ProfileChecklistItem(
        id: 'goals',
        title: 'Goals & roles',
        subtitle: 'What you’re looking for',
        requiredForApply: false,
        done: hasGoals,
        route: '/profile-edit?section=roles',
      ),
      ProfileChecklistItem(
        id: 'video',
        title: 'Video profile',
        subtitle: 'A short video pitch',
        requiredForApply: false,
        done: hasVideoIntro,
        // No pushable route — showVideoProfileSheet() opens a modal from a
        // BuildContext, not a GoRoute. Landing on the tab and letting the
        // user tap the visible row is a fine outcome for a checklist item,
        // simpler than teaching every consumer of .route a modal-vs-push
        // special case for this one item.
        route: '/tabs/profile',
      ),
      ProfileChecklistItem(
        id: 'preferences',
        title: 'Job preferences',
        subtitle: 'Work mode, city, and employment type',
        requiredForApply: false,
        done: hasPreferences,
        // Was '/preferences' (a standalone screen, now removed) — this
        // concept lives inline on college Home's filter icon instead.
        // Kept as a real route (not removed) since home_dashboard_cards.dart's
        // "boost your profile" nudge reads this item's route independently
        // to build its own CTA button; leaving it pointed at a dead route
        // would break that nudge for anyone who hasn't set preferences yet.
        route: '/college/opportunity-filter',
      ),
    ];
  }

  int get profileCompletedCount => profileChecklist.where((i) => i.done).length;

  int get profileTotalCount => profileChecklist.length;

  int get profileProgressPercent {
    if (profileTotalCount == 0) return 0;
    return ((profileCompletedCount / profileTotalCount) * 100).round();
  }

  int get applyStepsRemaining =>
      profileChecklist.where((i) => i.requiredForApply && !i.done).length;

  List<ProfileChecklistItem> get missingForApply =>
      profileChecklist.where((i) => i.requiredForApply && !i.done).toList();
}
