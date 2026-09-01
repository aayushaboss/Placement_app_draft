import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_notifications.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/responsive_body.dart';

// Note: substituted flash_outline for "sparkles" as in value_slides_screen.dart
// — flutter_vector_icons' bundled Ionicons font predates the sparkles glyph.
const _typeIcons = {
  'opportunity': Ionicons.briefcase_outline,
  'application': Ionicons.trophy_outline,
  'course': Ionicons.book_outline,
  'system': Ionicons.flash_outline,
};

/// Mirrors frontend/app/notifications.tsx (Notifications).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSchool = context.watch<AppState>().user?.segment == Segment.school;
    final notifications = isSchool ? mockSchoolNotifications : mockNotifications;
    final topInset = MediaQuery.of(context).padding.top;
    final groups = <String>[];
    for (final n in notifications) {
      if (!groups.contains(n.group)) groups.add(n.group);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: topInset + AppSpacing.sm,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/tabs'),
                    child: const Icon(
                      Ionicons.chevron_back,
                      size: 26,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Notifications',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: AppFontWeight.semibold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxl),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: groups.map((g) {
                  final items = notifications
                      .where((n) => n.group == g)
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray400,
                            fontSize: 12,
                            fontWeight: AppFontWeight.medium,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Column(
                            children: items
                                .map(
                                  (n) => Padding(
                                    // The gap between cards has to live
                                    // outside the Material — Material
                                    // paints its background across its
                                    // whole layout box, so a margin on the
                                    // child inside it still gets painted
                                    // over, leaving consecutive cards
                                    // looking fused together with no
                                    // visible seam.
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: Material(
                                      color: AppColors.offWhite,
                                      borderRadius: BorderRadius.circular(AppRadius.xl),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(AppRadius.xl),
                                        // Tab-shell destinations (e.g. /tabs) must use go(), not push() — the
                                        // shell route isn't designed to be stacked on top of itself and
                                        // renders blank if pushed; regular detail routes push normally.
                                        onTap: n.route == null
                                            ? null
                                            : () => n.route!.startsWith('/tabs')
                                                  ? context.go(n.route!)
                                                  : context.push(n.route!),
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.lg,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              if (n.unread)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: AppColors.blue,
                                                        shape: BoxShape.circle,
                                                      ),
                                                )
                                              else
                                                const SizedBox(width: 8),
                                              const SizedBox(
                                                width: AppSpacing.md,
                                              ),
                                              Container(
                                                width: 40,
                                                height: 40,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.blueA10,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  _typeIcons[n.type] ??
                                                      Ionicons
                                                          .notifications_outline,
                                                  size: 18,
                                                  color: AppColors.blue,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.md,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      n.title,
                                                      style: AppTextStyles
                                                          .bodyLg
                                                          .copyWith(
                                                            color:
                                                                AppColors.ink,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                AppFontWeight
                                                                    .bold,
                                                          ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 2,
                                                          ),
                                                      child: Text(
                                                        n.body,
                                                        style: AppTextStyles
                                                            .caption
                                                            .copyWith(
                                                              color: AppColors
                                                                  .gray500,
                                                              fontSize: 13,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (n.route != null)
                                                const Icon(
                                                  Ionicons.chevron_forward,
                                                  size: 18,
                                                  color: AppColors.gray400,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
