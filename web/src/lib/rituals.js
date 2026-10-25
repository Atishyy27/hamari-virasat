// The API stores list fields as newline-separated text.
export function toLines(value) {
  if (Array.isArray(value)) return value.filter(Boolean);
  return String(value || '')
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean);
}

// "Saas ji: prepares the sargi" -> { who, task }
export function toRoles(value) {
  return toLines(value).map((line) => {
    const i = line.indexOf(':');
    return i === -1 ? { who: '', task: line } : { who: line.slice(0, i).trim(), task: line.slice(i + 1).trim() };
  });
}

export const STATUS = {
  draft: { label: 'In progress', tone: 'draft' },
  submitted: { label: 'Sent to us', tone: 'draft' },
  draft_ready: { label: 'Draft ready', tone: 'draft' },
  approved: { label: 'Recorded', tone: 'done' }
};

export function statusOf(ritual) {
  return STATUS[ritual.status] || STATUS.draft;
}

export const emptyRitual = {
  title: '',
  category: '',
  steps: '',
  samagri: '',
  relative_roles: '',
  songs: '',
  additional_info: '',
  recipe_name: '',
  recipe_ingredients: '',
  recipe_method: ''
};

export function ritualToForm(r) {
  const recipe = r.recipes?.[0] || {};
  return {
    title: r.title || '',
    category: r.category || '',
    steps: toLines(r.steps).join('\n'),
    samagri: toLines(r.samagri).join('\n'),
    relative_roles: toLines(r.relative_roles).join('\n'),
    songs: r.songs || '',
    additional_info: r.additional_info || '',
    recipe_name: recipe.name || '',
    recipe_ingredients: toLines(recipe.ingredients).join('\n'),
    recipe_method: recipe.method || ''
  };
}

// Keeps every recipe after the first untouched, since the form edits one.
export function formToRitual(form, existing) {
  const others = existing?.recipes?.slice(1) || [];
  const first = form.recipe_name.trim()
    ? [{ id: existing?.recipes?.[0]?.id, name: form.recipe_name.trim(), ingredients: form.recipe_ingredients, method: form.recipe_method }]
    : [];
  return {
    title: form.title.trim(),
    category: form.category,
    phase: existing?.phase || '',
    status: existing?.status || 'draft',
    steps: form.steps,
    samagri: form.samagri,
    relative_roles: form.relative_roles,
    songs: form.songs,
    additional_info: form.additional_info,
    audio_paths: existing?.audio_paths || [],
    created_at: existing?.created_at,
    recipes: [...first, ...others]
  };
}
