import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'info_screens.dart';
import 'ui.dart';

/// Profile: who you are, the family's numbers and a few plain pages.
class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenFamily;

  const ProfileScreen({super.key, required this.user, required this.onSignOut, required this.onOpenFamily});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Family? _family;
  int _memories = 0;
  int _members = 0;
  int _rituals = 0;

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
    final members = await guard(context, () => repo.listMembers());
    if (!mounted) return;
    final rituals = await guard(context, () => repo.listRituals());
    if (!mounted) return;
    setState(() {
      _family = family ?? _family;
      _memories = memories?.length ?? _memories;
      _members = members?.length ?? _members;
      _rituals = rituals?.length ?? _rituals;
    });
  }

  String get _familyLine {
    final name = (_family?.name ?? '').trim();
    if (name.isEmpty) return 'Your family';
    final low = name.toLowerCase();
    return (low.contains('family') || low.contains('parivar')) ? name : '$name Family';
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.user.role == Role.familyAdmin;
    return Column(
      children: [
        const ScreenHeader(title: 'Profile'),
        Expanded(
          child: RefreshIndicator(
            color: kMaroon,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 12, bottom: 28),
              children: [
                SoftCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      InitialAvatar(widget.user.name, size: 72),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name.isEmpty ? 'Family member' : widget.user.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: display(22),
                            ),
                            const SizedBox(height: 4),
                            Text(_familyLine, style: body(13.5, color: kMuted)),
                            const SizedBox(height: 8),
                            Pill(admin ? 'Family Admin' : 'Member', strong: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                MaroonCard(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  child: Row(
                    children: [
                      _stat('$_memories', 'Memories'),
                      _stat('$_members', 'Members'),
                      _stat('$_rituals', 'Rituals'),
                    ],
                  ),
                ),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _row(
                        Icons.people_outline,
                        'Family & members',
                        trailing: plural(_members, 'member', 'members'),
                        onTap: widget.onOpenFamily,
                      ),
                      const Divider(height: 1, color: kLine),
                      _row(
                        Icons.shield_outlined,
                        'Privacy & permissions',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                        ),
                      ),
                      const Divider(height: 1, color: kLine),
                      _row(
                        Icons.help_outline,
                        'Help for elders',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        ),
                      ),
                      const Divider(height: 1, color: kLine),
                      _row(
                        Icons.spa_outlined,
                        'About Hamari Virasat',
                        trailing: 'Pricing, FAQ, contact',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InfoHubScreen(user: widget.user)),
                        ),
                      ),
                      const Divider(height: 1, color: kLine),
                      _row(
                        Icons.logout,
                        'Sign out',
                        onTap: () => confirmSignOut(context, widget.onSignOut),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text('HAMARI VIRASAT • Version 1.0', style: body(11.5, color: kMuted)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: display(24, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: body(12, color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, {String? trailing, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: kMaroon, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: body(15, weight: 600))),
            if (trailing != null) Text(trailing, style: body(13, color: kMuted)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: kMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Who can see what, in plain words.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'Privacy & permissions',
      items: [
        (
          Icons.lock_outline,
          'Only your family sees your family',
          'Rituals, recipes, songs, photographs, stories and the member list are visible only to people '
              'who have joined your family with its invite code.',
        ),
        (
          Icons.admin_panel_settings_outlined,
          'The platform admin cannot read it',
          'The Hamari Virasat super admin can see that your family account exists and switch it on or '
              'off. They cannot open any of your family content.',
        ),
        (
          Icons.manage_accounts_outlined,
          'What the family admin can do',
          'The family admin edits the family details, adds and removes members and can delete any memory. '
              'Every member can add rituals and memories.',
        ),
        (
          Icons.key_outlined,
          'Share the invite code with care',
          'Anyone with the code can join your family. Give it only to relatives.',
        ),
      ],
    );
  }
}

/// A short how-to in large type.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'Help for elders',
      large: true,
      items: [
        (
          Icons.add_circle_outline,
          'To save a memory',
          'Press the round + button at the bottom. Choose Photo, Voice or Story. Give it a name and press '
              'Preserve This Memory.',
        ),
        (
          Icons.mic_none_outlined,
          'To keep a song or a voice',
          'Record it on your phone first. Then press +, choose Voice and pick the recording.',
        ),
        (
          Icons.menu_book_outlined,
          'To read what the family saved',
          'Press Book at the bottom. Open Rituals, Recipes, Stories or Photo Albums.',
        ),
        (
          Icons.people_outline,
          'To see the family',
          'Press Family at the bottom to see everyone in the family.',
        ),
        (
          Icons.call_outlined,
          'If you are stuck',
          'Ask a younger family member, or the family admin, to sit with you once. It gets easy quickly.',
        ),
      ],
    );
  }
}

class _InfoPage extends StatelessWidget {
  final String title;
  final bool large;
  final List<(IconData, String, String)> items;
  const _InfoPage({required this.title, required this.items, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: title, back: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 28),
                children: [
                  for (final (icon, heading, text) in items)
                    SoftCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconBadge(icon, size: large ? 50 : 42, circle: true),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(heading, style: display(large ? 21 : 18)),
                                const SizedBox(height: 6),
                                Text(
                                  text,
                                  style: body(large ? 17 : 14.5, color: large ? kInk : kMuted).copyWith(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
