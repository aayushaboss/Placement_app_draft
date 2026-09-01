import 'dart:convert';
import 'dart:html' as html show window;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../utils/app_language_prefs_key.dart';
import '../utils/fomo_prefs_key.dart';

/// Mirrors frontend/src/context/AuthContext.tsx.
/// Provider + shared_preferences so segment/user/onboarding progress
/// survive an app restart, not just in-app navigation.
class AppState extends ChangeNotifier {
  static const _tokenKey = 'aerostar_access_token';
  static const _demoUserKey = 'aerostar_demo_user';
  static const _demoUsersKey = 'aerostar_demo_users';
  static const _savedOpportunitiesKey = 'saved_opportunities';
  static const _viewedStoriesKey = 'viewed_skill_stories';

  /// DEV-ONLY toggle: while true, every fresh app load starts signed out so
  /// onboarding can be retested end-to-end on every refresh. The
  /// `_demoUsersKey` map (used by the "I already have an account"
  /// returning-user path) is left intact either way, so that path still
  /// works when explicitly testing it via login. Flip to false to restore
  /// normal session persistence across app restarts.
  static const _devAlwaysStartSignedOut = false;

  /// Prototype stand-in for a real SMS/email-delivered code — fixed so
  /// testers have something predictable to type, rather than every code
  /// silently succeeding regardless of what's entered.
  static const demoOtpCode = '123456';
  static const _otpValidity = Duration(minutes: 5);

  String? _pendingOtpCode;
  DateTime? _otpSentAt;

  User? _user;
  bool _loading = true;
  List<String> _savedOpportunityIds = [];
  List<String> _viewedStoryIds = [];
  String? _appLanguage;

  User? get user => _user;
  bool get loading => _loading;
  List<String> get savedOpportunityIds => List.unmodifiable(_savedOpportunityIds);

  /// App display-language preference — see app_language_prefs_key.dart.
  /// Loaded synchronously inside bootstrap(), before _loading flips false,
  /// so it's already available the first time router.dart's redirect
  /// callback runs (that callback is synchronous and gated on
  /// `!appState.loading`, so there's no race).
  String? get appLanguage => _appLanguage;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _savedOpportunityIds = prefs.getStringList(_savedOpportunitiesKey) ?? [];
    _viewedStoryIds = prefs.getStringList(_viewedStoriesKey) ?? [];
    _appLanguage = prefs.getString(appLanguagePrefsKey);

