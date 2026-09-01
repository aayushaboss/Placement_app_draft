import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_articles.dart';
import '../../mockData/mock_bookings.dart';
import '../../mockData/mock_courses.dart';
import '../../models/article.dart';
import '../../models/booking.dart';
import '../../models/course.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/badges.dart';
import '../../widgets/course_carousel_section.dart';
import '../../widgets/fomo_notification_card.dart';
import '../../widgets/home_header.dart';
import '../../widgets/pill_button.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Mirrors frontend/src/screens/SchoolHome.tsx (SchoolHome).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class SchoolHomeScreen extends StatefulWidget {
  const SchoolHomeScreen({super.key});

  @override
  State<SchoolHomeScreen> createState() => _SchoolHomeScreenState();
}

class _SchoolHomeScreenState extends State<SchoolHomeScreen> {
  List<Course> _courses = [];
  List<Article> _articles = [];
  List<Booking> _bookings = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Branch index 0 (Home) — see router.dart's StatefulShellRoute.
    ScrollToTopRegistry.register(0, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowFomoSheet(context, isSchool: true);
    });
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(0);
    _scrollController.dispose();
    super.dispose();
  }

  void _load() {
    final user = context.read<AppState>().user;
    final clusters = user?.aptitudeResults?.matches.map((m) => m.cluster).toList() ?? const <String>[];
    setState(() {
      _courses = recommendedCourses(clusters);
      _articles = mockArticles;
      _bookings = listBookings();
    });
  }

  Future<void> _onRefresh() async {
    _load();
  }

  String _prettyDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${_weekdayShort[d.weekday - 1]}, ${_monthShort[d.month - 1]} ${d.day}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final clusters = user?.aptitudeResults?.matches.map((m) => m.cluster).toList() ?? const <String>[];
    final showAptitudeCta = user?.aptitudeResults == null;
    final upcoming = _bookings.isNotEmpty ? _bookings.first : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            HomeHeader(
              name: user?.name,
              photoUrl: user?.photoUrl,
              subtitle: 'Your career journey',
              onAvatarTap: () => context.go('/tabs/profile'),
              onBellTap: () => context.push('/notifications'),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue,
                onRefresh: _onRefresh,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    if (upcoming != null)
                      GestureDetector(
                        onTap: () => context.go('/tabs/sessions'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: const Border(left: BorderSide(color: AppColors.blue, width: 4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                child: const Icon(Ionicons.videocam, size: 22, color: AppColors.blue),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('UPCOMING SESSION', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 11, fontWeight: AppFontWeight.medium, letterSpacing: 0.8)),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        upcoming.kind == 'placement' ? (upcoming.sessionType ?? 'Placement session') : 'Counseling with ${upcoming.counselor}',
                                        style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 15, fontWeight: AppFontWeight.bold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '${_prettyDate(upcoming.date)} • ${upcoming.time} • ${upcoming.mode == 'online' ? 'Online' : 'Offline'}',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => context.push('/booking?kind=counseling'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Book free counseling', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 18, fontWeight: AppFontWeight.bold)),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(noOrphan('Talk 1:1 with an expert about your path.'), style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Ionicons.arrow_forward_circle, size: 34, color: AppColors.yellow),
                            ],
                          ),
                        ),
                      ),
                    if (showAptitudeCta)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'APTITUDE TEST',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.blue,
                                  fontWeight: AppFontWeight.medium,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.sm),
                                child: Text(
                                  'Find what fits you',
                                  textAlign: TextAlign.left,
                                  style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text(
                                  noOrphan('12 quick questions to unlock personalized clusters and recommendations.'),
                                  textAlign: TextAlign.left,
                                  style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.lg),
                                child: PillButton(
                                  label: 'Take the aptitude test',
                                  icon: Ionicons.flash,
                                  onPressed: () => context.push('/school/aptitude-intro'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (clusters.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl, left: AppSpacing.xl, right: AppSpacing.xl),
                        child: Row(
                          children: [
                            Expanded(child: Text('Your career clusters', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold))),
                            // The only other way back to the test once it's
                            // complete is a link buried inside Results —
                            // without this, the aptitude CTA card just
                            // vanishes for good after the first attempt.
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.push('/school/aptitude-intro'),
                              child: Text('Retake test', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 44 + AppSpacing.sm,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.md),
                          scrollDirection: Axis.horizontal,
                          itemCount: clusters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, i) => Align(
                            alignment: Alignment.center,
                            // Each chip jumps straight to its own cluster's
                            // card on Results, not just the generic top
                            // match — previously every chip opened the
                            // identical screen regardless of which cluster
                            // was tapped.
                            child: AppChip(
                              label: clusters[i],
                              onPressed: () => context.push(Uri(path: '/school/results', queryParameters: {'cluster': clusters[i]}).toString()),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: CourseCarouselSection(title: 'Recommended for you', courses: _courses),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl, left: AppSpacing.xl, right: AppSpacing.xl),
                      child: Text('Resources for you', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                      child: Column(
                        children: _articles
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    // Concentric with the inner ClipRRect: outerRadius = innerRadius (AppRadius.md) + the padding between them.
                                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.sm), boxShadow: AppShadows.soft),
                                    child: Row(
                                      children: [
                                        // Tinted icon, not a stock photo — same
                                        // no-real-image rule as every card in
                                        // the app (see CompanyMark).
                                        Container(
                                          width: 84,
                                          height: 84,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.md)),
                                          child: const Icon(Ionicons.document_text_outline, size: 32, color: AppColors.blue),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AppTag(label: a.tag),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.bold)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(a.readTime, style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
