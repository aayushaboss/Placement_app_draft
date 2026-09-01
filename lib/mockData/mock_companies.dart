import 'mock_opportunities.dart';

// Masked to 31 bits at every step — see mock_application_insights.dart for
// why (JS safe-integer overflow on web, collapses `% max` toward 0).
int _seeded(String seed, int salt, int max) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  hash = (hash + salt) & 0x7FFFFFFF;
  return hash % max;
}

const _tags = ['Indian MNC', 'Foreign MNC', 'Startup', 'Unicorn'];

/// A company tile for the search screen's "Featured companies" carousel —
/// Naukri's own search page leads with exactly this: a row of employers to
/// browse by, not just a text box. Open-role count is real (derived from
/// mockOpportunities); rating/review-count/tag are deterministic mock
/// stats, same pattern as the rest of the app's Naukri-parity numbers.
class CompanyProfile {
  final String name;
  final int openRoles;
  final double rating;
  final int reviewCount;
  final String tag;

  const CompanyProfile({
    required this.name,
    required this.openRoles,
    required this.rating,
    required this.reviewCount,
    required this.tag,
  });
}

/// One entry per distinct company in the current listings, most open roles
/// first — a company with nothing open right now isn't worth featuring.
List<CompanyProfile> featuredCompanies({int limit = 8}) {
  final counts = <String, int>{};
  for (final o in mockOpportunities) {
    counts[o.company] = (counts[o.company] ?? 0) + 1;
  }
  final companies = counts.entries.map((e) {
    final seed = e.key;
    return CompanyProfile(
      name: e.key,
      openRoles: e.value,
      rating: 3.5 + _seeded(seed, 1, 14) / 10,
      reviewCount: 80 + _seeded(seed, 2, 900),
      tag: _tags[_seeded(seed, 3, _tags.length)],
    );
  }).toList()
    ..sort((a, b) => b.openRoles.compareTo(a.openRoles));
  return companies.take(limit).toList();
}