    if (_devAlwaysStartSignedOut) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_demoUserKey);
      _user = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      _user = null;
      _loading = false;
      notifyListeners();
      _listenForCrossTabChanges();
      return;
    }
    // TODO: replace with real API call
    final identifier = token.startsWith('demo:') ? token.substring(5) : 'guest';
    final saved = await _loadSessionUser(prefs) ?? await _getSavedUser(prefs, identifier);
    _user = saved ?? _makeNewUser(identifier);
    _loading = false;
    notifyListeners();
    _listenForCrossTabChanges();
  }

  /// Two tabs on the same account both writing to shared_preferences (which
  /// is just localStorage on web) would otherwise race silently — the
  /// second tab's save clobbers the first's with neither tab's in-memory
  /// state aware anything changed. The browser's `storage` event only
  /// fires in *other* tabs than the one that made the write, so this is
  /// exactly the signal needed to pick up a change made elsewhere.
  void _listenForCrossTabChanges() {
    html.window.onStorage.listen((event) {
      if (event.key == _demoUserKey || event.key == _tokenKey) {
        refresh();
      }
    });
  }

  bool isOpportunitySaved(String id) => _savedOpportunityIds.contains(id);

  Future<void> toggleSavedOpportunity(String id) async {
    _savedOpportunityIds = _savedOpportunityIds.contains(id)
        ? _savedOpportunityIds.where((x) => x != id).toList()
        : [..._savedOpportunityIds, id];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedOpportunitiesKey, _savedOpportunityIds);
  }

  bool isStoryViewed(String id) => _viewedStoryIds.contains(id);

  /// Instagram-style: opening a story is enough to mark it viewed, whether
  /// or not the user answers every question.
  Future<void> markStoryViewed(String id) async {
    if (_viewedStoryIds.contains(id)) return;
    _viewedStoryIds = [..._viewedStoryIds, id];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_viewedStoriesKey, _viewedStoryIds);
  }

  User _makeNewUser(String identifier) => User(
        id: 'demo-$identifier',
        identifier: identifier,
        signInMethod: 'otp',
        // A real email sign-in still hands back nothing but the address
        // itself — no verified name the way Google's OAuth would — but the
        // local-part is a reasonable, genuinely-real guess worth prefilling
        // (still fully editable) rather than leaving the field blank for
        // no reason. Null for a bare phone number: there's nothing in a
        // phone number to guess a name from.
        name: _deriveNameFromEmail(identifier),
        city: null,
        appLanguage: _appLanguage,
        segment: null,
        onboardingComplete: false,
      );

  /// `aayusha.pagare@gmail.com` → `'Aayusha Pagare'`. Returns null for a
  /// non-email identifier (bare phone number) or an email with nothing
  /// usable before the @.
  String? _deriveNameFromEmail(String identifier) {
    final at = identifier.indexOf('@');
    if (at <= 0) return null;
    final localPart = identifier.substring(0, at);
    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
    final name = words.join(' ');
    return name.isEmpty ? null : name;
  }

  /// Prototype stand-in for an account that already finished onboarding.
  User _makeReturningUser(String identifier) => User(
        id: 'demo-$identifier',
        identifier: identifier,
        name: 'Aayusha',
        city: 'Bengaluru',
        appLanguage: _appLanguage,
        segment: Segment.ug,
        college: 'VIT Vellore',
        course: 'B.Tech',
        year: '3rd Year',
        fieldOfStudy: 'Computer Science',
        goal: 'internship',
        roles: const ['Software', 'Product'],
        onboardingComplete: true,
      );

  Future<Map<String, dynamic>> _loadUsersMap(SharedPreferences prefs) async {
    final raw = prefs.getString(_demoUsersKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AppState: corrupted $_demoUsersKey, starting from an empty map — $e');
      return {};
    }
  }

  Future<void> _saveUsersMap(SharedPreferences prefs, Map<String, dynamic> map) async {
    await prefs.setString(_demoUsersKey, jsonEncode(map));
  }

  Future<User?> _getSavedUser(SharedPreferences prefs, String identifier) async {
    final map = await _loadUsersMap(prefs);
    final raw = map[identifier];
    if (raw == null) return null;
    return User.fromJson(raw as Map<String, dynamic>);
  }

  Future<void> _persistUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_demoUserKey, jsonEncode(user.toJson()));
    final map = await _loadUsersMap(prefs);
    map[user.identifier] = user.toJson();
    await _saveUsersMap(prefs, map);
  }

  Future<User?> _loadSessionUser(SharedPreferences prefs) async {
    final raw = prefs.getString(_demoUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AppState: corrupted $_demoUserKey, treating as signed out — $e');
      return null;
    }
  }

  Future<void> requestOtp(String identifier) async {
    // TODO: replace with real API call — the code would be generated
    // server-side and delivered by SMS/email instead of fixed here.
    await Future.delayed(const Duration(milliseconds: 400));
    _pendingOtpCode = demoOtpCode;
    _otpSentAt = DateTime.now();
  }

  /// returning=true → existing-account login; skip onboarding if no saved profile yet (prototype).
  Future<User> verifyOtp(String identifier, String code, {bool returning = false}) async {
    // TODO: replace with real API call
    await Future.delayed(const Duration(milliseconds: 400));

    final sentAt = _otpSentAt;
    if (sentAt == null || DateTime.now().difference(sentAt) > _otpValidity) {
      throw Exception('otp_expired');
    }
    if (code != _pendingOtpCode) {
      throw Exception('otp_invalid');
    }
    _pendingOtpCode = null;
    _otpSentAt = null;

    final prefs = await SharedPreferences.getInstance();
    User next;
    if (returning) {
      final saved = await _getSavedUser(prefs, identifier);
      next = (saved != null && saved.onboardingComplete) ? saved : _makeReturningUser(identifier);
    } else {
      // New signup: always start fresh onboarding — do not reuse a previous completed profile.
      next = _makeNewUser(identifier);
    }

    await prefs.setString(_tokenKey, 'demo:$identifier');
    await _persistUser(next);
    _user = next;
    notifyListeners();
    return next;
  }

  /// Prototype stand-in for "Continue with Google" — a real integration
  /// would hand back a verified name/email/(sometimes) city instantly, no
  /// OTP step. Segment, college/class, and everything else Google wouldn't
  /// actually know still gets asked on the profile screen right after.
  Future<User> mockGoogleSignIn() async {
    // TODO: replace with real Google OAuth
    await Future.delayed(const Duration(milliseconds: 500));
    final identifier = 'aayusha.pagare@gmail.com';
    final next = User(
      id: 'demo-google-${DateTime.now().millisecondsSinceEpoch}',
      identifier: identifier,
      signInMethod: 'google',
      name: 'Aayusha Pagare',
      city: 'Pune',
      appLanguage: _appLanguage,
      onboardingComplete: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, 'demo:$identifier');
    await _persistUser(next);
    _user = next;
    notifyListeners();
    return next;
  }

  /// Single entry point for setting the app display-language — called both
  /// by the pre-onboarding picker (no User yet) and by the Profile-editable
  /// version (User already exists), so the "keep the raw pref and the
  /// User's copy in sync" logic lives in exactly one place.
  Future<void> setAppLanguage(String value) async {
    _appLanguage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appLanguagePrefsKey, value);
    if (_user != null) {
      final updated = _user!.copyWith(appLanguage: value);
      _user = updated;
      await _persistUser(updated);
    }
    notifyListeners();
  }

  Future<User> updateProfile(User Function(User current) patch) async {
    // TODO: replace with real API call
    final updated = patch(_user ?? _makeNewUser('guest'));
    _user = updated;
    await _persistUser(updated);
    notifyListeners();
    return updated;
  }

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      // Signed out — possibly from another tab. Only notify if this tab
      // actually had a user in memory, so a refresh before first sign-in
      // isn't a no-op churn of listeners.
      if (_user != null) {
        _user = null;
        notifyListeners();
      }
      return;
    }
    final saved = await _loadSessionUser(prefs);
    if (saved != null) {
      _user = saved;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Keep profile in _demoUsersKey so the same phone/email can log back in
    // without re-doing onboarding.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_demoUserKey);
    // The FOMO nudge's "already seen" flag is device-global, not per-user —
    // without clearing it here, dismissing it once during an earlier
    // session/account permanently hides it for every subsequent sign-in on
    // this browser, including a fresh account going through onboarding.
    await prefs.remove(fomoDismissedPrefsKey);
    _user = null;
    notifyListeners();
  }
}
