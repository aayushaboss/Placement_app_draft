import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'badges.dart';
import 'company_mark.dart';
import 'pill_button.dart';

/// Fixed-width job card for a horizontal carousel row — the same
/// information as [OpportunityRow] (role, company, location, stipend,
/// urgency), just reflowed for a Naukri-style "scroll sideways within a
/// topic" browse pattern instead of one long vertical feed. Deliberately
/// reuses the same card shell (AppShadows.card) and the same AppTag/
/// PillButton components as the rest of the app, not a bespoke look. The
/// outer corner radius is AppRadius.md + AppSpacing.lg — concentric with
/// CompanyMark's own AppRadius.md corner sitting AppSpacing.lg inside it,
/// not an unrelated token.
class OpportunityCarouselCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String stipend;
  final String? matchLabel;
  final String? deadlineLabel;
  final bool deadlineUrgent;
  final bool applied;
  final VoidCallback? onTap;
  final VoidCallback? onApply;

  const OpportunityCarouselCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.stipend,
    this.matchLabel,
    this.deadlineLabel,
    this.deadlineUrgent = false,
    this.applied = false,
    this.onTap,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineColor = deadlineUrgent ? AppColors.error : AppColors.gray500;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg),
        child: Container(
          width: 250,
          // Fixed, not intrinsic — cards in the same row need to line up
          // (same size, Apply at the same y-position across the row), which
          // intrinsic per-card sizing broke. Went briefly intrinsic to kill
          // the dead space the old 250 left above Apply on shorter cards,
          // but the fix for that is a *shorter* fixed height sized to the
          // realistic content (title+tags case), not dropping the shared
          // height altogether.
          height: 222,
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
                  CompanyMark(company: company, size: 44),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 15, height: 1.2),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _MetaLine(icon: Ionicons.location_outline, label: location),
              const SizedBox(height: AppSpacing.sm),
              _MetaLine(icon: Ionicons.cash_outline, label: stipend),
              if (matchLabel != null || deadlineLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (matchLabel != null) AppTag(label: matchLabel!, color: AppColors.blue, bg: AppColors.blueA10),
                      if (deadlineLabel != null) AppTag(label: deadlineLabel!, color: deadlineColor, bg: deadlineColor.withValues(alpha: 0.1)),
                    ],
                  ),
                ),
              // Pushes Apply to the card's bottom edge regardless of how
              // much the content above it takes up — same fixed baseline
              // across every card in the row, not just the ones with the
              // most content.
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: applied
                    ? const PillButton(label: 'Applied', icon: Ionicons.checkmark_circle, variant: PillVariant.secondary, compact: true, disabled: true, onPressed: null)
                    : PillButton(label: 'Apply', variant: PillVariant.secondary, compact: true, onPressed: onApply),
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
