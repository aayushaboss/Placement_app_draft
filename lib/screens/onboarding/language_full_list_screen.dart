import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../mockData/mock_profile_options.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/responsive_body.dart';

/// Full, searchable app-language list — pushed from LanguageSelectScreen's
/// "Other" row. Mirrors CourseCategoryPickerScreen's chrome (blue header +
/// back chevron), but single-select-and-pop rather than multi-select +
/// Done: tapping a row immediately returns it, since there's exactly one
/// app language active at a time (unlike course categories).
class LanguageFullListScreen extends StatefulWidget {
  const LanguageFullListScreen({super.key});

  @override
  State<LanguageFullListScreen> createState() => _LanguageFullListScreenState();
}

class _LanguageFullListScreenState extends State<LanguageFullListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(String language) {
    HapticFeedback.selectionClick();
    context.pop(language);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final query = _searchController.text.trim().toLowerCase();
    final results = query.isEmpty
        ? mockAppDisplayLanguages
        : mockAppDisplayLanguages.where((l) => l.toLowerCase().contains(query)).toList();

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
                Text('All languages', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 18, fontWeight: AppFontWeight.semibold)),
                const SizedBox(width: AppSpacing.xxl),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
            child: PillInput(
              controller: _searchController,
              placeholder: 'Search languages',
              icon: Ionicons.search_outline,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text('No languages match "$query".', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) {
                      final language = results[i];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _select(language),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(Ionicons.language_outline, size: 20, color: AppColors.blue),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(language, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      )),
    );
  }
}
