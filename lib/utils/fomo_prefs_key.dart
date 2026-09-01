/// SharedPreferences key for whether the FOMO notification-permission nudge
/// (widgets/fomo_notification_card.dart) has already been dismissed. Kept
/// here, not inline in that widget file, so state/app_state.dart can clear
/// it on logout without importing a widget file into the state layer.
const fomoDismissedPrefsKey = 'fomo_notification_dismissed';
