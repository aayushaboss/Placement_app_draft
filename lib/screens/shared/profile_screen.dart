import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/profile_readiness.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/initials.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/badges.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/responsive_body.dart';
import 'video_profile_screen.dart';

const _segmentLabels = {Segment.school: 'School Student', Segment.ug: 'Undergraduate', Segment.pg: 'Postgraduate', Segment.working: 'Working'};

class _ProfileRow {
  final IconData icon;
  final String label;
  final String? route;

  /// Optional live value shown before the chevron (e.g. the current app
  /// language) — null for every other row today.
  final String? trailing;
  const _ProfileRow({required this.icon, required this.label, this.route, this.trailing});
}

/// "Saved" is college-only — school users never bookmark opportunities.
List<_ProfileRow> _rowsFor(bool isSchool) => [
      if (!isSchool) const _ProfileRow(icon: Ionicons.bookmark_outline, label: 'Saved', route: '/saved'),
      const _ProfileRow(icon: Ionicons.calendar_outline, label: 'Bookings', route: '/tabs/sessions'),
      // College-only, same as Saved — school users have no Applications tab
      // to have swipe-deleted anything from in the first place.
      if (!isSchool) const _ProfileRow(icon: Ionicons.trash_outline, label: 'Recently Deleted', route: '/applications/recently-deleted'),
      // 'Support & Help' (routed to '/support') is on hold until there's
      // real company content behind it — see the note on that route in
      // router.dart. Re-add the row here once it's back.
    ];


