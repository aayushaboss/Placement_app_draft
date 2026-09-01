// Prototype mock data — delete when real API is wired. In-memory session store.
// Mirrors frontend/src/mockData/mockApplications.ts, extended with a status
// timeline + simulated company-bot chat (see models/application.dart).
import '../models/application.dart';
import 'mock_opportunities.dart';

DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

List<Application> _applications = _seedApplications();

List<Application> _seedApplications() {
  final apps = <Application>[];

  final interviewOpp = getOpportunityById('opp-frontend-intern');
  if (interviewOpp != null) {
    apps.add(Application(
      id: 'app-seed-interview',
      userId: 'demo',
      opportunityId: interviewOpp.id,
      opportunity: ApplicationOpportunitySummary(
        title: interviewOpp.title,
        company: interviewOpp.company,
        type: interviewOpp.type,
        image: interviewOpp.image,
      ),
      status: 'Interview',
      createdAt: _daysAgo(6).toIso8601String(),
      timeline: [
        ApplicationEvent(status: 'Applied', title: 'Application submitted', at: _daysAgo(6)),
        ApplicationEvent(status: 'In Review', title: 'Resume under review', at: _daysAgo(4)),
        ApplicationEvent(status: 'Interview', title: 'Interview scheduled', at: _daysAgo(1)),
      ],
      messages: [
        ApplicationMessage(
          id: 'm2',
          text: "Good news — you've cleared the first screen. We're comparing your profile with the shortlist now.",
          at: _daysAgo(4),
        ),
        ApplicationMessage(
          id: 'm3',
          text: "You're shortlisted! 🎉 Here are your interview details for Microsoft:",
          at: _daysAgo(1),
          interview: const InterviewDetails(
            round: 'Technical Round 1',
            dateLabel: 'Mon, 18 Aug',
            timeLabel: '1:00 PM',
            mode: 'Offline',
            location: 'Microsoft, 4th Floor, Prestige Tech Park, Bengaluru',
          ),
        ),
        ApplicationMessage(
          id: 'm4',
          text: 'Bring a printed resume and photo ID. Arrive 10 min early and ask for the campus-hiring desk.',
          at: _daysAgo(1),
        ),
      ],
    ));
  }

  final offerOpp = getOpportunityById('opp-uiux-intern');
  if (offerOpp != null) {
    apps.add(Application(
      id: 'app-seed-offer',
      userId: 'demo',
      opportunityId: offerOpp.id,
      opportunity: ApplicationOpportunitySummary(
        title: offerOpp.title,
        company: offerOpp.company,
        type: offerOpp.type,
        image: offerOpp.image,
      ),
      status: 'Offer',
      createdAt: _daysAgo(12).toIso8601String(),
      timeline: [
        ApplicationEvent(status: 'Applied', title: 'Application submitted', at: _daysAgo(12)),
        ApplicationEvent(status: 'In Review', title: 'Resume under review', at: _daysAgo(9)),
        ApplicationEvent(status: 'Interview', title: 'Interview completed', at: _daysAgo(5)),
        ApplicationEvent(status: 'Offer', title: 'Offer extended', at: _daysAgo(2)),
      ],
      messages: [
        ApplicationMessage(
          id: 'm2',
          text: 'Your portfolio stood out — moving you to the interview round.',
          at: _daysAgo(9),
        ),
        ApplicationMessage(
          id: 'm3',
          text: 'Thanks for chatting with our design lead this week — the team is finalizing decisions now.',
          at: _daysAgo(5),
        ),
        ApplicationMessage(
          id: 'm4',
          text: "🎉 Congratulations! Adobe would like to offer you the UI/UX Design Intern role. Check your registered email for the formal offer letter and next steps.",
          at: _daysAgo(2),
        ),
      ],
    ));
  }

  final rejectedOpp = getOpportunityById('opp-marketing-intern');
  if (rejectedOpp != null) {
    apps.add(Application(
      id: 'app-seed-rejected',
      userId: 'demo',
      opportunityId: rejectedOpp.id,
      opportunity: ApplicationOpportunitySummary(
        title: rejectedOpp.title,
        company: rejectedOpp.company,
        type: rejectedOpp.type,
        image: rejectedOpp.image,
      ),
      status: 'Rejected',
      createdAt: _daysAgo(9).toIso8601String(),
      // Only two milestones — some companies skip straight from application
      // to a walk-in round and a same-day decision, no separate review step.
      timeline: [
        ApplicationEvent(status: 'Applied', title: 'Application submitted', at: _daysAgo(9)),
        ApplicationEvent(status: 'Rejected', title: 'Decision received', at: _daysAgo(2)),
      ],
      messages: [
        ApplicationMessage(
          id: 'm2',
          text: "Dentsu moved forward with a candidate whose portfolio leaned more into paid-social campaigns — this one's closed.",
          at: _daysAgo(2),
        ),
      ],
    ));
  }

  final secondRejectedOpp = getOpportunityById('opp-content-intern');
  if (secondRejectedOpp != null) {
    apps.add(Application(
      id: 'app-seed-rejected-2',
      userId: 'demo',
      opportunityId: secondRejectedOpp.id,
      opportunity: ApplicationOpportunitySummary(
        title: secondRejectedOpp.title,
        company: secondRejectedOpp.company,
        type: secondRejectedOpp.type,
        image: secondRejectedOpp.image,
      ),
      status: 'Rejected',
      createdAt: _daysAgo(15).toIso8601String(),
      timeline: [
        ApplicationEvent(status: 'Applied', title: 'Application submitted', at: _daysAgo(15)),
        ApplicationEvent(status: 'In Review', title: 'Resume under review', at: _daysAgo(12)),
        ApplicationEvent(status: 'Rejected', title: 'Decision received', at: _daysAgo(7)),
      ],
      messages: [
        ApplicationMessage(
          id: 'm2',
          text: 'Your resume is with the editorial team now.',
          at: _daysAgo(12),
        ),
        ApplicationMessage(
          id: 'm3',
          text: "Ogilvy decided to go with someone who'd already published in their niche — this one's closed.",
          at: _daysAgo(7),
        ),
      ],
    ));
  }

  return apps;
}

