import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/site_content.dart';

// The app's own colours, as PDF colours.
const _maroon = PdfColor.fromInt(0xFF7B2437);
const _gold = PdfColor.fromInt(0xFFC39A4B);
const _ink = PdfColor.fromInt(0xFF3A2A22);
const _muted = PdfColor.fromInt(0xFF8A7A72);
const _cream = PdfColor.fromInt(0xFFF6F0E6);
const _line = PdfColor.fromInt(0xFFE9DFD0);

class _Fonts {
  final pw.Font body;
  final pw.Font display;
  const _Fonts(this.body, this.display);
}

/// The bundled Inter and Playfair files, so the rupee sign and accents render.
Future<_Fonts> _loadFonts() async {
  final body = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter.ttf'));
  final display = pw.Font.ttf(await rootBundle.load('assets/fonts/PlayfairDisplay.ttf'));
  return _Fonts(body, display);
}

/// Bytes of a stored photo, or null when it cannot be read (the caption still prints).
Future<Uint8List?> _photoBytes(String path) async {
  try {
    if (path.startsWith('asset:')) {
      return (await rootBundle.load(path.substring(6))).buffer.asUint8List();
    }
    final url = await repo.mediaUrl(path);
    if (url.startsWith('http')) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != 200) return null;
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      } finally {
        client.close();
      }
    }
    return await File(url).readAsBytes();
  } catch (_) {
    return null;
  }
}

List<String> _lines(String text) =>
    text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

pw.Widget _eyebrow(String text, _Fonts f, {PdfColor color = _gold}) => pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(font: f.body, fontSize: 8.5, color: color, letterSpacing: 1.6),
    );

pw.Widget _heading(String text, _Fonts f) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(text, style: pw.TextStyle(font: f.display, fontSize: 16, color: _maroon)),
          pw.Container(margin: const pw.EdgeInsets.only(top: 4), height: 0.8, width: 42, color: _gold),
        ],
      ),
    );

/// A block of text as bullets or numbered steps, one widget per line so pages can break.
List<pw.Widget> _textBlock(String title, String text, _Fonts f, {bool numbered = false}) {
  final lines = _lines(text);
  if (lines.isEmpty) return const [];
  return [
    _heading(title, f),
    for (var i = 0; i < lines.length; i++)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 18,
              child: pw.Text(
                numbered ? '${i + 1}.' : '•',
                style: pw.TextStyle(font: f.body, fontSize: 10.5, color: _gold),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                lines[i],
                style: pw.TextStyle(font: f.body, fontSize: 10.5, color: _ink, lineSpacing: 2.5),
              ),
            ),
          ],
        ),
      ),
  ];
}

pw.Widget _coverPage(Family? family, String title, String subtitle, _Fonts f) {
  pw.Widget root(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text(label.toUpperCase(),
                  style: pw.TextStyle(font: f.body, fontSize: 8, color: _gold, letterSpacing: 1.4)),
            ),
            pw.Text(value.isEmpty ? '—' : value,
                style: pw.TextStyle(font: f.body, fontSize: 11.5, color: PdfColors.white)),
          ],
        ),
      );
  return pw.Container(
    color: _maroon,
    padding: const pw.EdgeInsets.all(56),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('HAMARI VIRASAT',
            style: pw.TextStyle(font: f.display, fontSize: 13, color: _gold, letterSpacing: 3)),
        pw.SizedBox(height: 4),
        pw.Text('Legacy · Preservation · Continuity',
            style: pw.TextStyle(font: f.body, fontSize: 8.5, color: PdfColors.white, letterSpacing: 1.2)),
        pw.Spacer(),
        _eyebrow(subtitle, f),
        pw.SizedBox(height: 12),
        pw.Text(title, style: pw.TextStyle(font: f.display, fontSize: 38, color: PdfColors.white)),
        pw.SizedBox(height: 14),
        pw.Container(height: 1, width: 70, color: _gold),
        pw.SizedBox(height: 22),
        pw.Text((family?.name ?? '').isEmpty ? 'Our Family' : family!.name,
            style: pw.TextStyle(font: f.display, fontSize: 20, color: PdfColors.white)),
        pw.SizedBox(height: 14),
        root('Gotra', family?.gotra ?? ''),
        root('Kuldevi', family?.kuldevi ?? ''),
        root('Kuldevta', family?.kuldevta ?? ''),
        pw.Spacer(),
        pw.Text('Stories that live beyond generations',
            style: pw.TextStyle(font: f.body, fontSize: 9, color: PdfColors.white)),
      ],
    ),
  );
}

