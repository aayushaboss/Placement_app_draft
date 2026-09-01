import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mockData/mock_applications.dart';
import '../../mockData/mock_companies.dart';
import '../../mockData/mock_opportunities.dart';
import '../../mockData/mock_profile_options.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/autocomplete_field.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/badges.dart';
import '../../widgets/company_mark.dart';
import '../../widgets/opportunity_row.dart';
import '../../widgets/responsive_body.dart';

const _recentSearchesKey = 'recent_opportunity_searches';
const _maxRecentSearches = 5;
const _popularSearches = ['Software', 'Marketing', 'Data', 'Design', 'Finance', 'Content'];

/// Naukri-style dedicated search — its own full-screen destination with
/// recent/popular searches to start from, not an inline box that scrolls
/// away with the rest of the Home feed. The feed's search bar now just
/// opens this instead of filtering itself in place.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _locationController = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _recentSearches = [];
  List<Opportunity> _results = [];
  bool _hasSearched = false;
  late final List<String> _suggestionTerms = searchSuggestionTerms();
  late final List<CompanyProfile> _featuredCompanies = featuredCompanies();

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _locationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recentSearches = prefs.getStringList(_recentSearchesKey) ?? []);
  }

  Future<void> _saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [trimmed, ..._recentSearches.where((s) => s.toLowerCase() != trimmed.toLowerCase())].take(_maxRecentSearches).toList();
    await prefs.setStringList(_recentSearchesKey, updated);
    if (!mounted) return;
    setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (!mounted) return;
    setState(() => _recentSearches = []);
  }

  // Reads both fields directly rather than taking a param — Location is a
  // separate, independent filter from the main query now (AND, not OR), so
  // every search needs both values regardless of which field just changed.
  void _runSearch() {
    final appliedIds = listApplications().map((a) => a.opportunityId).toSet();
    final results = filterOpportunities(query: _controller.text, location: _locationController.text)
        .where((o) => !appliedIds.contains(o.id))
        .toList();
    final user = context.read<AppState>().user;
    results.sort((a, b) => b.matchScoreFor(user).compareTo(a.matchScoreFor(user)));
    setState(() {
      _results = results;
      _hasSearched = _controller.text.trim().isNotEmpty || _locationController.text.trim().isNotEmpty;
    });
  }

  void _selectSearch(String query) {
    HapticFeedback.selectionClick();
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _runSearch();
    _saveRecentSearch(query);
  }


  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(child: SafeArea(
        bottom: false,
        // start, not the Column default of center — the chevron is the
        // only child here that doesn't already stretch to the full width
        // (both search fields fill it via their own internal Row), so a
        // centered cross-axis alignment left it floating in the middle of
        // the screen instead of pinned to the left like every other
        // screen's back button.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, topInset > 0 ? AppSpacing.sm : AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: BackChevron(color: AppColors.ink, fallbackRoute: '/tabs'),
            ),
            // A bare title, no subtitle — this screen has no static fact
            // worth stating under it (unlike Saved's live bookmark count),
            // it just needs to answer "where am I" the way every other
            // titled screen in the app already does.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
              child: Text('Search', style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
            ),
            // Both fields share the exact same horizontal padding so they
            // line up edge-to-edge — the chevron used to sit inline with
            // the query field only, which pushed it in and narrowed it
            // relative to Location below, reading as two mismatched sizes
            // stacked on top of each other instead of one consistent pair.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: AutocompleteField(
                value: '',
                controller: _controller,
                focusNode: _focusNode,
                icon: Ionicons.search_outline,
                placeholder: 'Skill, role, or company…',
                options: _suggestionTerms,
                onChanged: (_) => _runSearch(),
              ),
            ),
            // A separate field, not folded into the query above — "React
            // AND Bengaluru" needs two independent filters, not one box
            // where typing a city name happens to also match location.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: AutocompleteField(
                value: '',
                controller: _locationController,
                icon: Ionicons.location_outline,
                placeholder: 'Location',
                options: mockCities,
                onChanged: (_) => _runSearch(),
              ),
            ),
            Expanded(
              child: !_hasSearched
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
                      children: [
                        if (_recentSearches.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recent searches', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 15)),
                              GestureDetector(
                                onTap: _clearRecentSearches,
                                child: Text('Clear', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 13, fontWeight: AppFontWeight.medium)),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: _recentSearches
                                .map((s) => _SearchChip(label: s, icon: Ionicons.time_outline, onTap: () => _selectSearch(s)))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        Text('Popular searches', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 15)),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _popularSearches
                              .map((s) => _SearchChip(label: s, icon: Ionicons.trending_up_outline, onTap: () => _selectSearch(s)))
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Featured companies', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold, fontSize: 15)),
                        // Card height (136, matching _CompanyTile's fixed
                        // height below) plus AppShadows.cardBuffer on each
                        // side — enough for AppShadows.card's blur to clear
                        // without a hard clip (see home_dashboard_cards.dart
                        // for the same fix, found the hard way there
                        // first). Keep this in sync with _CompanyTile's
                        // height — it's already drifted out of sync once.
                        SizedBox(
                          height: 136 + AppShadows.cardBuffer * 2,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: AppShadows.cardBuffer),
                            scrollDirection: Axis.horizontal,
                            itemCount: _featuredCompanies.length,
                            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, i) {
                              final c = _featuredCompanies[i];
                              return _CompanyTile(company: c, onTap: () => _selectSearch(c.name));
                            },
                          ),
                        ),
                      ],
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Ionicons.search_outline, size: 40, color: AppColors.gray400),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No matches for "${_controller.text.trim()}".',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                          itemBuilder: (context, i) {
                            final o = _results[i];
                            return OpportunityRow(
                              tag: o.type,
                              title: o.title,
                              subtitle: o.company,
                              meta: [o.location, o.stipend, o.duration],
                              matchLabel: o.matchLabelFor(user),
                              deadlineLabel: o.deadlineLabel,
                              deadlineUrgent: o.deadlineIsUrgent,
                              saved: appState.isOpportunitySaved(o.id),
                              onToggleSave: () => appState.toggleSavedOpportunity(o.id),
                              onTap: () {
                                _saveRecentSearch(_controller.text);
                                context.push('/opportunity/${o.id}');
                              },
                              onApply: () => startApplyFlow(context, o, onApplied: _runSearch),
                            );
                          },
                        ),
            ),
          ],
        ),
      )),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  final CompanyProfile company;
  final VoidCallback onTap;
  const _CompanyTile({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.md),
        child: Container(
          width: 180,
          // Was 122, which left only a few px of slack over this content's
          // actual height (name + rating row + tag + roles line, plus
          // AppSpacing.md padding top/bottom) — comfortable in one render
          // but not enough margin for font-metric variance across
          // browsers/devices, which read as the card "overflowing".
          height: 136,
          padding: const EdgeInsets.all(AppSpacing.md),
          // Concentric with CompanyMark's own AppRadius.md corner sitting
          // AppSpacing.md inside it, not an unrelated token.
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.md),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CompanyMark(company: company.name, size: 32),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5, fontWeight: AppFontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Ionicons.star, size: 12, color: AppColors.warning),
                  const SizedBox(width: 3),
                  Text(
                    '${company.rating.toStringAsFixed(1)} · ${company.reviewCount} reviews',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTag(label: company.tag),
              const Spacer(),
              Text(
                '${company.openRoles} role${company.openRoles == 1 ? '' : 's'} open',
                style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 11.5, fontWeight: AppFontWeight.medium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SearchChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.gray500),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5, fontWeight: AppFontWeight.medium)),
          ],
        ),
      ),
    );
  }
}
