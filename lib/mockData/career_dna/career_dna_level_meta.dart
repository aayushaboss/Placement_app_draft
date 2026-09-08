import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/widgets.dart' show IconData;

/// Display-only metadata for all 5 Career DNA levels — used by the landing
/// (level-map) screen and each level's own intro screen. Kept separate from
/// each level's real question-bank/scoring file (career_dna_levelN_data.dart)
/// so the landing screen can render all 5 level cards (including the locked
/// ones, whose content may not be authored yet) without importing every
/// level's full weight-matrix data.
class CareerDnaLevelMeta {
  final int level;
  final String title;
  final String tagline;
  final String whatThisMeasures;
  final String noRightWrongCopy;
  final IconData icon;
  final int questionCount;
  final String estTime;

  const CareerDnaLevelMeta({
    required this.level,
    required this.title,
    required this.tagline,
    required this.whatThisMeasures,
    required this.noRightWrongCopy,
    required this.icon,
    required this.questionCount,
    required this.estTime,
  });
}

// Copy here is deliberately terse — short fragments, not full paragraphs —
// per direct feedback that the level-intro screen read as too much to read
// before even starting. Also scrubbed of college-only framing ("college
// situations", "your first job" assuming a first job specifically) since
// this feature spans every non-school segment (UG/PG/Working), not just
// current students.
const careerDnaLevelMeta = [
  CareerDnaLevelMeta(
    level: 1,
    title: 'Personality & Behaviour',
    tagline: 'How do you naturally act?',
    whatThisMeasures: 'How you handle teamwork, setbacks, and decisions.',
    noRightWrongCopy: 'No right or wrong answers — just be yourself.',
    icon: Ionicons.person_outline,
    questionCount: 20,
    estTime: '8–10 min',
  ),
  CareerDnaLevelMeta(
    level: 2,
    title: 'Interest & Career Preference',
    tagline: 'What attracts you?',
    whatThisMeasures: 'What excites you, motivates you, and suits how you work.',
    noRightWrongCopy: 'Pick what feels like you, not what sounds impressive.',
    icon: Ionicons.compass_outline,
    questionCount: 20,
    estTime: '12–15 min',
  ),
  CareerDnaLevelMeta(
    level: 3,
    title: 'Social Interaction & Teamwork',
    tagline: 'How do you interact with people?',
    whatThisMeasures: 'How you lead, listen, and handle conflict in a team.',
    noRightWrongCopy: "Answer with what you'd really do, not the 'right' answer.",
    icon: Ionicons.people_outline,
    questionCount: 20,
    estTime: '15–18 min',
  ),
  CareerDnaLevelMeta(
    level: 4,
    title: 'Employability & Workplace Readiness',
    tagline: 'How do you operate at work?',
    whatThisMeasures: 'How you handle ownership, priorities, and feedback at work.',
    noRightWrongCopy: "Answer honestly — not what your manager wants to hear.",
    icon: Ionicons.briefcase_outline,
    questionCount: 20,
    estTime: '18–20 min',
  ),
  CareerDnaLevelMeta(
    level: 5,
    title: 'Career Mapping',
    tagline: 'Where do all four dimensions point you?',
    whatThisMeasures: 'Combines everything so far into your final career direction.',
    noRightWrongCopy: "Pick what you'd genuinely enjoy, not the highest-paying option.",
    icon: Ionicons.rocket_outline,
    questionCount: 20,
    estTime: '20–25 min',
  ),
];
