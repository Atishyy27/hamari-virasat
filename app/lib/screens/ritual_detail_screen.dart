import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/site_content.dart';
import '../pdf/heirloom_pdf.dart';
import '../theme.dart';
import 'ritual_form_screen.dart';
import 'site_ui.dart';
import 'ui.dart';

/// One ritual with everything under it. Recipes are kept here, under their ritual.
class RitualDetailScreen extends StatefulWidget {
  final AppUser user;
  final String ritualId;

  const RitualDetailScreen({super.key, required this.user, required this.ritualId});

  @override
  State<RitualDetailScreen> createState() => _RitualDetailScreenState();
}

class _RitualDetailScreenState extends State<RitualDetailScreen> {
  Ritual? _ritual;
  bool _loading = true;
  bool _working = false; // a status change or PDF build is running

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ritual = await guard(context, () => repo.getRitual(widget.ritualId));
    if (!mounted) return;
    setState(() {
      _ritual = ritual;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final ritual = _ritual;
    if (ritual == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RitualFormScreen(user: widget.user, existing: ritual)),
    );
    if (mounted) await _load();
  }

  Future<void> _delete() async {
    final ritual = _ritual;
    if (ritual == null) return;
    final ok = await confirm(
      context,
      '"${ritual.title}" and its recipes will be removed for the whole family. This cannot be undone.',
      title: 'Delete this ritual?',
      yes: 'Delete',
    );
    if (!ok || !mounted) return;
    final done = await guardOk(context, () => repo.deleteRitual(ritual.id));
    if (done && mounted) Navigator.pop(context);
  }

  String _fileName(String path) => path.split('/').last;

  Future<void> _setStatus(String status, String done) async {
    final ritual = _ritual;
    if (ritual == null || _working) return;
    setState(() => _working = true);
    final ok = await guardOk(context, () => repo.saveRitual(ritual.copyWith(status: status)));
    if (!mounted) return;
    setState(() => _working = false);
    if (ok) {
      showInfo(context, done);
      await _load();
    }
  }

  Future<void> _approve() async {
    final ok = await confirm(
      context,
      'Approving marks this ritual as final. It becomes part of your Heritage Book and its PDF heirloom document.',
      title: 'Approve this draft?',
      yes: 'Approve',
      no: 'Not yet',
    );
    if (ok && mounted) await _setStatus(kStatusApproved, 'Approved. This ritual is now in your Heritage Book.');
  }

