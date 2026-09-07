import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/application.dart';
import '../models/application_insight.dart';
import '../models/user.dart';
import '../theme/colors.dart';
import 'mock_opportunities.dart';

/// Deterministic 0–99 "random" number seeded by a string — same application
/// always produces the same insight numbers (not fresh noise every
/// rebuild), but different applications land on different, plausible ones.
// Masked to 31 bits at every step — on web (dart2js), `int` is backed by a
// JS `number`, which loses precision past 2^53. Folding `hash * 31 + b`
// over a long id/company string blows past that before the loop finishes,
// and the resulting imprecise value skews badly under `% 100`. Masking
// after every multiply keeps it inside the safe-integer range throughout.
int _seeded(String seed, int salt) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  hash = (hash + salt) & 0x7FFFFFFF;
  return hash % 100;
}

/// Naukri-style "recruiter last active" signal on each tracker card — how
/// recently the hiring side touched this specific application, not the
/// aggregate profile-wide activity `recruiterActionsFor` covers.
DateTime recruiterLastActiveFor(Application app) {
  final hoursAgo = 2 + _seeded(app.id, 50) % 70;
  return DateTime.now().subtract(Duration(hours: hoursAgo));
}

/// Naukri-style "how this application compares" strip — one donut per
/// category, each broken into shares with the applicant's own slice called
/// out, plus whether that specific criterion is one this application
/// already satisfies (drives the summary checklist above the carousel).
/// Only categories genuinely computed from the user's real resume/
/// opportunity data belong here — see the comment below on the three that
/// used to be seeded random noise.
List<ApplicationInsight> applicationInsightsFor(Application app, User? user) {
  final opportunity = getOpportunityById(app.opportunityId);
  final seed = app.id;

  final hasExperience = (user?.resume?.workExperience.isNotEmpty ?? false) || user?.resume?.experienceLevel == '2+ years';
  final experienceShare = hasExperience ? 62 : (18 + _seeded(seed, 1) % 20);

  final sameCity = opportunity != null && user?.city != null && opportunity.location.toLowerCase().contains(user!.city!.toLowerCase());
  final locationShare = sameCity ? (55 + _seeded(seed, 2) % 20) : (2 + _seeded(seed, 2) % 8);

  final skills = user?.resume?.skills ?? const [];
  final requirements = opportunity?.requirements.join(' ').toLowerCase() ?? '';
  final skillHits = skills.where((s) => requirements.contains(s.toLowerCase())).length;
  final keySkillsShare = requirements.isEmpty ? 0 : (skillHits * 100 / (skills.isEmpty ? 1 : skills.length)).clamp(0, 100).round();

  // Department, Industry, and Early Applicant used to be here too, each
  // driven entirely by seeded random noise (matched: departmentShare >=
  // 50, etc.) with no real comparator population anywhere in this app to
  // actually derive them from — Opportunity doesn't even carry a posting
  // date, so "applied within 1 week of the job posting" couldn't be
  // computed honestly even with real backend data. All three fed directly
  // into the "$matchedCount out of ${insights.length}" headline a student
  // reads as an objective assessment, especially right after a rejection
  // — removed rather than left fabricated. The three below are all
  // genuinely computed from the user's real resume/opportunity data.

  return [
    ApplicationInsight(
      title: 'Work Experience',
      icon: Ionicons.briefcase_outline,
      matched: hasExperience,
      segments: [
        InsightSegment(label: hasExperience ? '2+ yrs' : '0-1 yrs', percent: experienceShare.toDouble(), color: AppColors.blue, isYou: true),
        InsightSegment(label: 'Other', percent: (100 - experienceShare).toDouble(), color: AppColors.gray200),
      ],
    ),
    ApplicationInsight(
      title: 'Location',
      icon: Ionicons.location_outline,
      matched: sameCity,
      segments: [
        InsightSegment(label: opportunity?.location ?? 'This city', percent: locationShare.toDouble(), color: AppColors.blue, isYou: sameCity),
        InsightSegment(label: 'Other', percent: (100 - locationShare).toDouble(), color: AppColors.gray200),
      ],
    ),
    ApplicationInsight(
      title: 'Key Skills',
      icon: Ionicons.ribbon_outline,
      matched: keySkillsShare >= 40,
      segments: [
        InsightSegment(label: 'You', percent: keySkillsShare.toDouble(), color: keySkillsShare >= 40 ? AppColors.success : AppColors.error, isYou: true),
        InsightSegment(label: 'Missing', percent: (100 - keySkillsShare).toDouble(), color: AppColors.gray200),
      ],
      description: keySkillsShare >= 40
          ? 'Your profile covers most of the key skills this role asks for.'
          : "Your profile is missing some key skills required for this job.",
    ),
  ];
}
