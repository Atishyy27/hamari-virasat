import { store } from '../services/store.js';
import { requireFields } from '../middleware/validate.js';

export function joinWaitlist(req, res) {
  requireFields(req.body, ['ritual_key'], 'ritual_key is required.');
  const entry = store.addToWaitlist(req.user.id, req.user.family_id, req.body.ritual_key);
  res.status(201).json({ message: 'Added to waitlist.', entry });
}

export function listWaitlist(req, res) {
  res.json({ waitlist: store.listWaitlist(req.user.id) });
}