/// Everything recorded for one ritual, in the order of its documentation form.
Future<List<pw.Widget>> _ritualBody(Ritual r, _Fonts f) async {
  final out = <pw.Widget>[
    _eyebrow(r.category.isEmpty ? 'Ritual' : r.category, f),
    pw.SizedBox(height: 6),
    pw.Text(r.title.isEmpty ? '(untitled)' : r.title,
        style: pw.TextStyle(font: f.display, fontSize: 26, color: _ink)),
    if (r.phase.isNotEmpty)
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Text(r.phase, style: pw.TextStyle(font: f.body, fontSize: 10, color: _muted)),
      ),
  ];

  final roots = [
    for (final k in const ['Gotra', 'Kuldevi', 'Kuldevta'])
      if ((r.sections[k] ?? '').isNotEmpty) '$k: ${r.sections[k]}',
  ];
  if (roots.isNotEmpty) out.addAll(_textBlock('Ancestral Profile', roots.join('\n'), f));

  out.addAll(_textBlock('Samagri & Offerings', r.samagri, f));
  out.addAll(_textBlock('Ritual Steps', r.steps, f, numbered: true));

  // The catalogue's other sub-sections, in the website's order, then any left over.
  final template = templateFor(r.templateKey);
  final printed = <String>{'Gotra', 'Kuldevi', 'Kuldevta'};
  for (final s in template?.subSections ?? const <SubSection>[]) {
    if (s.kind == SectionKind.text && printed.add(s.name)) {
      out.addAll(_textBlock(s.name, r.sections[s.name] ?? '', f));
    }
  }
  for (final e in r.sections.entries) {
    if (printed.add(e.key)) out.addAll(_textBlock(e.key, e.value, f));
  }

  out.addAll(_textBlock('Roles of Relatives', r.relativeRoles, f));

  if (r.recipes.isNotEmpty) {
    out.add(_heading('Special Foods & Recipes', f));
    for (final recipe in r.recipes) {
      out.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _cream,
            border: pw.Border.all(color: _line, width: 0.6),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(recipe.name, style: pw.TextStyle(font: f.display, fontSize: 13, color: _ink)),
              if (_lines(recipe.ingredients).isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _eyebrow('Ingredients', f),
                pw.SizedBox(height: 3),
                pw.Text(_lines(recipe.ingredients).join(', '),
                    style: pw.TextStyle(font: f.body, fontSize: 10, color: _ink, lineSpacing: 2)),
              ],
              if (_lines(recipe.method).isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _eyebrow('Method', f),
                pw.SizedBox(height: 3),
                for (var i = 0; i < _lines(recipe.method).length; i++)
                  pw.Text('${i + 1}. ${_lines(recipe.method)[i]}',
                      style: pw.TextStyle(font: f.body, fontSize: 10, color: _ink, lineSpacing: 2)),
              ],
            ],
          ),
        ),
      );
    }
  }

  out.addAll(_textBlock('Songs, Prayers & Mantras', r.songs, f));
  if (r.audioPaths.isNotEmpty) {
    out.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Text(
          '${r.audioPaths.length} recording(s) are kept with this ritual in the family app.',
          style: pw.TextStyle(font: f.body, fontSize: 9.5, color: _muted),
        ),
      ),
    );
  }

  if (r.photoPaths.isNotEmpty) {
    out.add(_heading('Family Photos', f));
    final tiles = <pw.Widget>[];
    for (var i = 0; i < r.photoPaths.length && i < 6; i++) {
      final bytes = await _photoBytes(r.photoPaths[i]);
      final caption = i < r.photoCaptions.length ? r.photoCaptions[i] : '';
      pw.Widget picture;
      try {
        picture = bytes == null
            ? pw.Container(height: 110, color: _cream)
            : pw.Image(pw.MemoryImage(bytes), height: 110, fit: pw.BoxFit.cover);
      } catch (_) {
        picture = pw.Container(height: 110, color: _cream);
      }
      tiles.add(
        pw.SizedBox(
          width: 150,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.ClipRRect(horizontalRadius: 4, verticalRadius: 4, child: picture),
              pw.SizedBox(height: 4),
              pw.Text(caption.isEmpty ? 'Photo ${i + 1}' : caption,
                  style: pw.TextStyle(font: f.body, fontSize: 9, color: _muted)),
            ],
          ),
        ),
      );
    }
    out.add(pw.Wrap(spacing: 12, runSpacing: 12, children: tiles));
  }

  out.addAll(_textBlock('Additional Information', r.additionalInfo, f));
  return out;
}

