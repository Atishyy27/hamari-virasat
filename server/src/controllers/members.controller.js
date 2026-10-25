import { store } from '../services/store.js';
import { requireFields } from '../middleware/validate.js';

export function listMembers(req, res) {
  res.json({ members: store.listMembers(req.family.id) });
}

export function addMember(req, res) {
  const { name, relation, phone } = req.body;
  requireFields(req.body, ['name'], 'Member name is required.');
  const member = store.addMember(req.family.id, { name, relation, phone });
  res.status(201).json({ message: 'Family member added.', member });
}

export function updateMember(req, res) {
  const { name, relation, phone } = req.body;
  const member = store.updateMember(req.family.id, req.params.id, { name, relation, phone });
  res.json({ message: 'Member updated.', member });
}

export function deleteMember(req, res) {
  store.deleteMember(req.family.id, req.params.id);
  res.json({ message: 'Member removed from family space.' });
}
