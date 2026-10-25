import { store } from '../services/store.js';
import { requireFields } from '../middleware/validate.js';
import { badRequest, notFound } from '../utils/httpError.js';

const VALID_STATUSES = ['draft', 'submitted', 'draft_ready', 'approved'];

// Scoped lookup; 404 if the ritual is not in caller's family
function findRitualOrThrow(familyId, ritualId) {
  const ritual = store.getRitual(familyId, ritualId);
  if (!ritual) throw notFound('Ritual not found.');
  return ritual;
}

export function listRituals(req, res) {
  res.json({ rituals: store.listRituals(req.family.id) });
}

export function getRitual(req, res) {
  res.json({ ritual: findRitualOrThrow(req.family.id, req.params.id) });
}

// Any member can add rituals and recipes
export function createRitual(req, res) {
  const { title, category, phase, samagri, steps, relative_roles, recipes, songs, additional_info, status } = req.body;
  requireFields(req.body, ['title'], 'Ritual title is required.');

  const ritual = store.saveRitual(req.family.id, {
    title,
    category,
    phase,
    samagri,
    steps,
    relative_roles,
    recipes,
    songs,
    additional_info,
    status: status || 'draft'
  });

  res.status(201).json({ message: 'Ritual and recipes recorded successfully.', ritual });
}

// Update ritual and replace its recipes
export function updateRitual(req, res) {
  const existing = findRitualOrThrow(req.family.id, req.params.id);
  const ritual = store.saveRitual(req.family.id, {
    ...req.body,
    id: existing.id,
    created_at: existing.created_at
  });
  res.json({ message: 'Ritual updated.', ritual });
}

export function updateRitualStatus(req, res) {
  const { status } = req.body;
  if (!VALID_STATUSES.includes(status)) {
    throw badRequest(`Invalid status. Must be one of: ${VALID_STATUSES.join(', ')}`);
  }
  const existing = findRitualOrThrow(req.family.id, req.params.id);
  const ritual = store.saveRitual(req.family.id, { ...existing, status });
  res.json({ message: `Ritual status updated to ${status}.`, ritual });
}

// Cascade deletes its recipes
export function deleteRitual(req, res) {
  store.deleteRitual(req.family.id, req.params.id);
  res.json({ message: 'Ritual and its sacred recipes removed from family space.' });
}
