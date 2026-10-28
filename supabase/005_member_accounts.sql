-- ---------------------------------------------------------------------------
-- Hamari Virasat: every account is on its family's member list.
--   Creating or joining a family adds the person to family_members, with the
--   row id set to their profile id. A name the admin already added with the
--   same phone number is taken over instead of adding a second entry.
--   Joining is refused once the family is full for its plan.
--   Removing a linked row also removes that person's profile, so they lose
--   access and can join a family afresh. The family admin cannot be removed.
-- Run after 004_plans.sql, in the Supabase SQL editor. Safe to run again.
-- ---------------------------------------------------------------------------

-- The phone number behind a phone login, which signs in as p<digits>@example.com.
create or replace function public.login_phone(p_email text)
returns text
language sql
immutable
as $$
  select coalesce(substring(p_email from '^p(\d{10})@example\.com$'), '')
$$;

-- Puts a new profile on its family's list. Called by the two RPCs below.
create or replace function public.list_new_account(p_profile public.profiles)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text := public.login_phone(p_profile.email);
  v_row   text;
  v_plan  text;
begin
  if v_phone <> '' then
    select m.id into v_row
    from public.family_members m
    where m.family_id = p_profile.family_id
      and right(regexp_replace(m.phone, '\D', '', 'g'), 10) = v_phone
      and not exists (select 1 from public.profiles p where p.id::text = m.id)
    limit 1;
  end if;

  if v_row is not null then
    update public.family_members set id = p_profile.id::text, phone = v_phone where id = v_row;
    return;
  end if;

  select f.plan into v_plan from public.families f where f.id = p_profile.family_id;
  if (select count(*) from public.family_members m where m.family_id = p_profile.family_id)
     >= public.plan_member_limit(v_plan) then
    raise exception 'This family''s % plan is full (% members). Ask your family admin to upgrade.',
      initcap(coalesce(v_plan, 'basic')), public.plan_member_limit(v_plan);
  end if;

  insert into public.family_members (id, family_id, name, phone)
  values (p_profile.id::text, p_profile.family_id, p_profile.full_name, v_phone);
end
$$;

revoke execute on function public.list_new_account(public.profiles) from public, anon, authenticated;

-- Same as in schema.sql, plus the list_new_account call.
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

  perform public.list_new_account(v_profile);
  return v_profile;
end
$$;

-- Same as in schema.sql, plus the list_new_account call.
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

  perform public.list_new_account(v_profile);
  return v_profile;
end
$$;

-- The admin cannot take themselves off the list.
create or replace function public.family_members_protect_admin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from public.profiles p
    where p.id::text = old.id and p.family_id = old.family_id and p.role = 'family_admin'
  ) and exists (select 1 from public.families f where f.id = old.family_id) then
    raise exception 'The family admin cannot be removed';
  end if;
  return old;
end
$$;

drop trigger if exists family_members_protect_admin on public.family_members;
create trigger family_members_protect_admin
  before delete on public.family_members
  for each row execute function public.family_members_protect_admin();

-- Taking a member who joined off the list removes their profile, and with it their access.
create or replace function public.family_members_drop_account()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.profiles p
  where p.id::text = old.id and p.family_id = old.family_id and p.role = 'member';
  return old;
end
$$;

drop trigger if exists family_members_drop_account on public.family_members;
create trigger family_members_drop_account
  after delete on public.family_members
  for each row execute function public.family_members_drop_account();

-- Accounts made before this file: take over a typed-in entry with the same name, else add one.
-- The plan limit is not applied here, so an existing family may show more members than its plan.
-- One entry per profile and one profile per entry, even when two people share a name.
with pairs as (
  select distinct on (m.id) m.id as entry_id, p.id::text as profile_id
  from public.family_members m
  join public.profiles p
    on p.family_id = m.family_id and lower(trim(p.full_name)) = lower(trim(m.name))
  where not exists (select 1 from public.family_members x where x.id = p.id::text)
    and not exists (select 1 from public.profiles q where q.id::text = m.id)
  order by m.id, p.id
), unique_pairs as (
  select distinct on (profile_id) entry_id, profile_id from pairs order by profile_id, entry_id
)
update public.family_members m
set id = u.profile_id
from unique_pairs u
where m.id = u.entry_id;

alter table public.family_members disable trigger family_members_enforce_limit;
insert into public.family_members (id, family_id, name, phone)
select p.id::text, p.family_id, p.full_name, public.login_phone(p.email)
from public.profiles p
where p.family_id is not null
  and not exists (select 1 from public.family_members m where m.id = p.id::text);
alter table public.family_members enable trigger family_members_enforce_limit;
