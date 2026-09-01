import 'aptitude.dart';
import 'it_skill_entry.dart';
import 'job_preferences.dart';
import 'language_entry.dart';
import 'parsed_resume.dart';

/// Mirrors frontend/src/context/AuthContext.tsx `Segment` + `User`.
enum Segment { school, ug, pg, working }

Segment? segmentFromString(String? value) {
  switch (value) {
    case 'school':
      return Segment.school;
    case 'ug':
      return Segment.ug;
    case 'pg':
      return Segment.pg;
    case 'working':
      return Segment.working;
    default:
      return null;
  }
}

String? segmentToString(Segment? segment) => segment?.name;

class User {
  final String id;
  final String identifier;

  /// How this account was created — `'google'` or `'otp'` (the phone/email
  /// OTP flow shares one method since neither ever hands back real profile
  /// data the way a real Google sign-in would). Drives the "pulled from
  /// your account" banner on the onboarding profile screen — without this,
  /// that banner had no way to tell an actually-Google-prefilled field
  /// apart from one that just happened to be non-empty for some other
  /// reason.
  final String? signInMethod;
  final String? name;
  final String? city;

  /// App display-language preference — unrelated to `languages` below
  /// (which is what the student themself knows, for their resume). Set
  /// before this User even exists (see AppState.setAppLanguage /
  /// app_language_prefs_key.dart) and mirrored here once an account is
  /// created, so it round-trips through the normal profile save/load path
  /// like every other field.
  final String? appLanguage;
  final Segment? segment;
  final String? currentClass;
  final String? board;
  final String? college;
  final String? course;
  final String? year;
  final String? fieldOfStudy;

  /// Postgrads only — work experience before starting this program, e.g.
  /// '1-2 yrs'. Optional: collected on the same onboarding screen as
  /// college/course/year but never gates Continue, same as [fieldOfStudy].
  final String? priorExperience;

  /// Segment.working only — the highest level of formal education
  /// completed, e.g. '12th pass'. This segment has no college/course/year
  /// of its own, so this is the one thing it collects, and unlike
  /// [priorExperience] it's required (it's the only question asked).
  final String? highestQualification;
  final String? goal;
  final List<String>? roles;
  final String? photoUrl;
  final ParsedResume? resume;
  final AptitudeResults? aptitudeResults;
  final JobPreferences? preferences;
  final List<LanguageEntry>? languages;

  /// Video pitch, recorded or uploaded — mirrors Naukri's "video profile."
  /// Stored as a local blob: URL (web) alongside the original filename,
  /// same pattern as the profile photo and resume PDF upload already use.
  final String? videoIntroUrl;
  final String? videoIntroFileName;

  /// Naukri's diversity & inclusion section, reduced to the one field that
  /// meaningfully applies to a student audience. Null means unanswered —
  /// distinct from false, so the profile doesn't imply an answer nobody gave.
  final bool? differentlyAbled;

  /// Free-text detail shown only once [differentlyAbled] is true — mirrors
  /// Naukri's own conditional follow-up field.
  final String? differentlyAbledDetails;

  /// Programming languages, software, and tools — Naukri's "IT skills".
  final List<ITSkillEntry>? itSkills;

  final bool onboardingComplete;

  /// School users can defer the career-fit quiz; home shows a nudge CTA.
  final bool aptitudeSkipped;

  const User({
    required this.id,
    required this.identifier,
    this.signInMethod,
    this.name,
    this.city,
    this.appLanguage,
    this.segment,
    this.currentClass,
    this.board,
    this.college,
    this.course,
    this.year,
    this.fieldOfStudy,
    this.priorExperience,
    this.highestQualification,
    this.goal,
    this.roles,
    this.photoUrl,
    this.resume,
    this.aptitudeResults,
    this.preferences,
    this.languages,
    this.videoIntroUrl,
    this.videoIntroFileName,
    this.differentlyAbled,
    this.differentlyAbledDetails,
    this.itSkills,
    this.onboardingComplete = false,
    this.aptitudeSkipped = false,
  });

