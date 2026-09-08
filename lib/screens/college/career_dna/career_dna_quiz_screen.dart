import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../mockData/career_dna/career_dna_registry.dart';
import '../../../models/career_dna.dart';
import '../../../models/career_dna_question.dart';
import '../../../state/app_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/responsive_body.dart';

/// The one-question-per-page quiz shell, shared by all 5 Career DNA levels.
/// Mirrors aptitude_screen.dart's mechanics wholesale (PageController +
/// NeverScrollableScrollPhysics, in-memory answers only, 220ms auto-advance
/// timer, back-chevron, leave-confirmation dialog, PopScope) with one
/// deliberate deviation: the status label reads "40% complete" (percent
/// text), per the user's explicit ask, not aptitude_screen.dart's own
/// "Q3 of 20" counter style. Answers are genuinely never persisted until
/// the final submit — quitting mid-quiz loses all progress on this level,
/// by design (see the plan's persistence-discipline note).
class CareerDnaQuizScreen extends StatefulWidget {
  final int level;
  const CareerDnaQuizScreen({super.key, required this.level});

  @override
  State<CareerDnaQuizScreen> createState() => _CareerDnaQuizScreenState();
}

class _CareerDnaQuizScreenState extends State<CareerDnaQuizScreen> {
  late final PageController _pageController;
  late final List<CareerDnaQuestion> _questions;
  int _index = 0;
  final Map<String, String> _answers = {};
  bool _calculating = false;
  bool _animating = false;
  Timer? _advanceTimer;

  int get _total => _questions.length;

  double get _progress {
    if (_total == 0) return 0;
    final current = _questions[_index];
    final answered = _answers[current.id] != null ? 1 : 0;
    return (_index + answered) / _total;
  }

  @override
  void initState() {
    super.initState();
    _questions = careerDnaQuestionsForLevel(widget.level);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _calculating = true);
    final appState = context.read<AppState>();
    try {
      final current = appState.user?.careerDnaOrEmpty ?? const CareerDnaProfile();
      final updated = computeAndApplyCareerDnaLevel(widget.level, _answers, current);
      await appState.updateProfile((u) => u.copyWith(careerDna: updated));
      if (!mounted) return;
      context.go('/college/career-dna/level/${widget.level}/complete');
    } catch (_) {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _goTo(int page) async {
    if (_animating || page == _index || page < 0 || page >= _total) return;
    setState(() => _animating = true);
    await _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    if (!mounted) return;
    setState(() {
      _index = page;
      _animating = false;
    });
  }

  Future<void> _goBack() async {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (_index > 0) {
      _goTo(_index - 1);
      return;
    }
    if (_answers.isEmpty) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Are you sure you want to quit?', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 17, fontWeight: AppFontWeight.semibold)),
        content: Text(
          "You'll lose your progress on this level.",
          style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Keep answering', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Leave', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: AppFontWeight.bold)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  void _answer(String optionId) {
    if (_calculating || _animating) return;
    _advanceTimer?.cancel();
    HapticFeedback.lightImpact();
    final questionId = _questions[_index].id;
    setState(() => _answers[questionId] = optionId);

    _advanceTimer = Timer(const Duration(milliseconds: 220), () async {
      _advanceTimer = null;
      if (!mounted) return;
      if (_index + 1 >= _total) {
        _submit();
      } else {
        await _goTo(_index + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_calculating) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.blue,
          body: ResponsiveBody(child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 3)),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Text(
                      'Calculating your results…',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: AppFontWeight.medium),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Matching your answers to your natural style',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: AppColors.whiteA70),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ),
      );
    }

    if (_total == 0) {
      // Defensive only — sequential unlocking should make this unreachable.
      return Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text("This level isn't available yet.", style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          ),
        )),
      );
    }

    final topInset = MediaQuery.of(context).padding.top;
    final percentComplete = (_progress * 100).round();

    return PopScope(
      canPop: _index == 0 && _answers.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: ResponsiveBody(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _goBack,
                      child: const Icon(Ionicons.chevron_back, size: 44 - AppSpacing.lg, color: AppColors.ink),
                    ),
                    Expanded(
                      child: Text(
                        '$percentComplete% complete',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.regular),
                      ),
                    ),
                    SizedBox(width: 44 - AppSpacing.lg),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _progress.clamp(0.04, 1.0)),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: AppSpacing.sm - AppSpacing.xs / 2,
                      backgroundColor: AppColors.offWhite,
                      valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _total,
                  onPageChanged: (page) {
                    if (_index != page) setState(() => _index = page);
                  },
                  itemBuilder: (context, i) {
                    final question = _questions[i];
                    return _QuestionBody(question: question, answers: _answers, onAnswer: _answer);
                  },
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  final CareerDnaQuestion question;
  final Map<String, String> answers;
  final ValueChanged<String> onAnswer;

  const _QuestionBody({required this.question, required this.answers, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            textAlign: TextAlign.left,
            style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, height: 1.25),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: Column(
              children: question.options.map((opt) {
                final selected = answers[question.id] == opt.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () => onAnswer(opt.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue : AppColors.offWhite,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.text,
                              textAlign: TextAlign.left,
                              style: AppTextStyles.bodyLg.copyWith(color: selected ? AppColors.white : AppColors.ink, fontWeight: AppFontWeight.medium),
                            ),
                          ),
                          if (selected) const Icon(Ionicons.checkmark_circle, size: 20, color: AppColors.white),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
