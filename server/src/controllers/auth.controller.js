import { store } from '../services/store.js';
import { createToken } from '../middleware/auth.js';
import { requireFields } from '../middleware/validate.js';
import { toPublicUser } from '../serializers/user.js';
import { config } from '../config.js';
import { badRequest, forbidden, notFound, unauthorized } from '../utils/httpError.js';

const DEMO_EMAILS = {
  admin: 'demo@example.com',
  member: 'member@example.com',
  super: 'super@example.com'
};

function assertPasswordStrength(password) {
  if (typeof password !== 'string' || password.length < config.minPasswordLength) {
    throw badRequest(`Password must be at least ${config.minPasswordLength} characters.`);
  }
}

function assertEmailAvailable(email) {
  if (store.findUserByEmail(email)) {
    throw badRequest('An account with this email already exists.');
  }
}

// Family for a user, refusing deactivated spaces
function activeFamilyFor(user) {
  if (!user.family_id) return null;
  const family = store.findFamilyById(user.family_id) || null;
  if (family && !family.active) {
    throw forbidden('Your family space is deactivated. Contact super admin.');
  }
  return family;
}

const authPayload = (message, user, family) => ({
  message,
  token: createToken(user),
  user: toPublicUser(user),
  family
});

// Register a new family (caller becomes family_admin)
export function registerFamily(req, res) {
  const { name, email, password, family_name, gotra, kuldevi, kuldevta } = req.body;
  requireFields(req.body, ['name', 'email', 'password', 'family_name'],
    'Name, email, password, and family name are required.');
  assertPasswordStrength(password);
  assertEmailAvailable(email);

  const family = store.createFamily({
    name: family_name,
    gotra: gotra || '',
    kuldevi: kuldevi || '',
    kuldevta: kuldevta || ''
  });

  const user = store.createUser({
    email,
    password,
    full_name: name,
    role: 'family_admin',
    family_id: family.id
  });

  // Add self to flat member list
  store.addMember(family.id, { name, relation: 'Self / Family Admin', phone: '' });

  res.status(201).json(authPayload('Family space registered successfully.', user, family));
}

// Join an existing family using invite code (caller becomes member)
export function joinFamily(req, res) {
  const { name, email, password, invite_code } = req.body;
  requireFields(req.body, ['name', 'email', 'password', 'invite_code'],
    'Name, email, password, and invite code are required.');
  assertPasswordStrength(password);
  assertEmailAvailable(email);

  const family = store.findFamilyByInviteCode(invite_code);
  if (!family) throw notFound('Invalid invite code. Family not found.');
  if (!family.active) throw forbidden('This family space has been deactivated.');

  const user = store.createUser({
    email,
    password,
    full_name: name,
    role: 'member',
    family_id: family.id
  });

  store.addMember(family.id, { name, relation: 'Member', phone: '' });

  res.status(201).json(authPayload(`Joined ${family.name} successfully.`, user, family));
}

// Standard email/password login
export function login(req, res) {
  const { email, password } = req.body;
  requireFields(req.body, ['email', 'password'], 'Email and password are required.');

  const user = store.verifyCredentials(email, password);
  if (!user) throw unauthorized('Invalid email or password.');

  const family = activeFamilyFor(user);
  res.json(authPayload('Signed in successfully.', user, family));
}

// Quick demo 1-tap login (matching mobile app _demoButton)
export function demoLogin(req, res) {
  if (!config.demoLoginEnabled) throw notFound('Demo login is disabled.');

  const { type } = req.body || {}; // 'admin' | 'member' | 'super'
  const user = store.findUserByEmail(DEMO_EMAILS[type] || DEMO_EMAILS.admin);
  if (!user) throw notFound('Demo account not found.');

  const family = activeFamilyFor(user);
  res.json(authPayload(`Signed in as ${user.full_name}`, user, family));
}

// Current user profile and family
export function me(req, res) {
  res.json({ user: toPublicUser(req.user), family: req.family || null });
}
