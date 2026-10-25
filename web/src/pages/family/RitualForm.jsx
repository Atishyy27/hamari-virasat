import { useState } from 'react';

export default function RitualForm({ initial, categories, title, submitLabel, onSubmit, onCancel }) {
  const [form, setForm] = useState(initial);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [showFood, setShowFood] = useState(Boolean(initial.recipe_name));

  const set = (key) => (e) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    setBusy(true);
    try {
      await onSubmit(form);
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  };

  return (
    <form className="leaf leaf--plain ritual-form stack" onSubmit={submit}>
      <h2 className="panel-title">{title}</h2>

      <div className="form-row">
        <label className="field">
          <span>Ritual name</span>
          <input className="input" value={form.title} onChange={set('title')} placeholder="e.g. Ahoi Ashtami" required autoFocus />
        </label>
        <label className="field">
          <span>Kind of ritual</span>
          <select className="input" value={form.category} onChange={set('category')}>
            <option value="">Choose one</option>
            {categories.map((c) => (
              <option key={c.id} value={c.name}>{c.name}</option>
            ))}
          </select>
        </label>
      </div>

      <label className="field">
        <span>Steps, in order</span>
        <textarea className="input" value={form.steps} onChange={set('steps')} placeholder={'One step on each line\nSargi before sunrise\nEvening katha'} />
      </label>

      <div className="form-row">
        <label className="field">
          <span>Samagri</span>
          <textarea className="input" value={form.samagri} onChange={set('samagri')} placeholder={'One item on each line\nMitti ka karwa\nChhalni'} />
        </label>
        <label className="field">
          <span>Who does what</span>
          <textarea className="input" value={form.relative_roles} onChange={set('relative_roles')} placeholder={'Relative: what they do\nSaas ji: prepares the sargi'} />
        </label>
      </div>

      {showFood ? (
        <fieldset className="food">
          <legend className="field-label">Food made for it</legend>
          <label className="field">
            <span>Dish</span>
            <input className="input" value={form.recipe_name} onChange={set('recipe_name')} placeholder="e.g. Thekua" />
          </label>
          <div className="form-row">
            <label className="field">
              <span>Ingredients</span>
              <textarea className="input" value={form.recipe_ingredients} onChange={set('recipe_ingredients')} placeholder="One on each line" />
            </label>
            <label className="field">
              <span>Method</span>
              <textarea className="input" value={form.recipe_method} onChange={set('recipe_method')} />
            </label>
          </div>
        </fieldset>
      ) : (
        <button type="button" className="btn btn--quiet add-food" onClick={() => setShowFood(true)}>
          + Add the food made for it
        </button>
      )}

      <label className="field">
        <span>Songs sung</span>
        <input className="input" value={form.songs} onChange={set('songs')} placeholder="e.g. Karwa Mata ki Aarti, sung by Dadi" />
      </label>

      {error && <p className="form-error" role="alert">{error}</p>}

      <div className="form-actions">
        <button type="button" className="btn btn--line" onClick={onCancel} disabled={busy}>Cancel</button>
        <button type="submit" className="btn btn--cloth" disabled={busy}>
          {busy && <span className="spinner" aria-hidden="true" />}
          {submitLabel}
        </button>
      </div>
    </form>
  );
}
