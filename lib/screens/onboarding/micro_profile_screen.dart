import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_profile_options.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/autocomplete_field.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/field_label.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/responsive_body.dart';

const _classOptions = ['Class 11', 'Class 12', 'Below 11'];
const _boardOptions = ['CBSE', 'State', 'IB', 'Other'];
const _priorExperienceOptions = ['Fresher', '1-2 yrs', '3-5 yrs', '5+ yrs'];
const _qualificationOptions = ['Below 10th', '10th pass', '12th pass', 'Diploma', 'Graduate', 'Postgraduate'];
const _educatedQualifications = {'Diploma', 'Graduate', 'Postgraduate'};

const _segmentOptions = [
  (Segment.school, 'School'),
  (Segment.ug, 'Undergraduate'),
  (Segment.pg, 'Postgraduate'),
  (Segment.working, 'Working'),
];

/// One screen instead of a per-question quiz: whatever the mocked Google
/// sign-in already handed back (name, city) shows up pre-filled at the top
/// — with a progress bar proving it — and only the handful of things
/// Google could never know (segment, college/class, course/board, year)
/// need actual typing. The "Continue with Email" path lands here too, just
/// without anything pre-filled, using the exact same fields.
class MicroProfileScreen extends StatefulWidget {
  const MicroProfileScreen({super.key});

  @override
  State<MicroProfileScreen> createState() => _MicroProfileScreenState();
}

class _MicroProfileScreenState extends State<MicroProfileScreen> {
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  String? _signInMethod;
  // Captured alongside _signInMethod in _hydrateFromUser — the exact
  // signal (already used the same way in otp_screen.dart/booking_screen.
  // dart) for whether this account still needs a phone number asked: a
  // phone sign-up's identifier never contains '@', a Google or email
  // sign-up's always does.
  String _identifier = '';
  String _city = '';
  Segment? _segment;
  String _college = '';
  String _course = '';
  String _currentClass = '';
  String _board = '';
  String _semester = '';
  String _priorExperience = '';
  // Only relevant when _priorExperience == '5+ yrs' — an optional refinement
  // on top of the bucket chip, not a replacement for it (see
  // _effectivePriorExperience).
  final _priorExperienceExactController = TextEditingController();
  String _highestQualification = '';
  bool _loading = false;
  bool _hydrated = false;

  bool get _isSchool => _segment == Segment.school;
  bool get _isWorking => _segment == Segment.working;
  bool get _isEducatedWorking => _isWorking && _educatedQualifications.contains(_highestQualification);

  /// Phone sign-up's identifier already is a phone number (auto-filled in
  /// AppState._makeNewUser) — only Google/email sign-ups still need to be
  /// asked here.
  bool get _needsPhone => _identifier.contains('@');

  /// Same 10-15-digit bound already established in login_screen.dart's own
  /// `_valid` getter, reused here rather than inventing a new one.
  bool get _isValidPhone {
    final digits = _phoneController.text.trim();
    return digits.length >= 10 && digits.length <= 15;
  }

  // City/College/Course are free-text (AutocompleteField), unlike the
  // chip-selected fields below them — trimming before every emptiness
  // check on these three (matching how Name already does) stops a
  // whitespace-only entry from counting as "filled" and slipping into the
  // saved profile.
  List<bool> get _filled {
    final base = [
      _nameController.text.trim().isNotEmpty,
      _city.trim().isNotEmpty,
      if (_needsPhone) _isValidPhone,
      _segment != null,
    ];
    if (_segment == null) return base;
    if (_isSchool) return [...base, _currentClass.isNotEmpty, _board.isNotEmpty];
    if (_isWorking) {
      return [
        ...base,
        _highestQualification.isNotEmpty,
        if (_isEducatedWorking) ...[_college.trim().isNotEmpty, _course.trim().isNotEmpty],
      ];
    }
    return [
      ...base,
      _college.trim().isNotEmpty,
      _course.trim().isNotEmpty,
      if (_segment != Segment.pg) _semester.isNotEmpty,
    ];
  }

  double get _progress => _filled.where((f) => f).length / _filled.length;

