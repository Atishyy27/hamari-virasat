import { store } from '../services/store.js';
import { badRequest } from '../utils/httpError.js';

export function listOrders(req, res) {
  res.json({ orders: store.listOrders(req.family.id) });
}

// Price per ritual is server-side only; any client-sent price is ignored
export function createOrder(req, res) {
  const { ritual_keys } = req.body;
  if (!Array.isArray(ritual_keys) || ritual_keys.length === 0) {
    throw badRequest('At least one ritual key is required to order.');
  }
  const order = store.createOrder(req.family.id, req.user.id, ritual_keys);
  res.status(201).json({ message: 'Order created successfully.', order });
}
