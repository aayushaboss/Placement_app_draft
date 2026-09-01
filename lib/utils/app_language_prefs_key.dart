/// SharedPreferences key for the app's own display-language preference —
/// unrelated to LanguageEntry/`_LanguageStep` (which represents languages a
/// *student* knows, for their resume). Read/written directly, same as
/// fomo_prefs_key.dart's flag, since it must be chosen before any signed-in
/// User exists (the picker is shown pre-onboarding). Unlike that flag,
/// AppState.logout() deliberately does NOT clear this one — a chosen
/// display language is a durable device preference, not a per-account
/// "have they seen this" flag.
const appLanguagePrefsKey = 'app_display_language';
