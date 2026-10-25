import { useEffect, useState } from 'react';
import { Search, ShieldCheck } from 'lucide-react';
import AppShell from '../../components/layout/AppShell';
import { api } from '../../api/client';
import { useSession } from '../../context/SessionContext';

export default function AdminPage() {
  const session = useSession();

  useEffect(() => {
    document.title = 'Operator console · Hamari Virasat';
  }, []);

  if (session.status === 'checking') {
    return <AppShell label="Operator console"><p className="loading wrap"><span className="spinner" aria-hidden="true" /> Checking your session…</p></AppShell>;
  }

  if (session.status !== 'signed-in') {
    return <AppShell label="Operator console"><OperatorSignIn /></AppShell>;
  }

  if (session.user.role !== 'super_admin') {
    return (
      <AppShell label="Operator console" onSignOut={session.signOut}>
        <div className="wrap">
          <div className="leaf leaf--plain empty">
            <h1 className="panel-title">Operators only</h1>
            <p>You are signed in to a family book. Sign out and sign in with the operator account to continue.</p>
          </div>
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell label="Operator console" onSignOut={session.signOut}>
      <Console />
    </AppShell>
  );
}

function OperatorSignIn() {
  const { login } = useSession();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    setBusy(true);
    try {
      await login(email, password);
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  };

  return (
    <div className="auth">
      <form className="leaf auth-leaf stack" onSubmit={submit}>
        <h1 className="auth-title">Operator sign in</h1>
        <p className="form-note">Operators can switch family accounts on or off. They cannot read any family’s book.</p>
        <label className="field">
          <span>Email</span>
          <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="username" required />
        </label>
        <label className="field">
          <span>Password</span>
          <input className="input" type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" required />
        </label>
        {error && <p className="form-error" role="alert">{error}</p>}
        <button className="btn btn--cloth" type="submit" disabled={busy}>
          {busy && <span className="spinner" aria-hidden="true" />} Sign in
        </button>
      </form>
    </div>
  );
}

function Console() {
  const [families, setFamilies] = useState(null);
  const [query, setQuery] = useState('');
  const [error, setError] = useState('');
  const [pending, setPending] = useState(null);
  const [check, setCheck] = useState(null);

  useEffect(() => {
    api.listFamiliesForSuperAdmin()
      .then((d) => setFamilies(d.families))
      .catch((err) => setError(err.message));
  }, []);

  const toggle = async (fam) => {
    if (fam.active && !window.confirm(`Deactivate ${fam.name}? Its members will not be able to sign in until you turn it back on.`)) return;
    setPending(fam.id);
    setError('');
    try {
      const { family } = await api.setFamilyActive(fam.id, !fam.active);
      setFamilies((list) => list.map((f) => (f.id === family.id ? family : f)));
    } catch (err) {
      setError(err.message);
    } finally {
      setPending(null);
    }
  };

  const runCheck = async () => {
    try {
      setCheck(await api.checkRitualsAsSuperAdmin());
    } catch (err) {
      setError(err.message);
    }
  };

  const shown = (families || []).filter((f) => f.name.toLowerCase().includes(query.trim().toLowerCase()));
  const activeCount = (families || []).filter((f) => f.active).length;

  return (
    <div className="wrap family">
      <header className="family-head">
        <div>
          <h1 className="family-name">Family accounts</h1>
          {families && <p className="family-details num">{activeCount} active of {families.length}</p>}
        </div>
      </header>

      <div className="leaf leaf--plain">
        <div className="panel-head">
          <label className="search">
            <Search size={18} aria-hidden="true" />
            <span className="sr-only">Search families</span>
            <input className="input" value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search by family name" />
          </label>
        </div>

        {error && <p className="form-error" role="alert">{error}</p>}
        {!families && !error && <p className="loading"><span className="spinner" aria-hidden="true" /> Loading…</p>}

        {families && (
          <table className="accounts">
            <thead>
              <tr>
                <th scope="col">Family</th>
                <th scope="col">Joined</th>
                <th scope="col">Status</th>
                <th scope="col"><span className="sr-only">Action</span></th>
              </tr>
            </thead>
            <tbody>
              {shown.map((f) => (
                <tr key={f.id}>
                  <td className="accounts-name">{f.name}</td>
                  <td className="num">{new Date(f.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</td>
                  <td><span className={`stamp ${f.active ? 'stamp--done' : 'stamp--draft'}`}>{f.active ? 'Active' : 'Off'}</span></td>
                  <td className="accounts-action">
                    <button className={`btn btn--small ${f.active ? 'btn--line' : 'btn--cloth'}`} onClick={() => toggle(f)} disabled={pending === f.id}>
                      {f.active ? 'Deactivate' : 'Activate'}
                    </button>
                  </td>
                </tr>
              ))}
              {shown.length === 0 && (
                <tr><td colSpan={4} className="form-note">No family matches “{query}”.</td></tr>
              )}
            </tbody>
          </table>
        )}
      </div>

      <div className="leaf leaf--plain privacy-check">
        <h2 className="panel-title"><ShieldCheck size={22} aria-hidden="true" /> Privacy check</h2>
        <p className="form-note">Ask the database for every family’s rituals using this operator account.</p>
        <button className="btn btn--line btn--small" onClick={runCheck}>Run the check</button>
        {check && (
          <p className="check-result" role="status">
            <strong className="num">{check.result_rows_count}</strong> rows returned. {check.result_rows_count === 0 ? 'Operators cannot read family content.' : 'Unexpected: investigate before going live.'}
          </p>
        )}
      </div>
    </div>
  );
}
