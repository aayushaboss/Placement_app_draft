import '../../models/career_dna.dart';
import '../../models/career_dna_question.dart';
import '../../utils/career_dna_scoring.dart';

/// Level 1 — Personality & Behaviour. 20 questions, transcribed verbatim
/// from the source assessment doc. Weight matrices are authored using that
/// doc's own scale (— = 0, Low = 1, Medium = 2, High = 3, VeryHigh = 4),
/// applied against this level's 10 Core Personality Dimensions — Q6's
/// weights below are the doc's own literal worked example; every other
/// question's weights follow the same rule mechanically from its stated
/// Primary Traits. Never shown to the student — see career_dna_scoring.dart.
const List<String> careerDnaLevel1Dimensions = [
  'leadershipInitiative',
  'communicationConfidence',
  'teamOrientation',
  'adaptability',
  'decisionMaking',
  'problemSolving',
  'learningAgility',
  'resilience',
  'socialOrientation',
  'ambitionGrowth',
];

final List<CareerDnaQuestion> careerDnaLevel1Questions = [
  const CareerDnaQuestion(
    id: 'l1q1',
    text: "You join a new group activity where you don't know anyone. What would you naturally do?",
    options: [
      CareerDnaOption(id: 'a', text: 'Start a conversation with someone who seems approachable.', weights: {'socialOrientation': 4, 'communicationConfidence': 3, 'adaptability': 1}),
      CareerDnaOption(id: 'b', text: 'Observe the group for a while before getting involved.', weights: {'socialOrientation': 1, 'communicationConfidence': 1, 'adaptability': 3}),
      CareerDnaOption(id: 'c', text: 'Look for someone I already know or feel comfortable with.', weights: {'socialOrientation': 2, 'communicationConfidence': 1, 'adaptability': 1}),
      CareerDnaOption(id: 'd', text: 'Focus on the activity itself and let conversations happen naturally.', weights: {'socialOrientation': 2, 'communicationConfidence': 2, 'adaptability': 4}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q2',
    text: 'Your group has several different ideas for a shared project. What role would you naturally take?',
    options: [
      CareerDnaOption(id: 'a', text: 'Help the group combine the strongest ideas.', weights: {'teamOrientation': 4, 'leadershipInitiative': 2, 'communicationConfidence': 2}),
      CareerDnaOption(id: 'b', text: 'Share the idea I believe will work best.', weights: {'teamOrientation': 1, 'leadershipInitiative': 3, 'communicationConfidence': 4}),
      CareerDnaOption(id: 'c', text: "Listen to everyone's views before deciding what I think.", weights: {'teamOrientation': 3, 'leadershipInitiative': 1, 'communicationConfidence': 3}),
      CareerDnaOption(id: 'd', text: 'Focus on executing whichever idea the group selects.', weights: {'teamOrientation': 3, 'leadershipInitiative': 1, 'communicationConfidence': 1, 'problemSolving': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q3',
    text: 'You are asked to do something you have never done before. What sounds most like you?',
    options: [
      CareerDnaOption(id: 'a', text: 'Try it and learn while doing it.', weights: {'learningAgility': 4, 'adaptability': 3, 'problemSolving': 2}),
      CareerDnaOption(id: 'b', text: 'Understand the process first and then begin.', weights: {'learningAgility': 2, 'adaptability': 1, 'problemSolving': 3}),
      CareerDnaOption(id: 'c', text: 'Find someone who has done it before and learn from them.', weights: {'learningAgility': 2, 'socialOrientation': 3, 'adaptability': 1}),
      CareerDnaOption(id: 'd', text: 'Explore different ways of doing it before choosing one.', weights: {'learningAgility': 3, 'adaptability': 4, 'problemSolving': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q4',
    text: 'A close friend achieves something that you also wanted. What would most naturally happen?',
    options: [
      CareerDnaOption(id: 'a', text: 'I would genuinely celebrate their achievement.', weights: {'teamOrientation': 4, 'socialOrientation': 3, 'ambitionGrowth': 1}),
      CareerDnaOption(id: 'b', text: 'I would become curious about how they achieved it.', weights: {'learningAgility': 3, 'ambitionGrowth': 2, 'teamOrientation': 2}),
      CareerDnaOption(id: 'c', text: 'I would compare my progress with theirs.', weights: {'ambitionGrowth': 3, 'teamOrientation': 1, 'socialOrientation': 1}),
      CareerDnaOption(id: 'd', text: 'I would use it as motivation for my own goals.', weights: {'ambitionGrowth': 4, 'teamOrientation': 2, 'learningAgility': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q5',
    text: 'You have planned your day, but an unexpected situation changes your plans. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Quickly make a new plan.', weights: {'decisionMaking': 4, 'adaptability': 3}),
      CareerDnaOption(id: 'b', text: 'Take some time to understand the situation first.', weights: {'decisionMaking': 2, 'adaptability': 2, 'problemSolving': 2}),
      CareerDnaOption(id: 'c', text: 'Ask someone I trust what they think I should do.', weights: {'decisionMaking': 1, 'socialOrientation': 3, 'adaptability': 1}),
      CareerDnaOption(id: 'd', text: 'Go with the change and see how things develop.', weights: {'adaptability': 4, 'decisionMaking': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q6',
    text: 'Nobody has volunteered to organise an important group activity. Which response feels most natural?',
    options: [
      CareerDnaOption(id: 'a', text: 'Wait and see who takes responsibility.', weights: {'leadershipInitiative': 1}),
      CareerDnaOption(id: 'b', text: 'Offer to help whoever takes charge.', weights: {'leadershipInitiative': 2, 'teamOrientation': 3}),
      CareerDnaOption(id: 'c', text: 'Suggest how the activity could be organised.', weights: {'leadershipInitiative': 3, 'teamOrientation': 2, 'adaptability': 2}),
      CareerDnaOption(id: 'd', text: 'Take responsibility for coordinating it.', weights: {'leadershipInitiative': 4, 'teamOrientation': 2, 'adaptability': 3}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q7',
    text: 'Someone strongly disagrees with your opinion during a discussion. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Explain why I see things differently.', weights: {'communicationConfidence': 4, 'adaptability': 1}),
      CareerDnaOption(id: 'b', text: 'Ask them why they think differently.', weights: {'adaptability': 3, 'communicationConfidence': 2, 'learningAgility': 2}),
      CareerDnaOption(id: 'c', text: 'Think about whether their argument changes my opinion.', weights: {'adaptability': 4, 'decisionMaking': 2}),
      CareerDnaOption(id: 'd', text: 'Move the discussion forward even if we disagree.', weights: {'communicationConfidence': 2, 'teamOrientation': 3, 'decisionMaking': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q8',
    text: 'You prepared seriously for something important, but the outcome was much lower than expected. What would you most likely do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Look at what may have gone wrong.', weights: {'learningAgility': 3, 'resilience': 2, 'problemSolving': 2}),
      CareerDnaOption(id: 'b', text: 'Take some time before thinking about it again.', weights: {'resilience': 3, 'learningAgility': 1}),
      CareerDnaOption(id: 'c', text: 'Talk to someone who might understand what happened.', weights: {'resilience': 2, 'socialOrientation': 3}),
      CareerDnaOption(id: 'd', text: 'Change my preparation strategy for the next attempt.', weights: {'learningAgility': 4, 'resilience': 3, 'ambitionGrowth': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q9',
    text: 'Your friends are planning a trip and everyone has different preferences. Which role would you naturally take?',
    options: [
      CareerDnaOption(id: 'a', text: 'Suggest places and activities.', weights: {'socialOrientation': 3, 'leadershipInitiative': 1, 'teamOrientation': 1}),
      CareerDnaOption(id: 'b', text: 'Work out the practical details and budget.', weights: {'problemSolving': 4, 'teamOrientation': 1}),
      CareerDnaOption(id: 'c', text: 'Try to find an option everyone can enjoy.', weights: {'teamOrientation': 4, 'socialOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Let others decide and adapt to the plan.', weights: {'adaptability': 4, 'teamOrientation': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q10',
    text: 'You get an opportunity to participate in something you have never tried before. What attracts you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'The possibility of learning something new.', weights: {'learningAgility': 4, 'adaptability': 1}),
      CareerDnaOption(id: 'b', text: 'The excitement of doing something different.', weights: {'adaptability': 4, 'learningAgility': 1}),
      CareerDnaOption(id: 'c', text: 'Knowing that people I trust are involved.', weights: {'socialOrientation': 3, 'adaptability': 1}),
      CareerDnaOption(id: 'd', text: 'The possibility of achieving something significant.', weights: {'ambitionGrowth': 4, 'leadershipInitiative': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q11',
    text: 'A friend asks you for help while you are busy with your own work. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Help them immediately if the issue seems important.', weights: {'teamOrientation': 4, 'decisionMaking': 1}),
      CareerDnaOption(id: 'b', text: 'Finish my task and then help them.', weights: {'decisionMaking': 3, 'teamOrientation': 2, 'leadershipInitiative': 1}),
      CareerDnaOption(id: 'c', text: 'Give them a quick suggestion so they can continue.', weights: {'teamOrientation': 2, 'problemSolving': 2, 'decisionMaking': 2}),
      CareerDnaOption(id: 'd', text: 'Ask them what exactly they need before deciding.', weights: {'decisionMaking': 4, 'teamOrientation': 2, 'problemSolving': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q12',
    text: 'You are suddenly asked to speak in front of a group without preparation. Which feels most like you?',
    options: [
      CareerDnaOption(id: 'a', text: 'Start speaking and organise my thoughts while talking.', weights: {'communicationConfidence': 4, 'adaptability': 3}),
      CareerDnaOption(id: 'b', text: 'Take a moment to organise my thoughts first.', weights: {'communicationConfidence': 2, 'problemSolving': 2, 'adaptability': 1}),
      CareerDnaOption(id: 'c', text: 'Keep it short and communicate the main point.', weights: {'communicationConfidence': 3, 'problemSolving': 2}),
      CareerDnaOption(id: 'd', text: 'Try to involve the audience in the conversation.', weights: {'communicationConfidence': 3, 'socialOrientation': 3, 'adaptability': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q13',
    text: 'You are stuck while trying to solve a difficult problem. What would you naturally try first?',
    options: [
      CareerDnaOption(id: 'a', text: 'Try a completely different approach.', weights: {'problemSolving': 3, 'adaptability': 4}),
      CareerDnaOption(id: 'b', text: 'Search for information or examples.', weights: {'problemSolving': 4, 'adaptability': 1}),
      CareerDnaOption(id: 'c', text: 'Ask someone who may have faced something similar.', weights: {'teamOrientation': 3, 'socialOrientation': 2, 'problemSolving': 1}),
      CareerDnaOption(id: 'd', text: 'Step away briefly and return with a fresh perspective.', weights: {'adaptability': 2, 'resilience': 3, 'problemSolving': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q14',
    text: 'Someone asks you to coordinate something important for a group. Which part would you naturally enjoy most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Deciding how everything should be organised.', weights: {'leadershipInitiative': 4, 'problemSolving': 2}),
      CareerDnaOption(id: 'b', text: 'Getting people involved.', weights: {'socialOrientation': 4, 'leadershipInitiative': 2, 'teamOrientation': 2}),
      CareerDnaOption(id: 'c', text: 'Solving unexpected issues along the way.', weights: {'problemSolving': 4, 'adaptability': 2}),
      CareerDnaOption(id: 'd', text: 'Making sure the details are completed properly.', weights: {'problemSolving': 3, 'leadershipInitiative': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q15',
    text: 'You participate in a competition where several participants are much better than you. What would interest you most?',
    options: [
      CareerDnaOption(id: 'a', text: 'Testing myself against strong competitors.', weights: {'ambitionGrowth': 4, 'resilience': 2}),
      CareerDnaOption(id: 'b', text: 'Observing how the best participants approach it.', weights: {'learningAgility': 4, 'ambitionGrowth': 1}),
      CareerDnaOption(id: 'c', text: 'Finding my own strategy to perform well.', weights: {'problemSolving': 3, 'ambitionGrowth': 2}),
      CareerDnaOption(id: 'd', text: 'Seeing how much I can improve through the experience.', weights: {'learningAgility': 3, 'ambitionGrowth': 3, 'resilience': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q16',
    text: 'You have two equally attractive choices and need to select one. What would you naturally rely on?',
    options: [
      CareerDnaOption(id: 'a', text: 'Information and facts.', weights: {'decisionMaking': 4, 'problemSolving': 2}),
      CareerDnaOption(id: 'b', text: 'Advice from people I trust.', weights: {'socialOrientation': 4, 'decisionMaking': 1}),
      CareerDnaOption(id: 'c', text: 'What feels right to me.', weights: {'decisionMaking': 2, 'adaptability': 2}),
      CareerDnaOption(id: 'd', text: 'Which option could create better opportunities later.', weights: {'ambitionGrowth': 4, 'decisionMaking': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q17',
    text: 'A person in your group is finding it difficult to complete their part of a project. What would you naturally do?',
    options: [
      CareerDnaOption(id: 'a', text: 'Ask what they are finding difficult.', weights: {'teamOrientation': 4, 'socialOrientation': 2}),
      CareerDnaOption(id: 'b', text: 'Show them how I would approach it.', weights: {'leadershipInitiative': 3, 'teamOrientation': 2, 'problemSolving': 2}),
      CareerDnaOption(id: 'c', text: 'Give them some time to figure it out themselves.', weights: {'adaptability': 2, 'teamOrientation': 1, 'leadershipInitiative': 1}),
      CareerDnaOption(id: 'd', text: "Adjust the team's plan based on the situation.", weights: {'leadershipInitiative': 3, 'adaptability': 3, 'teamOrientation': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q18',
    text: 'You unexpectedly get an entire day free. Which option sounds most appealing?',
    options: [
      CareerDnaOption(id: 'a', text: 'Meet friends or spend time socially.', weights: {'socialOrientation': 4, 'teamOrientation': 1}),
      CareerDnaOption(id: 'b', text: 'Learn or explore something interesting.', weights: {'learningAgility': 4, 'socialOrientation': 1}),
      CareerDnaOption(id: 'c', text: 'Relax and do whatever I feel like.', weights: {'adaptability': 2, 'ambitionGrowth': 1}),
      CareerDnaOption(id: 'd', text: 'Work on something useful for my future.', weights: {'ambitionGrowth': 4, 'learningAgility': 1}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q19',
    text: "Something you were confident about doesn't work out. What would you naturally do?",
    options: [
      CareerDnaOption(id: 'a', text: 'Try to understand what happened.', weights: {'resilience': 3, 'learningAgility': 2}),
      CareerDnaOption(id: 'b', text: 'Take some time to reset before deciding what to do next.', weights: {'resilience': 4, 'adaptability': 1}),
      CareerDnaOption(id: 'c', text: 'Talk it through with someone close to me.', weights: {'resilience': 2, 'socialOrientation': 4}),
      CareerDnaOption(id: 'd', text: 'Look for another way to achieve the same goal.', weights: {'resilience': 3, 'ambitionGrowth': 3, 'adaptability': 2}),
    ],
  ),
  const CareerDnaQuestion(
    id: 'l1q20',
    text: 'Imagine yourself five years from now. Which situation would make you feel most satisfied?',
    options: [
      CareerDnaOption(id: 'a', text: 'Becoming highly skilled at something valuable.', weights: {'learningAgility': 4, 'ambitionGrowth': 2}),
      CareerDnaOption(id: 'b', text: 'Taking on greater responsibility and influence.', weights: {'leadershipInitiative': 4, 'ambitionGrowth': 2}),
      CareerDnaOption(id: 'c', text: 'Building strong relationships and a good professional network.', weights: {'socialOrientation': 4, 'teamOrientation': 2}),
      CareerDnaOption(id: 'd', text: 'Experiencing different opportunities and continuing to grow.', weights: {'adaptability': 4, 'learningAgility': 2, 'ambitionGrowth': 1}),
    ],
  ),
];

const _archetypes = {
  'leader': CareerDnaArchetype(
    id: 'leader',
    name: 'The Leader',
    naturalStyle: "You take ownership naturally and step up when something needs direction. You're comfortable being the one people look to, and you'd rather shape a decision than just wait for one.",
    growthAreaTitle: 'Listening & Collaboration',
    growthAreaText: 'Your instinct to take charge is a real strength — pairing it with a habit of drawing more out of quieter teammates before deciding will make your calls land even better.',
    strengths: ['Ownership', 'Initiative', 'Decisiveness', 'Influence'],
    environments: ['Management', 'Entrepreneurship', 'Operations', 'Project Leadership'],
  ),
  'connector': CareerDnaArchetype(
    id: 'connector',
    name: 'The Connector',
    naturalStyle: "You're genuinely energized by people — understanding them, bringing them together, and making sure everyone's actually heard. Rooms feel easier when you're in them.",
    growthAreaTitle: 'Structured Decision-Making',
    growthAreaText: "Your read on people is a real edge. Backing it with a bit more structure when a decision needs to move fast — not just consensus — will make that edge even sharper.",
    strengths: ['Communication', 'Empathy', 'Relationship-Building', 'Social Awareness'],
    environments: ['Sales', 'Marketing', 'HR', 'Client Management', 'Public Relations'],
  ),
  'strategist': CareerDnaArchetype(
    id: 'strategist',
    name: 'The Strategist',
    naturalStyle: 'You think before you act, and it shows — you naturally break a problem down, weigh the real options, and land on a well-reasoned call rather than the first idea that shows up.',
    growthAreaTitle: 'Confident Communication',
    growthAreaText: 'Your thinking is already sound — the next step is simply saying it with more conviction, sooner, so the room benefits from it before the decision is already made.',
    strengths: ['Analytical Thinking', 'Problem Solving', 'Judgement', 'Depth'],
    environments: ['Consulting', 'Research', 'Analytics', 'Strategy', 'Finance'],
  ),
  'explorer': CareerDnaArchetype(
    id: 'explorer',
    name: 'The Explorer',
    naturalStyle: 'You tend to be curious, adaptable and comfortable exploring new experiences. You likely enjoy environments where you can learn continuously and where every day does not look exactly the same.',
    growthAreaTitle: 'Structured Planning & Consistency',
    growthAreaText: 'Your profile suggests you enjoy variety and new experiences. Building a few stronger planning habits can help you convert that flexibility into consistent, compounding results.',
    strengths: ['Curiosity', 'Adaptability', 'Learning', 'Exploration'],
    environments: ['Startups', 'Marketing', 'Business Development', 'Consulting', 'Entrepreneurship'],
  ),
  'achiever': CareerDnaArchetype(
    id: 'achiever',
    name: 'The Achiever',
    naturalStyle: "You're driven by real, visible progress — setting a goal and pushing toward it is genuinely motivating for you, and setbacks tend to fuel the next attempt rather than stall you.",
    growthAreaTitle: 'Patience & Team Trust',
    growthAreaText: 'Your drive is a genuine asset. Slowing down just enough to bring others fully along — not only to move faster yourself — will multiply what that drive can achieve.',
    strengths: ['Ambition', 'Persistence', 'Goal Orientation', 'Resilience'],
    environments: ['Sales', 'Business Development', 'Consulting', 'Growth Roles', 'Entrepreneurship'],
  ),
  'builder': CareerDnaArchetype(
    id: 'builder',
    name: 'The Builder',
    naturalStyle: "You're the one things can actually be handed to — reliable, organised, and focused on genuinely finishing what you start, not just starting it.",
    growthAreaTitle: 'Comfort with Change',
    growthAreaText: "Your consistency is rare and valuable. Getting a little more comfortable with ambiguity — situations without a clear process yet — will open up even more of what you're capable of.",
    strengths: ['Reliability', 'Organisation', 'Consistency', 'Execution'],
    environments: ['Operations', 'Project Management', 'Engineering', 'Finance', 'Quality & Process'],
  ),
};

/// Weighted primary(x2)/secondary(x1) classifier — highest total wins, with
/// a deterministic tie-break by this fixed priority order (Leader first).
/// BUILDER's doc-defined traits ("reliable, organised, consistent,
/// execution-focused") don't map onto any single one of the 10 given
/// dimensions as cleanly as the other 5 archetypes do — Team Orientation +
/// Resilience is the closest approximation, flagged here for a second look
/// once real usage data exists.
const _classifierRules = [
  ('leader', 'leadershipInitiative', 'decisionMaking'),
  ('connector', 'socialOrientation', 'communicationConfidence'),
  ('strategist', 'problemSolving', 'decisionMaking'),
  ('explorer', 'adaptability', 'learningAgility'),
  ('achiever', 'ambitionGrowth', 'resilience'),
  ('builder', 'teamOrientation', 'resilience'),
];

CareerDnaArchetype _classifyArchetype(Map<String, int> scores) {
  var bestId = _classifierRules.first.$1;
  var bestScore = -1;
  for (final (id, primary, secondary) in _classifierRules) {
    final score = 2 * (scores[primary] ?? 0) + (scores[secondary] ?? 0);
    if (score > bestScore) {
      bestScore = score;
      bestId = id;
    }
  }
  return _archetypes[bestId]!;
}

CareerDnaLevel1Result computeCareerDnaLevel1Result(Map<String, String> answers) {
  final scores = normalizedDimensionScores(
    questions: careerDnaLevel1Questions,
    answers: answers,
    dimensions: careerDnaLevel1Dimensions,
  );
  return CareerDnaLevel1Result(
    dimensionScores: scores,
    archetype: _classifyArchetype(scores),
    completedAt: DateTime.now().toIso8601String(),
  );
}
