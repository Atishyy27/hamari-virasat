import { badRequest } from '../utils/httpError.js';

const isMissing = (value) =>
  value === undefined || value === null || (typeof value === 'string' && value.trim() === '');

// Throws 400 with `message` if any of `fields` is missing or blank in `body`
export function requireFields(body, fields, message) {
  const missing = fields.filter(field => isMissing(body?.[field]));
  if (missing.length > 0) {
    throw badRequest(message || `Missing required fields: ${missing.join(', ')}.`);
  }
}
