// Prototype mock data — delete when real API is wired.
// Mirrors frontend/src/mockData/mockOpportunities.ts.
import '../models/opportunity.dart';

/// Deadlines are generated relative to "now" (not baked-in absolute dates)
/// so the urgency indicator on cards always looks live, no matter when this
/// prototype is actually run/demoed.
String _deadlineIn(int days) => DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);

final List<Opportunity> mockOpportunities = [
  Opportunity(
    id: 'opp-frontend-intern',
    title: 'Frontend Developer Intern',
    company: 'Microsoft',
    type: 'Internship',
    location: 'Bengaluru',
    workMode: 'Hybrid',
    stipend: '₹25,000/mo',
    duration: '6 months',
    category: 'Software',
    image:
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    about:
        'Join our product team to build delightful web experiences with React and TypeScript.',
    requirements: ['React & JavaScript basics', 'HTML/CSS fluency', 'Git workflow', 'Eye for detail'],
    prepCourses: ['course-coding-basics', 'course-interview-prep'],
    deadline: _deadlineIn(3),
    applicantCount: 86,
    screeningQuestions: const ['When can you start?', 'Comfortable with a hybrid role?'],
    screeningQuestionOptions: const [
      ['Immediately', 'In 2 weeks', 'In a month'],
      ['Yes', 'No', 'Need more details'],
    ],
  ),
  Opportunity(
    id: 'opp-data-analyst',
    title: 'Junior Data Analyst',
    company: 'Deloitte',
    type: 'Full-time',
    location: 'Pune',
    workMode: 'Onsite',
    stipend: '₹6.5 LPA',
    duration: 'Permanent',
    category: 'Data',
    employmentType: 'Full-time',
    image:
        'https://images.unsplash.com/photo-1551288049-bebda4e38f71?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    about: 'Turn raw data into decisions. Work with SQL, dashboards and stakeholders.',
    requirements: ['SQL proficiency', 'Excel / Sheets', 'Basic statistics', 'Communication'],
    prepCourses: ['course-data-analytics', 'course-interview-prep'],
    deadline: _deadlineIn(9),
    applicantCount: 142,
    screeningQuestions: const ['Total years of experience?', 'Willing to relocate to Pune?'],
    screeningQuestionOptions: const [
      ['Fresher', '0-1 years', '1-3 years'],
      ['Yes', 'No', 'Already in Pune'],
    ],
  ),
  Opportunity(
    id: 'opp-marketing-intern',
    title: 'Digital Marketing Intern',
    company: 'Dentsu',
    type: 'Internship',
    location: 'Remote',
    workMode: 'Remote',
    stipend: '₹15,000/mo',
    duration: '3 months',
    category: 'Marketing',
    image:
        'https://images.unsplash.com/photo-1460925895917-afdab827c52f?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    about: 'Run social campaigns, write copy and learn performance marketing hands-on.',
    requirements: ['Strong writing', 'Social media savvy', 'Canva basics', 'Curiosity'],
    prepCourses: ['course-design-thinking', 'course-resume-builder'],
    deadline: _deadlineIn(2),
    applicantCount: 58,
    screeningQuestions: const ['When can you start?', 'Do you have a laptop for remote work?'],
    screeningQuestionOptions: const [
      ['Immediately', 'In 2 weeks', 'In a month'],
      ['Yes', 'No'],
    ],
  ),
  Opportunity(
    id: 'opp-finance-analyst',
    title: 'Finance Analyst Trainee',
    company: 'Morgan Stanley',
    type: 'Full-time',
    location: 'Mumbai',
    workMode: 'Onsite',
    stipend: '₹7 LPA',
    duration: 'Permanent',
    category: 'Finance',
    employmentType: 'Full-time',
    image:
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    about: 'Support investment research and financial modeling for our analyst team.',
    requirements: [
      'Accounting fundamentals',
      'Excel modeling',
      'Analytical mindset',
      'Attention to detail',
    ],
    prepCourses: ['course-commerce-finance', 'course-interview-prep'],
    deadline: _deadlineIn(21),
    applicantCount: 97,
    screeningQuestions: const ['Total years of experience?', 'Willing to relocate to Mumbai?'],
    screeningQuestionOptions: const [
      ['Fresher', '0-1 years', '1-3 years'],
      ['Yes', 'No', 'Already in Mumbai'],
    ],
  ),
  Opportunity(
    id: 'opp-uiux-intern',
    title: 'UI/UX Design Intern',
    company: 'Adobe',
    type: 'Internship',
    location: 'Hyderabad',
    workMode: 'Hybrid',
    stipend: '₹20,000/mo',
    duration: '6 months',
    category: 'Design',
    image:
        'https://images.unsplash.com/photo-1561070791-2526d30994b5?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    about: 'Design mobile-first flows in Figma and ship pixel-perfect interfaces.',
    requirements: ['Figma', 'Design fundamentals', 'Portfolio', 'Collaboration'],
    prepCourses: ['course-design-thinking', 'course-resume-builder'],
    deadline: _deadlineIn(5),
    applicantCount: 73,
    screeningQuestions: const ['Do you have a portfolio ready?', 'Comfortable with a hybrid role?'],
    screeningQuestionOptions: const [
      ['Yes', 'No', 'Still building it'],
      ['Yes', 'No', 'Need more details'],
    ],
  ),
  Opportunity(
    id: 'opp-backend-engineer',
    title: 'Backend Engineer (Fresher)',
    company: 'Amazon',
    type: 'Full-time',
    location: 'Bengaluru',
    workMode: 'Hybrid',
    stipend: '₹9 LPA',
    duration: 'Permanent',
    category: 'Software',
    employmentType: 'Full-time',
    image:
        'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    about: 'Build scalable APIs and services with Python and cloud infrastructure.',
    requirements: ['Python', 'REST APIs', 'Databases', 'Problem solving'],
    prepCourses: ['course-coding-basics', 'course-data-analytics'],
    deadline: _deadlineIn(14),
    applicantCount: 164,
    screeningQuestions: const ['Total years of experience?', 'When can you start?'],
    screeningQuestionOptions: const [
      ['Fresher', '0-1 years', '1-3 years'],
      ['Immediately', 'In 2 weeks', 'In a month'],
    ],
  ),
  Opportunity(
    id: 'opp-content-intern',
    title: 'Content Writer Intern',
    company: 'Ogilvy',
    type: 'Internship',
    location: 'Remote',
    workMode: 'Remote',
    stipend: '₹12,000/mo',
    duration: '4 months',
    category: 'Content',
    image:
        'https://images.unsplash.com/photo-1455390582262-044cdead277a?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    about: 'Write blogs, scripts and social content for a fast-growing media brand.',
    requirements: ['Excellent English', 'Research skills', 'SEO basics', 'Creativity'],
    prepCourses: ['course-resume-builder', 'course-design-thinking'],
    deadline: _deadlineIn(30),
    applicantCount: 41,
    screeningQuestions: const ['When can you start?', 'Do you have writing samples to share?'],
    screeningQuestionOptions: const [
      ['Immediately', 'In 2 weeks', 'In a month'],
      ['Yes', 'No', 'Can prepare some'],
    ],
  ),
  Opportunity(
    id: 'opp-product-intern',
    title: 'Associate Product Manager Intern',
    company: 'Accenture',
    type: 'Internship',
    location: 'Gurugram',
    workMode: 'Onsite',
    stipend: '₹30,000/mo',
    duration: '6 months',
    category: 'Product',
    image:
        'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    about: 'Own features end-to-end, talk to users and drive the roadmap with the team.',
    requirements: ['Structured thinking', 'Communication', 'Basic analytics', 'User empathy'],
    prepCourses: ['course-data-analytics', 'course-interview-prep'],
    deadline: _deadlineIn(7),
    applicantCount: 119,
    screeningQuestions: const ['When can you start?', 'Comfortable working onsite in Gurugram?'],
    screeningQuestionOptions: const [
      ['Immediately', 'In 2 weeks', 'In a month'],
      ['Yes', 'No', 'Already in Gurugram'],
    ],
  ),
  ..._extraOpportunities,
];

