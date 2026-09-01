import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_profile_activity.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../utils/relative_time.dart';
import '../../widgets/responsive_body.dart';

const _actionIcons = {
  'Viewed your profile': Ionicons.eye_outline,
  'Downloaded your resume': Ionicons.download_outline,
  'Shortlisted you': Ionicons.star_outline,
  'Saved your profile': Ionicons.bookmark_outline,
};

/// Naukri's "Recruiter Actions" — a company-attributed activity feed
/// ("Microsoft viewed your profile"), not just a bare count. The Home
/// dashboard's "Recruiter actions" card used to open the generic
/// Notifications feed, which has no recruiter-specific content — this is
/// the real destination.
class RecruiterActionsScreen extends StatelessWidget {
  const RecruiterActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final actions = recruiterActionsFor(user);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: Column(
        children: [
          Container(
            color: AppColors.blue,
            padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(onTap: () => context.pop(), child: const Icon(Ionicons.chevron_back, size: 26, color: AppColors.white)),
                Text('Recruiter actions', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 18, fontWeight: AppFontWeight.semibold)),
                const SizedBox(width: AppSpacing.xxl),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                Text(
                  noOrphan("What recruiters have done with your profile — most recent first."),
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5, height: 1.3),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...actions.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                            child: Icon(_actionIcons[a.action] ?? Ionicons.business_outline, size: 18, color: AppColors.blue),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.company, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14.5, fontWeight: AppFontWeight.semibold)),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(a.action, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12.5)),
                                ),
                              ],
                            ),
                          ),
                          Text(relativeTimeLabel(a.at), style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 11.5)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