/// Mirrors frontend/src/screens/ProfileScreen.tsx (ProfileScreen).
/// Hosted as the "Profile" tab in TabsScaffold. Naukri-style: information
/// sectioned into per-category cards instead of one long settings form, so
/// nothing reads as overwhelming and each card shows what's actually filled
/// in rather than just a label.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Branch index 4 (Profile) — see router.dart's StatefulShellRoute.
    ScrollToTopRegistry.register(4, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(4);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final appState = context.read<AppState>();
    await appState.logout();
    if (!context.mounted) return;
    context.go('/onboarding');
  }

  void _editBasics(BuildContext context) => context.push('/profile-edit?returnTo=%2Ftabs%2Fprofile');
  // /college/resume, not /college/resume/build directly — that screen is
  // the one that actually offers both options (upload a PDF, or "Don't
  // have a PDF? Build it here"). Jumping straight to /build skipped the
  // choice entirely and always looked like build-only.
  void _editResume(BuildContext context) => context.push('/college/resume');

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isSchool = user?.segment == Segment.school;
    final rows = [
      ..._rowsFor(isSchool),
      _ProfileRow(
        icon: Ionicons.language_outline,
        label: 'App language',
        route: '/language-select?edit=1',
        trailing: user?.appLanguage ?? 'English',
      ),
    ];
    final topInset = MediaQuery.of(context).padding.top;
    final resume = user?.resume;
    final hasResume = user?.hasResume ?? false;
    // Single source of truth for every card's done/not-done badge below —
    // same profileChecklist the Home feed's completion dial and _BoostTip
    // both read, so this screen can't silently disagree with them.
    final checklist = {for (final i in user?.profileChecklist ?? const []) i.id: i.done};

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
            decoration: const BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                  child: user?.photoUrl != null
                      ? ClipOval(child: Image.network(user!.photoUrl!, width: 84, height: 84, fit: BoxFit.cover))
                      : Text(initialsFor(user?.name), style: AppTextStyles.h1.copyWith(color: AppColors.blue, fontSize: 30, fontWeight: AppFontWeight.semibold)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(user?.name ?? 'Student', style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 22, fontWeight: AppFontWeight.extrabold)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(user?.identifier ?? '', style: AppTextStyles.body.copyWith(color: AppColors.whiteA70, fontSize: 14)),
                ),
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Ionicons.ribbon, size: 13, color: AppColors.blue),
                      const SizedBox(width: 5),
                      Text(
                        _segmentLabels[user?.segment] ?? 'Student',
                        style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium),
                      ),
                    ],
                  ),
                ),
                // School users' Profile tab only ever has the one Basic
                // details section (see profile_readiness.dart's segment
                // branch on profileChecklist), so a completion dial here
                // would just be a permanent, meaningless 100-or-0 — skip it
                // rather than show a ring that can't say anything useful.
                if (!isSchool)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProgressRing(
                          percent: user?.profileProgressPercent ?? 0,
                          size: 36,
                          background: AppColors.whiteA20,
                          valueColor: AppColors.yellow,
                          textColor: AppColors.white,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${user?.profileCompletedCount ?? 0}/${user?.profileTotalCount ?? 0} sections complete',
                          style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 12, fontWeight: AppFontWeight.medium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isSchool)
                  _SectionCard(
                    title: 'Resume',
                    icon: Ionicons.document_text_outline,
                    done: checklist['resume'],
                    onTap: () => _editResume(context),
                    child: hasResume
                        ? Text(
                            _skillsSummary(resume?.skills ?? const []),
                            style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5),
                          )
                        : Text(
                            'Add your resume so recruiters can find you.',
                            style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5),
                          ),
                  ),
                // Basic details and Goals & roles used to be two separate
                // cards, but both ever did was open the same /profile-edit
                // form at a different scroll position — reading as two
                // things when it's really one edit destination. Combined
                // into a single card; Employment below keeps its own card
                // since it now opens a genuinely distinct screen.
                _SectionCard(
                  title: 'Basic details',
                  icon: Ionicons.person_outline,
                  // Represents both checklist items this one card covers
                  // (see the comment above about why they're merged).
                  done: isSchool ? checklist['basic'] : ((checklist['basic'] ?? false) && (checklist['goals'] ?? false)),
                  onTap: () => _editBasics(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._basicDetailLines(user, isSchool).asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              noOrphan(e.value),
                              // Medium, not semibold — the card title above
                              // (now bold) is the heading; the name is this
                              // card's content and shouldn't compete with
                              // it at nearly the same weight.
                              style: e.key == 0
                                  ? AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14.5, fontWeight: AppFontWeight.medium)
                                  : AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5),
                            ),
                          )),
                      if (!isSchool) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(_goalLabel(user?.goal), style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5)),
                        ),
                        if (user?.roles?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: user!.roles!.map((r) => AppTag(label: r)).toList(),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                // College-only — a video pitch is a recruiter-facing
                // signal. School users aren't applying to jobs yet, so this
                // card stays out of their profile screen entirely — it
                // should look exactly like it did before.
                if (!isSchool)
                  _SectionCard(
                    title: 'Video profile',
                    icon: Ionicons.videocam_outline,
                    done: checklist['video'],
                    onTap: () => showVideoProfileSheet(context),
                    child: (user?.videoIntroUrl?.trim().isNotEmpty ?? false)
                        ? Row(
                            children: [
                              const Icon(Ionicons.play_circle, size: 16, color: AppColors.blue),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Video profile added', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 13.5, fontWeight: AppFontWeight.medium)),
                            ],
                          )
                        : Text(noOrphan('Pitch yourself with a short video.'), style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5)),
                  ),
                // The old standalone "Career preferences" card is gone —
                // that concept now lives inline on college Home's filter
                // icon instead (see college_feed_screen.dart /
                // opportunity_filter_screen.dart). checklist['preferences']
                // still exists and still counts toward the completion
                // percentage above; it just has no dedicated card here
                // anymore, the same way completing it now happens on Home.
                Container(
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      const _NotificationToggleRow(),
                      ...rows.asMap().entries.map((entry) {
                      final i = entry.key;
                      final r = entry.value;
                      return GestureDetector(
                        onTap: r.route == null
                            ? null
                            : () => r.route!.startsWith('/tabs') ? context.go(r.route!) : context.push(r.route!),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border, width: 1)) : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                child: Icon(r.icon, size: 20, color: AppColors.blue),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(r.label, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 15, fontWeight: AppFontWeight.medium)),
                              ),
                              if (r.trailing != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                                  child: Text(r.trailing!, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5)),
                                ),
                              const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
                            ],
                          ),
                        ),
                      );
                      }),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _logout(context),
                  child: Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xl),
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.error, width: 1.5)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Ionicons.log_out_outline, size: 20, color: AppColors.error),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Log out', style: AppTextStyles.bodyLg.copyWith(color: AppColors.error, fontSize: 16, fontWeight: AppFontWeight.medium)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Text('Aerostar Edge • v1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

