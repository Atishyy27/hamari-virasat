import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'add_memory_screen.dart';
import 'ui.dart';

/// One memory in a list, as on the Figma home: thumbnail, gold eyebrow, title, who and when.
class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  const MemoryCard({super.key, required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = memory;
    final by = m.createdByName.trim().isEmpty ? 'the family' : m.createdByName.trim().split(' ').first;
    return SoftCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 108,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 108),
                child: m.mediaPaths.isEmpty
                    ? Container(
                        color: kBlush,
                        alignment: Alignment.center,
                        child: Icon(memoryIcon(m.kind), color: kMaroon, size: 30),
                      )
                    : MediaImage(m.mediaPaths.first, kind: m.kind, cacheWidth: 400),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${memoryKindLabel(m.kind)} • ${m.createdAt.toLocal().year}'.toUpperCase(),
                      style: eyebrow(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.title.isEmpty ? '(untitled)' : m.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: display(18),
                    ),
                    const SizedBox(height: 6),
                    Text('Shared by $by • ${timeAgo(m.createdAt)}', style: body(12.5, color: kMuted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list or a photo grid of the family's memories, optionally limited to some kinds.
class MemoriesScreen extends StatefulWidget {
  final AppUser user;
  final String title;
  final List<String>? kinds; // null shows every kind
  final bool grid;
  final String emptyTitle;
  final String emptyLine;

  const MemoriesScreen({
    super.key,
    required this.user,
    required this.title,
    this.kinds,
    this.grid = false,
    this.emptyTitle = 'Nothing here yet',
    this.emptyLine = 'Memories your family adds will appear here.',
  });

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  List<Memory> _memories = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await guard(context, () => repo.listMemories());
    if (!mounted) return;
    final kinds = widget.kinds;
    setState(() {
      if (all != null) {
        _memories = kinds == null ? all : all.where((m) => kinds.contains(m.kind)).toList();
      }
      _loading = false;
    });
  }

  Future<void> _open(Memory m) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemoryDetailScreen(user: widget.user, memoryId: m.id)),
    );
    if (mounted) await _load();
  }

  Future<void> _add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddMemoryScreen(user: widget.user, initialKind: widget.kinds?.first)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_loading) {
      content = const Loading(key: ValueKey('loading'));
    } else if (_memories.isEmpty) {
      content = ListView(
        key: const ValueKey('empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: memoryIcon(widget.kinds?.first ?? 'story'),
            title: widget.emptyTitle,
            line: widget.emptyLine,
            action: FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add a memory'),
            ),
          ),
        ],
      );
    } else if (widget.grid) {
      content = GridView.builder(
        key: const ValueKey('grid'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemCount: _memories.length,
        itemBuilder: (context, i) => _GridTile(memory: _memories[i], onTap: () => _open(_memories[i])),
      );
    } else {
      content = ListView.builder(
        key: const ValueKey('list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        itemCount: _memories.length,
        itemBuilder: (context, i) => FadeSlideIn(
          key: ValueKey('memory-${_memories[i].id}'),
          index: i,
          child: MemoryCard(memory: _memories[i], onTap: () => _open(_memories[i])),
        ),
      );
    }
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: widget.title,
              back: true,
              trailing: IconButton(tooltip: 'Add a memory', icon: const Icon(Icons.add, color: kMaroon), onPressed: _add),
            ),
            Expanded(
              child: RefreshIndicator(color: kMaroon, onRefresh: _load, child: SoftSwitcher(child: content)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  const _GridTile({required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = memory;
    return SoftCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (m.mediaPaths.isEmpty)
                  Container(
                    color: kBlush,
                    alignment: Alignment.center,
                    child: Icon(memoryIcon(m.kind), color: kMaroon, size: 30),
                  )
                else
                  MediaImage(m.mediaPaths.first, kind: m.kind, cacheWidth: 400),
                if (m.mediaPaths.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${m.mediaPaths.length}', style: body(11.5, weight: 600, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Text(
              m.title.isEmpty ? '(untitled)' : m.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body(13.5, weight: 600),
            ),
          ),
        ],
      ),
    );
  }
}

/// One memory in full: media, title, story, tags, who added it and when.
class MemoryDetailScreen extends StatefulWidget {
  final AppUser user;
  final String memoryId;
  const MemoryDetailScreen({super.key, required this.user, required this.memoryId});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  Memory? _memory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memory = await guard(context, () => repo.getMemory(widget.memoryId));
    if (!mounted) return;
    setState(() {
      _memory = memory;
      _loading = false;
    });
  }

  bool get _canDelete {
    final m = _memory;
    if (m == null) return false;
    return widget.user.role == Role.familyAdmin || m.createdBy == widget.user.id;
  }

  Future<void> _delete() async {
    final m = _memory;
    if (m == null) return;
    final ok = await confirm(
      context,
      '"${m.title}" will be removed for the whole family. This cannot be undone.',
      title: 'Delete this memory?',
      yes: 'Delete',
    );
    if (!ok || !mounted) return;
    final done = await guardOk(context, () => repo.deleteMemory(m.id));
    if (done && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = _memory;
    final Widget content;
    if (_loading) {
      content = const Loading(key: ValueKey('loading'));
    } else if (m == null) {
      content = const Center(
        key: ValueKey('missing'),
        child: EmptyState(
          icon: Icons.search_off_outlined,
          title: 'Not found',
          line: 'This memory could not be found. It may have been removed by a family member.',
        ),
      );
    } else {
      content = ListView(
        key: const ValueKey('content'),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (m.mediaPaths.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView(
                children: [
                  for (final path in m.mediaPaths)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: MediaImage(path, kind: m.kind, cacheWidth: 1200),
                      ),
                    ),
                ],
              ),
            ),
          if (m.mediaPaths.length > 1)
            Center(
              child: Text('Swipe for ${m.mediaPaths.length} files', style: body(12, color: kMuted)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${memoryKindLabel(m.kind)} • ${m.createdAt.toLocal().year}'.toUpperCase(), style: eyebrow()),
                const SizedBox(height: 8),
                Text(m.title.isEmpty ? '(untitled)' : m.title, style: display(28)),
                const SizedBox(height: 10),
                Text(
                  'Shared by ${m.createdByName.trim().isEmpty ? 'the family' : m.createdByName.trim()}'
                  ' • ${formatDate(m.createdAt)}',
                  style: body(13, color: kMuted),
                ),
                if (m.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final t in m.tags) Pill(t, icon: Icons.sell_outlined, strong: true)],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.auto_stories_outlined,
            title: 'The story',
            child: m.story.trim().isEmpty
                ? const EmptyNote('No story written yet.')
                : Text(m.story, style: body(15.5).copyWith(height: 1.6)),
          ),
          if (m.kind == 'voice' || m.kind == 'video')
            SectionCard(
              icon: memoryIcon(m.kind),
              title: m.kind == 'voice' ? 'Recordings' : 'Videos',
              child: m.mediaPaths.isEmpty
                  ? const EmptyNote()
                  : Column(
                      children: [
                        for (final path in m.mediaPaths)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: IconBadge(memoryIcon(m.kind), size: 36),
                            title: Text(
                              path.split('/').last.replaceFirst(RegExp(r'^\d{10,}_'), ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: const Text('Saved in your family archive'),
                          ),
                      ],
                    ),
            ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Memory',
              back: true,
              trailing: _canDelete
                  ? IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: kMaroon),
                      onPressed: _delete,
                    )
                  : null,
            ),
            Expanded(child: SoftSwitcher(child: content)),
          ],
        ),
      ),
    );
  }
}
