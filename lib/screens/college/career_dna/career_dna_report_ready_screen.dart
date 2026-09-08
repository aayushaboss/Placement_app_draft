import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../services/career_dna_report_pdf.dart';
import '../../../state/app_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';

/// Shown right after the mock ₹51 payment succeeds — mirrors
/// resume_ready_view.dart's exact shape (same checkmark/title/file-card/
/// download-button layout) since the user asked for this to look like the
/// resume download screen, reusing that proven pattern rather than
/// inventing a new one.
class CareerDnaReportReadyScreen extends StatefulWidget {
  const CareerDnaReportReadyScreen({super.key});

  @override
  State<CareerDnaReportReadyScreen> createState() => _CareerDnaReportReadyScreenState();
}

class _CareerDnaReportReadyScreenState extends State<CareerDnaReportReadyScreen> {
  bool _downloading = false;

  Future<void> _download(String name) async {
    final user = context.read<AppState>().user;
    if (user == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await buildCareerDnaReportPdf(user);
      final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
      await Printing.sharePdf(bytes: bytes, filename: '${safeName.isEmpty ? 'career_quiz' : safeName}_career_quiz_report.pdf');
    } catch (e) {
      debugPrint('Career Quiz report PDF generation failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text("Couldn't generate the PDF"),
          action: SnackBarAction(label: 'Retry', textColor: AppColors.yellow, onPressed: () => _download(name)),
          duration: const Duration(seconds: 4),
          persist: false,
        ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final name = (user?.name?.trim().isNotEmpty ?? false) ? user!.name! : 'Your';
    final fileName = '$name Career Quiz Report';

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: ResponsiveBody(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                      child: const Icon(Ionicons.checkmark, size: 40, color: AppColors.blue),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Text('Your report is ready!', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 22, fontWeight: AppFontWeight.semibold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Your full Career Quiz report is unlocked and saved to your profile — download it any time.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.xl),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                            child: const Icon(Ionicons.document_text, size: 20, color: AppColors.blue),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('PDF · ready to download', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: PillButton(
                        label: 'Download PDF',
                        variant: PillVariant.secondary,
                        icon: Ionicons.download_outline,
                        loading: _downloading,
                        onPressed: user == null ? null : () => _download(fileName),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: PillButton(label: 'Done', onPressed: () => context.go('/tabs/career-dna')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
