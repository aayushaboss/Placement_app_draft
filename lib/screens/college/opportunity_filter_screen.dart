import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_profile_options.dart';
import '../../models/job_preferences.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/autocomplete_field.dart';
import '../../widgets/field_label.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

const _goalOptions = [
  ('internship', 'Internship'),
  ('job', 'Full-time'),
  ('both', 'Both'),
];

// Opportunity.workMode's real values — an earlier version of this facet
// (JobPreferences.shift) used a different, mismatched WFH/Hybrid/On-site
// vocabulary that matched nothing on an actual Opportunity.
const _workModeOptions = ['Remote', 'Onsite', 'Hybrid'];

const _employmentTypeOptions = ['Full-time', 'Part-time'];

/// Replaces the old standalone "Career preferences" screen — reachable from
/// college Home's filter icon. Unlike the Courses tab's filter (purely
/// ephemeral tab-local state), this one hydrates from and saves straight to
/// `AppState.user` on open/apply, since preferences here are meant to be
/// remembered, not reset every visit. Category and Job/Internship bind
/// directly to `User.roles`/`User.goal` (not a separate filter-only copy)
/// — the exact same lists Home's own carousels and match-scoring already
/// read, so the filter can never disagree with the rest of the app about
/// what a user is interested in.
class OpportunityFilterScreen extends StatefulWidget {
  const OpportunityFilterScreen({super.key});

  @override
  State<OpportunityFilterScreen> createState() => _OpportunityFilterScreenState();
}

class _OpportunityFilterScreenState extends State<OpportunityFilterScreen> {
  List<String> _roles = [];
  String _goal = '';
  String? _workMode;
  String? _employmentType;
  List<String> _cities = [];
  final _cityController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _hydrate() {
    final user = context.read<AppState>().user;
    _roles = List.of(user?.roles ?? const []);
    _goal = user?.goal ?? '';
    _workMode = user?.preferences?.workMode;
    _employmentType = user?.preferences?.employmentType;
    _cities = List.of(user?.preferences?.cities ?? const []);
  }

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _pickRoles() async {
    final result = await context.push<List<String>>('/college/opportunity-category-picker', extra: _roles);
    if (result != null) setState(() => _roles = result);
  }

