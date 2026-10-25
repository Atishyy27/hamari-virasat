import { useEffect, useState } from 'react';
import { UserPlus, X } from 'lucide-react';
import { api } from '../../api/client';

export default function MembersTab({ isAdmin }) {
  const [members, setMembers] = useState(null);
  const [error, setError] = useState('');
  const [form, setForm] = useState({ name: '', relation: '', phone: '' });
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    api.listMembers()
      .then((d) => setMembers(d.members))
      .catch((err) => setError(err.message));
  }, []);

  const set = (key) => (e) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const add = async (e) => {
    e.preventDefault();
    setError('');
    setBusy(true);
    try {
      const { member } = await api.addMember(form);
      setMembers((list) => [...list, member]);
      setForm({ name: '', relation: '', phone: '' });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  const remove = async (m) => {
    if (!window.confirm(`Remove ${m.name} from the family list?`)) return;
    try {
      await api.deleteMember(m.id);
      setMembers((list) => list.filter((x) => x.id !== m.id));
    } catch (err) {
      setError(err.message);
    }
  };

  if (!members) {
    return error
      ? <p className="form-error" role="alert">{error}</p>
      : <p className="loading"><span className="spinner" aria-hidden="true" /> Loading the family…</p>;
  }

  return (
    <div className="leaf leaf--plain">
      <div className="panel-head">
        <h2 className="panel-title">Family <span className="count num">{members.length}</span></h2>
      </div>
      <p className="form-note members-note">
        One flat list, no family tree. {isAdmin ? 'Only you, as family admin, can change it.' : 'Your family admin keeps this list.'}
      </p>

      <ul className="members">
        {members.map((m) => (
          <li key={m.id}>
            <span className="member-name">{m.name}</span>
            <span className="member-relation hand">{m.relation}</span>
            <span className="member-phone num">{m.phone}</span>
            {isAdmin && !m.relation?.startsWith('Self') && (
              <button className="icon-btn" onClick={() => remove(m)} aria-label={`Remove ${m.name}`}>
                <X size={18} />
              </button>
            )}
          </li>
        ))}
      </ul>

      {error && <p className="form-error" role="alert">{error}</p>}

      {isAdmin && (
        <form className="member-form" onSubmit={add}>
          <h3 className="field-label">Add someone</h3>
          <div className="form-row form-row--3">
            <label className="field">
              <span>Name</span>
              <input className="input" value={form.name} onChange={set('name')} required />
            </label>
            <label className="field">
              <span>Relation</span>
              <input className="input" value={form.relation} onChange={set('relation')} placeholder="e.g. Chachi ji" />
            </label>
            <label className="field">
              <span>Phone <small>(optional)</small></span>
              <input className="input" type="tel" value={form.phone} onChange={set('phone')} placeholder="+91" />
            </label>
          </div>
          <button className="btn btn--cloth btn--small" type="submit" disabled={busy}>
            <UserPlus size={18} aria-hidden="true" /> Add to the family
          </button>
        </form>
      )}
    </div>
  );
}
