import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/career_dna.dart';
import '../models/user.dart';

const _blue = PdfColor.fromInt(0xFF0A2FFF);
const _ink = PdfColor.fromInt(0xFF1C1C1E);
const _gray = PdfColor.fromInt(0xFF71717A);
const _border = PdfColor.fromInt(0xFFE5E5EA);

// Duplicated from career_dna_report_screen.dart's own private constant —
// that one is private to its file, and this PDF is generated independently
// of any widget tree, so a small copy here is simpler than exporting it.
// No raw percentage is ever printed anywhere in this document — same
// policy as the in-app report screen (a bare "23% Learning Agility" reads
// as a harsh verdict) — these phrases are only ever used in prose.
const _level1DimensionPhrases = {
  'leadershipInitiative': 'stepping up and taking initiative',
  'communicationConfidence': 'speaking up with confidence',
  'teamOrientation': 'working well with a team',
  'adaptability': 'adapting quickly to change',
  'decisionMaking': 'making clear decisions',
  'problemSolving': 'solving problems',
  'learningAgility': 'picking up new things fast',
  'resilience': 'bouncing back from setbacks',
  'socialOrientation': 'connecting with people',
  'ambitionGrowth': 'pushing yourself toward bigger goals',
};

/// Builds an actual downloadable Career Quiz report PDF — reuses the app's
/// own Poppins font files, mirroring resume_pdf.dart's structure/approach
/// exactly. Phase A only has real content for Level 1, so this renders
/// whichever levels are actually computed (just Level 1 today) rather than
/// assuming all 5 exist — Levels 2-5 slot into the same shape once their
/// own data lands, no change needed here.
Future<Uint8List> buildCareerDnaReportPdf(User user) async {
  final profile = user.careerDnaOrEmpty;

  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_400Regular.ttf'));
  final medium = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_500Medium.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_700Bold.ttf'));
  final extrabold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_800ExtraBold.ttf'));

  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
      build: (context) => [
        pw.Text('${(user.name?.trim().isNotEmpty ?? false) ? user.name : 'Your'} Career Quiz Report', style: pw.TextStyle(font: extrabold, fontSize: 20, color: _ink)),
        pw.SizedBox(height: 2),
        pw.Text('Aerostar Career Quiz — Personality & Behaviour', style: pw.TextStyle(font: medium, fontSize: 11, color: _blue)),
        pw.SizedBox(height: 18),
        if (profile.level1 != null) ..._level1Section(user.name, profile.level1!, bold, regular),
        if (!profile.allLevelsComplete) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Levels 2-5 add more to this report as you complete them in the app.',
            style: pw.TextStyle(font: regular, fontSize: 9.5, color: _gray),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}

List<pw.Widget> _level1Section(String? name, CareerDnaLevel1Result level1, pw.Font bold, pw.Font regular) {
  final firstName = (name?.trim().isNotEmpty ?? false) ? name!.trim().split(' ').first : null;
  final naturalStyle = level1.archetype.naturalStyle;
  final first = _firstSentence(naturalStyle);
  final rest = naturalStyle.substring(first.length).trim();

  return [
    _sectionHeader('Your Result', bold),
    pw.Text(level1.archetype.name, style: pw.TextStyle(font: bold, fontSize: 15, color: _ink)),
    pw.SizedBox(height: 4),
    pw.Text(first, style: pw.TextStyle(font: regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 16),
    _sectionHeader(firstName != null ? "$firstName's Personality Snapshot" : 'Your Personality Snapshot', bold),
    pw.Text('$rest ${_narrativeSummary(level1.dimensionScores)}', style: pw.TextStyle(font: regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 16),
    pw.Text(
      '${level1.archetype.growthAreaText} You could also thrive in places like ${_joinList(level1.archetype.environments)}.',
      style: pw.TextStyle(font: regular, fontSize: 10, color: _gray, lineSpacing: 1.5),
    ),
  ];
}

/// The opening sentence only — mirrors career_dna_report_screen.dart's own
/// `_firstSentence` exactly, so the PDF's hero matches the on-screen one.
String _firstSentence(String text) {
  final match = RegExp(r'^.*?[.!?](?=\s|$)').firstMatch(text);
  return match?.group(0) ?? text;
}

/// Mirrors career_dna_report_screen.dart's own `_narrativeSummary` exactly
/// — top 3 dimensions named plainly as strengths, bottom 2 framed as still
/// developing, no numbers anywhere, second person throughout.
String _narrativeSummary(Map<String, int> scores) {
  final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final strengths = sorted.take(3).map((e) => _level1DimensionPhrases[e.key] ?? e.key).toList();
  final growing = sorted.reversed.take(2).map((e) => _level1DimensionPhrases[e.key] ?? e.key).toList();

  return 'Looking at how you actually answered, your standout strengths are ${_joinList(strengths)} — these come through clearly and are genuinely worth leaning into. '
      "You're still growing into ${_joinList(growing)} — with a bit of intentional practice, that's real room to build, not something holding you back.";
}

pw.Widget _sectionHeader(String title, pw.Font bold) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 11, color: _blue, letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Divider(color: _border, thickness: 1),
        pw.SizedBox(height: 8),
      ],
    );

String _joinList(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}
