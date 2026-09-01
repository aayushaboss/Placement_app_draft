import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../mockData/mock_support.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/responsive_body.dart';

/// FAQ + contact screen, reached from Profile → Support & Help. Mirrors the
/// mobile Naukri/Internshala pattern — a category-filtered, expandable FAQ
/// list plus a short contact block below, rather than a full desktop-style
/// help center with a page per question.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _activeCategoryId;
  final Set<String> _expandedQuestions = {};

  void _selectCategory(String? id) {
    HapticFeedback.selectionClick();
    setState(() => _activeCategoryId = id);
  }

  void _toggleExpanded(String question) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedQuestions.contains(question)) {
        _expandedQuestions.remove(question);
      } else {
        _expandedQuestions.add(question);
      }
    });
  }

  void _showStub(String label) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label — coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final faqs = mockFaqs.where((f) => _activeCategoryId == null || f.categoryId == _activeCategoryId).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackChevron(fallbackRoute: '/tabs/profile'),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text('Support & Help', style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 28, fontWeight: AppFontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      "We're here to help with anything on Aerostar Edge.",
                      style: AppTextStyles.body.copyWith(color: AppColors.whiteA70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppChip(label: 'All', selected: _activeCategoryId == null, onPressed: () => _selectCategory(null)),
                      ...mockFaqCategories.map(
                        (c) => AppChip(label: c.label, selected: _activeCategoryId == c.id, onPressed: () => _selectCategory(c.id)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ...faqs.map((f) => _FaqTile(
                        item: f,
                        expanded: _expandedQuestions.contains(f.question),
                        onTap: () => _toggleExpanded(f.question),
                      )),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                    child: Text('Still need help?', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
                  ),
                  Container(
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _ContactRow(
                          icon: Ionicons.mail_outline,
                          label: 'Email us',
                          subtitle: 'support@aerostaredge.com',
                          isLast: false,
                          // UI only for now — stub pending a real mailto:/
                          // support-ticket integration (same pattern as
                          // booking_confirmed_screen.dart's
                          // _showCalendarSheet options).
                          onTap: () => _showStub('Email us'),
                        ),
                        _ContactRow(
                          icon: Ionicons.chatbubble_ellipses_outline,
                          label: 'Chat with us',
                          subtitle: 'Typically replies in a few minutes',
                          isLast: false,
                          onTap: () => _showStub('Chat with us'),
                        ),
                        _ContactRow(
                          icon: Ionicons.document_text_outline,
                          label: 'Raise a ticket',
                          subtitle: 'Track a support request',
                          isLast: true,
                          onTap: () => _showStub('Raise a ticket'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Center(
                      child: Text('Aerostar Edge • v1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final FaqItem item;
  final bool expanded;
  final VoidCallback onTap;
  const _FaqTile({required this.item, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      noOrphan(item.question),
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 14.5, fontWeight: AppFontWeight.medium, height: 1.35),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Ionicons.chevron_down, size: 18, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Text(
                      item.answer,
                      style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13.5, height: 1.45),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isLast;
  final VoidCallback onTap;
  const _ContactRow({required this.icon, required this.label, required this.subtitle, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: AppColors.blue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 15, fontWeight: AppFontWeight.medium)),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
            const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
