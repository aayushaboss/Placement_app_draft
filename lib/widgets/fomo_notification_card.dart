import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/fomo_prefs_key.dart';
import '../utils/no_orphan.dart';
import 'pill_button.dart';

const _missedCount = 60;

/// Naukri's landing-page FOMO nudge ("You missed out on 60 jobs last
/// week! Turn on notifications") — shown once, as a bottom sheet, on the
/// first Home arrival after onboarding. Not on the landing screen itself,
/// since there's no signed-in user to notify yet.
///
/// Call this from Home's first frame; it no-ops silently if the prompt has
/// already been seen. [isSchool] swaps the copy for the school segment,
/// which has no "openings" to miss — the underlying nudge/mechanism (turn on
/// browser notifications) is the same for both segments.
Future<void> maybeShowFomoSheet(BuildContext context, {required bool isSchool}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(fomoDismissedPrefsKey) ?? false) return;
  if (!context.mounted) return;

  final title = isSchool ? 'New certificate courses are up' : 'You missed $_missedCount+ new openings this week';
  final body = isSchool ? 'Turn on notifications so you never miss a new one.' : 'Turn on notifications so you never miss one again.';

  Future<void> dismiss() async {
    if (context.mounted) Navigator.of(context).pop();
    await prefs.setBool(fomoDismissedPrefsKey, true);
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xs,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
              child: const Icon(Ionicons.notifications_outline, size: 22, color: AppColors.blue),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(
              noOrphan(title),
              style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 20, fontWeight: AppFontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              noOrphan(body),
              style: AppTextStyles.body.copyWith(color: AppColors.gray500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: PillButton(
              label: 'Turn on',
              onPressed: () async {
                if (kIsWeb) {
                  try {
                    await html.Notification.requestPermission();
                  } catch (_) {
                    // Browser may not support the Notifications API at all —
                    // a denied or unsupported permission is still a
                    // completed FOMO prompt, not an error worth surfacing.
                  }
                }
                await dismiss();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(label: 'Not now', variant: PillVariant.ghost, onPressed: dismiss),
        ],
      ),
    ),
  );
}