/// Same working image set as the hand-authored cards above, cycled — a
/// broken/placeholder image link would undercut the "does this feel like a
/// real feed" point of padding the list out in the first place.
const _extraOpportunityImages = [
  'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
  'https://images.unsplash.com/photo-1551288049-bebda4e38f71?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
  'https://images.unsplash.com/photo-1460925895917-afdab827c52f?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
  'https://images.unsplash.com/photo-1554224155-6726b3ff858f?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
  'https://images.unsplash.com/photo-1561070791-2526d30994b5?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
  'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
  'https://images.unsplash.com/photo-1455390582262-044cdead277a?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
  'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
];

/// (title, company, type, location, workMode, stipend, duration, category,
/// employmentType) — 20 more listings purely to give the horizontal
/// carousels (and the "View all" grid) enough volume to actually feel like
/// scrolling through a real feed rather than 8 cards that end after one
/// swipe. employmentType is null for every Internship (the distinction
/// doesn't apply) and 'Full-time' for most Full-time entries, with a
/// couple deliberately 'Part-time' so the Home filter's Employment Type
/// facet has real variety to narrow against.
const _extraOpportunitySeeds = [
  ('Software Engineer Intern', 'IBM', 'Internship', 'Hyderabad', 'Hybrid', '₹22,000/mo', '6 months', 'Software', null),
  ('Full Stack Developer', 'EY', 'Full-time', 'Bengaluru', 'Remote', '₹8 LPA', 'Permanent', 'Software', 'Full-time'),
  ('Mobile App Developer Intern', 'Infosys', 'Internship', 'Pune', 'Onsite', '₹20,000/mo', '3 months', 'Software', null),
  ('QA Engineer Intern', 'IBM', 'Internship', 'Chennai', 'Hybrid', '₹18,000/mo', '6 months', 'Software', null),
  ('Data Science Intern', 'Deloitte', 'Internship', 'Bengaluru', 'Hybrid', '₹28,000/mo', '6 months', 'Data', null),
  ('Business Intelligence Analyst', 'Morgan Stanley', 'Full-time', 'Mumbai', 'Onsite', '₹7 LPA', 'Permanent', 'Data', 'Full-time'),
  ('ML Engineer Intern', 'EY', 'Internship', 'Hyderabad', 'Remote', '₹30,000/mo', '4 months', 'Data', null),
  ('Social Media Marketing Intern', 'Dentsu', 'Internship', 'Delhi', 'Onsite', '₹15,000/mo', '3 months', 'Marketing', null),
  ('Growth Marketing Associate', 'Dentsu', 'Full-time', 'Gurugram', 'Hybrid', '₹6 LPA', 'Permanent', 'Marketing', 'Full-time'),
  ('Investment Banking Analyst', 'Morgan Stanley', 'Full-time', 'Mumbai', 'Onsite', '₹9 LPA', 'Permanent', 'Finance', 'Full-time'),
  ('Accounts Executive', 'JPMorgan Chase', 'Full-time', 'Ahmedabad', 'Onsite', '₹4.5 LPA', 'Permanent', 'Finance', 'Part-time'),
  ('Graphic Design Intern', 'Adobe', 'Internship', 'Pune', 'Remote', '₹16,000/mo', '3 months', 'Design', null),
  ('Product Designer', 'Adobe', 'Full-time', 'Bengaluru', 'Hybrid', '₹8.5 LPA', 'Permanent', 'Design', 'Full-time'),
  ('Content Strategist Intern', 'Ogilvy', 'Internship', 'Delhi', 'Remote', '₹14,000/mo', '3 months', 'Content', null),
  ('Copywriter', 'Ogilvy', 'Full-time', 'Mumbai', 'Hybrid', '₹5 LPA', 'Permanent', 'Content', 'Part-time'),
  ('Product Analyst Intern', 'Accenture', 'Internship', 'Gurugram', 'Onsite', '₹26,000/mo', '6 months', 'Product', null),
  ('Business Development Intern', 'Wipro', 'Internship', 'Noida', 'Onsite', '₹15,000/mo', '3 months', 'Sales', null),
  ('Operations Associate', 'DHL', 'Full-time', 'Chennai', 'Onsite', '₹5.5 LPA', 'Permanent', 'Operations', 'Full-time'),
  ('HR Intern', 'Morgan Stanley', 'Internship', 'Mumbai', 'Hybrid', '₹13,000/mo', '3 months', 'HR', null),
  ('Research Analyst Intern', 'Deloitte', 'Internship', 'Pune', 'Remote', '₹20,000/mo', '4 months', 'Research', null),
];

