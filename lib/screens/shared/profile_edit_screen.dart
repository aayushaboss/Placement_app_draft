import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_profile_options.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/initials.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/autocomplete_field.dart';
import '../../widgets/field_label.dart';
import '../../widgets/not_found_view.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/responsive_body.dart';

const _classOptions = ['Class 11', 'Class 12', 'Below 11'];
const _boardOptions = ['CBSE', 'State', 'IB', 'Other'];
const _yearOptions = ['1st Year', '2nd Year', '3rd Year', 'Final Year'];
const _priorExperienceOptions = ['Fresher', '1-2 yrs', '3-5 yrs', '5+ yrs'];
const _qualificationOptions = ['Below 10th', '10th pass', '12th pass', 'Diploma', 'Graduate', 'Postgraduate'];
const _educatedQualifications = {'Diploma', 'Graduate', 'Postgraduate'};
const _goalOptions = [
  ('internship', 'Internship'),
  ('job', 'Full-time Job'),
  ('both', 'Both'),
];

/// Mirrors frontend/app/profile-edit.tsx (ProfileEdit).
class ProfileEditScreen extends StatefulWidget {
  /// Where to land after Save/back. Passed explicitly by whoever opened
  /// this screen (Home's progress card vs. the Profile tab) instead of
  /// relying on context.pop() — pop() was observed silently failing to
  /// return here (no exception, no navigation, just no-op), so this
  /// screen no longer depends on the Navigator stack at all.
  final String? returnTo;

  /// When 'roles', the screen scrolls straight to "Interested roles /
  /// industries" on open instead of leaving it wherever it happens to fall
  /// on this shared form — tapping "Goals & roles" on Profile used to land
  /// here at the top, on Basic details fields, with the thing that was
  /// actually tapped buried below a full scroll.
  final String? scrollToSection;

