import { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2, ArrowLeft, UtensilsCrossed, Music } from 'lucide-react';
import { api } from '../../api/client';
import { emptyRitual, formToRitual, ritualToForm, statusOf, toLines, toRoles } from '../../lib/rituals';
import { starterRituals } from '../../data/exampleFamily';
import RitualForm from './RitualForm';

export default function RitualsTab({ startWith }) {
  const [rituals, setRituals] = useState(null);
  const [categories, setCategories] = useState([]);
  const [error, setError] = useState('');
  // view: list | new | detail | edit
  const [view, setView] = useState(startWith ? 'new' : 'list');
  const [selectedId, setSelectedId] = useState(null);
  const [draftTitle, setDraftTitle] = useState(startWith || '');

  useEffect(() => {
    Promise.all([api.listRituals(), api.listCategories()])
      .then(([r, c]) => {
        setRituals(r.rituals);
        setCategories(c.categories);
      })
      .catch((err) => setError(err.message));
  }, []);

  const selected = rituals?.find((r) => r.id === selectedId);

  const startNew = (title = '') => {
    setDraftTitle(title);
    setView('new');
  };

  const create = async (form) => {
    const { ritual } = await api.createRitual(formToRitual(form));
    setRituals((list) => [...list, ritual]);
    setSelectedId(ritual.id);
    setView('detail');
  };

  const update = async (form) => {
    const { ritual } = await api.updateRitual(selected.id, formToRitual(form, selected));
    setRituals((list) => list.map((r) => (r.id === ritual.id ? ritual : r)));
    setView('detail');
  };

  const remove = async () => {
    if (!window.confirm(`Remove “${selected.title}” and its recipes from the family book?`)) return;
    try {
      await api.deleteRitual(selected.id);
      setRituals((list) => list.filter((r) => r.id !== selected.id));
      setView('list');
    } catch (err) {
      setError(err.message);
    }
  };

  if (error && !rituals) return <p className="form-error" role="alert">{error}</p>;
  if (!rituals) return <p className="loading"><span className="spinner" aria-hidden="true" /> Opening your book…</p>;

  if (view === 'new') {
    return (
      <RitualForm
        initial={{ ...emptyRitual, title: draftTitle }}
        categories={categories}
        title="Write down a ritual"
        submitLabel="Save to the book"
        onSubmit={create}
        onCancel={() => setView('list')}
      />
    );
  }

  if (view === 'edit' && selected) {
    return (
      <RitualForm
        initial={ritualToForm(selected)}
        categories={categories}
        title={`Edit ${selected.title}`}
        submitLabel="Save changes"
        onSubmit={update}
        onCancel={() => setView('detail')}
      />
    );
  }

  if (view === 'detail' && selected) {
    return <RitualDetail ritual={selected} onBack={() => setView('list')} onEdit={() => setView('edit')} onDelete={remove} error={error} />;
  }

  if (rituals.length === 0) {
    return (
      <div className="leaf leaf--plain empty">
        <h2 className="panel-title">Your book is empty</h2>
        <p>Start with a ritual your family performs every year.</p>
        <ul className="starters-inline">
          {starterRituals.slice(0, 6).map((r) => (
            <li key={r.title}>
              <button className="starter" onClick={() => startNew(r.title)}>
                <span className="deva" lang="hi">{r.hindi}</span>
                <span>{r.title}</span>
              </button>
            </li>
          ))}
        </ul>
        <button className="btn btn--cloth" onClick={() => startNew()}>
          <Plus size={18} aria-hidden="true" /> Write down a different ritual
        </button>
      </div>
    );
  }

  return (
    <div className="leaf leaf--plain">
      <div className="panel-head">
        <h2 className="panel-title">In your book <span className="count num">{rituals.length}</span></h2>
        <button className="btn btn--cloth btn--small" onClick={() => startNew()}>
          <Plus size={18} aria-hidden="true" /> Add a ritual
        </button>
      </div>
      {error && <p className="form-error" role="alert">{error}</p>}
      <ul className="entries">
        {rituals.map((r) => {
          const status = statusOf(r);
          return (
            <li key={r.id}>
              <button className="entry" onClick={() => { setSelectedId(r.id); setView('detail'); }}>
                <span className="entry-title">{r.title}</span>
                <span className="entry-meta">{r.category || 'Uncategorised'} · {toLines(r.steps).length} steps</span>
                <span className={`stamp stamp--${status.tone}`}>{status.label}</span>
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function RitualDetail({ ritual, onBack, onEdit, onDelete, error }) {
  const status = statusOf(ritual);
  const steps = toLines(ritual.steps);
  const samagri = toLines(ritual.samagri);
  const roles = toRoles(ritual.relative_roles);

  return (
    <article className="leaf ritual-detail">
      <div className="detail-bar">
        <button className="btn btn--quiet" onClick={onBack}>
          <ArrowLeft size={18} aria-hidden="true" /> All rituals
        </button>
        <div className="detail-actions">
          <button className="btn btn--line btn--small" onClick={onEdit}><Pencil size={16} aria-hidden="true" /> Edit</button>
          <button className="btn btn--quiet danger" onClick={onDelete}><Trash2 size={16} aria-hidden="true" /> Remove</button>
        </div>
      </div>

      <header className="page-head">
        <div>
          <h2 className="detail-title">{ritual.title}</h2>
          {ritual.category && <p className="form-note">{ritual.category}{ritual.phase ? ` · ${ritual.phase}` : ''}</p>}
        </div>
        <span className={`stamp stamp--${status.tone}`}>{status.label}</span>
      </header>

      {error && <p className="form-error" role="alert">{error}</p>}

      <h3 className="page-label">Vidhi <span className="deva" lang="hi">विधि</span></h3>
      {steps.length ? (
        <ol className="detail-steps">
          {steps.map((s, i) => <li key={i}>{s}</li>)}
        </ol>
      ) : <p className="form-note">No steps yet. <button className="btn btn--quiet" onClick={onEdit}>Add them</button></p>}

      <div className="page-columns">
        <div>
          <h3 className="page-label">Samagri <span className="deva" lang="hi">सामग्री</span></h3>
          {samagri.length ? <ul className="detail-list">{samagri.map((s, i) => <li key={i}>{s}</li>)}</ul> : <p className="form-note">Not written yet.</p>}
        </div>
        <div>
          <h3 className="page-label">Who does what</h3>
          {roles.length ? (
            <dl className="roles">
              {roles.map((r, i) => (
                <div key={i}>
                  {r.who && <dt>{r.who}</dt>}
                  <dd>{r.task}</dd>
                </div>
              ))}
            </dl>
          ) : <p className="form-note">Not written yet.</p>}
        </div>
      </div>

      {(ritual.recipes?.length > 0 || ritual.songs) && (
        <footer className="page-foot">
          {ritual.recipes?.map((rec) => (
            <details key={rec.id || rec.name} className="recipe">
              <summary><UtensilsCrossed size={18} aria-hidden="true" /> Made for it: <strong>{rec.name}</strong></summary>
              {toLines(rec.ingredients).length > 0 && (
                <ul className="detail-list">{toLines(rec.ingredients).map((s, i) => <li key={i}>{s}</li>)}</ul>
              )}
              {rec.method && <p>{rec.method}</p>}
            </details>
          ))}
          {ritual.songs && <p><Music size={18} aria-hidden="true" /> <span>Sung: <strong>{ritual.songs}</strong></span></p>}
        </footer>
      )}
    </article>
  );
}
