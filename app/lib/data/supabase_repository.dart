import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'repository.dart';

/// Real backend. Access rules live in the database (row level security in supabase/schema.sql),
/// not here: this class only asks, the database decides what comes back.
class SupabaseRepository implements Repository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _bucket = 'ritual-audio';
  static const _memoryBucket = 'memories';

  List<Map<String, dynamic>> _list(dynamic data) =>
      ((data ?? const []) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<AppUser> _me() async {
    final u = await currentUser();
    if (u == null) throw StateError('Not signed in');
    return u;
  }

  Future<String> _myFamilyId() async {
    final u = await _me();
    if (u.familyId == null) throw StateError('You are not part of a family');
    return u.familyId!;
  }

  // ---- auth ----

  @override
  Future<AppUser?> currentUser() async {
    final authUser = _db.auth.currentUser;
    if (authUser == null) return null;
    final row = await _db.from('profiles').select().eq('id', authUser.id).maybeSingle();
    if (row == null) return null;
    return AppUser.fromJson({...row, 'email': row['email'] ?? authUser.email ?? ''});
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await _db.auth.signInWithPassword(email: email.trim(), password: password);
    final user = await currentUser();
    if (user == null) {
      // The login exists but family setup never finished. Treated as "no account yet"
      // so the app offers the setup step again; signUp below picks the login back up.
      await _db.auth.signOut();
      throw StateError('Wrong email or password');
    }
    return user;
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
    try {
      await _db.auth.signUp(email: email.trim(), password: password);
    } on AuthException catch (e) {
      // A login left over from an unfinished setup: sign in to it and carry on.
      if (!e.message.toLowerCase().contains('already')) rethrow;
      await _db.auth.signInWithPassword(email: email.trim(), password: password);
    }
    // With "Confirm email" switched on in Supabase, sign up returns no session, so the
    // RPCs below (which need a signed-in user) would fail.
    if (_db.auth.currentUser == null) {
      throw StateError(
          'Sign up gave no session: turn off email confirmation in Supabase Auth settings');
    }
    if (hasFamily) {
      await _db.rpc('register_family',
          params: {'p_full_name': name.trim(), 'p_family_name': familyName.trim()});
    } else {
      await _db.rpc('join_family',
          params: {'p_full_name': name.trim(), 'p_invite_code': inviteCode!.trim()});
    }
    return _me();
  }

  @override
  Future<void> signOut() => _db.auth.signOut();

  // ---- family ----

  @override
  Future<Family?> myFamily() async {
    final familyId = await _myFamilyId();
    final row = await _db.from('families').select().eq('id', familyId).maybeSingle();
    return row == null ? null : Family.fromJson(row);
  }

  @override
  Future<void> saveFamily(Family family) async {
    final familyId = await _myFamilyId();
    await _db.from('families').update({
      'name': family.name,
      'gotra': family.gotra,
      'kuldevi': family.kuldevi,
      'kuldevta': family.kuldevta,
    }).eq('id', familyId);
  }

  // ---- members ----

  @override
  Future<List<FamilyMember>> listMembers() async {
    final familyId = await _myFamilyId();
    final rows = await _db.from('family_members').select().eq('family_id', familyId);
    return _list(rows).map(FamilyMember.fromJson).toList();
  }

  @override
  Future<void> saveMember(FamilyMember member) async {
    final familyId = await _myFamilyId();
    await _db.from('family_members').upsert({...member.toJson(), 'family_id': familyId});
  }

  @override
  Future<void> deleteMember(String id) async {
    await _db.from('family_members').delete().eq('id', id);
  }

  // ---- catalogue ----

  @override
  Future<List<RitualCategory>> listCategories() async {
    // No filter here on purpose: the database returns built-in rows (family_id null)
    // plus this family's own, and nothing else.
    final rows = await _db.from('ritual_categories').select();
    return _list(rows).map(RitualCategory.fromJson).toList();
  }

  @override
  Future<void> addCustomCategory(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final familyId = await _myFamilyId();
    await _db
        .from('ritual_categories')
        .insert({'id': newId(), 'name': n, 'phases': <String>[], 'family_id': familyId});
  }

  // ---- rituals ----

  @override
  Future<List<Ritual>> listRituals() async {
    final familyId = await _myFamilyId();
    final rows = await _db
        .from('rituals')
        .select('*, recipes(*)')
        .eq('family_id', familyId)
        .order('created_at', ascending: false);
    return _list(rows).map(Ritual.fromJson).toList();
  }

  @override
  Future<Ritual?> getRitual(String id) async {
    final row = await _db.from('rituals').select('*, recipes(*)').eq('id', id).maybeSingle();
    return row == null ? null : Ritual.fromJson(row);
  }

  @override
  Future<void> saveRitual(Ritual ritual) async {
    final familyId = await _myFamilyId();
    // Recipes are their own table, so they come out of the ritual row.
    final row = {...ritual.toJson(), 'family_id': familyId}..remove('recipes');
    await _db.from('rituals').upsert(row);
    await _db.from('recipes').delete().eq('ritual_id', ritual.id);
    for (final r in ritual.recipes) {
      await _db
          .from('recipes')
          .insert({...r.toJson(), 'ritual_id': ritual.id, 'family_id': familyId});
    }
  }

  @override
  Future<void> deleteRitual(String id) async {
    await _db.from('recipes').delete().eq('ritual_id', id);
    await _db.from('rituals').delete().eq('id', id);
  }

  @override
  Future<String> uploadAudio({required String ritualId, required String localPath}) async {
    final familyId = await _myFamilyId();
    final fileName = localPath.split('/').last;
    final path = '$familyId/$ritualId/$fileName';
    await _db.storage.from(_bucket).upload(path, File(localPath));
    return path;
  }

  @override
  Future<String> uploadRitualPhoto({required String ritualId, required String localPath}) async {
    final familyId = await _myFamilyId();
    final raw = localPath.split('/').last;
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    // Lives in the memories bucket so mediaUrl() can sign it; the first segment is the family.
    final path = '$familyId/rituals/$ritualId/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await _db.storage.from(_memoryBucket).upload(path, File(localPath));
    return path;
  }

  // ---- orders, waitlist, enquiries ----

  @override
  Future<RitualOrder> createOrder(List<String> ritualKeys, {int pricePerRitual = 299}) async {
    final familyId = await _myFamilyId();
    if (ritualKeys.isEmpty) throw StateError('Choose at least one ritual');
    final earlier = await _db
        .from('ritual_orders')
        .select('id')
        .eq('family_id', familyId)
        .eq('status', 'paid')
        .limit(1);
    final gross = ritualKeys.length * pricePerRitual;
    final discount = _list(earlier).isNotEmpty ? (gross * 0.10).round() : 0;
    final order = RitualOrder(
      id: newId(),
      familyId: familyId,
      ritualKeys: ritualKeys,
      amount: gross - discount,
      discount: discount,
      createdAt: DateTime.now(),
    );
    await _db.from('ritual_orders').insert(order.toJson());
    return order;
  }

  @override
  Future<List<RitualOrder>> listOrders() async {
    final familyId = await _myFamilyId();
    final rows = await _db
        .from('ritual_orders')
        .select()
        .eq('family_id', familyId)
        .order('created_at', ascending: false);
    return _list(rows).map(RitualOrder.fromJson).toList();
  }

  @override
  Future<void> joinWaitlist(String ritualKey) async {
    final me = await _me();
    final mine = await _db
        .from('waitlist')
        .select('id')
        .eq('user_id', me.id)
        .eq('ritual_key', ritualKey)
        .limit(1);
    if (_list(mine).isNotEmpty) return;
    await _db.from('waitlist').insert({
      ...WaitlistEntry(id: newId(), ritualKey: ritualKey, createdAt: DateTime.now()).toJson(),
      'family_id': me.familyId,
    });
  }

  @override
  Future<List<WaitlistEntry>> listWaitlist() async {
    final me = await _me();
    final rows = await _db.from('waitlist').select().eq('user_id', me.id);
    return _list(rows).map(WaitlistEntry.fromJson).toList();
  }

  @override
  Future<void> sendEnquiry(Enquiry enquiry) async {
    final me = await _me();
    await _db.from('enquiries').insert({...enquiry.toJson(), 'family_id': me.familyId});
  }

  @override
  Future<List<Enquiry>> listEnquiries() async {
    final me = await _me();
    final rows =
        await _db.from('enquiries').select().eq('user_id', me.id).order('created_at', ascending: false);
    return _list(rows).map(Enquiry.fromJson).toList();
  }

  // ---- memories ----

  @override
  Future<List<Memory>> listMemories() async {
    final familyId = await _myFamilyId();
    final rows = await _db
        .from('memories')
        .select()
        .eq('family_id', familyId)
        .order('created_at', ascending: false);
    return _list(rows).map(Memory.fromJson).toList();
  }

  @override
  Future<Memory?> getMemory(String id) async {
    final row = await _db.from('memories').select().eq('id', id).maybeSingle();
    return row == null ? null : Memory.fromJson(row);
  }

  @override
  Future<void> saveMemory(Memory memory) async {
    final me = await _me();
    if (me.familyId == null) throw StateError('You are not part of a family');
    final row = {...memory.toJson(), 'family_id': me.familyId};
    // A new memory leaves created_by to the database default (the caller).
    if (memory.createdBy.isEmpty) {
      row.remove('created_by');
      row['created_by_name'] = me.name;
    }
    await _db.from('memories').upsert(row);
  }

  @override
  Future<void> deleteMemory(String id) async {
    final memory = await getMemory(id);
    await _db.from('memories').delete().eq('id', id);
    // Best effort: a file left behind is harmless, a failed delete of the row is not.
    if (memory != null && memory.mediaPaths.isNotEmpty) {
      try {
        await _db.storage.from(_memoryBucket).remove(memory.mediaPaths);
      } catch (_) {}
    }
  }

  @override
  Future<String> uploadMemoryMedia({required String memoryId, required String localPath}) async {
    final familyId = await _myFamilyId();
    final raw = localPath.split('/').last;
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$familyId/$memoryId/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await _db.storage.from(_memoryBucket).upload(path, File(localPath));
    return path;
  }

  @override
  Future<String> mediaUrl(String path) =>
      _db.storage.from(_memoryBucket).createSignedUrl(path, 3600);

  // ---- super admin: accounts only ----

  @override
  Future<List<FamilySummary>> listFamilies() async {
    final rows = await _db.rpc('list_families_for_super_admin');
    return _list(rows).map(FamilySummary.fromJson).toList();
  }

  @override
  Future<void> setFamilyActive(String familyId, bool active) async {
    await _db.rpc('set_family_active', params: {'p_family_id': familyId, 'p_active': active});
  }
}