pw.PageTheme _pageTheme(_Fonts f) => pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(52, 52, 52, 46),
      theme: pw.ThemeData.withFont(base: f.body, bold: f.body),
    );

pw.Widget _footer(pw.Context context, String label, _Fonts f) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: f.body, fontSize: 8, color: _muted)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: f.body, fontSize: 8, color: _muted)),
        ],
      ),
    );

/// The heirloom document for one ritual.
Future<Uint8List> buildRitualPdf(Ritual ritual, Family? family) async {
  final f = await _loadFonts();
  final doc = pw.Document(title: ritual.title, author: 'Hamari Virasat');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => _coverPage(family, ritual.title.isEmpty ? 'Our Ritual' : ritual.title, 'A family ritual record', f),
    ),
  );
  final body = await _ritualBody(ritual, f);
  doc.addPage(
    pw.MultiPage(
      pageTheme: _pageTheme(f),
      footer: (c) => _footer(c, 'Hamari Virasat • ${family?.name ?? ''}', f),
      build: (_) => body,
    ),
  );
  return doc.save();
}

/// The whole Heritage Book: cover, contents, every ritual and the family's stories.
Future<Uint8List> buildBookPdf(Family? family, List<Ritual> rituals, List<Memory> memories) async {
  final f = await _loadFonts();
  final doc = pw.Document(title: 'Our Heritage, Our Story', author: 'Hamari Virasat');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => _coverPage(family, 'Our Heritage,\nOur Story', 'The family heritage book', f),
    ),
  );

  final stories = memories.where((m) => m.story.trim().isNotEmpty).toList();
  final recipes = rituals.fold<int>(0, (n, r) => n + r.recipes.length);
  doc.addPage(
    pw.MultiPage(
      pageTheme: _pageTheme(f),
      footer: (c) => _footer(c, 'Hamari Virasat • ${family?.name ?? ''}', f),
      build: (_) => [
        _eyebrow('Contents', f),
        pw.SizedBox(height: 6),
        pw.Text('Chapters', style: pw.TextStyle(font: f.display, fontSize: 26, color: _ink)),
        pw.SizedBox(height: 14),
        for (final line in [
          'Rituals: ${rituals.length} tradition(s)',
          'Recipes: $recipes family recipe(s), each under its ritual',
          'Stories: ${stories.length} memory(ies)',
        ])
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(line, style: pw.TextStyle(font: f.body, fontSize: 11.5, color: _ink)),
          ),
        pw.SizedBox(height: 10),
        for (var i = 0; i < rituals.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('${i + 1}.  ${rituals[i].title}',
                style: pw.TextStyle(font: f.body, fontSize: 10.5, color: _muted)),
          ),
      ],
    ),
  );

  for (final ritual in rituals) {
    final body = await _ritualBody(ritual, f);
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(f),
        footer: (c) => _footer(c, 'Hamari Virasat • ${family?.name ?? ''}', f),
        build: (_) => body,
      ),
    );
  }

  if (stories.isNotEmpty) {
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(f),
        footer: (c) => _footer(c, 'Hamari Virasat • ${family?.name ?? ''}', f),
        build: (_) => [
          _eyebrow('Chapter', f),
          pw.SizedBox(height: 6),
          pw.Text('Stories', style: pw.TextStyle(font: f.display, fontSize: 26, color: _ink)),
          for (final m in stories) ...[
            _heading(m.title.isEmpty ? '(untitled)' : m.title, f),
            if (m.createdByName.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('Shared by ${m.createdByName}',
                    style: pw.TextStyle(font: f.body, fontSize: 9, color: _muted)),
              ),
            for (final para in _lines(m.story))
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(para,
                    style: pw.TextStyle(font: f.body, fontSize: 10.5, color: _ink, lineSpacing: 2.5)),
              ),
            if (m.tags.isNotEmpty)
              pw.Text(m.tags.join(' • '), style: pw.TextStyle(font: f.body, fontSize: 9, color: _gold)),
          ],
        ],
      ),
    );
  }
  return doc.save();
}

String _fileName(String title) {
  final safe = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return 'hamari-virasat-${safe.isEmpty ? 'document' : safe}.pdf';
}

/// Opens the system share / save sheet with the PDF.
Future<void> sharePdf(Uint8List bytes, String title) =>
    Printing.sharePdf(bytes: bytes, filename: _fileName(title));

/// Opens the system print preview, from where the PDF can also be saved.
Future<void> previewPdf(Uint8List bytes, String title) =>
    Printing.layoutPdf(name: _fileName(title), onLayout: (_) async => bytes);
