import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../pdf/heirloom_pdf.dart';
import '../theme.dart';
import 'memories_screens.dart';
import 'recipes_screen.dart';
import 'rituals_screen.dart';
import 'ui.dart';

/// Heritage Book: the cover and its four chapters with live counts.
class BookScreen extends StatefulWidget {
  final AppUser user;
  const BookScreen({super.key, required this.user});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  Family? _family;
  List<Ritual> _rituals = const [];
  List<Memory> _memories = const [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final family = await guard(context, () => repo.myFamily());
    if (!mounted) return;
    final rituals = await guard(context, () => repo.listRituals());
    if (!mounted) return;
    final memories = await guard(context, () => repo.listMemories());
    if (!mounted) return;
    setState(() {
      _family = family ?? _family;
      _rituals = rituals ?? _rituals;
      _memories = memories ?? _memories;
      _loading = false;
    });
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  /// Builds the whole book as a PDF, then opens the print preview or the share sheet.
  Future<void> _export({required bool preview}) async {
    if (_exporting || _loading) return;
    if (_rituals.isEmpty && _memories.isEmpty) {
      showInfo(context, 'Add a ritual or a memory first, then your book has pages to show');
      return;
    }
    setState(() => _exporting = true);
    try {
      final bytes = await buildBookPdf(_family, _rituals, _memories);
      if (preview) {
        await previewPdf(bytes, 'Heritage Book');
      } else {
        await sharePdf(bytes, 'Heritage Book');
      }
    } catch (e) {
      if (mounted) showError(context, 'Could not create the book. Please try again.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String get _coverName {
    final name = (_family?.name ?? '').trim();
    if (name.isEmpty) return 'YOUR FAMILY';
    final low = name.toLowerCase();
    if (low.contains('family') || low.contains('parivar')) return name.toUpperCase();
    return 'THE ${name.toUpperCase()} FAMILY';
  }

  DateTime? get _lastUpdate {
    DateTime? latest;
    for (final d in [..._rituals.map((r) => r.createdAt), ..._memories.map((m) => m.createdAt)]) {
      if (latest == null || d.isAfter(latest)) latest = d;
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _rituals.fold<int>(0, (n, r) => n + r.recipes.length);
    final stories = _memories.where((m) => !m.isVisual).length;
    final photos = _memories.where((m) => m.isVisual).fold<int>(0, (n, m) => n + m.mediaPaths.length);
    return Column(
      children: [
        ScreenHeader(
          title: 'Heritage Book',
          trailing: TextButton(
            onPressed: _exporting ? null : () => _export(preview: true),
            child: _exporting
                ? const SizedBox(width: 18, height: 18, child: ButtonSpinner(color: kMaroon))
                : const Text('Preview'),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: kMaroon,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 12, bottom: 28),
              children: [
                MaroonCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_coverName, style: eyebrow()),
                                const SizedBox(height: 10),
                                Text('Our Heritage,\nOur Story', style: display(26, color: Colors.white)),
                              ],
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: kGold, width: 1.2),
                            ),
                            child: const Icon(Icons.spa_outlined, color: kGold, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      Text(
                        'Living edition • ${_loading ? 'Opening...' : updatedWhen(_lastUpdate)}',
                        style: body(13, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: OutlinedButton.icon(
                    onPressed: _exporting ? null : () => _export(preview: false),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Export book as PDF'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                  child: Text('Chapters', style: display(22)),
                ),
                _chapter(
                  1,
                  'Rituals',
                  plural(_rituals.length, 'tradition', 'traditions'),
                  Icons.temple_hindu_outlined,
                  const Color(0xFFEBD9D6),
                  () => _push(RitualsScreen(user: widget.user)),
                ),
                _chapter(
                  2,
                  'Recipes',
                  plural(recipes, 'family recipe', 'family recipes'),
                  Icons.soup_kitchen_outlined,
                  const Color(0xFFF1DFC2),
                  () => _push(RecipesScreen(user: widget.user)),
                ),
                _chapter(
                  3,
                  'Stories',
                  plural(stories, 'memory', 'memories'),
                  Icons.history_edu_outlined,
                  const Color(0xFFDDE5D8),
                  () => _push(
                    MemoriesScreen(
                      user: widget.user,
                      title: 'Stories',
                      kinds: const ['story', 'voice'],
                      emptyTitle: 'No stories yet',
                      emptyLine: 'Write down a story or add a voice note from an elder, before it is forgotten.',
                    ),
                  ),
                ),
                _chapter(
                  4,
                  'Photo Albums',
                  plural(photos, 'photograph', 'photographs'),
                  Icons.photo_library_outlined,
                  const Color(0xFFE8DED5),
                  () => _push(
                    MemoriesScreen(
                      user: widget.user,
                      title: 'Photo Albums',
                      kinds: const ['photo', 'video'],
                      grid: true,
                      emptyTitle: 'No photographs yet',
                      emptyLine: 'Add old family photographs and short videos so everyone can see them.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chapter(int n, String title, String count, IconData icon, Color fill, VoidCallback onTap) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon, size: 52, background: fill),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHAPTER $n', style: eyebrow(size: 10)),
                const SizedBox(height: 4),
                Text(title, style: display(19)),
                const SizedBox(height: 3),
                Text(_loading ? '...' : count, style: body(12.5, color: kMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kMuted),
        ],
      ),
    );
  }
}
