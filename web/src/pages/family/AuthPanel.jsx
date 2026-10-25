import { useState } from 'react';
import { useSession } from '../../context/SessionContext';

const MODES = [
  { id: 'new', label: 'New book' },
  { id: 'join', label: 'Join with code' },
  { id: 'signin', label: 'Sign in' }
];

const intro = {
  new: 'You’ll be the family admin. Invite the others with a code afterwards.',
  join: 'Ask your family admin for the invite code. It looks like SHARMA-1092.',
  signin: 'Welcome back.'
};

export default function AuthPanel({ initialMode = 'new', initialFamilyName = '' }) {
  const session = useSession();
  const [mode, setMode] = useState(MODES.some((m) => m.id === initialMode) ? initialMode : 'new');
  const [form, setForm] = useState({
    name: '',
    email: '',
    password: '',
    family_name: initialFamilyName,
    invite_code: ''
  });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const set = (key) => (e) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const run = async (action) => {
    setError('');
    setBusy(true);
    try {
      await action();
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  };

  const submit = (e) => {
    e.preventDefault();
    if (mode === 'signin') return run(() => session.login(form.email, form.password));
    if (mode === 'join') {
      return run(() => session.joinFamily({
        name: form.name, email: form.email, password: form.password, invite_code: form.invite_code
      }));
    }
    return run(() => session.registerFamily({
      name: form.name, email: form.email, password: form.password, family_name: form.family_name
    }));
  };

  return (
    <div className="auth">
      <div className="leaf auth-leaf">
        <h1 className="auth-title">Your family book</h1>

        <div className="segmented" role="tablist" aria-label="How do you want to start?">
          {MODES.map((m) => (
            <button
              key={m.id}
              role="tab"
              aria-selected={mode === m.id}
              onClick={() => { setMode(m.id); setError(''); }}
            >
              {m.label}
            </button>
          ))}
        </div>

        <p className="form-note auth-intro">{intro[mode]}</p>

        <form className="stack" onSubmit={submit}>
          {mode === 'new' && (
            <label className="field">
              <span>Family name</span>
              <input className="input" value={form.family_name} onChange={set('family_name')} placeholder="e.g. Sharma Parivar" required />
            </label>
          )}
          {mode === 'join' && (
            <label className="field">
              <span>Invite code</span>
              <input
                className="input input--code"
                value={form.invite_code}
                onChange={set('invite_code')}
                placeholder="SHARMA-1092"
                autoCapitalize="characters"
                required
              />
            </label>
          )}
          {mode !== 'signin' && (
            <label className="field">
              <span>Your name</span>
              <input className="input" value={form.name} onChange={set('name')} autoComplete="name" required />
            </label>
          )}
          <label className="field">
            <span>Email</span>
            <input className="input" type="email" value={form.email} onChange={set('email')} autoComplete="email" required />
          </label>
          <label className="field">
            <span>Password</span>
            <input
              className="input"
              type="password"
              value={form.password}
              onChange={set('password')}
              autoComplete={mode === 'signin' ? 'current-password' : 'new-password'}
              minLength={mode === 'signin' ? undefined : 8}
              required
            />
            {mode !== 'signin' && <small>At least 8 characters.</small>}
          </label>

          {error && <p className="form-error" role="alert">{error}</p>}

          <button className="btn btn--cloth" type="submit" disabled={busy}>
            {busy && <span className="spinner" aria-hidden="true" />}
            {mode === 'signin' ? 'Sign in' : mode === 'join' ? 'Join the family' : 'Create the family book'}
          </button>
        </form>

        <div className="auth-demo">
          <p>Just looking?</p>
          <button className="btn btn--line btn--small" disabled={busy} onClick={() => run(() => session.demoLogin('admin'))}>
            Open the example family
          </button>
        </div>
      </div>
    </div>
  );
}
