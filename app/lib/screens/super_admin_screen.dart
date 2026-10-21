import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'ui.dart';

/// Super admin sees family accounts only: name, created date, active flag. Never the content.
class SuperAdminScreen extends StatefulWidget {
  final Future<void> Function() onSignOut;
  const SuperAdminScreen({super.key, required this.onSignOut});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  List<FamilySummary> _families = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final families = await guard(context, () => repo.listFamilies());
    if (!mounted) return;
    setState(() {
      _families = families ?? _families;
      _loading = false;
    });
  }

  Future<void> _setActive(FamilySummary f, bool active) async {
    if (!active) {
      final ok = await confirm(
        context,
        'Members of ${f.name} will not be able to open their family space until it is switched on again.',
        title: 'Deactivate this family?',
        yes: 'Deactivate',
      );
      if (!ok || !mounted) return;
    }
    final done = await guardOk(context, () => repo.setFamilyActive(f.id, active));
    if (done && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _families.where((f) => f.active).length;
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Super Admin',
              trailing: TextButton(
                onPressed: () => confirmSignOut(context, widget.onSignOut),
                child: const Text('Sign out'),
              ),
            ),
            Expanded(
              child: SoftSwitcher(
                child: _loading
                    ? const Loading(key: ValueKey('loading'))
                    : RefreshIndicator(
                        key: const ValueKey('content'),
                        color: kMaroon,
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 12, bottom: 32),
                          children: [
                            MaroonCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('FAMILY ACCOUNTS', style: eyebrow()),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${plural(_families.length, 'family', 'families')}, $active active',
                                    style: display(22, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            SoftCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const IconBadge(Icons.lock_outline, size: 40, circle: true),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Family content is private. Rituals, recipes, memories, songs and member '
                                      'lists are not visible here. You can only see each family account and '
                                      'switch it on or off.',
                                      style: body(13.5, color: kMuted).copyWith(height: 1.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_families.isEmpty)
                              const EmptyState(
                                icon: Icons.groups_outlined,
                                title: 'No families yet',
                                line: 'Family accounts will appear here as soon as the first one signs up.',
                              ),
                            for (var i = 0; i < _families.length; i++)
                              FadeSlideIn(index: i, child: _familyCard(_families[i])),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _familyCard(FamilySummary f) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          InitialAvatar(f.name, size: 48, muted: !f.active),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(19)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Pill('Created ${formatDate(f.createdAt)}', icon: Icons.event_outlined),
                    Pill(f.active ? 'Active' : 'Inactive', strong: f.active),
                  ],
                ),
              ],
            ),
          ),
          Switch(value: f.active, onChanged: (v) => _setActive(f, v)),
        ],
      ),
    );
  }
}