  bool get _canContinue {
    if (_nameController.text.trim().isEmpty || _city.trim().isEmpty || _segment == null) return false;
    if (_needsPhone && !_isValidPhone) return false;
    if (_isSchool) return _currentClass.isNotEmpty && _board.isNotEmpty;
    if (_isWorking) {
      if (_highestQualification.isEmpty) return false;
      return !_isEducatedWorking || (_college.trim().isNotEmpty && _course.trim().isNotEmpty);
    }
    final semesterOk = _segment == Segment.pg || _semester.isNotEmpty;
    return _college.trim().isNotEmpty && _course.trim().isNotEmpty && semesterOk;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  // Runs once real BuildContext/Provider access is available — can't read
  // the just-signed-in user's prefilled name/city from initState.
  void _hydrateFromUser(User? user) {
    if (_hydrated || user == null) return;
    _hydrated = true;
    _nameController.text = user.name ?? '';
    _city = user.city ?? '';
    _phoneController.text = user.phone ?? '';
    _signInMethod = user.signInMethod;
    _identifier = user.identifier;
    // Previously only name/city/signInMethod were restored here — every
    // other field defaulted to blank on every visit, so the very likely
    // "Goals has nothing to pop, falls back to context.go('/onboarding/
    // profile')" back-navigation path landed on a form that had silently
    // forgotten everything the user just filled in, even though the
    // backing User record still had it all. Restoring the rest here too
    // (only when this is genuinely a re-visit — `user.segment != null`)
    // treats that path as resuming an edit, not starting fresh.
    if (user.segment != null) {
      _segment = user.segment;
      _currentClass = user.currentClass ?? '';
      _board = user.board ?? '';
      _college = user.college ?? '';
      _course = user.course ?? '';
      _semester = user.semester ?? '';
      _highestQualification = user.highestQualification ?? '';
      // Same "5+ yrs" exact-figure restoration already established in
      // profile_edit_screen.dart's own _hydrate — kept in sync deliberately.
      final rawPriorExperience = user.priorExperience ?? '';
      if (rawPriorExperience.isNotEmpty && !_priorExperienceOptions.contains(rawPriorExperience)) {
        _priorExperience = '5+ yrs';
        final leadingDigits = RegExp(r'^\d+').firstMatch(rawPriorExperience)?.group(0);
        if (leadingDigits != null) _priorExperienceExactController.text = leadingDigits;
      } else {
        _priorExperience = rawPriorExperience;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priorExperienceExactController.dispose();
    super.dispose();
  }

  /// The value actually saved for `priorExperience` — usually just the
  /// selected bucket chip, but when "5+ yrs" is selected and a precise
  /// figure was typed, the exact figure wins (e.g. "7 yrs" instead of the
  /// coarser "5+ yrs"). Kept separate from `_priorExperience` itself so the
  /// "5+ yrs" chip stays visibly selected while a number is being typed.
  String get _effectivePriorExperience {
    final exact = _priorExperienceExactController.text.trim();
    if (_priorExperience == '5+ yrs' && exact.isNotEmpty) return '$exact yrs';
    return _priorExperience;
  }

  void _selectPriorExperience(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      _priorExperience = value;
      if (value != '5+ yrs') _priorExperienceExactController.clear();
    });
  }

  /// The prior-experience question, as a label + chip row, plus — only when
  /// "5+ yrs" is selected — a small numeric refinement field right below it
  /// so someone with, say, 8 years doesn't have to settle for the coarse
  /// bucket. Returns a list (not a single widget) so both call sites can
  /// splice it directly into their surrounding `Column`'s `children`.
  List<Widget> _priorExperienceField(String label) {
    return [
      FieldLabel(label),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _priorExperienceOptions
            .map((o) => AppChip(label: o, selected: _priorExperience == o, onPressed: () => _selectPriorExperience(o)))
            .toList(),
      ),
      if (_priorExperience == '5+ yrs') ...[
        const FieldLabel('Exactly how many years? (optional)', tight: true),
        PillInput(
          controller: _priorExperienceExactController,
          placeholder: 'e.g. 7',
          icon: Ionicons.time_outline,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    ];
  }

  void _selectSegment(Segment s) {
    HapticFeedback.selectionClick();
    setState(() {
      // Switching branches leaves the other branches' fields populated but
      // hidden — clear them so a change of mind doesn't silently carry
      // stale values into the submitted profile.
      if (s == Segment.school) {
        _college = '';
        _course = '';
        _semester = '';
        _priorExperience = '';
        _priorExperienceExactController.clear();
        _highestQualification = '';
      } else if (s == Segment.working) {
        _currentClass = '';
        _board = '';
        _college = '';
        _course = '';
        _semester = '';
        _priorExperience = '';
        _priorExperienceExactController.clear();
      } else {
        _currentClass = '';
        _board = '';
        _highestQualification = '';
        // Semester is asked for UG only (never shown or collected for
        // PG) — clearing it unconditionally here, not just when leaving
        // this branch, is what stops a semester picked while on UG from
        // silently surviving a switch to PG and getting saved onto a
        // profile whose own form never displayed or asked for it.
        // _college/_course aren't cleared the same way: both UG and PG
        // (and Working+educated) ask for genuinely the same two fields,
        // so carrying that value across a UG<->PG change of mind is
        // correct, not stale.
        if (s == Segment.pg) _semester = '';
        if (s != Segment.pg) {
          _priorExperience = '';
          _priorExperienceExactController.clear();
        }
      }
      _segment = s;
    });
  }

  Future<void> _pickSemester() async {
    final picked = await showOptionListSheet(
      context,
      options: mockSemesters,
      currentValue: _semester.isEmpty ? null : _semester,
      title: 'Select semester',
    );
    if (picked == null) return;
    HapticFeedback.selectionClick();
    setState(() => _semester = picked);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _submit() async {
    if (!_canContinue) return;
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final isSchool = _isSchool;
      final isWorking = _isWorking;
      await appState.updateProfile((current) => isSchool
          ? current.copyWith(
              name: _nameController.text.trim(),
              city: _city.trim(),
              phone: _needsPhone ? _phoneController.text.trim() : null,
              segment: _segment,
              currentClass: _currentClass,
              board: _board,
              // School required profile is complete — aptitude is optional after this.
              onboardingComplete: true,
              aptitudeSkipped: true,
            )
          : isWorking
              ? current.copyWith(
                  name: _nameController.text.trim(),
                  city: _city.trim(),
                  phone: _needsPhone ? _phoneController.text.trim() : null,
                  segment: _segment,
                  highestQualification: _highestQualification,
                  college: _isEducatedWorking && _college.trim().isNotEmpty ? _college.trim() : null,
                  course: _isEducatedWorking && _course.trim().isNotEmpty ? _course.trim() : null,
                  priorExperience: _isEducatedWorking && _priorExperience.isNotEmpty ? _effectivePriorExperience : null,
                )
              : current.copyWith(
                  name: _nameController.text.trim(),
                  city: _city.trim(),
                  phone: _needsPhone ? _phoneController.text.trim() : null,
                  segment: _segment,
                  college: _college.trim(),
                  course: _course.trim(),
                  semester: _semester,
                  priorExperience: _segment == Segment.pg && _priorExperience.isNotEmpty ? _effectivePriorExperience : null,
                ));
      if (!mounted) return;
      context.go(isSchool ? '/tabs' : '/college/goals');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _hydrateFromUser(context.read<AppState>().user);
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final percent = (_progress * 100).round();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(onTap: _back, child: const Icon(Ionicons.chevron_back, size: 26, color: AppColors.ink)),
                  Expanded(
                    child: Text(
                      'Complete your profile',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxl),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: _progress.clamp(0.04, 1.0)),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: AppSpacing.sm - AppSpacing.xs / 2,
                          backgroundColor: AppColors.offWhite,
                          valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('$percent%', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.medium)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                // Generous bottom padding — not just cosmetic. Whenever this
                // screen's content is shorter than the viewport (common,
                // since it's only 3-5 fields), the scroll view has nothing
                // to scroll *to*, so the fixed Continue bar right below reads
                // as glued to the last field with only the old xl (20px) gap.
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tied to signInMethod, not just "is some field
                    // non-empty" — the old check couldn't tell an actually
                    // Google-prefilled field apart from one that happened
                    // to be non-empty for an unrelated reason, so it could
                    // claim a Google pull that never happened. Email/phone
                    // sign-in never gets a city (nothing to derive it
                    // from), so that variant only ever talks about the name.
                    if (_signInMethod == 'google')
                      _AutofillBanner(text: 'Pulled from your Google account — edit anytime.')
                    else if (_signInMethod == 'otp' && _nameController.text.trim().isNotEmpty)
                      _AutofillBanner(text: "We've filled in your name from your email — edit anytime."),
                    const FieldLabel('Full name', tight: true),
                    PillInput(controller: _nameController, placeholder: 'Your name', icon: Ionicons.person_outline, maxLength: 60, onChanged: (_) => setState(() {})),
                    const FieldLabel('City'),
                    AutocompleteField(
                      value: _city,
                      placeholder: 'e.g. Mumbai',
                      icon: Ionicons.location_outline,
                      options: mockCities,
                      onChanged: (v) => setState(() => _city = v),
                    ),
                    // Only Google/email sign-ups reach here — phone sign-up's
                    // identifier already is the phone number (see
                    // AppState._makeNewUser), so asking again there would be
                    // redundant.
                    if (_needsPhone) ...[
                      const FieldLabel('Phone number'),
                      PillInput(
                        controller: _phoneController,
                        placeholder: '9876543210',
                        icon: Ionicons.call_outline,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const FieldLabel('What stage are you at?'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _segmentOptions
                          .map((s) => AppChip(label: s.$2, selected: _segment == s.$1, onPressed: () => _selectSegment(s.$1)))
                          .toList(),
                    ),
                    if (_isSchool) ...[
                      const FieldLabel('Which class are you in?'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _classOptions.map((o) => AppChip(label: o, selected: _currentClass == o, onPressed: () => setState(() => _currentClass = o))).toList(),
                      ),
                      const FieldLabel('Which board do you study under?'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _boardOptions.map((o) => AppChip(label: o, selected: _board == o, onPressed: () => setState(() => _board = o))).toList(),
                      ),
                    ] else if (_isWorking) ...[
                      const FieldLabel("What's the highest level you've completed?"),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _qualificationOptions
                            .map((o) => AppChip(
                                  label: o,
                                  selected: _highestQualification == o,
                                  onPressed: () => setState(() {
                                    _highestQualification = o;
                                    // Downgrading away from an institution-level
                                    // qualification leaves those fields hidden but
                                    // populated — clear them, same reasoning as
                                    // the segment-switch clearing above.
                                    if (!_educatedQualifications.contains(o)) {
                                      _college = '';
                                      _course = '';
                                      _priorExperience = '';
                                      _priorExperienceExactController.clear();
                                    }
                                  }),
                                ))
                            .toList(),
                      ),
                      if (_isEducatedWorking) ...[
                        // Same wording as profile_edit_screen.dart and the
                        // resume builder use for this same concept — three
                        // different phrasings for one field (institution/
                        // specialize vs college-or-university/studying vs
                        // Institution/Degree) read as inconsistent when a
                        // user moves between onboarding, profile edit, and
                        // the resume builder for the exact same data.
                        const FieldLabel('College / University'),
                        AutocompleteField(
                          value: _college,
                          placeholder: 'e.g. BITS Goa',
                          icon: Ionicons.business_outline,
                          options: mockColleges,
                          onChanged: (v) => setState(() => _college = v),
                        ),
                        const FieldLabel('Course / Degree'),
                        AutocompleteField(
                          value: _course,
                          placeholder: 'e.g. B.Tech, B.Com, Diploma in Mechanical, MBA…',
                          icon: Ionicons.book_outline,
                          options: mockCourses,
                          onChanged: (v) => setState(() => _course = v),
                        ),
                        ..._priorExperienceField('Total work experience (optional)'),
                      ],
                    ] else if (_segment != null) ...[
                      const FieldLabel('College / University'),
                      AutocompleteField(
                        value: _college,
                        placeholder: 'e.g. BITS Goa',
                        icon: Ionicons.business_outline,
                        options: mockColleges,
                        onChanged: (v) => setState(() => _college = v),
                      ),
                      const FieldLabel('Course / Degree'),
                      AutocompleteField(
                        value: _course,
                        placeholder: _segment == Segment.pg ? 'e.g. Finance, Marketing, HR, Data Science…' : 'e.g. B.Tech, MBA, B.Sc…',
                        icon: Ionicons.book_outline,
                        options: mockCourses,
                        onChanged: (v) => setState(() => _course = v),
                      ),
                      if (_segment != Segment.pg) ...[
                        const FieldLabel('Which semester are you in?'),
                        DatePickerField(
                          value: _semester.isEmpty ? null : _semester,
                          placeholder: 'Select semester',
                          icon: Ionicons.layers_outline,
                          onTap: _pickSemester,
                        ),
                      ],
                      if (_segment == Segment.pg) ..._priorExperienceField('Work experience before this program (optional)'),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
              decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
              child: PillButton(label: 'Continue', onPressed: _canContinue ? _submit : null, loading: _loading, disabled: !_canContinue),
            ),
          ],
        )),
      ),
    );
  }
}

class _AutofillBanner extends StatelessWidget {
  final String text;
  const _AutofillBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          const Icon(Ionicons.checkmark_circle, size: 18, color: AppColors.blue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              noOrphan(text),
              style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
            ),
          ),
        ],
      ),
    );
  }
}
