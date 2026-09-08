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
const _level1DimensionLabels = {
  'leadershipInitiative': 'Leadership & Initiative',
  'communicationConfidence': 'Communication & Confidence',
  'teamOrientation': 'Team Orientation',
  'adaptability': 'Adaptability',
  'decisionMaking': 'Decision Making',
  'problemSolving': 'Problem Solving',
  'learningAgility': 'Learning Agility',
  'resilience': 'Resilience',
  'socialOrientation': 'Social Orientation',
  'ambitionGrowth': 'Ambition & Growth',
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
        if (profile.level1 != null) ..._level1Section(profile.level1!, bold, medium, regular),
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

List<pw.Widget> _level1Section(CareerDnaLevel1Result level1, pw.Font bold, pw.Font medium, pw.Font regular) {
  final entries = level1.dimensionScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = entries.take(10).toList();

  return [
    _sectionHeader('Your Result', bold),
    pw.Text(level1.archetype.name, style: pw.TextStyle(font: bold, fontSize: 15, color: _ink)),
    pw.SizedBox(height: 4),
    pw.Text(level1.archetype.naturalStyle, style: pw.TextStyle(font: regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 16),
    _sectionHeader('Your Personality Scores', bold),
    ...top.map((e) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(_level1DimensionLabels[e.key] ?? e.key, style: pw.TextStyle(font: medium, fontSize: 10, color: _ink)),
              pw.Text('${e.value}%', style: pw.TextStyle(font: bold, fontSize: 10, color: _blue)),
            ],
          ),
        )),
    pw.SizedBox(height: 10),
    pw.Text(
      '${level1.archetype.growthAreaText} You could also thrive in places like ${_joinList(level1.archetype.environments)}.',
      style: pw.TextStyle(font: regular, fontSize: 10, color: _gray, lineSpacing: 1.5),
    ),
  ];
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
