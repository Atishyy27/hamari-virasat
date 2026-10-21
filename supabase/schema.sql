-- Hamari Virasat: database schema, row-level security, RPCs, storage and seed data.
-- Paste the whole file into the Supabase SQL editor and run it. Safe to run again.
-- Column names match the toJson keys in app/lib/data/models.dart.
--
-- To make a signed-up user the super admin (run once, by hand, with their email):
-- insert into public.profiles (id, full_name, email, role) select id, 'Super Admin', email, 'super_admin' from auth.users where email = 'you@example.com' on conflict (id) do update set role = 'super_admin', family_id = null;

-- ---------------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------------

create table if not exists public.families (
  id          text primary key default gen_random_uuid()::text,
  name        text not null,
  gotra       text not null default '',
  kuldevi     text not null default '',
  kuldevta    text not null default '',
  invite_code text not null unique,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

create table if not exists public.profiles (
  id        uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  email     text not null default '',
  role      text not null default 'member'
            check (role in ('super_admin', 'family_admin', 'member')),
  family_id text references public.families (id) on delete set null,
  -- A super admin never belongs to a family, so no family policy can ever match them.
  constraint profiles_super_admin_has_no_family
    check (role <> 'super_admin' or family_id is null)
);

-- A flat list. No parent, spouse or any other link between members: there is no tree.
create table if not exists public.family_members (
  id        text primary key default gen_random_uuid()::text,
  family_id text not null references public.families (id) on delete cascade,
  name      text not null,
  relation  text not null default '',
  phone     text not null default ''
);

-- family_id null means a built-in category that every family sees.
create table if not exists public.ritual_categories (
  id        text primary key default gen_random_uuid()::text,
  family_id text references public.families (id) on delete cascade,
  name      text not null,
  phases    text[] not null default '{}'
);

create table if not exists public.rituals (
  id             text primary key default gen_random_uuid()::text,
  family_id      text not null references public.families (id) on delete cascade,
  title          text not null default '',
  category       text not null default '',
  phase          text not null default '',
  samagri        text not null default '',
  steps          text not null default '',
  relative_roles text not null default '',
  audio_paths    text[] not null default '{}',
  created_by     uuid default auth.uid(),
  created_at     timestamptz not null default now()
);

-- A recipe always hangs off a ritual. There is no standalone recipe.
create table if not exists public.recipes (
  id          text primary key default gen_random_uuid()::text,
  ritual_id   text not null references public.rituals (id) on delete cascade,
  family_id   text not null references public.families (id) on delete cascade,
  name        text not null,
  ingredients text not null default '',
  method      text not null default ''
);

create index if not exists profiles_family_id_idx          on public.profiles (family_id);
create index if not exists family_members_family_id_idx    on public.family_members (family_id);
create index if not exists ritual_categories_family_id_idx on public.ritual_categories (family_id);
create index if not exists rituals_family_id_idx           on public.rituals (family_id);
create index if not exists recipes_ritual_id_idx           on public.recipes (ritual_id);
create index if not exists recipes_family_id_idx           on public.recipes (family_id);

-- ---------------------------------------------------------------------------
-- 2. Helper functions used by the policies
--    security definer + fixed search_path: they read profiles without going
--    through the profiles policies, which would otherwise recurse.
-- ---------------------------------------------------------------------------

-- The caller's family id, but only if they are a family user and the family is active.
-- Returns null for a super admin, a signed-out caller and a deactivated family.
create or replace function public.my_family_id()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.family_id
  from public.profiles p
  join public.families f on f.id = p.family_id
  where p.id = auth.uid()
    and p.role in ('family_admin', 'member')
    and f.active
$$;

create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role from public.profiles p where p.id = auth.uid()
$$;

-- A family admin may edit the family's details, but not these four columns.
-- Not security definer on purpose: current_user must be the real caller's role.
-- set_family_active() runs as its owner, so it passes through untouched.
create or replace function public.families_protect_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.id          := old.id;
    new.active      := old.active;
    new.invite_code := old.invite_code;
    new.created_at  := old.created_at;
  end if;
  return new;
end
$$;

drop trigger if exists families_protect_columns on public.families;
create trigger families_protect_columns
  before update on public.families
  for each row execute function public.families_protect_columns();

-- ---------------------------------------------------------------------------
-- 3. Row-level security
--    Nothing below grants a super admin any access to family content.
-- ---------------------------------------------------------------------------

alter table public.profiles          enable row level security;
alter table public.families          enable row level security;
alter table public.family_members    enable row level security;
alter table public.ritual_categories enable row level security;
alter table public.rituals           enable row level security;
alter table public.recipes           enable row level security;

revoke all on public.profiles, public.families, public.family_members,
              public.ritual_categories, public.rituals, public.recipes from anon;

-- profiles: read only from the client. Rows are created by the RPCs below,
-- so nobody can write their own role.
revoke all on public.profiles from authenticated;
grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.families, public.family_members,
      public.ritual_categories, public.rituals, public.recipes to authenticated;

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated
  using (id = auth.uid() or (family_id is not null and family_id = public.my_family_id()));

-- families: own row only. No delete policy for anyone.
drop policy if exists families_select on public.families;
create policy families_select on public.families
  for select to authenticated
  using (id = public.my_family_id());

-- Insert is allowed only for the admin's own existing id, so it can never add a
-- row (the primary key already exists). It is here so a client upsert works.
drop policy if exists families_insert on public.families;
create policy families_insert on public.families
  for insert to authenticated
  with check (id = public.my_family_id() and public.my_role() = 'family_admin');

drop policy if exists families_update on public.families;
create policy families_update on public.families
  for update to authenticated
  using (id = public.my_family_id() and public.my_role() = 'family_admin')
  with check (id = public.my_family_id() and public.my_role() = 'family_admin');

-- family_members: everyone in the family reads, only the family admin writes.
drop policy if exists family_members_select on public.family_members;
create policy family_members_select on public.family_members
  for select to authenticated
  using (family_id = public.my_family_id());

drop policy if exists family_members_insert on public.family_members;
create policy family_members_insert on public.family_members
  for insert to authenticated
  with check (family_id = public.my_family_id() and public.my_role() = 'family_admin');

drop policy if exists family_members_update on public.family_members;
create policy family_members_update on public.family_members
  for update to authenticated
  using (family_id = public.my_family_id() and public.my_role() = 'family_admin')
  with check (family_id = public.my_family_id() and public.my_role() = 'family_admin');

drop policy if exists family_members_delete on public.family_members;
create policy family_members_delete on public.family_members
  for delete to authenticated
  using (family_id = public.my_family_id() and public.my_role() = 'family_admin');

-- ritual_categories: built-ins are readable by any signed-in user, custom ones
-- only by their own family. Built-ins cannot be changed from the app.
drop policy if exists ritual_categories_select on public.ritual_categories;
create policy ritual_categories_select on public.ritual_categories
  for select to authenticated
  using (family_id is null or family_id = public.my_family_id());

drop policy if exists ritual_categories_insert on public.ritual_categories;
create policy ritual_categories_insert on public.ritual_categories
  for insert to authenticated
  with check (family_id = public.my_family_id());

drop policy if exists ritual_categories_update on public.ritual_categories;
create policy ritual_categories_update on public.ritual_categories
  for update to authenticated
  using (family_id = public.my_family_id())
  with check (family_id = public.my_family_id());

drop policy if exists ritual_categories_delete on public.ritual_categories;
create policy ritual_categories_delete on public.ritual_categories
  for delete to authenticated
  using (family_id = public.my_family_id() and public.my_role() = 'family_admin');

-- rituals: any member of the family reads and writes.
drop policy if exists rituals_select on public.rituals;
create policy rituals_select on public.rituals
  for select to authenticated
  using (family_id = public.my_family_id());

drop policy if exists rituals_insert on public.rituals;
create policy rituals_insert on public.rituals
  for insert to authenticated
  with check (family_id = public.my_family_id());

drop policy if exists rituals_update on public.rituals;
create policy rituals_update on public.rituals
  for update to authenticated
  using (family_id = public.my_family_id())
  with check (family_id = public.my_family_id());

drop policy if exists rituals_delete on public.rituals;
create policy rituals_delete on public.rituals
  for delete to authenticated
  using (family_id = public.my_family_id());

-- recipes: same as rituals, and the parent ritual must belong to the same family.
drop policy if exists recipes_select on public.recipes;
create policy recipes_select on public.recipes
  for select to authenticated
  using (family_id = public.my_family_id());

drop policy if exists recipes_insert on public.recipes;
create policy recipes_insert on public.recipes
  for insert to authenticated
  with check (
    family_id = public.my_family_id()
    and exists (select 1 from public.rituals r
                where r.id = ritual_id and r.family_id = public.my_family_id())
  );

drop policy if exists recipes_update on public.recipes;
create policy recipes_update on public.recipes
  for update to authenticated
  using (family_id = public.my_family_id())
  with check (
    family_id = public.my_family_id()
    and exists (select 1 from public.rituals r
                where r.id = ritual_id and r.family_id = public.my_family_id())
  );

drop policy if exists recipes_delete on public.recipes;
create policy recipes_delete on public.recipes
  for delete to authenticated
  using (family_id = public.my_family_id());

-- ---------------------------------------------------------------------------
-- 4. RPCs the app calls
-- ---------------------------------------------------------------------------

-- Starts a new family. The caller becomes its family admin.
create or replace function public.register_family(p_full_name text, p_family_name text)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid       uuid := auth.uid();
  v_family_id text := gen_random_uuid()::text;
  v_code      text;
  v_profile   public.profiles;
begin
  if v_uid is null then
    raise exception 'Not signed in';
  end if;
  if exists (select 1 from public.profiles where id = v_uid) then
    raise exception 'This account already has a profile';
  end if;
  if coalesce(trim(p_family_name), '') = '' then
    raise exception 'Family name is required';
  end if;

  loop
    v_code := upper(substr(md5(gen_random_uuid()::text), 1, 6));
    exit when not exists (select 1 from public.families where invite_code = v_code);
  end loop;

  insert into public.families (id, name, invite_code)
  values (v_family_id, trim(p_family_name), v_code);

  insert into public.profiles (id, full_name, email, role, family_id)
  values (
    v_uid,
    coalesce(trim(p_full_name), ''),
    coalesce((select u.email from auth.users u where u.id = v_uid), ''),
    'family_admin',
    v_family_id
  )
  returning * into v_profile;

  return v_profile;
end
$$;

-- Joins an existing, active family as a member using its invite code.
create or replace function public.join_family(p_full_name text, p_invite_code text)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid       uuid := auth.uid();
  v_family_id text;
  v_profile   public.profiles;
begin
  if v_uid is null then
    raise exception 'Not signed in';
  end if;
  if exists (select 1 from public.profiles where id = v_uid) then
    raise exception 'This account already has a profile';
  end if;

  select f.id into v_family_id
  from public.families f
  where f.invite_code = upper(trim(coalesce(p_invite_code, ''))) and f.active;

  if v_family_id is null then
    raise exception 'Invalid invite code';
  end if;

  insert into public.profiles (id, full_name, email, role, family_id)
  values (
    v_uid,
    coalesce(trim(p_full_name), ''),
    coalesce((select u.email from auth.users u where u.id = v_uid), ''),
    'member',
    v_family_id
  )
  returning * into v_profile;

  return v_profile;
end
$$;

-- The only window a super admin has onto families: four account columns, no content.
create or replace function public.list_families_for_super_admin()
returns table (id text, name text, active boolean, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.my_role() is distinct from 'super_admin' then
    raise exception 'Super admin only';
  end if;
  return query
    select f.id, f.name, f.active, f.created_at
    from public.families f
    order by f.created_at desc;
end
$$;

create or replace function public.set_family_active(p_family_id text, p_active boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.my_role() is distinct from 'super_admin' then
    raise exception 'Super admin only';
  end if;
  update public.families f set active = p_active where f.id = p_family_id;
  if not found then
    raise exception 'Family not found';
  end if;
end
$$;

revoke execute on function public.my_family_id()                       from public, anon;
revoke execute on function public.my_role()                            from public, anon;
revoke execute on function public.register_family(text, text)          from public, anon;
revoke execute on function public.join_family(text, text)              from public, anon;
revoke execute on function public.list_families_for_super_admin()      from public, anon;
revoke execute on function public.set_family_active(text, boolean)     from public, anon;

grant execute on function public.my_family_id()                        to authenticated;
grant execute on function public.my_role()                             to authenticated;
grant execute on function public.register_family(text, text)           to authenticated;
grant execute on function public.join_family(text, text)               to authenticated;
grant execute on function public.list_families_for_super_admin()       to authenticated;
grant execute on function public.set_family_active(text, boolean)      to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Storage: private bucket for folk song audio
--    Object path: <family_id>/<ritual_id>/<filename>
--    The first path segment must be the caller's own family id.
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('ritual-audio', 'ritual-audio', false)
on conflict (id) do update set public = false;

drop policy if exists ritual_audio_select on storage.objects;
create policy ritual_audio_select on storage.objects
  for select to authenticated
  using (bucket_id = 'ritual-audio'
         and (storage.foldername(name))[1] = public.my_family_id());

drop policy if exists ritual_audio_insert on storage.objects;
create policy ritual_audio_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'ritual-audio'
              and (storage.foldername(name))[1] = public.my_family_id());

drop policy if exists ritual_audio_update on storage.objects;
create policy ritual_audio_update on storage.objects
  for update to authenticated
  using (bucket_id = 'ritual-audio'
         and (storage.foldername(name))[1] = public.my_family_id())
  with check (bucket_id = 'ritual-audio'
              and (storage.foldername(name))[1] = public.my_family_id());

drop policy if exists ritual_audio_delete on storage.objects;
create policy ritual_audio_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'ritual-audio'
         and (storage.foldername(name))[1] = public.my_family_id());

-- ---------------------------------------------------------------------------
-- 6. Seed: built-in ritual categories (family_id null)
-- ---------------------------------------------------------------------------

insert into public.ritual_categories (id, family_id, name, phases) values
  ('builtin_child_birth',   null, 'Child Birth (Sanskara)',
     array['Chatti / Shashti Puja']),
  ('builtin_annaprasan',    null, 'Annaprasan', '{}'),
  ('builtin_mundan',        null, 'Mundan', '{}'),
  ('builtin_vidya_arambh',  null, 'Vidya Arambh', '{}'),
  ('builtin_puberty',       null, 'Puberty or Reaching to the Age Ritual', '{}'),
  ('builtin_boy_wedding',   null, 'Boy Wedding (Var Paksha)',
     array['Shagun', 'Haldi', 'Tilak', 'Sangeet', 'Madwa', 'Matkore',
           'Kohbar Art', 'Gidhari', 'Matri Pooja', 'Barat Prasthan']),
  ('builtin_girl_wedding',  null, 'Girl Wedding (Kanya Paksha)',
     array['Shagun', 'Haldi', 'Tilak', 'Sangeet', 'Madwa', 'Matkore',
           'Kohbar Art', 'Gidhari', 'Matri Pooja', 'Barat Prasthan']),
  ('builtin_death_ritual',  null, 'Death Ritual (Antyesti Sanskar)', '{}')
on conflict (id) do update
  set name = excluded.name, phases = excluded.phases, family_id = null;
