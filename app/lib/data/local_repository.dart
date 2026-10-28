import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'repository.dart';

/// On-device implementation for the demo build. One JSON blob in shared_preferences.
/// It enforces the same access rules as the real backend so the demo behaves the same.
class LocalRepository implements Repository {
  static const _key = 'hv_local_db_v3'; // v3 added orders and ritual status; a new key reseeds the demo

  late SharedPreferences _prefs;
  late Map<String, dynamic> _db;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _db = _seed();
      await _save();
    } else {
      _db = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (_listAllAccounts()) await _save();
    }
  }

  /// Accounts made before members were linked to the family list: put them on it.
  bool _listAllAccounts() {
    final members = _rows('members');
    var changed = false;
    for (final u in _rows('users')) {
      final familyId = u['family_id'] as String?;
      if (familyId == null || members.any((m) => m['id'] == u['id'])) continue;
      changed = true;
      // The admin may already have typed this person in: take over that entry.
      final name = ((u['full_name'] ?? '') as String).trim().toLowerCase();
      final typed = members.indexWhere((m) =>
          m['family_id'] == familyId &&
          !_rows('users').any((a) => a['id'] == m['id']) &&
          (m['name'] as String).trim().toLowerCase() == name);
      if (typed >= 0) {
        members[typed] = {...members[typed], 'id': u['id']};
        continue;
      }
      members.add(FamilyMember(
        id: u['id'] as String,
        familyId: familyId,
        name: (u['full_name'] ?? '') as String,
        phone: _phoneOf((u['email'] ?? '') as String),
      ).toJson());
    }
    if (changed) _put('members', members);
    return changed;
  }

  /// The phone number behind a phone login, which signs in as p<digits>@example.com.
  static String _phoneOf(String email) =>
      RegExp(r'^p(\d{10})@example\.com$').firstMatch(email)?.group(1) ?? '';

  static String _last10(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    return d.length > 10 ? d.substring(d.length - 10) : d;
  }

  Plan _planOf(String familyId) =>
      _rows('families').where((f) => f['id'] == familyId).map(Family.fromJson).firstOrNull?.plan ??
      Plan.basic;

  Future<void> _save() => _prefs.setString(_key, jsonEncode(_db));

  List<Map<String, dynamic>> _rows(String table) =>
      ((_db[table] ?? <dynamic>[]) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  void _put(String table, List<Map<String, dynamic>> rows) => _db[table] = rows;

  // ---- access rules ----

  AppUser? _me() {
    final id = _db['session'] as String?;
    if (id == null) return null;
    for (final u in _rows('users')) {
      if (u['id'] == id) return AppUser.fromJson(u);
    }
    return null;
  }

  /// Family content is for people inside a family. A super admin never gets through here.
  AppUser _requireFamilyUser() {
    final u = _me();
    if (u == null) throw StateError('Not signed in');
    if (u.role == Role.superAdmin) throw StateError('Super admin cannot view family data');
    if (u.familyId == null) throw StateError('You are not part of a family');
    return u;
  }

  AppUser _requireFamilyAdmin() {
    final u = _requireFamilyUser();
    if (u.role != Role.familyAdmin) throw StateError('Only the family admin can do this');
    return u;
  }

  void _requireSuperAdmin() {
    final u = _me();
    if (u == null || u.role != Role.superAdmin) throw StateError('Super admin only');
  }

  // ---- auth ----

  @override
  Future<AppUser?> currentUser() async => _me();

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    var e = email.trim().toLowerCase();
    var pass = password;
    // The quick demo logins of the real backend map onto the seeded local users.
    const demo = {
      'demo@example.com': 'admin@demo.in',
      'member@example.com': 'member@demo.in',
      'super@example.com': 'super@demo.in',
    };
    if (demo.containsKey(e) && password == 'Virasat@2026') {
      e = demo[e]!;
      pass = 'demo123';
    }
    for (final u in _rows('users')) {
      if (u['email'] == e && u['password'] == pass) {
        final user = AppUser.fromJson(u);
        if (user.familyId != null && !_familyActive(user.familyId!)) {
          throw StateError('This family account is deactivated');
        }
        _db['session'] = u['id'];
        await _save();
        return user;
      }
    }
    throw StateError('Wrong email or password');
  }

  bool _familyActive(String familyId) {
    for (final f in _rows('families')) {
      if (f['id'] == familyId) return (f['active'] ?? true) as bool;
    }
    return false;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    String? familyName,
    String? inviteCode,
  }) async {
    final hasFamily = familyName != null && familyName.trim().isNotEmpty;
    final hasCode = inviteCode != null && inviteCode.trim().isNotEmpty;
    if (hasFamily == hasCode) {
      throw ArgumentError('Give a family name or an invite code, exactly one');
    }
    final e = email.trim().toLowerCase();
    final users = _rows('users');
    if (users.any((u) => u['email'] == e)) throw StateError('Email already registered');

    final families = _rows('families');
    late String familyId;
    late Role role;
    if (hasFamily) {
      familyId = newId();
      role = Role.familyAdmin;
      families.add({
        ...Family(id: familyId, name: familyName.trim(), inviteCode: _newInviteCode()).toJson(),
        'active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      _put('families', families);
    } else {
      final code = inviteCode!.trim().toUpperCase();
      final match = families.where((f) => f['invite_code'] == code).toList();
      if (match.isEmpty) throw StateError('Invite code not found');
      familyId = match.first['id'] as String;
      role = Role.member;
    }

    final user =
        AppUser(id: newId(), name: name.trim(), email: e, role: role, familyId: familyId);

    // Everyone who joins is on the family list. A name the admin already added with this
    // phone number becomes theirs; otherwise they take a new place, if the plan has one.
    final members = _rows('members');
    final accountIds = users.map((u) => u['id']).toSet();
    final phone = _phoneOf(e);
    final claim = phone.isEmpty
        ? -1
        : members.indexWhere((m) =>
            m['family_id'] == familyId &&
            !accountIds.contains(m['id']) &&
            _last10((m['phone'] ?? '') as String) == phone);
    if (claim >= 0) {
      members[claim] = {...members[claim], 'id': user.id, 'phone': phone};
    } else {
      final plan = _planOf(familyId);
      if (members.where((m) => m['family_id'] == familyId).length >= plan.memberLimit) {
        throw StateError(
            "This family's ${plan.label} plan is full (${plan.memberLimit} members). Ask your family admin to upgrade.");
      }
      members.add(FamilyMember(id: user.id, familyId: familyId, name: user.name, phone: phone).toJson());
    }

    users.add({...user.toJson(), 'password': password});
    _put('users', users);
    _put('members', members);
    _db['session'] = user.id;
    await _save();
    return user;
  }

  String _newInviteCode() {
    final n = DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase();
    return n.substring(n.length - 6);
  }

  @override
  Future<void> signOut() async {
    _db.remove('session');
    await _save();
  }

  // ---- family ----

  @override
  Future<Family?> myFamily() async {
    final u = _requireFamilyUser();
    for (final f in _rows('families')) {
      if (f['id'] == u.familyId) return Family.fromJson(f);
    }
    return null;
  }

  @override
  Future<void> saveFamily(Family family) async {
    final u = _requireFamilyAdmin();
    final families = _rows('families');
    final i = families.indexWhere((f) => f['id'] == u.familyId);
    if (i < 0) throw StateError('Family not found');
    // Only the editable fields; id, invite code and active stay as they are.
    families[i] = {
      ...families[i],
      'name': family.name,
      'gotra': family.gotra,
      'kuldevi': family.kuldevi,
      'kuldevta': family.kuldevta,
    };
    _put('families', families);
    await _save();
  }

  // ---- members ----

  @override
  Future<List<FamilyMember>> listMembers() async {
    final u = _requireFamilyUser();
    return _rows('members')
        .where((m) => m['family_id'] == u.familyId)
        .map(FamilyMember.fromJson)
        .toList();
  }

  @override
  Future<void> saveMember(FamilyMember member) async {
    final u = _requireFamilyAdmin();
    final row = {...member.toJson(), 'family_id': u.familyId};
    final members = _rows('members');
    final i = members.indexWhere((m) => m['id'] == member.id && m['family_id'] == u.familyId);
    if (i < 0) {
      final limit = _planOf(u.familyId!).memberLimit;
      if (members.where((m) => m['family_id'] == u.familyId).length >= limit) {
        throw StateError('Your plan allows up to $limit members');
      }
    }
    if (i >= 0) {
      members[i] = row;
    } else {
      members.add(row);
    }
    _put('members', members);
    await _save();
  }

  @override
  Future<void> deleteMember(String id) async {
    final u = _requireFamilyAdmin();
    final users = _rows('users');
    final account = users.where((a) => a['id'] == id && a['family_id'] == u.familyId).firstOrNull;
    if (account != null && roleFromString(account['role'] as String?) == Role.familyAdmin) {
      throw StateError('The family admin cannot be removed');
    }
    final members = _rows('members')
      ..removeWhere((m) => m['id'] == id && m['family_id'] == u.familyId);
    _put('members', members);
    // A member who joined loses the account too, so the number can join a family afresh.
    if (account != null) _put('users', users..remove(account));
    await _save();
  }

  // ---- catalogue ----

  @override
  Future<List<RitualCategory>> listCategories() async {
    final u = _requireFamilyUser();
    return _rows('categories')
        .where((c) => c['family_id'] == null || c['family_id'] == u.familyId)
        .map(RitualCategory.fromJson)
        .toList();
  }

  @override
  Future<void> addCustomCategory(String name) async {
    final u = _requireFamilyUser();
    final n = name.trim();
    if (n.isEmpty) return;
    final cats = _rows('categories');
    cats.add({'id': newId(), 'name': n, 'phases': <String>[], 'family_id': u.familyId});
    _put('categories', cats);
    await _save();
  }

  // ---- rituals ----

  @override
  Future<List<Ritual>> listRituals() async {
    final u = _requireFamilyUser();
    final list = _rows('rituals')
        .where((r) => r['family_id'] == u.familyId)
        .map(Ritual.fromJson)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Ritual?> getRitual(String id) async {
    final u = _requireFamilyUser();
    for (final r in _rows('rituals')) {
      if (r['id'] == id && r['family_id'] == u.familyId) return Ritual.fromJson(r);
    }
    return null;
  }

  @override
  Future<void> saveRitual(Ritual ritual) async {
    final u = _requireFamilyUser();
    final row = {...ritual.toJson(), 'family_id': u.familyId};
    final rituals = _rows('rituals');
    final i = rituals.indexWhere((r) => r['id'] == ritual.id);
    if (i >= 0) {
      if (rituals[i]['family_id'] != u.familyId) throw StateError('Not your family\'s ritual');
      rituals[i] = row;
    } else {
      rituals.add(row);
    }
    _put('rituals', rituals);
    await _save();
  }

  @override
  Future<void> deleteRitual(String id) async {
    final u = _requireFamilyUser();
    final rituals = _rows('rituals')
      ..removeWhere((r) => r['id'] == id && r['family_id'] == u.familyId);
    _put('rituals', rituals);
    await _save();
  }

  @override
  Future<String> uploadAudio({required String ritualId, required String localPath}) async {
    _requireFamilyUser();
    return localPath; // nothing to upload on device
  }

  @override
  Future<String> uploadRitualPhoto({required String ritualId, required String localPath}) async {
    _requireFamilyUser();
    return localPath; // nothing to upload on device
  }

  // ---- orders, waitlist, enquiries ----

  @override
  Future<RitualOrder> createOrder(List<String> ritualKeys, {int pricePerRitual = 299}) async {
    final u = _requireFamilyUser();
    if (ritualKeys.isEmpty) throw StateError('Choose at least one ritual');
    final orders = _rows('orders');
    final returning = orders.any((o) => o['family_id'] == u.familyId && o['status'] == 'paid');
    final gross = ritualKeys.length * pricePerRitual;
    final discount = returning ? (gross * 0.10).round() : 0;
    final order = RitualOrder(
      id: newId(),
      familyId: u.familyId!,
      ritualKeys: ritualKeys,
      amount: gross - discount,
      discount: discount,
      createdAt: DateTime.now(),
    );
    orders.add(order.toJson());
    _put('orders', orders);
    await _save();
    return order;
  }

  @override
  Future<List<RitualOrder>> listOrders() async {
    final u = _requireFamilyUser();
    final list = _rows('orders')
        .where((o) => o['family_id'] == u.familyId)
        .map(RitualOrder.fromJson)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> joinWaitlist(String ritualKey) async {
    final u = _me();
    if (u == null) throw StateError('Not signed in');
    final rows = _rows('waitlist');
    if (rows.any((w) => w['user_id'] == u.id && w['ritual_key'] == ritualKey)) return;
    rows.add({
      ...WaitlistEntry(id: newId(), ritualKey: ritualKey, createdAt: DateTime.now()).toJson(),
      'user_id': u.id,
    });
    _put('waitlist', rows);
    await _save();
  }

  @override
  Future<List<WaitlistEntry>> listWaitlist() async {
    final u = _me();
    if (u == null) throw StateError('Not signed in');
    return _rows('waitlist').where((w) => w['user_id'] == u.id).map(WaitlistEntry.fromJson).toList();
  }

  @override
  Future<void> sendEnquiry(Enquiry enquiry) async {
    final u = _me();
    if (u == null) throw StateError('Not signed in');
    final rows = _rows('enquiries')..add({...enquiry.toJson(), 'user_id': u.id});
    _put('enquiries', rows);
    await _save();
  }

  @override
  Future<List<Enquiry>> listEnquiries() async {
    final u = _me();
    if (u == null) throw StateError('Not signed in');
    return _rows('enquiries').where((e) => e['user_id'] == u.id).map(Enquiry.fromJson).toList();
  }

  // ---- memories ----

  @override
  Future<List<Memory>> listMemories() async {
    final u = _requireFamilyUser();
    final list = _rows('memories')
        .where((m) => m['family_id'] == u.familyId)
        .map(Memory.fromJson)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Memory?> getMemory(String id) async {
    final u = _requireFamilyUser();
    for (final m in _rows('memories')) {
      if (m['id'] == id && m['family_id'] == u.familyId) return Memory.fromJson(m);
    }
    return null;
  }

  @override
  Future<void> saveMemory(Memory memory) async {
    final u = _requireFamilyUser();
    final row = {...memory.toJson(), 'family_id': u.familyId};
    final memories = _rows('memories');
    final i = memories.indexWhere((m) => m['id'] == memory.id);
    if (i >= 0) {
      if (memories[i]['family_id'] != u.familyId) throw StateError('Not your family\'s memory');
      if (memories[i]['created_by'] != u.id) throw StateError('Only the author can edit this memory');
      memories[i] = row;
    } else {
      row['created_by'] = u.id;
      row['created_by_name'] = u.name;
      memories.add(row);
    }
    _put('memories', memories);
    await _save();
  }

  @override
  Future<void> deleteMemory(String id) async {
    final u = _requireFamilyUser();
    final memories = _rows('memories');
    final i = memories.indexWhere((m) => m['id'] == id && m['family_id'] == u.familyId);
    if (i < 0) return;
    if (memories[i]['created_by'] != u.id && u.role != Role.familyAdmin) {
      throw StateError('Only the author or the family admin can delete this memory');
    }
    memories.removeAt(i);
    _put('memories', memories);
    await _save();
  }

  @override
  Future<String> uploadMemoryMedia({required String memoryId, required String localPath}) async {
    _requireFamilyUser();
    return localPath; // nothing to upload on device
  }

  @override
  Future<String> mediaUrl(String path) async => path;

  // ---- super admin: accounts only ----

  @override
  Future<List<FamilySummary>> listFamilies() async {
    _requireSuperAdmin();
    // FamilySummary.fromJson reads id, name, active, created_at and nothing else.
    return _rows('families').map(FamilySummary.fromJson).toList();
  }

  @override
  Future<void> setFamilyActive(String familyId, bool active) async {
    _requireSuperAdmin();
    final families = _rows('families');
    final i = families.indexWhere((f) => f['id'] == familyId);
    if (i < 0) throw StateError('Family not found');
    families[i] = {...families[i], 'active': active};
    _put('families', families);
    await _save();
  }

  // ---- first-run data ----

  Map<String, dynamic> _seed() {
    const fam = 'fam_demo';
    final now = DateTime.now();
    Map<String, dynamic> user(String id, String name, String email, Role role, String? familyId) => {
          ...AppUser(id: id, name: name, email: email, role: role, familyId: familyId).toJson(),
          'password': 'demo123',
        };
    Map<String, dynamic> cat(String id, String name, [List<String> phases = const []]) =>
        {'id': id, 'name': name, 'phases': phases, 'family_id': null};

    return {
      'users': [
        user('u_admin', 'Ramesh Mishra', 'admin@demo.in', Role.familyAdmin, fam),
        user('u_member', 'Anita Mishra', 'member@demo.in', Role.member, fam),
        user('u_super', 'Super Admin', 'super@demo.in', Role.superAdmin, null),
      ],
      'families': [
        {
          ...const Family(
            id: fam,
            name: 'Mishra Parivar',
            gotra: 'Kashyap',
            kuldevi: 'Vindhyavasini Mata',
            kuldevta: 'Baba Vishwanath',
            inviteCode: 'MISHRA',
            plan: Plan.pro,
          ).toJson(),
          'active': true,
          'created_at': now.toIso8601String(),
        },
      ],
      'members': [
        const FamilyMember(id: 'u_admin', familyId: fam, name: 'Ramesh Mishra').toJson(),
        const FamilyMember(id: 'm2', familyId: fam, name: 'Sushila Mishra').toJson(),
        const FamilyMember(id: 'u_member', familyId: fam, name: 'Anita Mishra').toJson(),
        const FamilyMember(id: 'm4', familyId: fam, name: 'Suresh Tiwari').toJson(),
      ],
      'categories': [
        cat('c1', 'Child Birth (Sanskara)'),
        cat('c2', 'Annaprasan'),
        cat('c3', 'Mundan'),
        cat('c4', 'Vidya Arambh'),
        cat('c5', 'Puberty or Reaching to the Age Ritual'),
        cat('c6', 'Boy Wedding (Var Paksha)', const [
          'Shagun',
          'Haldi',
          'Tilak',
          'Sangeet',
          'Madwa',
          'Matkore',
          'Kohbar Art',
          'Gidhari',
          'Matri Pooja',
          'Barat Prasthan',
        ]),
        cat('c7', 'Girl Wedding (Kanya Paksha)'),
        cat('c8', 'Death Ritual (Antyesti Sanskar)'),
      ],
      'rituals': [
        Ritual(
          id: 'r1',
          familyId: fam,
          title: 'Chatti / Shashti Puja',
          category: 'Child Birth (Sanskara)',
          templateKey: 'chatti',
          status: kStatusApproved,
          samagri: 'Haldi, kumkum, akshat\nNaye kapde\nDiya aur ghee',
          steps: 'Chhathe din shishu ko snan\nKuldevi ki puja\nNaamkaran',
          relativeRoles: 'Mama: naye kapde aur shagun lata hai\nDadi: puja karwati hai',
          recipes: const [
            Recipe(
              id: 'rc1',
              name: 'Gud ki Kheer',
              ingredients: 'Chawal, doodh, gud, elaichi',
              method: 'Chawal ko doodh me dheemi aanch par pakayein, aanch se utaar kar gud milayein.',
            ),
          ],
          createdAt: now,
        ).toJson(),
        Ritual(
          id: 'r2',
          familyId: fam,
          title: 'Haldi',
          category: 'Boy Wedding (Var Paksha)',
          phase: 'Haldi',
          samagri: 'Haldi, sarson ka tel, doob, peele kapde',
          steps: 'Paanch suhagin haldi chadhati hain\nGeet gaye jaate hain',
          relativeRoles: 'Bua: pehli haldi lagati hai',
          createdAt: now.subtract(const Duration(days: 1)),
        ).toJson(),
        // Started from a paid catalogue ritual and still being filled in.
        Ritual(
          id: 'r3',
          familyId: fam,
          title: 'Karwa Chauth',
          category: 'Festival',
          templateKey: 'karwa_chauth',
          status: kStatusDraft,
          samagri: 'Karwa, chalni, diya\nSindoor, chudi, bindi',
          sections: const {'Sargi details': 'Saas subah 4 baje sargi deti hain: feni, mathri, phal aur mewa.'},
          createdAt: now.subtract(const Duration(hours: 6)),
        ).toJson(),
      ],
      'orders': [
        RitualOrder(
          id: 'o1',
          familyId: fam,
          ritualKeys: const ['chatti', 'karwa_chauth'],
          amount: 598,
          createdAt: now.subtract(const Duration(days: 3)),
        ).toJson(),
      ],
      'memories': [
        Memory(
          id: 'mem1',
          familyId: fam,
          kind: 'photo',
          title: 'Diwali at Dadi\'s old home',
          story: 'The whole family around one table, diyas in every window and Dadi\'s kheer on the stove.',
          tags: const ['Diwali', 'Dadi', '1987'],
          mediaPaths: const ['asset:assets/images/memory_diwali.png'],
          createdBy: 'u_admin',
          createdByName: 'Ramesh Mishra',
          createdAt: now.subtract(const Duration(days: 2)),
        ).toJson(),
        Memory(
          id: 'mem2',
          familyId: fam,
          kind: 'story',
          title: 'How Dadaji chose our family name',
          story: 'Dadaji used to tell this every Holi. When he moved to the city for work, '
              'the clerk asked for a surname and he gave the name of our village.',
          tags: const ['Dadaji', 'Holi'],
          createdBy: 'u_member',
          createdByName: 'Anita Mishra',
          createdAt: now.subtract(const Duration(days: 5)),
        ).toJson(),
      ],
    };
  }
}