  void _selectGoal(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      _goal = key;
      // Employment type only means anything for Full-time/Both — clear it
      // rather than leave a stale selection that would silently zero out
      // results once Internship is combined with it.
      if (key == 'internship') _employmentType = null;
    });
  }

  void _toggleWorkMode(String mode) {
    HapticFeedback.selectionClick();
    setState(() => _workMode = _workMode == mode ? null : mode);
  }

  void _toggleEmploymentType(String type) {
    if (_goal == 'internship') return;
    HapticFeedback.selectionClick();
    setState(() => _employmentType = _employmentType == type ? null : type);
  }

  void _addCity(String c) {
    final trimmed = c.trim();
    if (trimmed.isEmpty) return;
    final alreadyAdded = _cities.any((existing) => existing.toLowerCase() == trimmed.toLowerCase());
    if (alreadyAdded) return;
    HapticFeedback.selectionClick();
    setState(() => _cities = [..._cities, trimmed]);
  }

  void _removeCity(String c) {
    HapticFeedback.selectionClick();
    setState(() => _cities = _cities.where((x) => x != c).toList());
  }

  bool get _valid => _goal.isNotEmpty && _roles.isNotEmpty;

  // Clears only the true *filter* facets — not Category/Goal, which are
  // identity fields bound to the profile (see this screen's own doc
  // comment above). The old implementation called setState(_hydrate),
  // which re-read every field — including Category/Goal — from the last
  // *saved* profile. Since those two rarely change, Reset would silently
  // revert Work mode/Employment type/Cities to whatever was saved last
  // time Apply was tapped rather than actually clearing them — often
  // producing no visible change at all, which read as "Reset is broken."
  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _workMode = null;
      _employmentType = null;
      _cities = [];
    });
  }

  Future<void> _apply() async {
    if (!_valid) return;
    setState(() => _loading = true);
    final prefs = JobPreferences(cities: _cities, workMode: _workMode, employmentType: _employmentType);
    await context.read<AppState>().updateProfile((current) => current.copyWith(goal: _goal, roles: _roles, preferences: prefs));
    if (!mounted) return;
    setState(() => _loading = false);
    // go(), not pop() — pop() after this screen's own await gap updates the
    // URL (confirmed via the browser's location hash) but leaves this
    // screen's widget tree on-screen, unpopped: the same silently-broken
    // pop() behavior already documented and worked around in
    // profile_edit_screen.dart's save flow. This screen is always reached
    // from Home's filter icon, so returning straight there is correct
    // regardless of how it was pushed.
    context.go('/tabs');
  }

  Widget _removableChip(String label, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Ionicons.close, size: 14, color: AppColors.blue),
          ],
        ),
      ),
    );
  }

  // Same visual language as _removableChip, minus the close icon — Category
  // is only ever edited wholesale via the picker screen (_pickRoles), not
  // added/removed inline the way cities are, so a badge here is read-only;
  // the whole row it sits in already opens that picker on tap.
  Widget _roleBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final employmentDisabled = _goal == 'internship';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: Column(
        children: [
          Container(
            color: AppColors.blue,
            padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(onTap: () => context.pop(), child: const Icon(Ionicons.chevron_back, size: 26, color: AppColors.white)),
                Text('Filter jobs', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 18, fontWeight: AppFontWeight.semibold)),
                const SizedBox(width: AppSpacing.xxl),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                const FieldLabel('Category', tight: true),
                GestureDetector(
                  onTap: _pickRoles,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 54),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      children: [
                        const Icon(Ionicons.briefcase_outline, size: 18, color: AppColors.gray500),
                        const SizedBox(width: 8),
                        Expanded(
                          // Real badges, not a comma-joined string — matches
                          // "Preferred cities" below visually (blueA10 pill,
                          // blue text), just read-only: this row's own tap
                          // target already opens the picker screen, which is
                          // the only place roles are actually edited, so a
                          // badge here doesn't need its own remove `x`.
                          child: _roles.isEmpty
                              ? Text('All roles', style: AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.gray400, fontWeight: AppFontWeight.regular))
                              : Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: _roles.map((r) => _roleBadge(r)).toList(),
                                ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
                      ],
                    ),
                  ),
                ),
                const FieldLabel('Internship or full-time'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _goalOptions
                      .map((g) => AppChip(label: g.$2, selected: _goal == g.$1, onPressed: () => _selectGoal(g.$1)))
                      .toList(),
                ),
                const FieldLabel('Work mode'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _workModeOptions
                      .map((m) => AppChip(label: m, selected: _workMode == m, onPressed: () => _toggleWorkMode(m)))
                      .toList(),
                ),
                const FieldLabel('Employment type'),
                if (employmentDisabled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Only applies to full-time roles.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12),
                    ),
                  ),
                Opacity(
                  opacity: employmentDisabled ? 0.4 : 1.0,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _employmentTypeOptions
                        .map((t) => AppChip(
                              label: t,
                              selected: _employmentType == t,
                              disabled: employmentDisabled,
                              onPressed: () => _toggleEmploymentType(t),
                            ))
                        .toList(),
                  ),
                ),
                const FieldLabel('Preferred cities'),
                if (_cities.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _cities.map((c) => _removableChip(c, () => _removeCity(c))).toList(),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: AutocompleteField(
                    value: '',
                    placeholder: 'e.g. Bengaluru',
                    icon: Ionicons.location_outline,
                    options: mockCities,
                    onChanged: (_) {},
                    onSelected: _addCity,
                    onSubmitted: _addCity,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PillButton(label: 'Apply', onPressed: _valid ? _apply : null, loading: _loading, disabled: !_valid),
                const SizedBox(height: AppSpacing.md),
                // De-emphasized on purpose, same treatment as "Clear
                // filters" elsewhere (college_feed_screen.dart,
                // courses_explore_screen.dart) — Reset is a minor, reversible
                // action and shouldn't visually compete with Apply.
                GestureDetector(
                  onTap: _reset,
                  child: Text('Reset', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
