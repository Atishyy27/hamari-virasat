import { store } from '../services/store.js';
import { badRequest } from '../utils/httpError.js';

// Public contact form / elder dictation assistance
export function createEnquiry(req, res) {
  const { name, phone, email, message, family_id } = req.body;
  if (!name || (!phone && !email)) {
    throw badRequest('Name and either phone or email are required.');
  }
  const enquiry = store.addEnquiry({ name, phone, email, message, family_id });
  res.status(201).json({
    message: 'Enquiry received. Our heritage concierge team will reach out soon.',
    enquiry
  });
}

// Super admin only (contains contact details)
export function listEnquiries(req, res) {
  res.json({ enquiries: store.listEnquiries() });
}
