// API tests: node:test + global fetch against the app on an ephemeral port
import { test, before, after, describe } from 'node:test';
import assert from 'node:assert/strict';

process.env.NODE_ENV = 'test';
const { default: app } = await import('../src/app.js');
const { store } = await import('../src/services/store.js');

const DEMO_PASSWORD = 'Virasat@2026';
let server;
let baseUrl;

async function api(method, path, { token, body } = {}) {
  const headers = {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : (typeof body === 'string' ? body : JSON.stringify(body))
  });
  const data = await res.json();
  return { status: res.status, data };
}

const demoLogin = async (type) => (await api('POST', '/api/auth/demo-login', { body: { type } })).data.token;

before(async () => {
  store.reset();
  await new Promise(resolve => {
    server = app.listen(0, () => {
      baseUrl = `http://127.0.0.1:${server.address().port}`;
      resolve();
    });
  });
});

after(() => new Promise(resolve => server.close(resolve)));

test('health check', async () => {
  const { status, data } = await api('GET', '/api/health');
  assert.equal(status, 200);
  assert.equal(data.status, 'ok');
});

test('unknown route and malformed JSON return JSON errors', async () => {
  const missing = await api('GET', '/api/nope');
  assert.equal(missing.status, 404);
  assert.match(missing.data.error, /Route not found/);

  const bad = await api('POST', '/api/auth/login', { body: '{"email":' });
  assert.equal(bad.status, 400);
  assert.equal(bad.data.error, 'Malformed JSON body.');
});

describe('auth', () => {
  test('login succeeds with normalised email and hides passwordHash', async () => {
    const { status, data } = await api('POST', '/api/auth/login', {
      body: { email: '  Demo@Example.com ', password: DEMO_PASSWORD }
    });
    assert.equal(status, 200);
    assert.ok(data.token);
    assert.deepEqual(Object.keys(data.user).sort(), ['email', 'family_id', 'full_name', 'id', 'role']);
    assert.equal(data.user.role, 'family_admin');
    assert.equal(data.family.id, 'fam_mishra');
    assert.ok(!JSON.stringify(data).includes('passwordHash'));
  });

  test('login with wrong password returns 401', async () => {
    const { status, data } = await api('POST', '/api/auth/login', {
      body: { email: 'demo@example.com', password: 'wrong-password' }
    });
    assert.equal(status, 401);
    assert.equal(data.error, 'Invalid email or password.');
  });

  test('stored passwords are bcrypt hashes', () => {
    for (const user of store.users) assert.match(user.passwordHash, /^\$2[aby]\$/);
  });

  test('demo-login admin returns token, user and family', async () => {
    const { status, data } = await api('POST', '/api/auth/demo-login', { body: { type: 'admin' } });
    assert.equal(status, 200);
    assert.ok(data.token);
    assert.equal(data.user.email, 'demo@example.com');
    assert.equal(data.family.id, 'fam_mishra');
  });

  test('register enforces min password length, then /me works', async () => {
    const short = await api('POST', '/api/auth/register-family', {
      body: { name: 'Asha', email: 'asha@example.com', password: 'short', family_name: 'Verma' }
    });
    assert.equal(short.status, 400);

    const ok = await api('POST', '/api/auth/register-family', {
      body: { name: 'Asha', email: ' Asha@Example.com ', password: 'longenough1', family_name: 'Verma' }
    });
    assert.equal(ok.status, 201);
    assert.equal(ok.data.user.email, 'asha@example.com');
    assert.equal(ok.data.user.role, 'family_admin');

    const dupe = await api('POST', '/api/auth/register-family', {
      body: { name: 'Asha', email: 'ASHA@example.com', password: 'longenough1', family_name: 'Verma' }
    });
    assert.equal(dupe.status, 400);

    const me = await api('GET', '/api/auth/me', { token: ok.data.token });
    assert.equal(me.status, 200);
    assert.equal(me.data.family.id, ok.data.family.id);
    assert.equal(me.data.user.passwordHash, undefined);
  });
});

