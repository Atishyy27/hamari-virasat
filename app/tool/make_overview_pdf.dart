// Builds the client overview PDF from the phone screenshots.
// Run from the app directory: dart run tool/make_overview_pdf.dart
// Input: ../design/screens-small/*.jpg   Output: ~/Desktop/Hamari-Virasat-App-Overview.pdf
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const maroon = PdfColor.fromInt(0xFF7B2437);
const cream = PdfColor.fromInt(0xFFF6F0E6);
const gold = PdfColor.fromInt(0xFFC39A4B);
const ink = PdfColor.fromInt(0xFF3A2A22);
const muted = PdfColor.fromInt(0xFF7A6A60);

// File name (without extension) to the caption printed under the screen.
const captions = <String, String>{
  '01-splash': 'Splash',
  '02-onboarding-1': 'Onboarding 1',
  '03-onboarding-2': 'Onboarding 2',
  '04-onboarding-3': 'Onboarding 3',
  '05-otp-login': 'Mobile number and OTP',
  '06-home': 'Home',
  '07-home-lower': 'Home: recent memories',
  '08-family': 'Family: name and details',
  '09-family-members': 'Family: members',
  '10-book': 'Heritage Book',
  '11-book-rituals': 'Rituals',
  '12-ritual-detail': 'Ritual: status and PDF',
  '12b-ritual-detail-lower': 'Ritual: recipes inside',
  '13-book-recipes': 'Recipes by ritual',
  '14-book-stories': 'Stories',
  '15-book-photos': 'Photo albums',
  '16-profile': 'Profile',
  '17-profile-lower': 'Profile: more',
  '18-add-memory': 'Add a memory',
  '19-catalogue': 'Riti Riwaj catalogue',
  '19b-catalogue-lower': 'Catalogue: rituals',
  '20-catalogue-selected': 'Ritual selected',
  '22-ritual-form': 'Ritual form',
  '23-about': 'About Hamari Virasat',
  '25-pricing': 'Pricing',
  '27-how-it-works': 'How it works',
  '28-privacy': 'Privacy and permissions',
  '29-help-for-elders': 'Help for elders',
};

pw.Widget h(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: maroon)),
    );

pw.Widget p(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(t, style: const pw.TextStyle(fontSize: 10.5, color: ink, lineSpacing: 2)),
    );

pw.Widget bullets(List<String> items) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final i in items)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(
                  width: 4, height: 4, margin: const pw.EdgeInsets.only(top: 4, right: 7),
                  decoration: const pw.BoxDecoration(color: gold, shape: pw.BoxShape.circle)),
              pw.Expanded(child: pw.Text(i, style: const pw.TextStyle(fontSize: 10.5, color: ink, lineSpacing: 2))),
            ]),
          ),
      ],
    );

pw.Widget table(List<List<String>> rows) => pw.TableHelper.fromTextArray(
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: maroon),
      cellStyle: const pw.TextStyle(fontSize: 10, color: ink),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2D6C6), width: 0.6),
      cellAlignment: pw.Alignment.centerLeft,
    );

