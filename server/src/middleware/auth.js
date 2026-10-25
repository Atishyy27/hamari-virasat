import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { store } from '../services/store.js';
import { forbidden, notFound, unauthorized } from '../utils/httpError.js';

export function createToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role,
      family_id: user.family_id
    },
    config.jwtSecret,
    { expiresIn: '30d' }
  );
}

export function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(unauthorized('Authentication required. Please sign in.'));
  }

  let payload;
  try {
    payload = jwt.verify(authHeader.split(' ')[1], config.jwtSecret);
  } catch {
    return next(unauthorized('Invalid or expired authentication token.'));
  }

  const user = store.findUserById(payload.id);
  if (!user) {
    return next(unauthorized('User account not found or removed.'));
  }

  // If user belongs to a family, verify the family is active
  if (user.family_id) {
    const family = store.findFamilyById(user.family_id);
    if (!family) {
      return next(notFound('Family space not found.'));
    }
    if (!family.active) {
      return next(forbidden('Family space is currently deactivated. Please contact support or your super admin.'));
    }
    req.family = family;
  }

  req.user = user;
  next();
}

// Ensures caller has an active family_id (blocks Super Admin from reading family content)
export function requireFamily(req, res, next) {
  if (req.user.role === 'super_admin') {
    return next(forbidden('Access denied: Super Admin accounts cannot view or access family content.'));
  }
  if (!req.user.family_id) {
    return next(forbidden('User does not belong to any family.'));
  }
  next();
}

// Ensures caller is the Family Admin (can edit family details, delete members)
export function requireFamilyAdmin(req, res, next) {
  if (req.user.role !== 'family_admin') {
    return next(forbidden('Action restricted to Family Admin only.'));
  }
  next();
}

// Ensures caller is the Platform Super Admin (can only list/toggle accounts)
export function requireSuperAdmin(req, res, next) {
  if (req.user.role !== 'super_admin') {
    return next(forbidden('Action restricted to Super Admin only.'));
  }
  next();
}
