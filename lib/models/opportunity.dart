/// Mirrors frontend/src/mockData/mockOpportunities.ts `Opportunity`.
class Opportunity {
  final String id;
  final String title;
  final String company;
  final String type;
  final String location;
  final String workMode;
  final String stipend;
  final String duration;
  final String category;

  /// `Full-time`/`Part-time` — only ever meaningful when [type] is
  /// `'Full-time'`; every Internship leaves this null. Lets the Home
  /// filter's Employment Type facet actually narrow results, unlike
  /// [type] alone (Internship vs Full-time), which is a separate facet.
  final String? employmentType;
  final String image;
  final String about;
  final List<String> requirements;
  final List<String> prepCourses;

  /// ISO date (yyyy-MM-dd) the application window closes. Drives the
  /// urgency indicator on cards — prototype-only, replace with a real
  /// deadline from the API later.
  final String deadline;

  /// How many people have applied so far — shown on the detail page
  /// (Naukri-style social proof). Mocked; a real API would return this.
  final int applicantCount;

  /// Quick pre-apply screening questions, company-voice ("Are you willing
  /// to relocate?"). Paired index-for-index with [screeningQuestionOptions]
  /// — each question carries its own tappable quick-answer badges rather
  /// than one generic Yes/No set reused everywhere.
  final List<String> screeningQuestions;
  final List<List<String>> screeningQuestionOptions;

  const Opportunity({
    required this.id,
    required this.title,
    required this.company,
    required this.type,
    required this.location,
    required this.workMode,
    required this.stipend,
    required this.duration,
    required this.category,
    this.employmentType,
    required this.image,
    required this.about,
    required this.requirements,
    required this.prepCourses,
    required this.deadline,
    this.applicantCount = 0,
    this.screeningQuestions = const [],
    this.screeningQuestionOptions = const [],
  });
}