Future<void> main() async {
  final dir = Directory('../design/screens-small');
  final files = <String, pw.MemoryImage>{};
  for (final name in captions.keys) {
    final f = File('${dir.path}/$name.jpg');
    if (f.existsSync()) files[name] = pw.MemoryImage(f.readAsBytesSync());
  }
  stdout.writeln('screens found: ${files.length} of ${captions.length}');

  final doc = pw.Document(title: 'Hamari Virasat: App Overview', author: 'Atishay Jain');
  final theme = pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 34),
    buildBackground: (c) => pw.FullPage(ignoreMargins: true, child: pw.Container(color: cream)),
  );

  doc.addPage(pw.MultiPage(
    pageTheme: theme,
    footer: (c) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Hamari Virasat app overview, 10 Oct 2026, page ${c.pageNumber} of ${c.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: muted))),
    build: (c) => [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(color: maroon, borderRadius: pw.BorderRadius.circular(12)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('HAMARI VIRASAT', style: pw.TextStyle(fontSize: 9, color: gold, letterSpacing: 2)),
          pw.SizedBox(height: 6),
          pw.Text('Mobile app: build overview',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 4),
          pw.Text('Android app with a live database. Status as of 10 October 2026.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.white)),
        ]),
      ),
      h('What is ready'),
      bullets([
        'All screens of the Figma design: splash, three onboarding screens, mobile number and OTP, Home, Family, Add a Memory, Heritage Book and Profile, with the five-tab bottom bar.',
        'The three requested changes: (1) no family tree, only the family name and its members; (2) the super admin cannot see any family data; (3) recipes are shown inside a ritual.',
        'The website features inside the app: Riti Riwaj catalogue at Rs 299 per ritual, selecting one or many rituals, checkout, the guided ritual form with save and resume, document status, PDF download, About, How it works, Pricing, FAQ, contact form, WhatsApp and call booking.',
        'A live database with login, family-wise privacy rules and file storage for photos, videos and audio.',
        'Sample data so the app does not open empty: 3 families, 14 members, 16 rituals, 14 recipes, 18 memories and 6 photos.',
      ]),
      h('How to try it'),
      p('Install the APK sent with this document. On the OTP screen, under "Try a demo account", tap one of the three buttons. No typing is needed.'),
      table([
        ['Demo account', 'What it shows'],
        ['Family admin', 'Full family: can add and edit members, rituals, recipes and memories'],
        ['Member', 'Same family, view and add, cannot edit family details or members'],
        ['Super admin', 'Only the list of families with an active switch. No family content is visible'],
      ]),
      pw.SizedBox(height: 4),
      p('A new family can also be created: enter any 10-digit mobile number and any 6 digits on the OTP screen, then give a name and a family name.'),
      h('The three changes, and how each is enforced'),
      table([
        ['Change asked', 'In the app', 'In the database'],
        ['Remove the family tree', 'Family tab shows the family name, gotra, kuldevi, kuldevta and a plain list of members', 'Members are stored as a flat list with no parent or generation links'],
        ['Super admin cannot see admin data', 'Super admin screen lists only family names and an active switch', 'Access rules sit in the database itself. Tested: a super admin reading families, rituals, recipes and members gets zero rows in all four'],
        ['Recipe under ritual', 'Recipes open inside the ritual. The Recipes chapter is a list that leads back to the ritual', 'Every recipe row belongs to exactly one ritual'],
      ]),
      h('What is a demo stand-in for now'),
      bullets([
        'OTP: any 6-digit code is accepted. Real SMS verification needs an SMS provider account and will replace this.',
        'Payment: the Rs 299 checkout records the order but no money is charged. Razorpay will be connected with the business account keys.',
        'FAQ answers: written from the website text, because the website page carries only the questions. Final answers are needed.',
        'Onboarding photos and the logo mark are taken from the design screens. The original image files are needed for a sharp result.',
        'Video and voice memories are saved and listed. Playing them inside the app is still to be added.',
        '"Draft ready" on a ritual is set by a demo button. A team-side screen to prepare and send drafts is not built yet.',
      ]),
      h('Technology, in brief'),
      table([
        ['Part', 'Choice', 'Why'],
        ['App', 'Flutter', 'One codebase gives Android now, and iPhone and a web version later'],
        ['Database, login, files', 'Supabase (Postgres), Mumbai region', 'Privacy rules are enforced inside the database, so one family can never read another family\'s data'],
        ['Storage use', 'Photos are resized before upload. Limits: video 60 seconds and 25 MB, audio 10 MB', 'Keeps storage cost low as families add media'],
      ]),
    ],
  ));

  // Screens, 8 to a page (4 by 2).
  final names = files.keys.toList();
  const perPage = 8;
  for (var start = 0; start < names.length; start += perPage) {
    final chunk = names.sublist(start, start + perPage > names.length ? names.length : start + perPage);
    doc.addPage(pw.Page(
      pageTheme: theme,
      build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(start == 0 ? 'Screens, as running on a phone' : 'Screens (continued)',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: maroon)),
        pw.SizedBox(height: 10),
        pw.Wrap(spacing: 11, runSpacing: 12, children: [
          for (final n in chunk)
            pw.SizedBox(
              width: 122,
              child: pw.Column(children: [
                pw.Container(
                  height: 264,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromInt(0xFFD9CBB8), width: 0.8)),
                  child: pw.Image(files[n]!, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(height: 4),
                pw.Text(captions[n]!, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8.5, color: ink)),
              ]),
            ),
        ]),
      ]),
    ));
  }

  final out = File('${Platform.environment['HOME']}/Desktop/Hamari-Virasat-App-Overview.pdf');
  out.writeAsBytesSync(await doc.save());
  stdout.writeln('wrote ${out.path} (${out.lengthSync()} bytes, ${doc.document.pdfPageList.pages.length} pages)');
}
