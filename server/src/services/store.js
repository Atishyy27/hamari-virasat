import { 
  initialFamilies, 
  initialUsers, 
  initialMembers, 
  initialCategories, 
  initialRituals, 
  initialRecipes, 
  initialOrders, 
  initialMemories 
} from '../data/seedData.js';
import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import { config } from '../config.js';
import { badRequest, forbidden, notFound } from '../utils/httpError.js';

const BCRYPT_ROUNDS = 10;
const BCRYPT_PREFIX = /^\$2[aby]\$/;

export const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

const hashPassword = (password) => bcrypt.hashSync(String(password), BCRYPT_ROUNDS);

class MemoryStore {
  constructor() {
    this.reset();
  }

  // Restore seed state (deep copies so mutations never leak into seed objects)
  reset() {
    this.families = structuredClone(initialFamilies);
    this.users = structuredClone(initialUsers).map(u => ({
      ...u,
      email: normalizeEmail(u.email),
      // Seed passwords are plaintext; hash them once at construction
      passwordHash: BCRYPT_PREFIX.test(u.passwordHash) ? u.passwordHash : hashPassword(u.passwordHash)
    }));
    this.members = structuredClone(initialMembers);
    this.categories = structuredClone(initialCategories);
    this.rituals = structuredClone(initialRituals);
    this.recipes = structuredClone(initialRecipes);
    this.orders = structuredClone(initialOrders);
    this.memories = structuredClone(initialMemories);
    this.waitlist = [];
    this.enquiries = [];
  }

  // -------------------------------------------------------------
  // AUTH & USERS
  // -------------------------------------------------------------
  findUserByEmail(email) {
    const normalized = normalizeEmail(email);
    if (!normalized) return null;
    return this.users.find(u => u.email === normalized);
  }

  // Returns the user when email + password match, otherwise null
  verifyCredentials(email, password) {
    const user = this.findUserByEmail(email);
    if (!user || !user.passwordHash || typeof password !== 'string') return null;
    return bcrypt.compareSync(password, user.passwordHash) ? user : null;
  }

  findUserById(id) {
    return this.users.find(u => u.id === id);
  }

  createUser({ email, password, full_name, role, family_id }) {
    // Check constraint: profiles_super_admin_has_no_family
    // check (role <> 'super_admin' or family_id is null)
    if (role === 'super_admin' && family_id !== null) {
      throw badRequest('Database constraint violation: super_admin family_id must be null');
    }
    const normalized = normalizeEmail(email);
    if (!normalized) throw badRequest('Email is required.');
    if (this.findUserByEmail(normalized)) {
      throw badRequest('An account with this email already exists.');
    }

    const newUser = {
      id: `usr_${crypto.randomUUID().slice(0, 8)}`,
      email: normalized,
      passwordHash: hashPassword(password),
      full_name,
      role: role || 'member',
      family_id: role === 'super_admin' ? null : family_id
    };
    this.users.push(newUser);
    return newUser;
  }

  // -------------------------------------------------------------
  // FAMILIES
  // -------------------------------------------------------------
  findFamilyById(id) {
    return this.families.find(f => f.id === id);
  }

  findFamilyByInviteCode(code) {
    if (!code) return null;
    return this.families.find(f => f.invite_code.toUpperCase() === code.trim().toUpperCase());
  }

  createFamily({ name, gotra = '', kuldevi = '', kuldevta = '' }) {
    const randomSuffix = Math.floor(1000 + Math.random() * 9000);
    const slug = name.replace(/[^a-zA-Z]/g, '').slice(0, 6).toUpperCase();
    const invite_code = `${slug || 'FAMILY'}-${randomSuffix}`;
    const newFam = {
      id: `fam_${crypto.randomUUID().slice(0, 8)}`,
      name,
      gotra,
      kuldevi,
      kuldevta,
      invite_code,
      active: true,
      created_at: new Date().toISOString()
    };
    this.families.push(newFam);
    return newFam;
  }

  updateFamily(id, updates) {
    const fam = this.findFamilyById(id);
    if (!fam) throw notFound('Family not found.');

    // Trigger rule from README: invite_code and active flag cannot be changed by family admin
    if (updates.gotra !== undefined) fam.gotra = updates.gotra;
    if (updates.kuldevi !== undefined) fam.kuldevi = updates.kuldevi;
    if (updates.kuldevta !== undefined) fam.kuldevta = updates.kuldevta;
    if (updates.name !== undefined) fam.name = updates.name;

    return fam;
  }

