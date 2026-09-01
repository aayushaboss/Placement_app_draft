import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_aptitude.dart';
import '../../models/aptitude.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/brand.dart';
import '../../widgets/responsive_body.dart';

/// Mirrors frontend/app/school/aptitude.tsx (Aptitude).
class AptitudeScreen extends StatefulWidget {
  const AptitudeScreen({super.key});

  @override
  State<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends State<AptitudeScreen> {
  late final PageController _pageController;
  int _index = 0;
  final Map<String, dynamic> _answers = {};
  bool _calculating = false;
  bool _animating = false;
  Timer? _advanceTimer;

  int get _total => mockAptitudeQuestions.length;

  double get _progress {
    if (_total == 0) return 0;
    final current = mockAptitudeQuestions[_index];
    final answered = _answers[current.id] != null ? 1 : 0;
    return (_index + answered) / _total;
  }

  @override
  void initState() {
    super.initState();
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
      // TODO: replace with real API call
      await appState.updateProfile((current) => current.copyWith(
            aptitudeResults: mockAptitudeResults,
            aptitudeSkipped: false,
            onboardingComplete: true,
          ));
      await appState.refresh();
      if (!mounted) return;
      context.go('/school/results');
    } catch (_) {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _goTo(int page) async {
    if (_animating || page == _index || page < 0 || page >= _total) return;
    setState(() => _animating = true);
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() {
      _index = page;
      _animating = false;
    });
  }

  void _goBack() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (_index > 0) {
      _goTo(_index - 1);
    } else {
      context.pop();
    }
  }

  void _answer(dynamic value) {
    if (_calculating || _animating || _advanceTimer != null) return;
    HapticFeedback.lightImpact();
    final questionId = mockAptitudeQuestions[_index].id;
    setState(() => _answers[questionId] = value);

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
                  const WingLogo(size: AppSpacing.xxxl + AppSpacing.xxl),
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: CircularProgressIndicator(color: AppColors.yellow),
                  ),
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
                      'Matching your answers to career clusters',
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

    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      // Without this, the system/browser back gesture pops the whole route
      // instead of stepping back one question, skipping however many of
      // the 12 questions are behind the current one.
      canPop: _index == 0,
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
                      'Q${_index + 1} of $_total',
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
                  final question = mockAptitudeQuestions[i];
                  return _QuestionBody(
                    question: question,
                    answers: _answers,
                    onAnswer: _answer,
                  );
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
  final AptitudeQuestion question;
  final Map<String, dynamic> answers;
  final ValueChanged<dynamic> onAnswer;

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
            style: AppTextStyles.h1.copyWith(
              color: AppColors.ink,
              fontWeight: AppFontWeight.medium,
              height: 1.25,
            ),
          ),
          if (question.type == AptitudeQuestionType.single) _buildSingle(),
          if (question.type == AptitudeQuestionType.forced) _buildForced(),
          if (question.type == AptitudeQuestionType.slider) _buildSlider(),
        ],
      ),
    );
  }

  Widget _buildSingle() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        children: (question.options ?? []).map((opt) {
          final selected = answers[question.id] == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () => onAnswer(opt),
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
                        opt,
                        textAlign: TextAlign.left,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: selected ? AppColors.white : AppColors.ink,
                          fontWeight: AppFontWeight.medium,
                        ),
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
    );
  }

  Widget _buildForced() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (question.options ?? []).map((opt) {
          final selected = answers[question.id] == opt;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: opt == question.options!.last ? 0 : AppSpacing.md),
              child: GestureDetector(
                onTap: () => onAnswer(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  constraints: BoxConstraints(minHeight: AppSpacing.xxxl * 3 + AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blue : AppColors.offWhite,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
                    boxShadow: selected ? null : AppShadows.soft,
                  ),
                  child: Text(
                    opt,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h3.copyWith(
                      color: selected ? AppColors.white : AppColors.ink,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlider() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 2, 3, 4, 5].map((v) {
              final selected = answers[question.id] == v;
              final size = 40 + v * AppSpacing.xs + AppSpacing.xs / 2;
              return GestureDetector(
                onTap: () => onAnswer(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blue : AppColors.offWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
                  ),
                  child: Text(
                    '$v',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: selected ? AppColors.white : AppColors.gray500,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(question.minLabel ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontWeight: AppFontWeight.medium)),
                Text(question.maxLabel ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontWeight: AppFontWeight.medium)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
