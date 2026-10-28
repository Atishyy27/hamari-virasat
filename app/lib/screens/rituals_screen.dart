import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/site_content.dart';
import '../theme.dart';
import 'catalogue_screen.dart';
import 'ritual_detail_screen.dart';
import 'ritual_form_screen.dart';
import 'site_ui.dart';
import 'ui.dart';

/// The Rituals chapter: every ritual the family has recorded, grouped by category.
/// With [festivals] on it is the Festivals chapter instead, showing festivals only.
class RitualsScreen extends StatefulWidget {
  final AppUser user;
  final String familyName;
  final bool festivals;
  const RitualsScreen({super.key, required this.user, this.familyName = '', this.festivals = false});

  @override
  State<RitualsScreen> createState() => _RitualsScreenState();
}

class _RitualsScreenState extends State<RitualsScreen> {
  final _search = TextEditingController();
  List<Ritual> _rituals = const [];
  List<RitualOrder> _orders = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rituals = await guard(context, () => repo.listRituals());
    if (!mounted) return;
    List<RitualOrder> orders = _orders;
    try {
      orders = await repo.listOrders();
    } catch (_) {
      // Orders only add the "ready to fill" cards; the list works without them.
    }
    if (!mounted) return;
    setState(() {
      _rituals = rituals?.where((r) => isFestival(r.category, r.templateKey) == widget.festivals).toList() ?? _rituals;
      _orders = orders;
      _loading = false;
    });
  }

  /// Catalogue rituals that are paid for and not started yet.
  List<RitualTemplate> get _readyToFill {
    final paid = <String>[
      for (final o in _orders)
        if (o.status == 'paid') ...o.ritualKeys,
    ];
    for (final r in _rituals) {
      paid.remove(r.templateKey); // one started ritual uses up one purchase
    }
    return [
      for (final key in paid)
        if (templateFor(key) case final t? when (t.stage == kFestivalStage) == widget.festivals) t,
    ];
  }

  Future<void> _openCatalogue() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatalogueScreen(user: widget.user, festivals: widget.festivals)),
    );
    if (mounted) await _load();
  }

  Future<void> _start(RitualTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RitualFormScreen(user: widget.user, templateKey: template.key)),
    );
    if (mounted) await _load();
  }

  /// "ritual" or "festival", for the copy on this page.
  String get _noun => widget.festivals ? 'festival' : 'ritual';

  Widget _documentCard() {
    return MaroonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RITI RIWAJ', style: eyebrow()),
          const SizedBox(height: 8),
          Text('Document a new $_noun', style: display(21, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Choose from our collection: ₹299 per $_noun, documented in full as a PDF heirloom.',
            style: body(13.5, color: Colors.white.withValues(alpha: 0.92)).copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _openCatalogue,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kMaroon),
            child: Text(widget.festivals ? 'Browse festivals' : 'Browse rituals'),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RitualFormScreen(user: widget.user, initialCategory: widget.festivals ? kFestivalStage : null),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _open(Ritual r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RitualDetailScreen(user: widget.user, ritualId: r.id)),
    );
    if (mounted) await _load();
  }

  bool _matches(Ritual r) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return r.title.toLowerCase().contains(q) ||
        r.category.toLowerCase().contains(q) ||
        r.phase.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _rituals.where(_matches).toList();
    // Group by category, keeping the order the repository returned.
    final groups = <String, List<Ritual>>{};
    for (final r in shown) {
      groups.putIfAbsent(r.category.isEmpty ? 'Other' : r.category, () => []).add(r);
    }

    final children = <Widget>[];
    if (!_loading) {
      children.add(_documentCard());
      final ready = _readyToFill;
      if (ready.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Text('PAID · READY TO FILL', style: eyebrow()),
          ),
        );
        for (final t in ready) {
          children.add(
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              onTap: () => _start(t),
              child: Row(
                children: [
                  Expanded(child: Text(t.title, style: display(17))),
                  TextButton(onPressed: () => _start(t), child: const Text('Start form')),
                ],
              ),
            ),
          );
        }
      }
    }
    if (_loading) {
      children.add(const Padding(padding: EdgeInsets.only(top: 80), child: Loading()));
    } else if (_rituals.isEmpty) {
      children.add(
        FadeSlideIn(
          child: EmptyState(
            icon: Icons.temple_hindu_outlined,
            title: 'Your traditions start here',
            line: 'Record a $_noun: what is needed, the steps, who does what, '
                'the food that is cooked and the songs that are sung.',
            action: FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text('Add $_noun'),
            ),
          ),
        ),
      );
    } else {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search ${_noun}s, categories or phases',
              prefixIcon: const Icon(Icons.search, size: 22),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
      );
      if (shown.isEmpty) {
        children.add(
          EmptyState(
            icon: Icons.search_off_outlined,
            title: 'Nothing found',
            line: 'No $_noun matches "${_query.trim()}". Try another word.',
          ),
        );
      }
      var index = 0;
      for (final entry in groups.entries) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Row(
              children: [
                Expanded(child: Text(entry.key.toUpperCase(), style: eyebrow())),
                Text('${entry.value.length}', style: body(12.5, weight: 600, color: kMuted)),
              ],
            ),
          ),
        );
        for (final r in entry.value) {
          children.add(
            FadeSlideIn(
              key: ValueKey('ritual-${r.id}'),
              index: index++,
              child: _RitualCard(ritual: r, onTap: () => _open(r)),
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: widget.festivals ? 'Festivals' : 'Rituals',
              back: true,
              trailing: IconButton(tooltip: 'Add $_noun', icon: const Icon(Icons.add, color: kMaroon), onPressed: _add),
            ),
            Expanded(
              child: RefreshIndicator(
                color: kMaroon,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 28),
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  final Ritual ritual;
  final VoidCallback onTap;
  const _RitualCard({required this.ritual, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = ritual;
    final facts = <String>[
      if (r.phase.isNotEmpty) r.phase,
      plural(r.recipes.length, 'recipe', 'recipes'),
      plural(r.audioPaths.length, 'song', 'songs'),
    ];
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(categoryIcon(r.category), size: 52, background: const Color(0xFFEBD9D6)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title.isEmpty ? '(untitled)' : r.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: display(18),
                ),
                const SizedBox(height: 4),
                Text(
                  facts.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(12.5, color: kMuted),
                ),
                if (r.status != kStatusApproved) ...[
                  const SizedBox(height: 6),
                  StatusChip(r.status),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kMuted),
        ],
      ),
    );
  }
}
