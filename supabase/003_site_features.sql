-- Hamari Virasat: what the website offers, inside the app.
--   rituals gain a documentation status, the catalogue ritual they came from, songs,
--   additional information, photos with captions and the catalogue's other sub-sections.
--   New tables: ritual_orders (paid catalogue rituals), waitlist, enquiries.
-- Run after schema.sql and 002_memories.sql, in the Supabase SQL editor. Safe to run again.
-- Column names match the toJson keys in app/lib/data/models.dart.

-- ---------------------------------------------------------------------------
-- 1. Rituals: new columns
--    status is added with default 'approved' so rituals that already exist stay
--    finished, then the default moves to 'draft' for everything created from here on.
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from information_schema.columns
                 where table_schema = 'public' and table_name = 'rituals'
                   and column_name = 'status') then
    alter table public.rituals add column status text not null default 'approved';
  end if;
end $$;

alter table public.rituals alter column status set default 'draft';

alter table public.rituals drop constraint if exists rituals_status_check;
alter table public.rituals add constraint rituals_status_check
  check (status in ('draft', 'submitted', 'draft_ready', 'approved'));

alter table public.rituals add column if not exists template_key    text   not null default '';
alter table public.rituals add column if not exists songs           text   not null default '';
alter table public.rituals add column if not exists additional_info text   not null default '';
alter table public.rituals add column if not exists photo_paths     text[] not null default '{}';
alter table public.rituals add column if not exists photo_captions  text[] not null default '{}';
alter table public.rituals add column if not exists sections        jsonb  not null default '{}'::jsonb;

-- Ritual photos live in the existing private 'memories' bucket under
--   <family_id>/rituals/<ritual_id>/<filename>
-- The bucket's policies key on the first path segment, so nothing new is needed.

-- ---------------------------------------------------------------------------
-- 2. Orders: catalogue rituals a family has paid for
-- ---------------------------------------------------------------------------

create table if not exists public.ritual_orders (
  id          text primary key default gen_random_uuid()::text,
  family_id   text not null references public.families (id) on delete cascade,
  ritual_keys text[] not null default '{}',
  amount      integer not null default 0 check (amount >= 0),
  discount    integer not null default 0 check (discount >= 0),
  status      text not null default 'paid' check (status in ('paid', 'refunded')),
  created_by  uuid default auth.uid(),
  created_at  timestamptz not null default now()
);

create index if not exists ritual_orders_family_id_idx on public.ritual_orders (family_id);

alter table public.ritual_orders enable row level security;

revoke all on public.ritual_orders from anon;
grant select, insert on public.ritual_orders to authenticated;

-- Family only, through my_family_id(), which is null for a super admin.
drop policy if exists ritual_orders_select on public.ritual_orders;
create policy ritual_orders_select on public.ritual_orders
  for select to authenticated
  using (family_id = public.my_family_id());

drop policy if exists ritual_orders_insert on public.ritual_orders;
create policy ritual_orders_insert on public.ritual_orders
  for insert to authenticated
  with check (family_id = public.my_family_id() and created_by = auth.uid());

-- No update or delete policy: an order is a record, the app never changes one.

-- ---------------------------------------------------------------------------
-- 3. Waitlist: "notify me when available" for rituals that are coming soon
-- ---------------------------------------------------------------------------

create table if not exists public.waitlist (
  id         text primary key default gen_random_uuid()::text,
  user_id    uuid not null default auth.uid(),
  family_id  text references public.families (id) on delete cascade,
  ritual_key text not null,
  created_at timestamptz not null default now(),
  unique (user_id, ritual_key)
);

alter table public.waitlist enable row level security;

revoke all on public.waitlist from anon;
grant select, insert on public.waitlist to authenticated;

-- Own rows only.
drop policy if exists waitlist_select on public.waitlist;
create policy waitlist_select on public.waitlist
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists waitlist_insert on public.waitlist;
create policy waitlist_insert on public.waitlist
  for insert to authenticated
  with check (user_id = auth.uid()
              and (family_id is null or family_id = public.my_family_id()));

-- ---------------------------------------------------------------------------
-- 4. Enquiries: messages from the contact form
-- ---------------------------------------------------------------------------

create table if not exists public.enquiries (
  id         text primary key default gen_random_uuid()::text,
  user_id    uuid not null default auth.uid(),
  family_id  text references public.families (id) on delete set null,
  name       text not null default '',
  email      text not null default '',
  phone      text not null default '',
  topic      text not null default '',
  message    text not null default '',
  created_at timestamptz not null default now()
);

alter table public.enquiries enable row level security;

revoke all on public.enquiries from anon;
grant select, insert on public.enquiries to authenticated;

-- Own rows only. The team reads enquiries from the Supabase dashboard, not through the app.
drop policy if exists enquiries_select on public.enquiries;
create policy enquiries_select on public.enquiries
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists enquiries_insert on public.enquiries;
create policy enquiries_insert on public.enquiries
  for insert to authenticated
  with check (user_id = auth.uid()
              and (family_id is null or family_id = public.my_family_id()));