  const ProfileEditScreen({super.key, this.returnTo, this.scrollToSection});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  final _rolesFieldKey = GlobalKey();
  String _city = '';
  String _college = '';
  String _course = '';
  String _fieldOfStudy = '';
  String _currentClass = '';
  String _board = '';
  String _year = '';
  String _priorExperience = '';
  // Only relevant when _priorExperience == '5+ yrs' — see
  // _effectivePriorExperience.
  final _priorExperienceExactController = TextEditingController();
  String _highestQualification = '';
  String _goal = '';
  List<String> _roles = [];
  String? _photoUrl;
  XFile? _photoFile;
  bool _loading = false;
  bool _hydrated = false;
  bool _scrolledToSection = false;

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    _priorExperienceExactController.dispose();
    super.dispose();
  }

  void _maybeScrollToSection() {
    if (_scrolledToSection || widget.scrollToSection != 'roles') return;
    _scrolledToSection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rolesFieldKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.05);
      }
    });
  }

  void _hydrate(User user) {
    if (_hydrated) return;
    _nameController.text = user.name ?? '';
    _city = user.city ?? '';
    _college = user.college ?? '';
    _course = user.course ?? '';
    _fieldOfStudy = user.fieldOfStudy ?? '';
    _currentClass = user.currentClass ?? '';
    _board = user.board ?? '';
    _year = user.year ?? '';
    // A previously-saved exact figure (e.g. "7 yrs", from the "5+ yrs"
    // refinement field) matches none of the 4 bucket chips — treat it as
    // the "5+ yrs" bucket for chip-selection purposes and restore the
    // number into its own field, rather than leaving no chip selected.
    final rawPriorExperience = user.priorExperience ?? '';
    if (rawPriorExperience.isNotEmpty && !_priorExperienceOptions.contains(rawPriorExperience)) {
      _priorExperience = '5+ yrs';
      final leadingDigits = RegExp(r'^\d+').firstMatch(rawPriorExperience)?.group(0);
      if (leadingDigits != null) _priorExperienceExactController.text = leadingDigits;
    } else {
      _priorExperience = rawPriorExperience;
    }
    _highestQualification = user.highestQualification ?? '';
    _goal = user.goal ?? '';
    _roles = user.roles ?? [];
    _photoUrl = user.photoUrl;
    _hydrated = true;
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty && _city.trim().isNotEmpty;

  /// The value actually saved for `priorExperience` — usually just the
  /// selected bucket chip, but when "5+ yrs" is selected and a precise
  /// figure was typed, the exact figure wins (e.g. "7 yrs" instead of the
  /// coarser "5+ yrs").
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
  /// "5+ yrs" is selected — a small numeric refinement field right below
  /// it. Same shape as the generic `_chipField` helper below (not routed
  /// through it, since that one is shared by several unrelated fields and
  /// doesn't need the extra conditional field).
  Widget _priorExperienceField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  void _toggleRole(String r) {
    HapticFeedback.selectionClick();
    setState(() => _roles = _roles.contains(r) ? _roles.where((x) => x != r).toList() : [..._roles, r]);
  }

  Future<void> _fromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _photoFile = file;
        _photoUrl = file.path;
      });
    }
  }

  Future<void> _fromCamera() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _photoFile = file;
        _photoUrl = file.path;
      });
    }
  }

  void _pickPhoto() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Ionicons.camera_outline, color: AppColors.blue),
              title: Text('Take Photo', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _fromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.images_outline, color: AppColors.blue),
              title: Text('Choose from Gallery', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _fromGallery();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final isSchool = appState.user?.segment == Segment.school;
      final isWorking = appState.user?.segment == Segment.working;
      // On web, a picked photo's path is normally a short blob: URL, but
      // if the platform ever hands back a full base64 data: URI instead
      // (large images can be tens/hundreds of KB as a string), persisting
      // it can blow past the browser's per-origin storage quota and throw.
      // Keep it for this session's preview either way, but don't let a
      // save-breaking value get written to storage.
      final photoUrl = (_photoUrl != null && _photoUrl!.length > 20000) ? null : _photoUrl;
      // TODO: replace with real API call (upload photo + update profile)
      await appState.updateProfile((current) => isSchool
          ? current.copyWith(
              name: _nameController.text,
              city: _city,
              currentClass: _currentClass,
              board: _board,
              photoUrl: photoUrl,
            )
          : isWorking
              ? current.copyWith(
                  name: _nameController.text,
                  city: _city,
                  highestQualification: _highestQualification.isNotEmpty ? _highestQualification : null,
                  college: _educatedQualifications.contains(_highestQualification) && _college.isNotEmpty ? _college : null,
                  course: _educatedQualifications.contains(_highestQualification) && _course.isNotEmpty ? _course : null,
                  priorExperience: _educatedQualifications.contains(_highestQualification) && _priorExperience.isNotEmpty ? _effectivePriorExperience : null,
                  goal: _goal,
                  roles: _roles,
                  photoUrl: photoUrl,
                )
              : current.copyWith(
                  name: _nameController.text,
                  city: _city,
                  college: _college,
                  course: _course,
                  year: _year,
                  fieldOfStudy: _fieldOfStudy,
                  priorExperience: appState.user?.segment == Segment.pg && _priorExperience.isNotEmpty ? _effectivePriorExperience : null,
                  goal: _goal,
                  roles: _roles,
                  photoUrl: photoUrl,
                ));
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      // go(), not pop() — pop() was confirmed silently failing here (tap
      // registers, save completes, no error, but nothing navigates).
      context.go(widget.returnTo ?? '/tabs');
    } catch (e) {
      // There was no catch here before — a failed save (e.g. the picked
      // photo being too large to persist to local storage) threw silently,
      // the loading spinner reset, and nothing else visibly happened at
      // all. Surface it instead of failing dark.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not save changes: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _avatarImage() {
    if (_photoFile != null) {
      if (kIsWeb) {
        return Image.network(_photoFile!.path, width: 104, height: 104, fit: BoxFit.cover);
      }
      return Image.file(File(_photoFile!.path), width: 104, height: 104, fit: BoxFit.cover);
    }
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return Image.network(_photoUrl!, width: 104, height: 104, fit: BoxFit.cover);
    }
    return Container(
      width: 104,
      height: 104,
      alignment: Alignment.center,
      color: AppColors.blue,
      child: Text(initialsFor(_nameController.text), style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 34, fontWeight: AppFontWeight.semibold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null) {
      return NotFoundView(
        title: "You're signed out",
        message: 'Sign back in to edit your profile.',
        buttonLabel: 'Sign in',
        onAction: () => context.go('/onboarding'),
      );
    }
    _hydrate(user);
    _maybeScrollToSection();
    final isSchool = user.segment == Segment.school;
    final isWorking = user.segment == Segment.working;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(child: Column(
          children: [
            Container(
              color: AppColors.blue,
              padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go(widget.returnTo ?? '/tabs'),
                    child: const Icon(Ionicons.chevron_back, size: 26, color: AppColors.white),
                  ),
                  Text('Edit Profile', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 18, fontWeight: AppFontWeight.semibold)),
                  const SizedBox(width: AppSpacing.xxl),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipOval(child: _avatarImage()),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: AppColors.blue, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                                  child: const Icon(Ionicons.camera, size: 16, color: AppColors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text('Tap to upload from camera or gallery', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 13)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _fromCamera,
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Ionicons.camera_outline, size: 18, color: AppColors.blue),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text('Camera', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 14, fontWeight: AppFontWeight.medium)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              GestureDetector(
                                onTap: _fromGallery,
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Ionicons.images_outline, size: 18, color: AppColors.blue),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text('Gallery', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 14, fontWeight: AppFontWeight.medium)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const FieldLabel('Full name', tight: true),
                  PillInput(controller: _nameController, placeholder: 'Your name', icon: Ionicons.person_outline, onChanged: (_) => setState(() {})),
                  const FieldLabel('City'),
                  AutocompleteField(value: _city, placeholder: 'e.g. Mumbai', icon: Ionicons.location_outline, options: mockCities, onChanged: (v) => setState(() => _city = v)),
                  if (isSchool) ...[
                    _chipField('Current class', _classOptions, _currentClass, (v) => setState(() => _currentClass = v)),
                    _chipField('Board', _boardOptions, _board, (v) => setState(() => _board = v)),
                  ] else ...[
                    if (isWorking) ...[
                      _chipField('Highest qualification completed', _qualificationOptions, _highestQualification, (v) => setState(() {
                            _highestQualification = v;
                            // Downgrading away from an institution-level
                            // qualification leaves those fields hidden but
                            // populated — clear them.
                            if (!_educatedQualifications.contains(v)) {
                              _college = '';
                              _course = '';
                              _priorExperience = '';
                              _priorExperienceExactController.clear();
                            }
                          })),
                      if (_educatedQualifications.contains(_highestQualification)) ...[
                        const FieldLabel('Which institution did you attend?'),
                        AutocompleteField(value: _college, placeholder: 'e.g. BITS Goa', icon: Ionicons.business_outline, options: mockColleges, onChanged: (v) => setState(() => _college = v)),
                        const FieldLabel('What did you specialize in?'),
                        AutocompleteField(
                          value: _course,
                          placeholder: 'e.g. B.Tech, B.Com, Diploma in Mechanical, MBA…',
                          icon: Ionicons.book_outline,
                          options: mockCourses,
                          onChanged: (v) => setState(() => _course = v),
                        ),
                        _priorExperienceField('Total work experience'),
                      ],
                    ] else ...[
                      const FieldLabel('College / University'),
                      AutocompleteField(value: _college, placeholder: 'e.g. BITS Goa', icon: Ionicons.business_outline, options: mockColleges, onChanged: (v) => setState(() => _college = v)),
                      const FieldLabel('Course / Degree'),
                      AutocompleteField(value: _course, placeholder: 'e.g. B.Tech, MBA, B.Sc…', icon: Ionicons.book_outline, options: mockCourses, onChanged: (v) => setState(() => _course = v)),
                      if (user.segment != Segment.pg) _chipField('Year', _yearOptions, _year, (v) => setState(() => _year = v)),
                      if (user.segment == Segment.pg) _priorExperienceField('Work experience before this program'),
                      const FieldLabel('Field of study'),
                      AutocompleteField(value: _fieldOfStudy, placeholder: 'e.g. Computer Science', icon: Ionicons.school_outline, options: mockFieldsOfStudy, onChanged: (v) => setState(() => _fieldOfStudy = v)),
                    ],
                    const FieldLabel('Looking for'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _goalOptions
                          .map((g) => AppChip(label: g.$2, selected: _goal == g.$1, onPressed: () => setState(() => _goal = g.$1)))
                          .toList(),
                    ),
                    FieldLabel('Interested roles / industries', key: _rolesFieldKey),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: mockAllRoles.map((r) => AppChip(label: r, selected: _roles.contains(r), onPressed: () => _toggleRole(r))).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
              decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
              child: PillButton(label: 'Save changes', onPressed: _save, loading: _loading, disabled: !_canSave),
            ),
          ],
        )),
      ),
    );
  }

  Widget _chipField(String label, List<String> options, String value, ValueChanged<String> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((o) => AppChip(label: o, selected: value == o, onPressed: () => onSelect(o))).toList(),
        ),
      ],
    );
  }

}
