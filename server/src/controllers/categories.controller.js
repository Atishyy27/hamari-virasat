import { store } from '../services/store.js';
import { requireFields } from '../middleware/validate.js';

// Built-in (family_id == null) + caller's custom categories
export function listCategories(req, res) {
  res.json({ categories: store.listCategories(req.family.id) });
}

export function addCategory(req, res) {
  requireFields(req.body, ['name'], 'Category name is required.');
  const category = store.addCustomCategory(req.family.id, String(req.body.name).trim());
  res.status(201).json({ message: 'Custom category added.', category });
}
