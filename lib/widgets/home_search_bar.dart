import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mockData/mock_opportunities.dart';
import '../mockData/mock_profile_options.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'pill_input.dart';

const _recentSearchesKey = 'recent_opportunity_searches';
const _maxRecentSearches = 5;

/// Single pinned search bar for the college Home feed — replaces the old
/// dedicated `/search` screen. Tapping it opens a dropdown: recent searches
/// (or, first time, a few starter suggestions), and typed-match suggestions
/// while typing. Picking one (or pressing enter) opens `/opportunities`
/// filtered to that query.
class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  List<String> _recent = [];
  late final List<String> _suggestionTerms = searchSuggestionTerms();
  static final List<String> _starterSuggestions = mockAllRoles.take(6).toList();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_refreshOverlay);
    _loadRecent();
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recent = prefs.getStringList(_recentSearchesKey) ?? []);
    _refreshOverlay();
  }

  Future<void> _saveRecent(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [trimmed, ..._recent.where((s) => s.toLowerCase() != trimmed.toLowerCase())].take(_maxRecentSearches).toList();
    await prefs.setStringList(_recentSearchesKey, updated);
    if (!mounted) return;
    setState(() => _recent = updated);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (!mounted) return;
    setState(() => _recent = []);
    _refreshOverlay();
  }

  void _onFocusChange() => _refreshOverlay();

  void _submit(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    HapticFeedback.selectionClick();
    _saveRecent(q);
    _controller.clear();
    _focusNode.unfocus();
    _removeOverlay();
    context.push('/opportunities?q=${Uri.encodeQueryComponent(q)}');
  }

  // --- Dropdown ---

  List<_DropRow> _rows() {
    final typed = _controller.text.trim();
    if (typed.isNotEmpty) {
      final q = typed.toLowerCase();
      return _suggestionTerms
          .where((t) => t.toLowerCase().contains(q))
          .take(6)
          .map((t) => _DropRow(label: t, icon: Ionicons.search_outline, onTap: () => _submit(t)))
          .toList();
    }
    if (_recent.isNotEmpty) {
      return _recent
          .map((s) => _DropRow(label: s, icon: Ionicons.time_outline, onTap: () => _submit(s)))
          .toList();
    }
    return _starterSuggestions
        .map((s) => _DropRow(label: s, icon: Ionicons.trending_up_outline, onTap: () => _submit(s)))
        .toList();
  }

  bool get _showRecentHeader => _controller.text.trim().isEmpty && _recent.isNotEmpty;
  bool get _showStarterHeader => _controller.text.trim().isEmpty && _recent.isEmpty;

  void _refreshOverlay() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
      return;
    }
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlay);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  Widget _buildOverlay(BuildContext context) {
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 0;
    final rows = _rows();

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, AppSpacing.xs),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppShadows.dropdown,
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                if (_showRecentHeader)
                  _DropHeader(label: 'Recent searches', trailingLabel: 'Clear', onTrailingTap: _clearRecent),
                if (_showStarterHeader) const _DropHeader(label: 'Popular searches'),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyedSubtree(
        key: _fieldKey,
        child: PillInput(
          controller: _controller,
          focusNode: _focusNode,
          icon: Ionicons.search_outline,
          placeholder: 'Search jobs, companies, roles',
          textInputAction: TextInputAction.search,
          onChanged: (_) => _refreshOverlay(),
          onSubmitted: _submit,
        ),
      ),
    );
  }
}

class _DropHeader extends StatelessWidget {
  final String label;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  const _DropHeader({required this.label, this.trailingLabel, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 11, fontWeight: AppFontWeight.medium, letterSpacing: 0.4),
            ),
          ),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailingLabel!,
                style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DropRow({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.gray500),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
