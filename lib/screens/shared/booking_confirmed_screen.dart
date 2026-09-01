import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

const _weekdayFullNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthFullNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// Mirrors frontend/app/booking-confirmed.tsx (BookingConfirmed).
class BookingConfirmedScreen extends StatefulWidget {
  final String kind;
  final String date;
  final String time;
  final String mode;
  final String counselor;
  final String sessionType;
  final String venueName;
  final String venueAddress;

  const BookingConfirmedScreen({
    super.key,
    required this.kind,
    required this.date,
    required this.time,
    required this.mode,
    required this.counselor,
    required this.sessionType,
    this.venueName = '',
    this.venueAddress = '',
  });

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
    _checkController.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final appState = context.read<AppState>();
    // TODO: replace with real API call (local mock)
    await appState.updateProfile((current) => current.copyWith(onboardingComplete: true));
    if (!mounted) return;
    context.go('/tabs');
  }

  /// UI only for now — each option's onTap is a stub pending confirmation
  /// of this sheet before the actual Google/Apple/.ics logic gets wired in
  /// (via a separate CalendarService, not inline here).
  void _showCalendarSheet() {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.xxl,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
                child: Text('Add to Calendar', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
              ),
              _CalendarOptionTile(
                iconWidget: SvgPicture.asset('assets/icons/google.svg', width: 19, height: 19),
                // Google's own brand blue, not an app design-system color —
                // deliberately not an AppColors token since it has to match
                // Google's mark, not our palette.
                iconColor: const Color(0xFF4285F4),
                label: 'Google Calendar',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              if (isIOS)
                _CalendarOptionTile(
                  icon: Ionicons.logo_apple,
                  iconColor: AppColors.ink,
                  label: 'Apple Calendar',
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              _CalendarOptionTile(
                icon: Ionicons.download_outline,
                iconColor: AppColors.blue,
                label: 'Download .ics file',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _prettyDate {
    try {
      final d = DateTime.parse(widget.date);
      return '${_weekdayFullNames[d.weekday - 1]}, ${_monthFullNames[d.month - 1]} ${d.day}';
    } catch (_) {
      return widget.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isPlacement = widget.kind == 'placement';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: ResponsiveBody(child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _checkScale,
                          child: Container(
                            width: 110,
                            height: 110,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle, boxShadow: AppShadows.yellow),
                            child: const Icon(Ionicons.checkmark, size: 56, color: AppColors.blue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xl),
                          child: Text(
                            "You're all set!",
                            style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 30, fontWeight: AppFontWeight.semibold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            noOrphan('Your ${isPlacement ? 'placement session' : 'counseling session'} is confirmed.'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, fontSize: 15),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: AppSpacing.xxl),
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                          child: Column(
                            children: [
                              if (widget.counselor.isNotEmpty)
                                _Row(icon: Ionicons.person_circle_outline, label: 'With', value: widget.counselor),
                              if (widget.sessionType.isNotEmpty)
                                _Row(icon: Ionicons.list_outline, label: 'Session', value: widget.sessionType),
                              _Row(icon: Ionicons.calendar_outline, label: 'Date', value: _prettyDate),
                              _Row(icon: Ionicons.time_outline, label: 'Time', value: widget.time),
                              _Row(
                                icon: widget.mode == 'online' ? Ionicons.videocam_outline : Ionicons.location_outline,
                                label: 'Mode',
                                value: widget.mode == 'online' ? 'Online' : 'Offline',
                              ),
                            ],
                          ),
                        ),
                        if (widget.mode == 'offline' && widget.venueAddress.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: AppSpacing.md),
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: AppShadows.card,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                  child: const Icon(Ionicons.location, size: 18, color: AppColors.blue),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (widget.venueName.isNotEmpty)
                                        Text(widget.venueName, textAlign: TextAlign.left, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(widget.venueAddress, textAlign: TextAlign.left, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13, height: 1.4)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, bottomInset + AppSpacing.lg),
                child: Column(
                  children: [
                    PillButton(label: 'Add to Calendar', variant: PillVariant.outlineWhite, icon: Ionicons.calendar_outline, onPressed: _showCalendarSheet),
                    const SizedBox(height: AppSpacing.md),
                    PillButton(label: 'Done', onPressed: _done),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.blue),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, fontWeight: AppFontWeight.regular)),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium),
          ),
        ],
      ),
    );
  }
}

class _CalendarOptionTile extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  /// Overrides [icon] — for the Google Calendar row, which needs the real
  /// multi-color "G" logo instead of a single-color IconData glyph.
  final Widget? iconWidget;

  const _CalendarOptionTile({this.icon, required this.iconColor, required this.label, required this.onTap, this.iconWidget});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: iconWidget ?? Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
            ),
            const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
