import 'dart:async' show unawaited;
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

/// Naukri's landing-page FOMO nudge ("Turn on notifications so you never
/// miss an opening") — shown once, as a bottom sheet, on the first Home
/// arrival after onboarding. Not on the landing screen itself, since
/// there's no signed-in user to notify yet.
///
/// Call this from Home's first frame; it no-ops silently if the prompt has
/// already been seen. [isSchool] swaps the copy for the school segment,
/// which has no "openings" to miss — the underlying nudge/mechanism (turn on
/// browser notifications) is the same for both segments.
Future<void> maybeShowFomoSheet(BuildContext context, {required bool isSchool}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(fomoDismissedPrefsKey) ?? false) return;
  if (!context.mounted) return;

  // No fabricated "60+ missed" number — this used to be a hardcoded count
  // shown to every user regardless of account age, including one that had
  // literally never opened the feed yet and couldn't have missed anything.
  final title = isSchool ? 'New certificate courses are up' : "Don't miss new openings";
  final body = isSchool ? 'Turn on notifications so you never miss a new one.' : 'Turn on notifications so you never miss one that fits.';

  Future<void> dismiss() async {
    if (context.mounted) Navigator.of(context).pop();
    await prefs.setBool(fomoDismissedPrefsKey, true);
  }

  // Dismissible now (tap the scrim, or drag down) — previously the only
  // way out was one of the two buttons below, with no tap-outside escape
  // like every other bottom sheet in the app allows.
  unawaited(showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
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
  // Marks it seen no matter how the sheet closed — including a scrim tap
  // or drag-down, which dismiss() above never runs for since those don't
  // go through either button's onPressed.
  ).then((_) => prefs.setBool(fomoDismissedPrefsKey, true)));
}
