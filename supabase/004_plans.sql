-- ---------------------------------------------------------------------------
-- Hamari Virasat: family plans and the member limit (16 Oct 2026 review).
--   Every family is on a plan: basic (2 members), pro (4) or premium (8).
--   The plan is set by the platform only; a family admin cannot change it.
-- Run after 003_site_features.sql, in the Supabase SQL editor. Safe to run again.
-- Column names match the toJson keys in app/lib/data/models.dart.
-- ---------------------------------------------------------------------------

alter table public.families
  add column if not exists plan text not null default 'basic';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'families_plan_check') then
    alter table public.families
      add constraint families_plan_check check (plan in ('basic', 'pro', 'premium'));
  end if;
end
$$;

-- Same as in schema.sql, now also keeping the plan out of the family admin's hands.
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
    new.plan        := old.plan;
  end if;
  return new;
end
$$;

create or replace function public.plan_member_limit(p_plan text)
returns integer
language sql
immutable
as $$
  select case p_plan when 'premium' then 8 when 'pro' then 4 else 2 end
$$;

-- Refuses a new member once the family list is full for its plan.
create or replace function public.family_members_enforce_limit()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_limit integer;
  v_count integer;
begin
  -- The app saves with upsert, which fires insert triggers on an edit too: let edits through.
  if exists (select 1 from public.family_members m where m.id = new.id) then
    return new;
  end if;

  select public.plan_member_limit(f.plan) into v_limit
  from public.families f where f.id = new.family_id;

  select count(*) into v_count
  from public.family_members m where m.family_id = new.family_id;

  if v_count >= coalesce(v_limit, 2) then
    raise exception 'Your plan allows up to % members', coalesce(v_limit, 2);
  end if;
  return new;
end
$$;

drop trigger if exists family_members_enforce_limit on public.family_members;
create trigger family_members_enforce_limit
  before insert on public.family_members
  for each row execute function public.family_members_enforce_limit();
