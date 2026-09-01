import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_applications.dart';
import '../../mockData/mock_opportunities.dart';
import '../../models/opportunity_match.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/opportunity_row.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// Mirrors frontend/src/screens/SavedScreen.tsx (SavedScreen).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final items = mockOpportunities.where((o) => appState.isOpportunitySaved(o.id)).toList();
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, topInset + AppSpacing.sm, AppSpacing.lg, 0),
            child: BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/profile'),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                  child: Text(
                    noOrphan('${items.length} bookmarked opportunit${items.length == 1 ? 'y' : 'ies'}'),
                    textAlign: TextAlign.left,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                              child: const Icon(Ionicons.bookmark_outline, size: 34, color: AppColors.blue),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: Text('Nothing saved yet', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: AppFontWeight.medium)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text(
                                'Tap the bookmark on any opportunity to keep it here.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xl),
                              child: PillButton(
                                label: 'Browse opportunities',
                                full: false,
                                onPressed: () => context.go('/tabs'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxxl),
                    children: List.generate(items.length, (i) {
                      final o = items[i];
                      final row = OpportunityRow(
                        tag: o.type,
                        title: o.title,
                        subtitle: o.company,
                        meta: [o.location, o.stipend, o.duration],
                        matchLabel: o.matchLabelFor(user),
                        deadlineLabel: o.deadlineLabel,
                        deadlineUrgent: o.deadlineIsUrgent,
                        saved: appState.isOpportunitySaved(o.id),
                        applied: listApplications().any((a) => a.opportunityId == o.id),
                        onToggleSave: () => appState.toggleSavedOpportunity(o.id),
                        onTap: () => context.push('/opportunity/${o.id}'),
                        onApply: () => startApplyFlow(context, o, onApplied: () => setState(() {})),
                      );
                      return i == items.length - 1 ? row : Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: row);
                    }),
                  ),
          ),
        ],
      )),
    );
  }
}
