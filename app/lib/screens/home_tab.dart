import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'info_screens.dart';
import 'memories_screens.dart';
import 'recipes_screen.dart';
import 'ritual_form_screen.dart';
import 'rituals_screen.dart';
import 'site_ui.dart';
import 'ui.dart';

/// Home: greeting, the legacy banner, four quick tiles and the latest memories.
class HomeTab extends StatefulWidget {
  final AppUser user;
  final VoidCallback onCapture;
  final VoidCallback onOpenFamily;
  final VoidCallback onOpenBook;

  const HomeTab({
    super.key,
    required this.user,
    required this.onCapture,
    required this.onOpenFamily,
    required this.onOpenBook,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Family? _family;
  List<Memory> _memories = const [];
  int _rituals = 0;
  Ritual? _draft; // most recent ritual still being filled in
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final family = await guard(context, () => repo.myFamily());
    if (!mounted) return;
    final memories = await guard(context, () => repo.listMemories());
    if (!mounted) return;
    final rituals = await guard(context, () => repo.listRituals());
    if (!mounted) return;
    setState(() {
      _family = family ?? _family;
      _memories = memories ?? _memories;
      _rituals = rituals?.length ?? _rituals;
      if (rituals != null) {
        final drafts = rituals.where((r) => r.status == kStatusDraft).toList();
        _draft = drafts.isEmpty ? null : drafts.first;
      }
      _loading = false;
    });
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  String get _firstName {
    final parts = widget.user.name.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? 'there' : parts.first;
  }

  String get _familyTitle {
    final name = (_family?.name ?? '').trim();
    if (name.isEmpty) return 'Your Family';
    final low = name.toLowerCase();
    if (low.contains('family') || low.contains('parivar')) return name;
    return 'The $name Family';
  }

  String get _legacyLine {
    if (_memories.isEmpty && _rituals == 0) return 'A home for every memory your family holds dear';
    final parts = <String>[
      if (_memories.isNotEmpty) plural(_memories.length, 'memory', 'memories'),
      if (_rituals > 0) plural(_rituals, 'ritual', 'rituals'),
    ];
    return 'A home for ${parts.join(' and ')}';
  }

  @override
  Widget build(BuildContext context) {
    final recent = _memories.take(4).toList();
    return RefreshIndicator(
      color: kMaroon,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 18, bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Namaste, $_firstName', style: body(14.5, weight: 500, color: kMuted)),
                      const SizedBox(height: 4),
                      Text(_familyTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: display(28)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InitialAvatar(widget.user.name, size: 52),
              ],
            ),
          ),
          const SizedBox(height: 10),
          MaroonCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR FAMILY LEGACY', style: eyebrow()),
                      const SizedBox(height: 8),
                      Text(_legacyLine, style: display(21, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.menu_book_outlined, color: kGold, size: 46),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _tile(Icons.add_photo_alternate_outlined, 'Add Memory', widget.onCapture)),
                    const SizedBox(width: 12),
                    Expanded(child: _tile(Icons.people_outline, 'Family', widget.onOpenFamily)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tile(
                        Icons.soup_kitchen_outlined,
                        'Recipes',
                        () => _push(RecipesScreen(user: widget.user)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tile(
                        Icons.temple_hindu_outlined,
                        'Rituals',
                        () => _push(RitualsScreen(user: widget.user)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_draft != null)
            SoftCard(
              margin: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              onTap: () => _push(RitualFormScreen(user: widget.user, existing: _draft)),
              child: Row(
                children: [
                  const IconBadge(Icons.edit_note_outlined, size: 44, circle: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONTINUE WHERE YOU LEFT OFF', style: eyebrow(size: 10)),
                        const SizedBox(height: 4),
                        Text(
                          _draft!.title.isEmpty ? 'Your ritual draft' : _draft!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: display(17),
                        ),
                        const SizedBox(height: 4),
                        StatusChip(_draft!.status),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kMuted),
                ],
              ),
            ),
          Center(
            child: TextButton.icon(
              onPressed: () => _push(const HowItWorksScreen()),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('How it works'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 12, 6),
            child: Row(
              children: [
                Expanded(child: Text('Recent memories', style: display(22))),
                if (_memories.isNotEmpty)
                  TextButton(
                    onPressed: () => _push(MemoriesScreen(user: widget.user, title: 'All memories')),
                    child: const Text('See all'),
                  ),
              ],
            ),
          ),
          if (_loading)
            const Padding(padding: EdgeInsets.only(top: 40), child: Loading())
          else if (recent.isEmpty)
            EmptyState(
              icon: Icons.auto_stories_outlined,
              title: 'Your story starts here',
              line: 'Add the first photo, voice note or story and it will live here for the whole family.',
              action: FilledButton.icon(
                onPressed: widget.onCapture,
                icon: const Icon(Icons.add),
                label: const Text('Add a memory'),
              ),
            )
          else
            for (var i = 0; i < recent.length; i++)
              FadeSlideIn(
                key: ValueKey('memory-${recent[i].id}'),
                index: i,
                child: MemoryCard(
                  memory: recent[i],
                  onTap: () => _push(MemoryDetailScreen(user: widget.user, memoryId: recent[i].id)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return SoftCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon, size: 44, circle: true),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(label, maxLines: 1, style: body(14.5, weight: 600))),
          ),
        ],
      ),
    );
  }
}