  Future<void> _downloadPdf() async {
    final ritual = _ritual;
    if (ritual == null || _working) return;
    setState(() => _working = true);
    try {
      Family? family;
      try {
        family = await repo.myFamily();
      } catch (_) {}
      final bytes = await buildRitualPdf(ritual, family);
      await sharePdf(bytes, ritual.title);
    } catch (e) {
      if (mounted) showError(context, 'Could not create the PDF. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// What the family can do next, depending on where the ritual stands.
  Widget _statusCard(Ritual ritual) {
    final String line;
    Widget? action;
    switch (ritual.status) {
      case kStatusDraft:
        line = 'This ritual is still a draft. Continue where you left off, then submit it for documentation.';
        action = FilledButton(onPressed: _edit, child: const Text('Continue filling'));
      case kStatusSubmitted:
        line = 'Submitted. Our team is preparing your draft document. It will be ready within 7 days.';
        if (kDemoMode) {
          action = TextButton(
            onPressed: _working ? null : () => _setStatus(kStatusDraftReady, 'Draft marked as ready'),
            child: const Text('Demo: mark the draft as ready'),
          );
        }
      case kStatusDraftReady:
        line = 'Your draft is ready. Read it below or download the PDF, then approve it.';
        action = FilledButton(onPressed: _working ? null : _approve, child: const Text('Approve draft'));
      default:
        line = 'Approved and preserved in your Heritage Book.';
    }
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(ritual.status),
              const Spacer(),
              if (_working) const ButtonSpinner(color: kMaroon),
            ],
          ),
          const SizedBox(height: 10),
          Text(line, style: body(13.5, color: kMuted).copyWith(height: 1.45)),
          if (action != null) ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: action),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _working ? null : _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Download PDF'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => openLink(context, kSamplePdfUrl),
              child: const Text('See a sample document'),
            ),
          ),
        ],
      ),
    );
  }

  /// Sections that only exist for some rituals: the ancestral profile, the catalogue's
  /// extra sub-sections, written songs, photos and additional information.
  List<Widget> _extraSections(Ritual ritual) {
    final out = <Widget>[];
    final roots = [
      for (final k in const ['Gotra', 'Kuldevi', 'Kuldevta'])
        if ((ritual.sections[k] ?? '').isNotEmpty) '$k: ${ritual.sections[k]}',
    ];
    if (roots.isNotEmpty) {
      out.add(SectionCard(
        icon: Icons.account_balance_outlined,
        title: 'Ancestral Profile',
        child: LinesText(roots.join('\n')),
      ));
    }
    final shown = <String>{'Gotra', 'Kuldevi', 'Kuldevta'};
    final names = [
      for (final s in templateFor(ritual.templateKey)?.subSections ?? const <SubSection>[])
        if (s.kind == SectionKind.text) s.name,
      ...ritual.sections.keys,
    ];
    for (final name in names) {
      final text = ritual.sections[name] ?? '';
      if (!shown.add(name) || text.trim().isEmpty) continue;
      out.add(SectionCard(icon: Icons.edit_note_outlined, title: name, child: LinesText(text)));
    }
    if (ritual.songs.trim().isNotEmpty) {
      out.add(SectionCard(
        icon: Icons.lyrics_outlined,
        title: 'Songs, prayers & mantras',
        child: LinesText(ritual.songs),
      ));
    }
    if (ritual.photoPaths.isNotEmpty) {
      out.add(SectionCard(
        icon: Icons.photo_library_outlined,
        title: 'Family photos (${ritual.photoPaths.length})',
        child: Column(
          children: [
            for (var i = 0; i < ritual.photoPaths.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: MediaImage(ritual.photoPaths[i], cacheWidth: 900),
                      ),
                    ),
                    if (i < ritual.photoCaptions.length && ritual.photoCaptions[i].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(ritual.photoCaptions[i], style: body(13, color: kMuted)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ));
    }
    if (ritual.additionalInfo.trim().isNotEmpty) {
      out.add(SectionCard(
        icon: Icons.notes_outlined,
        title: 'Additional Information',
        child: LinesText(ritual.additionalInfo),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final ritual = _ritual;
    final Widget content;
    if (_loading) {
      content = const Loading(key: ValueKey('loading'));
    } else if (ritual == null) {
      content = const Center(
        key: ValueKey('missing'),
        child: EmptyState(
          icon: Icons.search_off_outlined,
          title: 'Not found',
          line: 'This ritual could not be found. It may have been removed by a family member.',
        ),
      );
    } else {
      content = RefreshIndicator(
        key: const ValueKey('content'),
        color: kMaroon,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 32),
          children: [
            MaroonCard(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((ritual.category.isEmpty ? 'Ritual' : ritual.category).toUpperCase(), style: eyebrow()),
                  const SizedBox(height: 10),
                  Text(
                    ritual.title.isEmpty ? '(untitled)' : ritual.title,
                    style: display(26, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusChip(ritual.status, onDark: true),
                      if (ritual.phase.isNotEmpty) Pill(ritual.phase, onDark: true),
                      Pill('Added ${formatDate(ritual.createdAt)}', icon: Icons.event_outlined, onDark: true),
                    ],
                  ),
                ],
              ),
            ),
            _statusCard(ritual),
            FadeSlideIn(
              index: 0,
              child: SectionCard(
                icon: Icons.shopping_basket_outlined,
                title: 'Samagri',
                child: LinesText(ritual.samagri),
              ),
            ),
            FadeSlideIn(
              index: 1,
              child: SectionCard(
                icon: Icons.format_list_numbered,
                title: 'Steps',
                child: LinesText(ritual.steps, numbered: true),
              ),
            ),
            FadeSlideIn(
              index: 2,
              child: SectionCard(
                icon: Icons.people_outline,
                title: 'Roles of relatives',
                child: LinesText(ritual.relativeRoles),
              ),
            ),
            FadeSlideIn(
              index: 3,
              child: SectionCard(
                icon: Icons.soup_kitchen_outlined,
                title: 'Recipes (${ritual.recipes.length})',
                child: ritual.recipes.isEmpty
                    ? const EmptyNote()
                    : Column(
                        children: [
                          for (final recipe in ritual.recipes) _RecipeTile(recipe: recipe),
                        ],
                      ),
              ),
            ),
            FadeSlideIn(
              index: 4,
              child: SectionCard(
                icon: Icons.music_note_outlined,
                title: 'Folk songs (${ritual.audioPaths.length})',
                child: ritual.audioPaths.isEmpty
                    ? const EmptyNote()
                    : Column(
                        children: [
                          for (final path in ritual.audioPaths)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const IconBadge(Icons.graphic_eq, size: 36),
                              title: Text(
                                _fileName(path),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            ..._extraSections(ritual),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Ritual',
              back: true,
              trailing: ritual == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined, color: kMaroon),
                          onPressed: _edit,
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, color: kMaroon),
                          onPressed: _delete,
                        ),
                      ],
                    ),
            ),
            Expanded(child: SoftSwitcher(child: content)),
          ],
        ),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final Recipe recipe;
  const _RecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: kMaroon,
          collapsedIconColor: kMaroon,
          title: Text(recipe.name, style: body(15.5, weight: 600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INGREDIENTS', style: eyebrow()),
            const SizedBox(height: 4),
            LinesText(recipe.ingredients),
            const SizedBox(height: 12),
            Text('METHOD', style: eyebrow()),
            const SizedBox(height: 4),
            LinesText(recipe.method, numbered: true),
          ],
        ),
      ),
    );
  }
}
