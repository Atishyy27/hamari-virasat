import { store } from '../services/store.js';
import { requireFields } from '../middleware/validate.js';

export function listMemories(req, res) {
  res.json({ memories: store.listMemories(req.family.id) });
}

export function addMemory(req, res) {
  const { title, type, media_path, caption, year } = req.body;
  requireFields(req.body, ['title'], 'Memory title is required.');
  const memory = store.saveMemory(req.family.id, {
    title,
    type: type || 'story',
    media_path: media_path || '',
    caption: caption || '',
    year: year || '',
    author_name: req.user.full_name
  });
  res.status(201).json({ message: 'Memory saved.', memory });
}

export function deleteMemory(req, res) {
  store.deleteMemory(req.family.id, req.params.id);
  res.json({ message: 'Memory removed.' });
}
