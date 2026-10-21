import 'models.dart';

/// The one seam between screens and storage. Screens only ever talk to [repo].
/// Two implementations: LocalRepository (on-device, demo) and SupabaseRepository (real backend).
abstract class Repository {
  // Auth
  Future<AppUser?> currentUser();
  Future<AppUser> signIn({required String email, required String password});

  /// Give [familyName] to start a new family (caller becomes family admin),
  /// or [inviteCode] to join an existing one as a member. Exactly one of the two.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    String? familyName,
    String? inviteCode,
  });
  Future<void> signOut();

  // Family (the signed-in user's own family only)
  Future<Family?> myFamily();
  Future<void> saveFamily(Family family); // family admin only

  // Members: a flat list, no tree
  Future<List<FamilyMember>> listMembers();
  Future<void> saveMember(FamilyMember member); // insert or update by id
  Future<void> deleteMember(String id);

  // Ritual catalogue: built-in categories plus this family's custom ones
  Future<List<RitualCategory>> listCategories();
  Future<void> addCustomCategory(String name);

  // Rituals, with their recipes nested inside
  Future<List<Ritual>> listRituals();
  Future<Ritual?> getRitual(String id);
  Future<void> saveRitual(Ritual ritual); // insert or update by id, replaces its recipes
  Future<void> deleteRitual(String id);

  /// Uploads a local audio file for a ritual and returns the stored path.
  Future<String> uploadAudio({required String ritualId, required String localPath});

  /// Uploads a photo for a ritual (same private bucket as memories) and returns the stored path.
  Future<String> uploadRitualPhoto({required String ritualId, required String localPath});

  // Orders: catalogue rituals the family has paid for (payment is a demo stand-in)
  /// Records a paid order for [ritualKeys] at [pricePerRitual] rupees each, taking 10% off
  /// when the family already has a paid order.
  Future<RitualOrder> createOrder(List<String> ritualKeys, {int pricePerRitual = 299});
  Future<List<RitualOrder>> listOrders(); // newest first

  // Waitlist for rituals that are coming soon, and messages from the contact form
  Future<void> joinWaitlist(String ritualKey);
  Future<List<WaitlistEntry>> listWaitlist();
  Future<void> sendEnquiry(Enquiry enquiry);
  Future<List<Enquiry>> listEnquiries();

  // Memories: photos, videos, voice notes and stories of the signed-in user's family
  Future<List<Memory>> listMemories(); // newest first
  Future<Memory?> getMemory(String id);
  Future<void> saveMemory(Memory memory); // insert or update by id
  Future<void> deleteMemory(String id); // author or family admin

  /// Uploads a local file for a memory and returns the stored path.
  Future<String> uploadMemoryMedia({required String memoryId, required String localPath});

  /// Something an image widget can show for a stored media path: an https URL on the
  /// real backend, the path itself (a local file, or `asset:<path>`) on the demo build.
  Future<String> mediaUrl(String path);

  // Super admin: accounts only. Must never return family content.
  Future<List<FamilySummary>> listFamilies();
  Future<void> setFamilyActive(String familyId, bool active);
}

/// Set once in main() before runApp.
late Repository repo;

/// New id for a record created on the device.
String newId() => 'id_${DateTime.now().microsecondsSinceEpoch}';