String _skillsSummary(List<String> skills) {
  if (skills.isEmpty) return 'Resume saved.';
  final shown = skills.take(4).join(', ');
  final more = skills.length - 4;
  return more > 0 ? '$shown +$more more' : shown;
}

String _goalLabel(String? goal) {
  switch (goal) {
    case 'internship':
      return 'Looking for an internship';
    case 'job':
      return 'Looking for a full-time job';
    case 'both':
      return 'Open to internships and full-time roles';
    default:
      return "What you're looking for.";
  }
}

List<String> _basicDetailLines(User? user, bool isSchool) {
  final lines = <String>[];
  lines.add(user?.name?.trim().isNotEmpty == true ? user!.name! : 'Name not set');
  lines.add(user?.city?.trim().isNotEmpty == true ? user!.city! : 'City not set');
  if (isSchool) {
    final classBoard = [user?.currentClass, user?.board].where((s) => s != null && s.trim().isNotEmpty).join(' • ');
    lines.add(classBoard.isEmpty ? 'Class & board not set' : classBoard);
  } else {
    final collegeLine = [user?.college, user?.course, user?.year].where((s) => s != null && s.trim().isNotEmpty).join(' • ');
    lines.add(collegeLine.isEmpty ? 'College details not set' : collegeLine);
  }
  return lines;
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget child;
  // null = don't show a badge at all (matches every existing call site
  // that doesn't pass it); non-null drives the checkmark/empty-circle
  // indicator from profileChecklist.
  final bool? done;
  const _SectionCard({required this.title, required this.icon, required this.child, this.onTap, this.done});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.blue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 15))),
                if (done != null) ...[
                  Icon(
                    done! ? Ionicons.checkmark_circle : Ionicons.ellipse_outline,
                    size: 16,
                    color: done! ? AppColors.success : AppColors.gray400,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (onTap != null) const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.gray400),
              ],
            ),
            Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: child),
          ],
        ),
      ),
    );
  }
}

/// Lets someone who dismissed the Home FOMO prompt (or just never saw it)
/// turn browser notifications on later — the one other place that action
/// lives, so it isn't gone for good after "Not now".
class _NotificationToggleRow extends StatefulWidget {
  const _NotificationToggleRow();

  @override
  State<_NotificationToggleRow> createState() => _NotificationToggleRowState();
}

class _NotificationToggleRowState extends State<_NotificationToggleRow> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = _permissionGranted();
  }

  bool _permissionGranted() {
    if (!kIsWeb) return false;
    try {
      return html.Notification.permission == 'granted';
    } catch (_) {
      // Notification API not exposed at all in this context (e.g. a
      // sandboxed preview iframe) — treat as unsupported, not "on".
      return false;
    }
  }

  Future<void> _toggle(bool value) async {
    if (!kIsWeb) return;
    if (!value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turn off notifications from your browser settings.')),
      );
      return;
    }
    String result = 'default';
    try {
      result = await html.Notification.requestPermission();
    } catch (_) {
      // Notification API unavailable in this context — nothing to request.
    }
    if (!mounted) return;
    setState(() => _enabled = _permissionGranted());
    if (result == 'denied' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notifications are blocked for this site — allow them from your browser's site settings.")),
      );
    } else if (result != 'granted' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't turn on notifications here — try from your device's browser settings.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
            child: const Icon(Ionicons.notifications_outline, size: 20, color: AppColors.blue),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text('Push notifications', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 15, fontWeight: AppFontWeight.medium)),
          ),
          Switch(value: _enabled, onChanged: _toggle, activeThumbColor: AppColors.blue),
        ],
      ),
    );
  }
}
