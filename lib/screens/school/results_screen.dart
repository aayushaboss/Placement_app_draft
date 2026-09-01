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
import '../../widgets/badges.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// Mirrors frontend/app/school/results.tsx (Results).
class ResultsScreen extends StatefulWidget {
  /// Set when reached by tapping a specific "career cluster" chip on Home
  /// — scrolls straight to that cluster's card in "All your matches"
  /// instead of always leaving the reader at the top (the genuine top
  /// match, which may not be the cluster they actually tapped).
  final String? initialCluster;

  const ResultsScreen({super.key, this.initialCluster});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  AptitudeResults? _results;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _matchKeys = {};
  bool _scrolledToCluster = false;

  @override
  void initState() {
    super.initState();
    final saved = context.read<AppState>().user?.aptitudeResults;
    _results = saved ?? mockAptitudeResults;
    for (final m in _results!.matches) {
      _matchKeys[m.cluster] = GlobalKey();
    }
    final target = widget.initialCluster;
    if (target != null && _matchKeys.containsKey(target)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrolledToCluster || !mounted) return;
        _scrolledToCluster = true;
        final ctx = _matchKeys[target]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOut, alignment: 0.1);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _skipHome() async {
    final appState = context.read<AppState>();
    // TODO: replace with real API call (local mock)
    await appState.updateProfile((current) => current.copyWith(onboardingComplete: true));
    if (!mounted) return;
    context.go('/tabs');
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    if (results == null) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(child: Center(child: CircularProgressIndicator(color: AppColors.blue))),
      );
    }

    final top = results.matches.first;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(child: Stack(
          children: [
            ListView(
              controller: _scrollController,
              padding: EdgeInsets.only(bottom: 140 + bottomInset),
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl),
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR TOP MATCH',
                        style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 13, fontWeight: AppFontWeight.medium, letterSpacing: 1.4),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          results.topMatch,
                          style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 32, fontWeight: AppFontWeight.semibold, height: 38 / 32),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${top.matchPercent}%',
                              style: const TextStyle(
                                fontFamily: kFontFamily,
                                color: AppColors.yellow,
                                fontSize: 56,
                                fontWeight: AppFontWeight.semibold,
                                letterSpacing: -1,
                                height: 58 / 56,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.md),
                              child: Text(
                                'fit',
                                style: AppTextStyles.h3.copyWith(color: AppColors.whiteA70, fontSize: 18, fontWeight: AppFontWeight.medium),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          top.why,
                          style: AppTextStyles.bodyLg.copyWith(color: AppColors.white, fontSize: 15, height: 22 / 15),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All your matches',
                        style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 20, fontWeight: AppFontWeight.medium),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...results.matches.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        return Padding(
                          key: _matchKeys[m.cluster],
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _MatchCard(rank: i + 1, match: m),
                        );
                      }),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/school/aptitude'),
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              'Retake test',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.gray400,
                                fontSize: 14,
                                fontWeight: AppFontWeight.medium,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PillButton(
                      label: 'Book Free Counseling Session',
                      icon: Ionicons.calendar,
                      onPressed: () => context.push('/booking?kind=counseling'),
                    ),
                    GestureDetector(
                      onTap: _skipHome,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          'Maybe later — go to home',
                          style: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 14, fontWeight: AppFontWeight.medium),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final int rank;
  final AptitudeMatch match;
  const _MatchCard({required this.rank, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                child: Text('$rank', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.medium, fontSize: 14)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(match.cluster, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 17, fontWeight: AppFontWeight.bold)),
              ),
              Text('${match.matchPercent}%', style: AppTextStyles.h2.copyWith(color: AppColors.blue, fontSize: 20, fontWeight: AppFontWeight.medium)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(match.why, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, height: 20 / 14)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'SAMPLE CAREERS',
              style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 0.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: match.sampleCareers.map((c) => AppTag(label: c)).toList(),
            ),
          ),
          if (match.recommendedStreams.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'RECOMMENDED STREAMS',
                style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 0.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: match.recommendedStreams
                    .map((s) => AppTag(label: s, color: AppColors.gray500, bg: AppColors.offWhite))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