  // -------------------------------------------------------------
  // SUPER ADMIN SPECIAL WINDOW
  // The ONLY window a super admin has: returns only (id, name, active, created_at)
  // -------------------------------------------------------------
  listFamiliesForSuperAdmin(callerRole) {
    if (callerRole !== 'super_admin') {
      throw forbidden('Super admin only.');
    }
    // Return only the 4 allowed columns, newest first
    return this.families
      .slice()
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .map(f => ({
        id: f.id,
        name: f.name,
        active: f.active,
        created_at: f.created_at
      }));
  }

  setFamilyActive(familyId, active, callerRole) {
    if (callerRole !== 'super_admin') {
      throw forbidden('Super admin only.');
    }
    const fam = this.findFamilyById(familyId);
    if (!fam) throw notFound('Family not found.');
    fam.active = Boolean(active);
    return fam;
  }

  // -------------------------------------------------------------
  // MEMBERS (Flat list, zero tree)
  // -------------------------------------------------------------
  listMembers(familyId) {
    if (!familyId) return [];
    return this.members.filter(m => m.family_id === familyId);
  }

  addMember(familyId, { name, relation, phone }) {
    if (!familyId) throw badRequest('Family ID required.');
    const member = {
      id: `m_${crypto.randomUUID().slice(0, 8)}`,
      family_id: familyId,
      name,
      relation: relation || 'Family Member',
      phone: phone || ''
    };
    this.members.push(member);
    return member;
  }

  updateMember(familyId, memberId, { name, relation, phone }) {
    const member = this.members.find(m => m.id === memberId && m.family_id === familyId);
    if (!member) throw notFound('Member not found.');
    if (name !== undefined) member.name = name;
    if (relation !== undefined) member.relation = relation;
    if (phone !== undefined) member.phone = phone;
    return member;
  }

  deleteMember(familyId, memberId) {
    const idx = this.members.findIndex(m => m.id === memberId && m.family_id === familyId);
    if (idx === -1) throw notFound('Member not found.');
    this.members.splice(idx, 1);
    return true;
  }

  // -------------------------------------------------------------
  // CATEGORIES
  // -------------------------------------------------------------
  listCategories(familyId) {
    // Built-in categories (family_id == null) + this family's custom categories
    return this.categories.filter(c => c.family_id === null || c.family_id === familyId);
  }

  addCustomCategory(familyId, name) {
    if (!familyId) throw badRequest('Family ID required.');
    const custom = {
      id: `cat_${crypto.randomUUID().slice(0, 8)}`,
      name,
      phases: ['Custom Ceremony'],
      family_id: familyId
    };
    this.categories.push(custom);
    return custom;
  }

  // -------------------------------------------------------------
  // RITUALS & RECIPES (Recipes strictly tied to Rituals)
  // -------------------------------------------------------------
  listRituals(familyId) {
    if (!familyId) return []; // Super admin gets 0 rows
    const rits = this.rituals.filter(r => r.family_id === familyId);
    return rits.map(r => {
      const recs = this.recipes.filter(rc => rc.ritual_id === r.id);
      return { ...r, recipes: recs };
    });
  }

  getRitual(familyId, ritualId) {
    if (!familyId) return null;
    const r = this.rituals.find(item => item.id === ritualId && item.family_id === familyId);
    if (!r) return null;
    const recs = this.recipes.filter(rc => rc.ritual_id === r.id);
    return { ...r, recipes: recs };
  }

  saveRitual(familyId, ritualData) {
    if (!familyId) throw badRequest('Family ID required.');
    const existingIdx = ritualData.id ? this.rituals.findIndex(r => r.id === ritualData.id && r.family_id === familyId) : -1;

    const ritualId = ritualData.id || `rit_${crypto.randomUUID().slice(0, 8)}`;
    const savedRitual = {
      id: ritualId,
      family_id: familyId,
      title: ritualData.title,
      category: ritualData.category || 'Other Traditions',
      phase: ritualData.phase || '',
      status: ritualData.status || 'draft',
      samagri: Array.isArray(ritualData.samagri) ? ritualData.samagri.join('\n') : (ritualData.samagri || ''),
      steps: Array.isArray(ritualData.steps) ? ritualData.steps.join('\n') : (ritualData.steps || ''),
      relative_roles: Array.isArray(ritualData.relative_roles) ? ritualData.relative_roles.join('\n') : (ritualData.relative_roles || ''),
      audio_paths: ritualData.audio_paths || [],
      songs: ritualData.songs || '',
      additional_info: ritualData.additional_info || '',
      created_at: ritualData.created_at || new Date().toISOString()
    };

    if (existingIdx !== -1) {
      this.rituals[existingIdx] = savedRitual;
    } else {
      this.rituals.push(savedRitual);
    }

    // Replace recipes associated with this ritual
    this.recipes = this.recipes.filter(rc => rc.ritual_id !== ritualId);
    if (Array.isArray(ritualData.recipes)) {
      ritualData.recipes.forEach((rec, idx) => {
        this.recipes.push({
          id: rec.id || `${ritualId}_rec${idx}`,
          ritual_id: ritualId,
          family_id: familyId,
          name: rec.name,
          ingredients: Array.isArray(rec.ingredients) ? rec.ingredients.join('\n') : (rec.ingredients || ''),
          method: Array.isArray(rec.method) ? rec.method.join('\n') : (rec.method || '')
        });
      });
    }

    const recs = this.recipes.filter(rc => rc.ritual_id === ritualId);
    return { ...savedRitual, recipes: recs };
  }

