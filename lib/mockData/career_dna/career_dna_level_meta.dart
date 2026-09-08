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

const careerDnaLevelMeta = [
  CareerDnaLevelMeta(
    level: 1,
    title: 'Personality & Behaviour',
    tagline: 'How do you naturally act?',
    whatThisMeasures: 'How you naturally respond to everyday college situations — teamwork, setbacks, decisions, and more.',
    noRightWrongCopy: "There are no right or wrong answers here. Choose what's closest to what you'd naturally do, not what sounds impressive.",
    icon: Ionicons.person_outline,
    questionCount: 20,
    estTime: '8–10 min',
  ),
  CareerDnaLevelMeta(
    level: 2,
    title: 'Interest & Career Preference',
    tagline: 'What attracts you?',
    whatThisMeasures: 'What kind of problems you enjoy, what motivates you, and the work environment that actually suits you.',
    noRightWrongCopy: 'Choose the option that feels most like you — not the one you think sounds best for a career.',
    icon: Ionicons.compass_outline,
    questionCount: 20,
    estTime: '12–15 min',
  ),
  CareerDnaLevelMeta(
    level: 3,
    title: 'Social Interaction & Teamwork',
    tagline: 'How do you interact with people?',
    whatThisMeasures: 'How you naturally operate in a team — leading, listening, resolving conflict, and everything in between.',
    noRightWrongCopy: "Pick the response closest to what you'd genuinely do — not what you think a company would prefer to hear.",
    icon: Ionicons.people_outline,
    questionCount: 20,
    estTime: '15–18 min',
  ),
  CareerDnaLevelMeta(
    level: 4,
    title: 'Employability & Workplace Readiness',
    tagline: 'How do you operate at work?',
    whatThisMeasures: 'How ready you are for real workplace situations — ownership, priorities, feedback, and judgement calls.',
    noRightWrongCopy: "Imagine you've just joined your first job. Answer with what you'd genuinely do, not what your manager would want to hear.",
    icon: Ionicons.briefcase_outline,
    questionCount: 20,
    estTime: '18–20 min',
  ),
  CareerDnaLevelMeta(
    level: 5,
    title: 'Career Mapping',
    tagline: 'Where do all four dimensions point you?',
    whatThisMeasures: 'The synthesis level — validates and combines everything from Levels 1-4 into your final career direction.',
    noRightWrongCopy: "Choose what you'd genuinely prefer to spend your working time doing — not the option with the highest salary or status.",
    icon: Ionicons.rocket_outline,
    questionCount: 20,
    estTime: '20–25 min',
  ),
];