  User copyWith({
    String? id,
    String? identifier,
    String? signInMethod,
    String? name,
    String? city,
    String? appLanguage,
    Segment? segment,
    String? currentClass,
    String? board,
    String? college,
    String? course,
    String? year,
    String? fieldOfStudy,
    String? priorExperience,
    String? highestQualification,
    String? goal,
    List<String>? roles,
    String? photoUrl,
    ParsedResume? resume,
    AptitudeResults? aptitudeResults,
    JobPreferences? preferences,
    List<LanguageEntry>? languages,
    String? videoIntroUrl,
    String? videoIntroFileName,
    bool? differentlyAbled,
    String? differentlyAbledDetails,
    List<ITSkillEntry>? itSkills,
    bool? onboardingComplete,
    bool? aptitudeSkipped,
  }) {
    return User(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      signInMethod: signInMethod ?? this.signInMethod,
      name: name ?? this.name,
      city: city ?? this.city,
      appLanguage: appLanguage ?? this.appLanguage,
      segment: segment ?? this.segment,
      currentClass: currentClass ?? this.currentClass,
      board: board ?? this.board,
      college: college ?? this.college,
      course: course ?? this.course,
      year: year ?? this.year,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      priorExperience: priorExperience ?? this.priorExperience,
      highestQualification: highestQualification ?? this.highestQualification,
      goal: goal ?? this.goal,
      roles: roles ?? this.roles,
      photoUrl: photoUrl ?? this.photoUrl,
      resume: resume ?? this.resume,
      aptitudeResults: aptitudeResults ?? this.aptitudeResults,
      preferences: preferences ?? this.preferences,
      languages: languages ?? this.languages,
      videoIntroUrl: videoIntroUrl ?? this.videoIntroUrl,
      videoIntroFileName: videoIntroFileName ?? this.videoIntroFileName,
      differentlyAbled: differentlyAbled ?? this.differentlyAbled,
      differentlyAbledDetails: differentlyAbledDetails ?? this.differentlyAbledDetails,
      itSkills: itSkills ?? this.itSkills,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      aptitudeSkipped: aptitudeSkipped ?? this.aptitudeSkipped,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identifier': identifier,
        'signInMethod': signInMethod,
        'name': name,
        'city': city,
        'appLanguage': appLanguage,
        'segment': segmentToString(segment),
        'currentClass': currentClass,
        'board': board,
        'college': college,
        'course': course,
        'year': year,
        'fieldOfStudy': fieldOfStudy,
        'priorExperience': priorExperience,
        'highestQualification': highestQualification,
        'goal': goal,
        'roles': roles,
        'photoUrl': photoUrl,
        'resume': resume?.toJson(),
        'aptitudeResults': aptitudeResults?.toJson(),
        'preferences': preferences?.toJson(),
        'languages': languages?.map((l) => l.toJson()).toList(),
        'videoIntroUrl': videoIntroUrl,
        'videoIntroFileName': videoIntroFileName,
        'differentlyAbled': differentlyAbled,
        'differentlyAbledDetails': differentlyAbledDetails,
        'itSkills': itSkills?.map((c) => c.toJson()).toList(),
        'onboardingComplete': onboardingComplete,
        'aptitudeSkipped': aptitudeSkipped,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        identifier: json['identifier'] as String,
        signInMethod: json['signInMethod'] as String?,
        name: json['name'] as String?,
        city: json['city'] as String?,
        appLanguage: json['appLanguage'] as String?,
        segment: segmentFromString(json['segment'] as String?),
        currentClass: json['currentClass'] as String?,
        board: json['board'] as String?,
        college: json['college'] as String?,
        course: json['course'] as String?,
        year: json['year'] as String?,
        fieldOfStudy: json['fieldOfStudy'] as String?,
        priorExperience: json['priorExperience'] as String?,
        highestQualification: json['highestQualification'] as String?,
        goal: json['goal'] as String?,
        roles: (json['roles'] as List?)?.cast<String>(),
        photoUrl: json['photoUrl'] as String?,
        resume: json['resume'] != null ? ParsedResume.fromJson(json['resume'] as Map<String, dynamic>) : null,
        aptitudeResults: json['aptitudeResults'] != null
            ? AptitudeResults.fromJson(json['aptitudeResults'] as Map<String, dynamic>)
            : null,
        preferences: json['preferences'] != null ? JobPreferences.fromJson(json['preferences'] as Map<String, dynamic>) : null,
        languages: (json['languages'] as List?)?.map((l) => LanguageEntry.fromJson(l as Map<String, dynamic>)).toList(),
        videoIntroUrl: json['videoIntroUrl'] as String?,
        videoIntroFileName: json['videoIntroFileName'] as String?,
        differentlyAbled: json['differentlyAbled'] as bool?,
        differentlyAbledDetails: json['differentlyAbledDetails'] as String?,
        itSkills: (json['itSkills'] as List?)?.map((c) => ITSkillEntry.fromJson(c as Map<String, dynamic>)).toList(),
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        aptitudeSkipped: json['aptitudeSkipped'] as bool? ?? false,
      );
}