  deleteRitual(familyId, ritualId) {
    const idx = this.rituals.findIndex(r => r.id === ritualId && r.family_id === familyId);
    if (idx === -1) throw notFound('Ritual not found.');
    this.rituals.splice(idx, 1);
    // Cascade delete recipes
    this.recipes = this.recipes.filter(rc => rc.ritual_id !== ritualId);
    return true;
  }

  // -------------------------------------------------------------
  // ORDERS (Catalogue ritual payments at ₹299 each)
  // -------------------------------------------------------------
  listOrders(familyId) {
    if (!familyId) return [];
    return this.orders
      .filter(o => o.family_id === familyId)
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  }

  // Price always comes from server config, never from the client
  createOrder(familyId, userId, ritualKeys) {
    const pricePerRitual = config.ritualPrice;
    if (!familyId) throw badRequest('Family ID required.');
    const existingOrders = this.listOrders(familyId);
    const hasPriorOrder = existingOrders.some(o => o.status === 'paid');
    
    // 10% discount for subsequent orders
    const subtotal = ritualKeys.length * pricePerRitual;
    const discount = hasPriorOrder ? Math.round(subtotal * 0.1) : 0;
    const totalAmount = subtotal - discount;

    const order = {
      id: `ord_${crypto.randomUUID().slice(0, 8)}`,
      family_id: familyId,
      ritual_keys: ritualKeys,
      amount: totalAmount,
      discount,
      status: 'paid',
      created_by: userId,
      created_at: new Date().toISOString()
    };
    this.orders.push(order);
    return order;
  }

  // -------------------------------------------------------------
  // WAITLIST & ENQUIRIES
  // -------------------------------------------------------------
  addToWaitlist(userId, familyId, ritualKey) {
    const exists = this.waitlist.some(w => w.user_id === userId && w.ritual_key === ritualKey);
    if (exists) return { message: 'Already on waitlist' };
    const entry = {
      id: `wait_${crypto.randomUUID().slice(0, 8)}`,
      user_id: userId,
      family_id: familyId,
      ritual_key: ritualKey,
      created_at: new Date().toISOString()
    };
    this.waitlist.push(entry);
    return entry;
  }

  listWaitlist(userId) {
    return this.waitlist.filter(w => w.user_id === userId);
  }

  listEnquiries() {
    return this.enquiries.slice();
  }

  addEnquiry({ name, phone, email, message, family_id = null }) {
    const enq = {
      id: `enq_${crypto.randomUUID().slice(0, 8)}`,
      name,
      phone,
      email,
      message,
      family_id,
      created_at: new Date().toISOString()
    };
    this.enquiries.push(enq);
    return enq;
  }

  // -------------------------------------------------------------
  // MEMORIES
  // -------------------------------------------------------------
  listMemories(familyId) {
    if (!familyId) return [];
    return this.memories
      .filter(m => m.family_id === familyId)
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  }

  saveMemory(familyId, memData) {
    if (!familyId) throw badRequest('Family ID required.');
    const memId = memData.id || `mem_${crypto.randomUUID().slice(0, 8)}`;
    const saved = {
      id: memId,
      family_id: familyId,
      title: memData.title,
      type: memData.type || 'story',
      media_path: memData.media_path || '',
      caption: memData.caption || '',
      year: memData.year || '',
      author_name: memData.author_name || '',
      created_at: memData.created_at || new Date().toISOString()
    };
    const idx = this.memories.findIndex(m => m.id === memId && m.family_id === familyId);
    if (idx !== -1) {
      this.memories[idx] = saved;
    } else {
      this.memories.push(saved);
    }
    return saved;
  }

  deleteMemory(familyId, memoryId) {
    const idx = this.memories.findIndex(m => m.id === memoryId && m.family_id === familyId);
    if (idx === -1) throw notFound('Memory not found.');
    this.memories.splice(idx, 1);
    return true;
  }
}

export const store = new MemoryStore();
