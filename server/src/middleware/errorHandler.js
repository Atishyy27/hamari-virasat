import { config } from '../config.js';

// 404 for unmatched routes
export function notFoundHandler(req, res) {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
}

// Global JSON error handler: { error: message }
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  // Malformed JSON body from express.json()
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Malformed JSON body.' });
  }

  const status = Number.isInteger(err.status) && err.status >= 400 && err.status < 600 ? err.status : 500;

  if (status >= 500) {
    if (config.nodeEnv !== 'test') console.error('[API Error]:', err);
    const message = config.isProduction ? 'Internal server error' : (err.message || 'Internal server error');
    return res.status(status).json({ error: message });
  }

  return res.status(status).json({ error: err.message || 'Request failed' });
}
