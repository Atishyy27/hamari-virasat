// Shared data contract for the whole app. Screens and repositories both depend on this file.

enum Role { superAdmin, familyAdmin, member }

Role roleFromString(String? s) {
  switch (s) {
    case 'super_admin':
      return Role.superAdmin;
    case 'family_admin':
      return Role.familyAdmin;
    default:
      return Role.member;
  }
}

String roleToString(Role r) {
  switch (r) {
    case Role.superAdmin:
      return 'super_admin';
    case Role.familyAdmin:
      return 'family_admin';
    case Role.member:
      return 'member';
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String? familyId; // null for super admin

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.familyId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': name,
        'email': email,
        'role': roleToString(role),
        'family_id': familyId,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: (j['full_name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        role: roleFromString(j['role'] as String?),
        familyId: j['family_id'] as String?,
      );
}

/// A family. No tree: just a name, its identity details and a flat member list.
class Family {
  final String id;
  final String name;
  final String gotra;
  final String kuldevi;
  final String kuldevta;
  final String inviteCode; // members join with this

  const Family({
    required this.id,
    required this.name,
    this.gotra = '',
    this.kuldevi = '',
    this.kuldevta = '',
    this.inviteCode = '',
  });

  Family copyWith({String? name, String? gotra, String? kuldevi, String? kuldevta}) => Family(
        id: id,
        name: name ?? this.name,
        gotra: gotra ?? this.gotra,
        kuldevi: kuldevi ?? this.kuldevi,
        kuldevta: kuldevta ?? this.kuldevta,
        inviteCode: inviteCode,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gotra': gotra,
        'kuldevi': kuldevi,
        'kuldevta': kuldevta,
        'invite_code': inviteCode,
      };

  factory Family.fromJson(Map<String, dynamic> j) => Family(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        gotra: (j['gotra'] ?? '') as String,
        kuldevi: (j['kuldevi'] ?? '') as String,
        kuldevta: (j['kuldevta'] ?? '') as String,
        inviteCode: (j['invite_code'] ?? '') as String,
      );
}

/// What the super admin is allowed to see about a family: the account, never the content.
class FamilySummary {
  final String id;
  final String name;
  final bool active;
  final DateTime createdAt;

  const FamilySummary({
    required this.id,
    required this.name,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'active': active,
        'created_at': createdAt.toIso8601String(),
      };

  factory FamilySummary.fromJson(Map<String, dynamic> j) => FamilySummary(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        active: (j['active'] ?? true) as bool,
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}

class FamilyMember {
  final String id;
  final String familyId;
  final String name;
  final String relation; // free text, e.g. "Dadi", "Mama"
  final String phone;

  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.name,
    this.relation = '',
    this.phone = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'name': name,
        'relation': relation,
        'phone': phone,
      };

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
        id: j['id'] as String,
        familyId: j['family_id'] as String,
        name: (j['name'] ?? '') as String,
        relation: (j['relation'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
      );
}

class RitualCategory {
  final String id;
  final String name; // e.g. "Boy Wedding (Var Paksha)"
  final List<String> phases; // e.g. Shagun, Haldi, Tilak

  const RitualCategory({required this.id, required this.name, this.phases = const []});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phases': phases};

  factory RitualCategory.fromJson(Map<String, dynamic> j) => RitualCategory(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        phases: ((j['phases'] ?? const []) as List).map((e) => e.toString()).toList(),
      );
}

/// A recipe lives under a ritual. There is no standalone recipe section.
class Recipe {
  final String id;
  final String name;
  final String ingredients;
  final String method;

  const Recipe({required this.id, required this.name, this.ingredients = '', this.method = ''});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'ingredients': ingredients, 'method': method};

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        ingredients: (j['ingredients'] ?? '') as String,
        method: (j['method'] ?? '') as String,
      );
}

/// Something the family wants to keep: a photo, a video, a voice note or a written story.
class Memory {
  final String id;
  final String familyId;
  final String kind; // 'photo' | 'video' | 'voice' | 'story'
  final String title;
  final String story;
  final List<String> tags;
  final List<String> mediaPaths; // storage paths, or local paths on the demo build
  final String createdBy; // user id, empty until saved
  final String createdByName;
  final DateTime createdAt;

  const Memory({
    required this.id,
    required this.familyId,
    required this.kind,
    required this.title,
    this.story = '',
    this.tags = const [],
    this.mediaPaths = const [],
    this.createdBy = '',
    this.createdByName = '',
    required this.createdAt,
  });

  bool get isVisual => kind == 'photo' || kind == 'video';

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'kind': kind,
        'title': title,
        'story': story,
        'tags': tags,
        'media_paths': mediaPaths,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'created_at': createdAt.toIso8601String(),
      };

  factory Memory.fromJson(Map<String, dynamic> j) => Memory(
        id: j['id'] as String,
        familyId: (j['family_id'] ?? '') as String,
        kind: (j['kind'] ?? 'story') as String,
        title: (j['title'] ?? '') as String,
        story: (j['story'] ?? '') as String,
        tags: ((j['tags'] ?? const []) as List).map((e) => e.toString()).toList(),
        mediaPaths: ((j['media_paths'] ?? const []) as List).map((e) => e.toString()).toList(),
        createdBy: (j['created_by'] ?? '').toString(),
        createdByName: (j['created_by_name'] ?? '') as String,
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}

/// Where a ritual stands in the documentation flow of the website.
const kStatusDraft = 'draft'; // family is still filling the form
const kStatusSubmitted = 'submitted'; // sent to the team for documentation
const kStatusDraftReady = 'draft_ready'; // the team's draft is waiting for approval
const kStatusApproved = 'approved'; // final, part of the Heritage Book

class Ritual {
  final String id;
  final String familyId;
  final String title;
  final String category; // category name
  final String phase; // phase name, may be empty
  final String samagri;
  final String steps;
  final String relativeRoles;
  final List<Recipe> recipes;
  final List<String> audioPaths; // storage paths or local file paths
  final DateTime createdAt;
  final String status; // one of the kStatus* values
  final String templateKey; // catalogue ritual this was started from, empty for a free-form one
  final String songs; // songs, prayers and mantras as text
  final String additionalInfo;
  final List<String> photoPaths;
  final List<String> photoCaptions; // same order as photoPaths
  final Map<String, String> sections; // answers to the catalogue's other sub-sections, by name

  const Ritual({
    required this.id,
    required this.familyId,
    required this.title,
    required this.category,
    this.phase = '',
    this.samagri = '',
    this.steps = '',
    this.relativeRoles = '',
    this.recipes = const [],
    this.audioPaths = const [],
    required this.createdAt,
    this.status = kStatusApproved,
    this.templateKey = '',
    this.songs = '',
    this.additionalInfo = '',
    this.photoPaths = const [],
    this.photoCaptions = const [],
    this.sections = const {},
  });

  Ritual copyWith({String? status}) => Ritual(
        id: id,
        familyId: familyId,
        title: title,
        category: category,
        phase: phase,
        samagri: samagri,
        steps: steps,
        relativeRoles: relativeRoles,
        recipes: recipes,
        audioPaths: audioPaths,
        createdAt: createdAt,
        status: status ?? this.status,
        templateKey: templateKey,
        songs: songs,
        additionalInfo: additionalInfo,
        photoPaths: photoPaths,
        photoCaptions: photoCaptions,
        sections: sections,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'title': title,
        'category': category,
        'phase': phase,
        'samagri': samagri,
        'steps': steps,
        'relative_roles': relativeRoles,
        'recipes': recipes.map((r) => r.toJson()).toList(),
        'audio_paths': audioPaths,
        'created_at': createdAt.toIso8601String(),
        'status': status,
        'template_key': templateKey,
        'songs': songs,
        'additional_info': additionalInfo,
        'photo_paths': photoPaths,
        'photo_captions': photoCaptions,
        'sections': sections,
      };

  factory Ritual.fromJson(Map<String, dynamic> j) => Ritual(
        id: j['id'] as String,
        familyId: j['family_id'] as String,
        title: (j['title'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        phase: (j['phase'] ?? '') as String,
        samagri: (j['samagri'] ?? '') as String,
        steps: (j['steps'] ?? '') as String,
        relativeRoles: (j['relative_roles'] ?? '') as String,
        recipes: ((j['recipes'] ?? const []) as List)
            .map((e) => Recipe.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        audioPaths: ((j['audio_paths'] ?? const []) as List).map((e) => e.toString()).toList(),
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ?? DateTime.now(),
        status: (j['status'] ?? kStatusApproved) as String,
        templateKey: (j['template_key'] ?? '') as String,
        songs: (j['songs'] ?? '') as String,
        additionalInfo: (j['additional_info'] ?? '') as String,
        photoPaths: ((j['photo_paths'] ?? const []) as List).map((e) => e.toString()).toList(),
        photoCaptions: ((j['photo_captions'] ?? const []) as List).map((e) => e.toString()).toList(),
        sections: ((j['sections'] ?? const {}) as Map)
            .map((k, v) => MapEntry(k.toString(), (v ?? '').toString())),
      );
}

/// A purchase of one or more catalogue rituals. Payment is a demo stand-in for now.
class RitualOrder {
  final String id;
  final String familyId;
  final List<String> ritualKeys; // catalogue keys bought in this order
  final int amount; // rupees actually charged, after discount
  final int discount; // rupees taken off
  final String status; // 'paid'
  final DateTime createdAt;

  const RitualOrder({
    required this.id,
    required this.familyId,
    required this.ritualKeys,
    required this.amount,
    this.discount = 0,
    this.status = 'paid',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'ritual_keys': ritualKeys,
        'amount': amount,
        'discount': discount,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory RitualOrder.fromJson(Map<String, dynamic> j) => RitualOrder(
        id: j['id'] as String,
        familyId: (j['family_id'] ?? '') as String,
        ritualKeys: ((j['ritual_keys'] ?? const []) as List).map((e) => e.toString()).toList(),
        amount: ((j['amount'] ?? 0) as num).toInt(),
        discount: ((j['discount'] ?? 0) as num).toInt(),
        status: (j['status'] ?? 'paid') as String,
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}

/// "Notify me when available" for a ritual that is not in the catalogue yet.
class WaitlistEntry {
  final String id;
  final String ritualKey;
  final DateTime createdAt;

  const WaitlistEntry({required this.id, required this.ritualKey, required this.createdAt});

  Map<String, dynamic> toJson() =>
      {'id': id, 'ritual_key': ritualKey, 'created_at': createdAt.toIso8601String()};

  factory WaitlistEntry.fromJson(Map<String, dynamic> j) => WaitlistEntry(
        id: j['id'] as String,
        ritualKey: (j['ritual_key'] ?? '') as String,
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}

/// A message sent through the contact form.
class Enquiry {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String topic;
  final String message;
  final DateTime createdAt;

  const Enquiry({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.topic,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'topic': topic,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };

  factory Enquiry.fromJson(Map<String, dynamic> j) => Enquiry(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        topic: (j['topic'] ?? '') as String,
        message: (j['message'] ?? '') as String,
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}
