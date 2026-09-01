import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../models/course.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

const categoryIcons = {
  'Counseling': Ionicons.compass_outline,
  'Technology': Ionicons.code_slash_outline,
  'Design': Ionicons.color_palette_outline,
  'Finance': Ionicons.cash_outline,
  'Science': Ionicons.flask_outline,
  'Placement': Ionicons.briefcase_outline,
};

/// One horizontally-scrolling row of course cards — promoted out of
/// courses_explore_screen.dart (where it was a private, header-less,
/// category-only carousel) so the Home feed's end-of-scroll "Boost your
/// chances" section can reuse the exact same card shell with a title/count/
/// "View all" header added, mirroring OpportunityCarouselSection's shape.
/// [onViewAll] is optional — courses_explore_screen.dart's own per-category
/// carousels pass none, since that screen already *is* the "view all"
/// destination.
class CourseCarouselSection extends StatelessWidget {
  final String title;
  final List<Course> courses;
  final VoidCallback? onViewAll;

  const CourseCarouselSection({super.key, required this.title, required this.courses, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: title, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
                      TextSpan(text: '  (${courses.length})', style: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 14)),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onViewAll,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View all', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
                        const SizedBox(width: 2),
                        const Icon(Ionicons.chevron_forward, size: 14, color: AppColors.blue),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // No explicit gap here — the carousel's own top padding below is
        // the gap, and it's also the shadow-safety buffer for
        // AppShadows.card (see AppShadows.cardBuffer).
        //
        // Horizontal inset is split sm (outer) + lg (ListView's own content
        // padding) rather than living entirely in the outer Padding — a
        // ListView clips to its own box regardless of an outer Padding's
        // width, so the first/last card's shadow (needs ~12px clearance
        // left/right, blurRadius with zero x-offset) was hard-clipped with
        // no padding of the ListView's own. sm+lg still sums to the usual
        // AppSpacing.xl total inset; same split already used correctly in
        // opportunity_carousel_section.dart's lane.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: SizedBox(
            height: 172 + AppShadows.cardBuffer * 2,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppShadows.cardBuffer, AppSpacing.lg, AppShadows.cardBuffer),
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) => _CourseCard(course: courses[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Same shell as OpportunityCarouselCard on the Home feed (fixed
/// width/height, AppShadows.card, tinted icon mark instead of a photo) —
/// deliberately the same card family, not a bespoke look for courses.
class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
      child: InkWell(
        onTap: () => context.push('/course/${course.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
        child: Container(
          width: 250,
          height: 172,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Icon(categoryIcons[course.category] ?? Ionicons.book_outline, size: 22, color: AppColors.blue),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 15, height: 1.2),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _MetaLine(icon: Ionicons.time_outline, label: course.duration),
              const SizedBox(height: AppSpacing.sm),
              _MetaLine(icon: Ionicons.layers_outline, label: '${course.modules} modules'),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('View syllabus →', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.gray500),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12.5, fontWeight: AppFontWeight.medium),
          ),
        ),
      ],
    );
  }
}
