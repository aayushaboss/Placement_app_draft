import 'dart:convert';
import 'dart:html' as html show window;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mockData/mock_applications.dart' show demoShowcaseUserId, setApplicationsUser;
import '../models/user.dart';
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
  static const _readNotificationsKey = 'read_notifications';

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
  List<String> _readNotificationIds = [];

  User? get user => _user;
  bool get loading => _loading;
  List<String> get savedOpportunityIds => List.unmodifiable(_savedOpportunityIds);

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _savedOpportunityIds = prefs.getStringList(_savedOpportunitiesKey) ?? [];
    _viewedStoryIds = prefs.getStringList(_viewedStoriesKey) ?? [];
    _readNotificationIds = prefs.getStringList(_readNotificationsKey) ?? [];

    if (_devAlwaysStartSignedOut) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_demoUserKey);
      _setUser(null);
      _loading = false;
      notifyListeners();
      return;
    }

    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      _setUser(null);
      _loading = false;
      notifyListeners();
      _listenForCrossTabChanges();
      return;
    }
    // TODO: replace with real API call
    final identifier = token.startsWith('demo:') ? token.substring(5) : 'guest';
    // Unlike verifyOtp's own _getSavedUser lookup (which must stay
    // strictly plain-keyed — see _accountMapKey), this recovery fallback
    // only runs when the primary session cache (_demoUserKey) is already
    // gone, and at that point there's no way to know which sign-in method
    // originally created the account for this token — checking the
    // Google-namespaced key too here is what keeps a lost Google session
    // recoverable, without reopening the OTP-side collision.
    final saved = await _loadSessionUser(prefs) ?? await _getSavedUser(prefs, identifier) ?? await _getSavedUser(prefs, 'google:$identifier');
    if (saved == null) {
      // A token with no recoverable profile anywhere = a stale/tampered
      // token. Clear it and start signed out rather than fabricating a
      // blank user (which used to drop straight into onboarding with a
      // half-real identity).
      await prefs.remove(_tokenKey);
      _setUser(null);
    } else {
      _setUser(saved);
    }
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

  /// Bumped whenever mock data mutates outside of AppState's own fields
  /// (an application deleted/restored, a booking created/cancelled/
  /// rescheduled) — a generic "something a kept-alive tab's cached state
  /// depends on just changed elsewhere" signal, distinct from [refresh]
  /// (which re-reads session/user state specifically). Screens that derive
  /// their view from listApplications()/listBookings() etc. should
  /// `context.watch<AppState>()` and re-run their own load on change,
  /// since StatefulShellRoute.indexedStack keeps every tab's State alive
  /// and nothing else tells a backgrounded tab its data is stale.
  int _dataVersion = 0;
  int get dataVersion => _dataVersion;
  void bumpDataVersion() {
    _dataVersion++;
    notifyListeners();
  }

  // In-memory only, not persisted — a lightweight "you were applying to
  // X" reminder for the resume gate's "Not now" dismiss, not a durable
  // cross-session record. Set when the user backs out of the gate sheet
  // without finishing their resume; cleared once they act on the
  // reminder or start a genuinely different apply flow.
  String? _pendingApplyOpportunityId;
  String? get pendingApplyOpportunityId => _pendingApplyOpportunityId;
  void setPendingApplyOpportunity(String? id) {
    if (_pendingApplyOpportunityId == id) return;
    _pendingApplyOpportunityId = id;
    notifyListeners();
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

  bool isNotificationRead(String id) => _readNotificationIds.contains(id);

  /// True once every notification in [ids] has been marked read — used to
  /// drive the Home bell's unread dot from real state instead of a
  /// hardcoded `unread: true`.
  bool hasUnreadNotifications(List<String> ids) =>
      ids.any((id) => !_readNotificationIds.contains(id));

  /// Marks every id in [ids] read in one batch — called when the
  /// Notifications screen opens, mirroring how markStoryViewed marks a
  /// single story read on open, just bulked since a whole list is shown
  /// at once here rather than one story at a time.
  Future<void> markNotificationsRead(List<String> ids) async {
    final newlyRead = ids.where((id) => !_readNotificationIds.contains(id));
    if (newlyRead.isEmpty) return;
    _readNotificationIds = [..._readNotificationIds, ...newlyRead];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readNotificationsKey, _readNotificationIds);
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

  /// The one place `_user` is assigned — keeps the applications store
  /// scoped to whoever's signed in (so one account never sees another's
  /// applications, and a fresh signup starts with an empty tab). Callers
  /// still `notifyListeners()` themselves.
  void _setUser(User? u) {
    _user = u;
    setApplicationsUser(u?.id);
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
        // Phone sign-up's identifier already *is* the phone number — auto-
        // filled here so that path is never asked again on the onboarding
        // profile screen (see MicroProfileScreen's `_needsPhone`, which
        // gates the question on this same `identifier.contains('@')`
        // check). Null for email/Google sign-ups, which have no phone to
        // auto-fill — that's exactly what the onboarding question is for.
        phone: identifier.contains('@') ? null : identifier,
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

  // Strictly a single, exact key — no namespace-crossing here, so that a
  // *new*-signup lookup (see verifyOtp's non-returning branch, which never
  // calls this at all) can never accidentally "become" the fixed Google
  // demo account. verifyOtp's "returning" login path and bootstrap()'s own
  // recovery fallback both call this twice, once per namespace, since both
  // of those are cases where the caller already knows the user is
  // asserting ownership of a specific identifier, not signing up fresh.
  Future<User?> _getSavedUser(SharedPreferences prefs, String identifier) async {
    final map = await _loadUsersMap(prefs);
    final raw = map[identifier];
    if (raw == null) return null;
    return User.fromJson(raw as Map<String, dynamic>);
  }

  // Google-created accounts are namespaced in the shared demo-users map so
  // typing that exact fixed demo email into the OTP phone/email flow can
  // never coincidentally load the Google-created record — the two sign-in
  // methods share no real verification in this prototype, so without this
  // the identifier alone would be enough to "become" that other account.
  // OTP-created accounts keep their plain identifier as the key, matching
  // what _getSavedUser (called only from the OTP flow) already looks up.
  String _accountMapKey(User user) => user.signInMethod == 'google' ? 'google:${user.identifier}' : user.identifier;

  Future<void> _persistUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_demoUserKey, jsonEncode(user.toJson()));
    final map = await _loadUsersMap(prefs);
    map[_accountMapKey(user)] = user.toJson();
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
      // Checks both the plain identifier key and the Google-namespaced one
      // (mirroring bootstrap()'s own recovery fallback) — unlike
      // _getSavedUser's own doc comment, which warns against this for a
      // *new*-signup lookup, "I already have an account" is the one place
      // it's actually correct: the user is explicitly asserting ownership
      // of this identifier, so an account they created via Google using
      // this same email should be found when they log back in with it
      // through the phone/email OTP path instead — not silently treated as
      // a brand-new signup and sent through onboarding again.
      final saved = await _getSavedUser(prefs, identifier) ?? await _getSavedUser(prefs, 'google:$identifier');
      // Whether complete or still mid-onboarding, a genuinely saved
      // profile for this identifier is resumed as-is. Only when nothing
      // is saved at all do we fall through to a new signup — this used to
      // silently substitute a hardcoded fixture profile instead (a
      // different name/city/college, already marked onboarded), dropping
      // anyone here — a genuinely new user who mis-tapped "I already have
      // an account," or anyone testing this path — straight into someone
      // else's fake completed profile with onboarding skipped entirely.
      next = saved ?? _makeNewUser(identifier);
    } else {
      // New signup: always start fresh onboarding — do not reuse a previous completed profile.
      next = _makeNewUser(identifier);
    }

    await prefs.setString(_tokenKey, 'demo:$identifier');
    await _persistUser(next);
    _setUser(next);
    notifyListeners();
    return next;
  }

  /// Prototype stand-in for "Continue with Google" — a real integration
  /// would hand back a verified name/email instantly, no OTP step.
  /// Segment, college/class, and everything else Google wouldn't actually
  /// know still gets asked on the profile screen right after.
  ///
  /// Deliberately always starts a fresh, blank onboarding — never resumes
  /// a previously-saved profile for this identity, even if one exists.
  /// An earlier version of this method resumed an already-onboarded
  /// account instead, but per direct, explicit instruction every tap of
  /// "Continue with Google" must go through the full onboarding flow.
  Future<User> mockGoogleSignIn() async {
    // TODO: replace with real Google OAuth
    await Future.delayed(const Duration(milliseconds: 500));
    const identifier = 'aayusha.pagare@gmail.com';
    final prefs = await SharedPreferences.getInstance();
    final next = User(
      // Stable id (not a per-login timestamp) so this account's
      // applications survive a re-login, and so it can own the seed
      // "showcase" applications — see demoShowcaseUserId.
      id: demoShowcaseUserId,
      identifier: identifier,
      signInMethod: 'google',
      name: 'Aayusha Pagare',
      onboardingComplete: false,
    );
    await prefs.setString(_tokenKey, 'demo:$identifier');
    await _persistUser(next);
    _setUser(next);
    notifyListeners();
    return next;
  }

  Future<User> updateProfile(User Function(User current) patch) async {
    // TODO: replace with real API call
    final current = _user;
    if (current == null) {
      // Every real caller runs with a signed-in user (onboarding, profile
      // edit, resume build, career-quiz submit/unlock — all router-gated).
      // Fabricating a tokenless "demo-guest" here just silently corrupts
      // state; fail loudly instead.
      throw StateError('updateProfile called with no signed-in user');
    }
    final updated = patch(current);
    _setUser(updated);
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
        _setUser(null);
        notifyListeners();
      }
      return;
    }
    final saved = await _loadSessionUser(prefs);
    if (saved != null) {
      _setUser(saved);
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
    // Per-account state that would otherwise leak into whoever signs in
    // next on this browser: saved jobs, read-notification state, viewed
    // stories, and the in-memory "you were applying to X" reminder.
    _savedOpportunityIds = [];
    _viewedStoryIds = [];
    _readNotificationIds = [];
    _pendingApplyOpportunityId = null;
    await prefs.remove(_savedOpportunitiesKey);
    await prefs.remove(_viewedStoriesKey);
    await prefs.remove(_readNotificationsKey);
    _setUser(null);
    notifyListeners();
  }
}
