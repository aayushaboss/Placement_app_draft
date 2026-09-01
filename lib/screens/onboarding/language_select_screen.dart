import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/responsive_body.dart';

const _quickPicks = ['English', 'Hindi', 'Gujarati'];

/// App display-language picker. Shown once, before onboarding even starts,
/// for a signed-out visitor (see router.dart's redirect — this is a stored
/// preference only, this app has no real UI-translation infrastructure).
/// Also reachable any time from Profile ("App language" row) with
/// [isEditMode] true, which swaps the header for a back chevron and the
/// destination-on-select from continuing onboarding to returning to Profile.
class LanguageSelectScreen extends StatelessWidget {
  final bool isEditMode;
  const LanguageSelectScreen({super.key, this.isEditMode = false});

  Future<void> _select(BuildContext context, String language) async {
    HapticFeedback.selectionClick();
    await context.read<AppState>().setAppLanguage(language);
    if (!context.mounted) return;
    if (isEditMode) {
      // go(), not pop() — pop() is a documented standing issue on some
      // routes in this app (see profile_edit_screen.dart's own save flow,
      // which works around it the same way).
      context.go('/tabs/profile');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Language updated to $language.')));
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _openFullList(BuildContext context) async {
    final result = await context.push<String>('/language-select/other');
    if (result != null && context.mounted) await _select(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEditMode) BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/profile'),
            Padding(
              padding: EdgeInsets.only(top: isEditMode ? AppSpacing.lg : 0),
              child: Text('Choose your language', style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                noOrphan('You can change this later in Settings.'),
                style: AppTextStyles.bodyLg.copyWith(color: AppColors.gray500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: Column(
                children: [
                  for (final language in _quickPicks)
                    _LanguageRow(icon: Ionicons.language_outline, label: language, onTap: () => _select(context, language)),
                  _LanguageRow(icon: Ionicons.globe_outline, label: 'Other', onTap: () => _openFullList(context)),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LanguageRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: AppColors.blue),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
              ),
              const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}
