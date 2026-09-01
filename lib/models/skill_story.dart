import 'package:flutter/material.dart';

/// One tappable choice on a story question. [isBestPractice] drives the
/// end-of-story score — not a pass/fail grade, just a light nudge toward
/// the stronger habit, shown after the pick so it still teaches something
/// even in a quiz that "has no wrong answers".
class StoryOption {
  final String label;
  final bool isBestPractice;
  final String? note;
  const StoryOption({required this.label, this.isBestPractice = false, this.note});
}

class StoryPage {
  final String prompt;
  final List<StoryOption> options;
  const StoryPage({required this.prompt, required this.options});
}

/// A short, swipeable "soft skills for jobs" story — mirrors the
/// Flo-style daily-insight card pattern: a colorful teaser card on the
/// home feed opens a full-screen 2–4 question mini-quiz ending in one
/// concrete takeaway, not a lesson.
class SkillStory {
  final String id;
  final String cardTitle;
  final String badge;
  final Color background;
  final Color foreground;
  final IconData icon;
  final List<StoryPage> pages;
  final String insightTitle;
  final String insightBody;

  const SkillStory({
    required this.id,
    required this.cardTitle,
    required this.badge,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.pages,
    required this.insightTitle,
    required this.insightBody,
  });
}
