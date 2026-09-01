// Prototype mock data — delete when real API is wired.
// Mirrors frontend/src/mockData/mockAptitude.ts.
import '../models/aptitude.dart';

const List<AptitudeQuestion> mockAptitudeQuestions = [
  AptitudeQuestion(
    id: 'q1',
    type: AptitudeQuestionType.single,
    text: 'Which activity sounds the most fun to you?',
    options: [
      'Solving a tricky puzzle',
      'Helping a friend feel better',
      'Designing a poster',
      'Running a small stall',
    ],
  ),
  AptitudeQuestion(
    id: 'q2',
    type: AptitudeQuestionType.single,
    text: 'In a group project, you naturally become the…',
    options: ['Idea generator', 'Organizer / planner', 'Presenter', 'Builder / maker'],
  ),
  AptitudeQuestion(
    id: 'q3',
    type: AptitudeQuestionType.slider,
    text: 'I enjoy working with numbers and data.',
    min: 1,
    max: 5,
    minLabel: 'Not at all',
    maxLabel: 'Love it',
  ),
  AptitudeQuestion(
    id: 'q4',
    type: AptitudeQuestionType.forced,
    text: 'Would you rather…',
    options: ['Fix a broken machine', 'Write a short story'],
  ),
  AptitudeQuestion(
    id: 'q5',
    type: AptitudeQuestionType.single,
    text: 'A perfect weekend project would be…',
    options: [
      'Coding a small app',
      'Volunteering at a camp',
      'Painting or editing videos',
      'Selling handmade items',
    ],
  ),
  AptitudeQuestion(
    id: 'q6',
    type: AptitudeQuestionType.slider,
    text: 'I like understanding how the human body works.',
    min: 1,
    max: 5,
    minLabel: 'Not really',
    maxLabel: 'Very much',
  ),
  AptitudeQuestion(
    id: 'q7',
    type: AptitudeQuestionType.forced,
    text: 'Would you rather…',
    options: ['Lead a team', 'Work quietly on your own'],
  ),
  AptitudeQuestion(
    id: 'q8',
    type: AptitudeQuestionType.single,
    text: 'Which school subject do you look forward to?',
    options: ['Mathematics / Physics', 'Biology / Chemistry', 'Economics / Business', 'Art / Literature'],
  ),
  AptitudeQuestion(
    id: 'q9',
    type: AptitudeQuestionType.slider,
    text: 'I enjoy convincing and negotiating with people.',
    min: 1,
    max: 5,
    minLabel: 'Avoid it',
    maxLabel: 'Thrive on it',
  ),
  AptitudeQuestion(
    id: 'q10',
    type: AptitudeQuestionType.single,
    text: 'A problem feels exciting when it is…',
    options: [
      'Logical and technical',
      'About people and care',
      'Open-ended and creative',
      'About money and strategy',
    ],
  ),
  AptitudeQuestion(
    id: 'q11',
    type: AptitudeQuestionType.forced,
    text: 'Would you rather…',
    options: ['Build a robot', 'Plan a fund-raising event'],
  ),
  AptitudeQuestion(
    id: 'q12',
    type: AptitudeQuestionType.single,
    text: 'People often praise you for being…',
    options: ['Analytical', 'Caring', 'Imaginative', 'Persuasive'],
  ),
];

final AptitudeResults mockAptitudeResults = AptitudeResults(
  topMatch: 'Technology & Computer Science',
  matches: const [
    AptitudeMatch(
      cluster: 'Technology & Computer Science',
      matchPercent: 88,
      why: 'You enjoy logical problem-solving and building things.',
      sampleCareers: ['Software Engineer', 'Data Analyst', 'Product Manager'],
      recommendedStreams: ['Science (PCM)', 'Computer Science'],
    ),
    AptitudeMatch(
      cluster: 'Commerce & Finance',
      matchPercent: 74,
      why: 'You like strategy, numbers and real-world impact.',
      sampleCareers: ['Financial Analyst', 'Entrepreneur', 'Accountant'],
      recommendedStreams: ['Commerce', 'Economics'],
    ),
    AptitudeMatch(
      cluster: 'Design & Creative',
      matchPercent: 68,
      why: 'You have a creative, imaginative streak.',
      sampleCareers: ['UX Designer', 'Content Creator', 'Architect'],
      recommendedStreams: ['Arts', 'Design'],
    ),
  ],
  generatedAt: DateTime.now().toIso8601String(),
);
