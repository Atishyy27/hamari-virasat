import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'ui.dart';

/// "Our Family": the family name, its identity details and its members as plain cards.
/// There is no family tree: the client asked for the name and the members only.
class FamilyScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback? onFamilyChanged;

  const FamilyScreen({super.key, required this.user, this.onFamilyChanged});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  Family? _family;
  List<FamilyMember> _members = const [];
  bool _loading = true;

  bool get _isAdmin => widget.user.role == Role.familyAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final family = await guard(context, () => repo.myFamily());
    if (!mounted) return;
    final members = await guard(context, () => repo.listMembers());
    if (!mounted) return;
    setState(() {
      _family = family ?? _family;
      _members = members ?? _members;
      _loading = false;
    });
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) showInfo(context, 'Invite code copied');
  }

  Future<void> _editFamily() async {
    final family = _family;
    if (family == null) return;
    final name = TextEditingController(text: family.name);
    final gotra = TextEditingController(text: family.gotra);
    final kuldevi = TextEditingController(text: family.kuldevi);
    final kuldevta = TextEditingController(text: family.kuldevta);
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Family details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(name, 'Family name', hint: 'e.g. Sharma'),
              _dialogField(gotra, 'Surname / Gotra', hint: 'e.g. Mishra / Kashyap'),
              _dialogField(kuldevi, 'Kuldevi', hint: 'e.g. Vindhyavasini Mata'),
              _dialogField(kuldevta, 'Kuldevta', hint: 'e.g. Baba Vishwanath', last: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (save != true || !mounted) return;
    if (name.text.trim().isEmpty) {
      showError(context, 'Family name cannot be empty');
      return;
    }
    final updated = family.copyWith(
      name: name.text.trim(),
      gotra: gotra.text.trim(),
      kuldevi: kuldevi.text.trim(),
      kuldevta: kuldevta.text.trim(),
    );
    final ok = await guardOk(context, () => repo.saveFamily(updated));
    if (!ok || !mounted) return;
    await _load();
    widget.onFamilyChanged?.call();
  }

  Future<void> _editMember([FamilyMember? existing]) async {
    final familyId = _family?.id ?? widget.user.familyId;
    if (familyId == null) return;
    final name = TextEditingController(text: existing?.name ?? '');
    final relation = TextEditingController(text: existing?.relation ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(existing == null ? 'Add family member' : 'Edit member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(name, 'Name', autofocus: existing == null),
              _dialogField(relation, 'Relation', hint: 'e.g. Dadi, Mama'),
              _dialogField(phone, 'Phone (optional)', keyboard: TextInputType.phone, last: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (save != true || !mounted) return;
    if (name.text.trim().isEmpty) {
      showError(context, 'Member name cannot be empty');
      return;
    }
    final member = FamilyMember(
      id: existing?.id ?? newId(),
      familyId: familyId,
      name: name.text.trim(),
      relation: relation.text.trim(),
      phone: phone.text.trim(),
    );
    final ok = await guardOk(context, () => repo.saveMember(member));
    if (ok && mounted) await _load();
  }

  Future<void> _deleteMember(FamilyMember m) async {
    final ok = await confirm(
      context,
      '${m.name} will be removed from the family list.',
      title: 'Remove this member?',
      yes: 'Remove',
    );
    if (!ok || !mounted) return;
    final done = await guardOk(context, () => repo.deleteMember(m.id));
    if (done && mounted) await _load();
  }

  /// Admin actions for one member, opened by tapping their card.
  Future<void> _memberActions(FamilyMember m) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(m.name, style: display(20)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit details'),
              onTap: () => Navigator.pop(c, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: const Text('Remove from family'),
              onTap: () => Navigator.pop(c, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _editMember(m);
    if (action == 'delete') await _deleteMember(m);
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool autofocus = false,
    bool last = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.words,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final family = _family;
    final Widget content;
    if (_loading) {
      content = const Loading();
    } else if (family == null) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.home_outlined,
            title: 'No family yet',
            line: 'We could not find a family for this account.',
            action: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ),
        ],
      );
    } else {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          SoftCard(
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
                          Text('FAMILY NAME', style: eyebrow()),
                          const SizedBox(height: 6),
                          Text(family.name, style: display(26)),
                        ],
                      ),
                    ),
                    if (_isAdmin)
                      TextButton(onPressed: _editFamily, child: const Text('Edit')),
                  ],
                ),
                const SizedBox(height: 14),
                _detail(Icons.badge_outlined, 'Surname / Gotra', family.gotra),
                _detail(Icons.local_florist_outlined, 'Kuldevi', family.kuldevi),
                _detail(Icons.temple_hindu_outlined, 'Kuldevta', family.kuldevta),
              ],
            ),
          ),
          if (family.inviteCode.isNotEmpty)
            SoftCard(
              child: Row(
                children: [
                  const IconBadge(Icons.key_outlined, size: 44, circle: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INVITE CODE', style: eyebrow()),
                        const SizedBox(height: 4),
                        Text(
                          family.inviteCode,
                          style: body(20, weight: 700).copyWith(letterSpacing: 3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Relatives enter this code to join the family.',
                          style: body(12.5, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy invite code',
                    icon: const Icon(Icons.copy_outlined, color: kMaroon),
                    onPressed: () => _copyCode(family.inviteCode),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Row(
              children: [
                Expanded(child: Text('Members', style: display(22))),
                Text(plural(_members.length, 'member', 'members'), style: body(13, color: kMuted)),
              ],
            ),
          ),
          if (!_isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                'View only. The family admin adds and edits members.',
                style: body(12.5, color: kMuted),
              ),
            ),
          if (_members.isEmpty)
            const EmptyState(
              icon: Icons.people_outline,
              title: 'No members yet',
              line: 'Add parents, grandparents, brothers and sisters so the whole family is here.',
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: LayoutBuilder(
                builder: (context, box) {
                  final width = (box.maxWidth - 14) / 2;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (var i = 0; i < _members.length; i++)
                        SizedBox(
                          width: width,
                          child: FadeSlideIn(
                            key: ValueKey('member-${_members[i].id}'),
                            index: i,
                            child: _memberCard(_members[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: OutlinedButton.icon(
                onPressed: () => _editMember(),
                icon: const Icon(Icons.add),
                label: const Text('Add Family Member'),
              ),
            ),
        ],
      );
    }
    return Column(
      children: [
        const ScreenHeader(title: 'Our Family'),
        Expanded(child: RefreshIndicator(color: kMaroon, onRefresh: _load, child: content)),
      ],
    );
  }

  Widget _memberCard(FamilyMember m) {
    final you = m.name.trim().toLowerCase() == widget.user.name.trim().toLowerCase();
    return SoftCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
      onTap: _isAdmin ? () => _memberActions(m) : null,
      child: Column(
        children: [
          InitialAvatar(m.name, size: 56),
          const SizedBox(height: 12),
          Text(
            m.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: body(14.5, weight: 600),
          ),
          const SizedBox(height: 4),
          Text(
            you ? 'You' : (m.relation.isEmpty ? 'Family' : m.relation),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: body(12.5, color: kMuted),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kMaroon),
          const SizedBox(width: 10),
          SizedBox(width: 118, child: Text(label, style: body(13.5, color: kMuted))),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not added yet' : value,
              style: body(13.5, weight: value.isEmpty ? 400 : 600, color: value.isEmpty ? kMuted : kInk),
            ),
          ),
        ],
      ),
    );
  }
}
