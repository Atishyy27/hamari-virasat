import { store } from '../services/store.js';

export function getMyFamily(req, res) {
  res.json({ family: req.family });
}

// Family admin updates gotra, kuldevi, kuldevta, name (invite_code / active are locked)
export function updateMyFamily(req, res) {
  const { gotra, kuldevi, kuldevta, name } = req.body;
  const family = store.updateFamily(req.family.id, { gotra, kuldevi, kuldevta, name });
  res.json({ message: 'Family details updated successfully.', family });
}