describe('family content', () => {
  let adminToken;
  let memberToken;

  before(async () => {
    adminToken = await demoLogin('admin');
    memberToken = await demoLogin('member');
  });

  test('family/me returns caller family', async () => {
    const { status, data } = await api('GET', '/api/family/me', { token: adminToken });
    assert.equal(status, 200);
    assert.equal(data.family.name.length > 0, true);
    assert.equal(data.family.id, 'fam_mishra');
  });

  test('admin can add and delete members; member gets 403', async () => {
    const added = await api('POST', '/api/members', { token: adminToken, body: { name: 'Test Cousin', relation: 'Cousin' } });
    assert.equal(added.status, 201);
    const id = added.data.member.id;

    const forbidden = await api('POST', '/api/members', { token: memberToken, body: { name: 'Nope' } });
    assert.equal(forbidden.status, 403);
    const forbiddenDelete = await api('DELETE', `/api/members/${id}`, { token: memberToken });
    assert.equal(forbiddenDelete.status, 403);

    const missingName = await api('POST', '/api/members', { token: adminToken, body: {} });
    assert.equal(missingName.status, 400);

    const removed = await api('DELETE', `/api/members/${id}`, { token: adminToken });
    assert.equal(removed.status, 200);
    const again = await api('DELETE', `/api/members/${id}`, { token: adminToken });
    assert.equal(again.status, 404);
  });

  test('ritual create, get and delete', async () => {
    const created = await api('POST', '/api/rituals', {
      token: memberToken,
      body: { title: 'Test Puja', steps: ['one', 'two'], recipes: [{ name: 'Kheer', ingredients: ['milk', 'rice'] }] }
    });
    assert.equal(created.status, 201);
    const { ritual } = created.data;
    assert.equal(ritual.steps, 'one\ntwo');
    assert.equal(ritual.recipes.length, 1);

    const fetched = await api('GET', `/api/rituals/${ritual.id}`, { token: adminToken });
    assert.equal(fetched.status, 200);
    assert.equal(fetched.data.ritual.title, 'Test Puja');

    const deleted = await api('DELETE', `/api/rituals/${ritual.id}`, { token: adminToken });
    assert.equal(deleted.status, 200);
    const gone = await api('GET', `/api/rituals/${ritual.id}`, { token: adminToken });
    assert.equal(gone.status, 404);
  });

  test('another family cannot see or delete this family rituals', async () => {
    const other = await api('POST', '/api/auth/register-family', {
      body: { name: 'Ravi', email: 'ravi@example.com', password: 'longenough1', family_name: 'Gupta' }
    });
    const list = await api('GET', '/api/rituals', { token: other.data.token });
    assert.equal(list.data.rituals.length, 0);
    const del = await api('DELETE', '/api/rituals/rit_karwa', { token: other.data.token });
    assert.equal(del.status, 404);
  });

  test('orders ignore client-sent price', async () => {
    const { status, data } = await api('POST', '/api/orders', {
      token: adminToken,
      body: { ritual_keys: ['a', 'b'], price_per_ritual: 0 }
    });
    assert.equal(status, 201);
    const subtotal = 2 * 299;
    assert.equal(data.order.amount, subtotal - data.order.discount);
    assert.ok(data.order.amount > 0);
  });
});

describe('super admin', () => {
  let superToken;

  before(async () => {
    superToken = await demoLogin('super');
  });

  test('super admin gets 403 on rituals and 0 rows from RLS leak test', async () => {
    const rituals = await api('GET', '/api/rituals', { token: superToken });
    assert.equal(rituals.status, 403);

    const leak = await api('GET', '/api/super-admin/test-rls-rituals-leak', { token: superToken });
    assert.equal(leak.status, 200);
    assert.equal(leak.data.result_rows_count, 0);
    assert.deepEqual(leak.data.rows, []);
  });

  test('families list exposes only id, name, active, created_at', async () => {
    const { status, data } = await api('GET', '/api/super-admin/families', { token: superToken });
    assert.equal(status, 200);
    for (const fam of data.families) {
      assert.deepEqual(Object.keys(fam).sort(), ['active', 'created_at', 'id', 'name']);
    }
  });

  test('deactivating a family blocks its users from login and /me', async () => {
    const reg = await api('POST', '/api/auth/register-family', {
      body: { name: 'Meera', email: 'meera@example.com', password: 'longenough1', family_name: 'Joshi' }
    });
    const familyId = reg.data.family.id;

    const off = await api('PUT', `/api/super-admin/families/${familyId}/status`, { token: superToken, body: { active: false } });
    assert.equal(off.status, 200);
    assert.equal(off.data.family.active, false);

    const login = await api('POST', '/api/auth/login', { body: { email: 'meera@example.com', password: 'longenough1' } });
    assert.equal(login.status, 403);
    const me = await api('GET', '/api/auth/me', { token: reg.data.token });
    assert.equal(me.status, 403);

    const on = await api('PUT', `/api/super-admin/families/${familyId}/status`, { token: superToken, body: { active: true } });
    assert.equal(on.data.family.active, true);
    const loginAgain = await api('POST', '/api/auth/login', { body: { email: 'meera@example.com', password: 'longenough1' } });
    assert.equal(loginAgain.status, 200);

    const missing = await api('PUT', '/api/super-admin/families/fam_nope/status', { token: superToken, body: { active: true } });
    assert.equal(missing.status, 404);
  });

  test('demo-login refuses a deactivated family', async () => {
    store.findFamilyById('fam_mishra').active = false;
    try {
      const { status } = await api('POST', '/api/auth/demo-login', { body: { type: 'admin' } });
      assert.equal(status, 403);
    } finally {
      store.findFamilyById('fam_mishra').active = true;
    }
  });

  test('enquiries: public create, super-admin-only list', async () => {
    const created = await api('POST', '/api/enquiries', { body: { name: 'Visitor', phone: '+91 90000 00000', message: 'Hi' } });
    assert.equal(created.status, 201);

    const anon = await api('GET', '/api/enquiries');
    assert.equal(anon.status, 401);
    const asAdmin = await api('GET', '/api/enquiries', { token: await demoLogin('admin') });
    assert.equal(asAdmin.status, 403);

    const asSuper = await api('GET', '/api/enquiries', { token: superToken });
    assert.equal(asSuper.status, 200);
    assert.ok(asSuper.data.enquiries.some(e => e.name === 'Visitor'));
  });
});

test('store seeds are deep-cloned', async () => {
  const { initialFamilies } = await import('../src/data/seedData.js');
  store.findFamilyById('fam_mishra').gotra = 'Mutated';
  assert.notEqual(initialFamilies.find(f => f.id === 'fam_mishra').gotra, 'Mutated');
  store.reset();
});
