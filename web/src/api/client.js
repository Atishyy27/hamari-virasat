// Thin wrapper around the Express API. Errors are thrown, never swallowed:
// a failed sign-in must look failed, not fall back to sample data.
const API_BASE = (import.meta.env.VITE_API_URL || '/api').replace(/\/+$/, '');
const TOKEN_KEY = 'hv_token';

export class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

function readToken() {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

let token = readToken();

export function setToken(next) {
  token = next || null;
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {
    // Private mode: the session simply won't survive a reload.
  }
}

export function hasToken() {
  return Boolean(token);
}

async function request(path, { method = 'GET', body } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  let res;
  try {
    res = await fetch(`${API_BASE}${path}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body)
    });
  } catch {
    throw new ApiError('Could not reach the server. Check your connection and try again.', 0);
  }

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    // A proxy or gateway error has no JSON body: the API itself is down.
    const fallback = res.status >= 502
      ? 'Our server is not responding right now. Please try again in a minute.'
      : `Something went wrong (${res.status}).`;
    throw new ApiError(data.error || fallback, res.status);
  }
  return data;
}

async function withSession(promise) {
  const data = await promise;
  if (data.token) setToken(data.token);
  return data;
}

export const api = {
  // Auth
  login: (email, password) => withSession(request('/auth/login', { method: 'POST', body: { email, password } })),
  demoLogin: (type = 'admin') => withSession(request('/auth/demo-login', { method: 'POST', body: { type } })),
  registerFamily: (form) => withSession(request('/auth/register-family', { method: 'POST', body: form })),
  joinFamily: (form) => withSession(request('/auth/join-family', { method: 'POST', body: form })),
  me: () => request('/auth/me'),

  // Family
  updateFamily: (updates) => request('/family/me', { method: 'PATCH', body: updates }),
  listMembers: () => request('/members'),
  addMember: (member) => request('/members', { method: 'POST', body: member }),
  deleteMember: (id) => request(`/members/${id}`, { method: 'DELETE' }),

  // Rituals
  listCategories: () => request('/categories'),
  listRituals: () => request('/rituals'),
  createRitual: (ritual) => request('/rituals', { method: 'POST', body: ritual }),
  updateRitual: (id, ritual) => request(`/rituals/${id}`, { method: 'PUT', body: ritual }),
  deleteRitual: (id) => request(`/rituals/${id}`, { method: 'DELETE' }),

  // Operator console
  listFamiliesForSuperAdmin: () => request('/super-admin/families'),
  setFamilyActive: (id, active) => request(`/super-admin/families/${id}/status`, { method: 'PUT', body: { active } }),
  checkRitualsAsSuperAdmin: () => request('/super-admin/test-rls-rituals-leak'),

  submitEnquiry: (enquiry) => request('/enquiries', { method: 'POST', body: enquiry })
};
