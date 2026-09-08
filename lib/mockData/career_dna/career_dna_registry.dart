import '../../models/career_dna.dart';
import '../../models/career_dna_question.dart';
import 'career_dna_level1_data.dart';

/// Single dispatch point so the shared quiz/report screens never need to
/// know which level they're driving — each level's own question bank +
/// scoring lives in its own career_dna_levelN_data.dart file (see
/// career_dna_level1_data.dart for the authoring pattern Levels 2-5 follow).
/// Levels 2-5 are wired here once their content is authored (Phase B) —
/// until then they're unreachable in practice (sequential unlock keeps them
/// locked), but return an empty question list defensively rather than
/// throwing if ever reached early.
List<CareerDnaQuestion> careerDnaQuestionsForLevel(int level) {
  switch (level) {
    case 1:
      return careerDnaLevel1Questions;
    default:
      return const [];
  }
}

/// Runs the right level's scoring + persists the result shape onto a
/// [CareerDnaProfile] copy. [current] is the student's profile so far —
/// needed by Level 5, whose own scoring cross-references Levels 1-4's
/// already-computed results (see the plan's synthesis design).
CareerDnaProfile computeAndApplyCareerDnaLevel(int level, Map<String, String> answers, CareerDnaProfile current) {
  switch (level) {
    case 1:
      return current.copyWith(level1: computeCareerDnaLevel1Result(answers));
    default:
      return current;
  }
}
