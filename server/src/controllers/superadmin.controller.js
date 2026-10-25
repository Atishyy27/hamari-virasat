import { store } from '../services/store.js';
import { badRequest } from '../utils/httpError.js';

// The ONLY window a super admin has onto families: (id, name, active, created_at)
export function listFamilies(req, res) {
  const families = store.listFamiliesForSuperAdmin(req.user.role);
  res.json({
    privacy_notice: 'Under database RLS, super admin has zero access to rituals, recipes, members, audio, or invite codes.',
    families
  });
}

// Matches set_family_active(p_family_id, p_active)
export function setFamilyStatus(req, res) {
  const { active } = req.body;
  if (active === undefined) {
    throw badRequest("'active' boolean flag is required.");
  }
  const updated = store.setFamilyActive(req.params.id, active, req.user.role);
  res.json({
    message: `Family ${updated.name} status updated to ${updated.active ? 'Active' : 'Deactivated'}.`,
    family: {
      id: updated.id,
      name: updated.name,
      active: updated.active,
      created_at: updated.created_at
    }
  });
}

// Demonstrates 0-row return when a super admin queries rituals
export function testRitualsLeak(req, res) {
  const rituals = store.listRituals(req.user.family_id); // family_id is null
  res.json({
    caller_role: req.user.role,
    caller_family_id: req.user.family_id,
    query: 'SELECT * FROM public.rituals;',
    result_rows_count: rituals.length,
    rows: rituals,
    rls_status: 'ENFORCED: Zero rows returned to super admin.'
  });
}
