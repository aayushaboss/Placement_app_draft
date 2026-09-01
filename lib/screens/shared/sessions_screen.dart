import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_bookings.dart';
import '../../models/booking.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Mirrors frontend/src/screens/Sessions.tsx (Sessions).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Booking> _bookings = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Branch index 2 (Sessions) — see router.dart's StatefulShellRoute. One
    // shared screen for both segments, so no segment check needed here.
    ScrollToTopRegistry.register(2, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _load();
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(2);
    _scrollController.dispose();
    super.dispose();
  }

  void _load() {
    // TODO: replace with real API call
    setState(() => _bookings = listBookings());
  }

  Future<void> _onRefresh() async => _load();

  void _book(bool isSchool) {
    final route = '/booking?kind=${isSchool ? 'counseling' : 'placement'}';
    context.push(route);
  }

  void _reschedule(Booking b) {
    final route = Uri(path: '/booking', queryParameters: {
      'kind': b.kind,
      'bookingId': b.id,
      'date': b.date,
      'time': b.time,
      'mode': b.mode,
      'sessionType': b.sessionType ?? '',
    }).toString();
    context.push(route);
  }

  void _askCancel(Booking b) {
    bool canceling = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isDismissible: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.errorA10, shape: BoxShape.circle),
                child: const Icon(Ionicons.alert, size: 28, color: AppColors.error),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text('Cancel this session?', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 20, fontWeight: AppFontWeight.semibold)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'You can always book a new session later.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: 'Yes, cancel session',
                    loading: canceling,
                    onPressed: () async {
                      setSheetState(() => canceling = true);
                      // TODO: replace with real API call
                      deleteBooking(b.id);
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      _load();
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(sheetContext).pop(),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text('Keep session', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, fontWeight: AppFontWeight.medium)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prettyDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${_weekdayShort[d.weekday - 1]}, ${_monthShort[d.month - 1]} ${d.day}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSchool = context.watch<AppState>().user?.segment == Segment.school;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // For college, still Profile-row-only (no bottom tab), so
                // this needs an explicit way back instead of relying on
                // tab-bar navigation. School gets this screen as its own
                // "Sessions" tab, where this chevron is just a harmless
                // extra shortcut to Profile.
                GestureDetector(
                  onTap: () => context.go('/tabs/profile'),
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Icon(Ionicons.chevron_back, size: 26, color: AppColors.ink),
                  ),
                ),
                Text('Bookings', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                  child: Text(
                    noOrphan('Counseling & placement support'),
                    textAlign: TextAlign.left,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.blue,
              onRefresh: _onRefresh,
              child: _bookings.isEmpty
                  ? ListView(
                      controller: _scrollController,
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
                                child: const Icon(Ionicons.calendar_outline, size: 34, color: AppColors.blue),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.md),
                                child: Text('No sessions yet', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: AppFontWeight.medium)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(top: AppSpacing.sm),
                                child: Text(
                                  'Book a ${isSchool ? 'counseling' : 'placement'} session to get expert 1:1 guidance.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 100),
                      children: _bookings.map((b) {
                        DateTime? d;
                        try {
                          d = DateTime.parse(b.date);
                        } catch (_) {}
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.md)),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(d != null ? '${d.day}' : '-', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 20, fontWeight: AppFontWeight.medium)),
                                        Text(d != null ? _monthShort[d.month - 1] : '', style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 11, fontWeight: AppFontWeight.medium)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          b.kind == 'placement' ? (b.sessionType ?? 'Placement session') : 'Counseling session',
                                          style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.bold),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text('${_prettyDate(b.date)} • ${b.time}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 13)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(b.mode == 'online' ? Ionicons.videocam_outline : Ionicons.location_outline, size: 12, color: AppColors.blue),
                                              const SizedBox(width: 4),
                                              Text('${b.mode == 'online' ? 'Online' : 'Offline'} • ${b.counselor}', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                                            ],
                                          ),
                                        ),
                                        if (b.mode == 'offline' && (b.venueAddress?.trim().isNotEmpty ?? false))
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              b.venueAddress!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Ionicons.checkmark_circle, size: 18, color: AppColors.success),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: AppSpacing.md),
                                padding: const EdgeInsets.only(top: AppSpacing.md),
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 1))),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _reschedule(b),
                                        child: Container(
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Ionicons.calendar_outline, size: 15, color: AppColors.blue),
                                              const SizedBox(width: AppSpacing.sm),
                                              Text('Reschedule', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _askCancel(b),
                                        child: Container(
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.error, width: 1.5)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Ionicons.close_circle_outline, size: 15, color: AppColors.error),
                                              const SizedBox(width: AppSpacing.sm),
                                              Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.error, fontSize: 13, fontWeight: AppFontWeight.medium)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: PillButton(
              label: isSchool ? '+ Book Counseling' : '+ Book Placement Session',
              onPressed: () => _book(isSchool),
            ),
          ),
        ],
      )),
    );
  }
}