final List<Opportunity> _extraOpportunities = List.generate(_extraOpportunitySeeds.length, (i) {
  final (title, company, type, location, workMode, stipend, duration, category, employmentType) = _extraOpportunitySeeds[i];
  final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return Opportunity(
    id: 'opp-extra-$i-$slug',
    title: title,
    company: company,
    type: type,
    location: location,
    workMode: workMode,
    stipend: stipend,
    duration: duration,
    category: category,
    employmentType: employmentType,
    image: _extraOpportunityImages[i % _extraOpportunityImages.length],
    about: 'Join $company as a $title, working with a small team that moves fast and ships often.',
    requirements: const ['Strong fundamentals', 'Good communication', 'Ownership mindset', 'Eagerness to learn'],
    prepCourses: const ['course-interview-prep'],
    deadline: _deadlineIn(5 + (i % 10)),
    applicantCount: 20 + (i * 7) % 140,
  );
});

List<Opportunity> filterOpportunities({
  String? type,
  String? workMode,
  String? query,
  List<String>? categories,
  String? location,
  String? employmentType,
  List<String>? locations,
}) {
  var items = mockOpportunities;
  if (type != null && type.toLowerCase() != 'all') {
    items = items.where((o) => o.type.toLowerCase() == type.toLowerCase()).toList();
  }
  if (workMode != null && workMode.toLowerCase() != 'all') {
    items = items.where((o) => o.workMode.toLowerCase() == workMode.toLowerCase()).toList();
  }
  // Null on every Internship (see Opportunity.employmentType), so filtering
  // by this while Internship is also selected correctly excludes
  // everything rather than silently matching nothing for an unclear reason.
  if (employmentType != null) {
    items = items.where((o) => (o.employmentType ?? '').toLowerCase() == employmentType.toLowerCase()).toList();
  }
  if (categories != null && categories.isNotEmpty) {
    final wanted = categories.map((c) => c.toLowerCase()).toSet();
    items = items.where((o) => wanted.contains(o.category.toLowerCase())).toList();
  }
  // Independent of `query` below — a search screen with a dedicated
  // Location field needs "React AND Bengaluru" (both must match), not
  // "React OR Bengaluru" the way a single free-text query treats location.
  final loc = location?.trim().toLowerCase();
  if (loc != null && loc.isNotEmpty) {
    items = items.where((o) => o.location.toLowerCase().contains(loc)).toList();
  }
  // Preferred-cities facet — OR-matched (any one of several saved cities
  // is a match), additive to (not a replacement for) the single `location`
  // param above, which search_screen.dart's dedicated Location field still
  // uses unchanged.
  if (locations != null && locations.isNotEmpty) {
    final wanted = locations.map((c) => c.trim().toLowerCase()).where((c) => c.isNotEmpty).toList();
    if (wanted.isNotEmpty) {
      items = items.where((o) => wanted.any((c) => o.location.toLowerCase().contains(c))).toList();
    }
  }
  final q = query?.trim().toLowerCase();
  if (q != null && q.isNotEmpty) {
    items = items.where((o) {
      return o.title.toLowerCase().contains(q) ||
          o.company.toLowerCase().contains(q) ||
          o.category.toLowerCase().contains(q) ||
          o.location.toLowerCase().contains(q);
    }).toList();
  }
  // Always hand back a fresh, independently-sortable copy — callers must
  // never be able to mutate the shared mockOpportunities order in place.
  return List.of(items);
}

/// Distinct company/category/title strings — the type-ahead suggestion
/// pool for the search screen's query box, mirroring Naukri's own mixed
/// company/skill/designation suggestions instead of only matching titles.
List<String> searchSuggestionTerms() {
  final terms = <String>{};
  for (final o in mockOpportunities) {
    terms.add(o.company);
    terms.add(o.category);
    terms.add(o.title);
  }
  return terms.toList()..sort();
}

Opportunity? getOpportunityById(String id) {
  try {
    return mockOpportunities.firstWhere((o) => o.id == id);
  } catch (_) {
    return null;
  }
}
