-- Hamari Virasat: memories (photos, videos, voice notes, stories) and their storage bucket.
-- Run after schema.sql, in the Supabase SQL editor. Safe to run again.
-- Column names match Memory.toJson in app/lib/data/models.dart.

-- ---------------------------------------------------------------------------
-- 1. Table
-- ---------------------------------------------------------------------------

create table if not exists public.memories (
  id              text primary key default gen_random_uuid()::text,
  family_id       text not null references public.families (id) on delete cascade,
  kind            text not null default 'story'
                  check (kind in ('photo', 'video', 'voice', 'story')),
  title           text not null default '',
  story           text not null default '',
  tags            text[] not null default '{}',
  media_paths     text[] not null default '{}',
  created_by      uuid default auth.uid(),
  created_by_name text not null default '',
  created_at      timestamptz not null default now()
);

create index if not exists memories_family_id_idx on public.memories (family_id);

-- ---------------------------------------------------------------------------
-- 2. Row-level security
--    Same shape as rituals: family only, through my_family_id(), which is null
--    for a super admin. Nothing here grants a super admin any access.
-- ---------------------------------------------------------------------------

alter table public.memories enable row level security;

revoke all on public.memories from anon;
grant select, insert, update, delete on public.memories to authenticated;

drop policy if exists memories_select on public.memories;
create policy memories_select on public.memories
  for select to authenticated
  using (family_id = public.my_family_id());

-- Any family member adds a memory, always under their own name.
drop policy if exists memories_insert on public.memories;
create policy memories_insert on public.memories
  for insert to authenticated
  with check (family_id = public.my_family_id() and created_by = auth.uid());

-- Only the author edits.
drop policy if exists memories_update on public.memories;
create policy memories_update on public.memories
  for update to authenticated
  using (family_id = public.my_family_id() and created_by = auth.uid())
  with check (family_id = public.my_family_id() and created_by = auth.uid());

-- The author deletes their own, the family admin deletes any.
drop policy if exists memories_delete on public.memories;
create policy memories_delete on public.memories
  for delete to authenticated
  using (family_id = public.my_family_id()
         and (created_by = auth.uid() or public.my_role() = 'family_admin'));

-- ---------------------------------------------------------------------------
-- 3. Storage: private bucket for memory media
--    Object path: <family_id>/<memory_id>/<filename>
--    The first path segment must be the caller's own family id.
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('memories', 'memories', false)
on conflict (id) do update set public = false;

drop policy if exists memories_media_select on storage.objects;
create policy memories_media_select on storage.objects
  for select to authenticated
  using (bucket_id = 'memories'
         and (storage.foldername(name))[1] = public.my_family_id());

drop policy if exists memories_media_insert on storage.objects;
create policy memories_media_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'memories'
              and (storage.foldername(name))[1] = public.my_family_id());

drop policy if exists memories_media_update on storage.objects;
create policy memories_media_update on storage.objects
  for update to authenticated
  using (bucket_id = 'memories'
         and (storage.foldername(name))[1] = public.my_family_id())
  with check (bucket_id = 'memories'
              and (storage.foldername(name))[1] = public.my_family_id());

drop policy if exists memories_media_delete on storage.objects;
create policy memories_media_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'memories'
         and (storage.foldername(name))[1] = public.my_family_id());