/// Excludes soft-deleted entries — see [removeApplication]/[deletedAt].
/// Sorted once, centrally, so every caller sees the same order: an Offer
/// is the one status worth surfacing above everything else regardless of
/// when it came in, so those go first; everything else (including other
/// Offers relative to each other) falls back to most-recently-applied
/// first.
List<Application> listApplications() {
  final apps = _applications.where((a) => a.deletedAt == null).toList();
  apps.sort((a, b) {
    final aOffer = a.status == 'Offer' ? 0 : 1;
    final bOffer = b.status == 'Offer' ? 0 : 1;
    if (aOffer != bOffer) return aOffer.compareTo(bOffer);
    return b.createdAt.compareTo(a.createdAt);
  });
  return apps;
}

/// Single source of truth for "has the signed-in user already applied to
/// this opportunity" — every job/opportunity card that shows an
/// Apply/Applied state should use this instead of hand-rolling the same
/// listApplications() lookup (several call sites used to, and drifted:
/// some hardcoded `false` regardless of the real answer).
bool isOpportunityApplied(String opportunityId) => _applications.any((a) => a.opportunityId == opportunityId && a.deletedAt == null);

/// Soft delete — swiping an application away no longer removes it outright,
/// it just marks when it was deleted. The entry never actually leaves
/// _applications, which is what makes [restoreApplication] trivial (no
/// index bookkeeping needed) and lets both the swipe's own SnackBar-undo
/// and the Recently Deleted screen share one restore path.
void removeApplication(String id) =>
    _applications = _applications.map((a) => a.id == id ? a.withDeletedAt(DateTime.now().toIso8601String()) : a).toList();

/// Entries currently in the trash, most-recently-deleted first.
/// TODO: auto-purge entries older than ~30 days (Gmail/Drive-style trash
/// retention) once there's a real backend to run that on a schedule — no
/// timer in this prototype, so deleted entries just persist for the session.
List<Application> listRecentlyDeleted() {
  final deleted = _applications.where((a) => a.deletedAt != null).toList();
  deleted.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
  return deleted;
}

/// Un-deletes — used both by the swipe's fast SnackBar-undo and by the
/// Recently Deleted screen's Restore action.
void restoreApplication(String id) =>
    _applications = _applications.map((a) => a.id == id ? a.withDeletedAt(null) : a).toList();

/// True hard removal — for a "Delete forever" action on an already-trashed
/// entry.
void permanentlyDelete(String id) => _applications = _applications.where((a) => a.id != id).toList();

Application? getApplicationById(String id) {
  final matches = _applications.where((a) => a.id == id);
  return matches.isEmpty ? null : matches.first;
}

Application? createApplication(
  String opportunityId, {
  String? note,
  Map<String, String>? screeningAnswers,
}) {
  // Excludes soft-deleted matches — otherwise re-applying after deleting an
  // application for this opportunity would just hand back the still-hidden
  // deleted entry instead of creating a fresh, visible one.
  final existing = _applications.where((a) => a.opportunityId == opportunityId && a.deletedAt == null);
  if (existing.isNotEmpty) return existing.first;
  final opp = getOpportunityById(opportunityId);
  if (opp == null) return null;
  final now = DateTime.now();
  final application = Application(
    id: 'app-${now.millisecondsSinceEpoch}',
    userId: 'demo',
    opportunityId: opportunityId,
    opportunity: ApplicationOpportunitySummary(
      title: opp.title,
      company: opp.company,
      type: opp.type,
      image: opp.image,
    ),
    status: 'Applied',
    createdAt: now.toIso8601String(),
    note: note,
    screeningAnswers: screeningAnswers,
    timeline: [
      ApplicationEvent(status: 'Applied', title: 'Application submitted', at: now),
    ],
    // No opening "thanks for applying" message — the Applied timeline step
    // above already says that; `messages` defaults to empty until there's
    // an actual update to show.
  );
  _applications = [application, ..._applications];
  return application;
}
