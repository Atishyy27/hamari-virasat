# Hamari Virasat

## What the app is

A mobile app where each family records its own riti-riwaj: the rituals, the samagri, the steps, who does what, the food and the folk songs.
Every family sees only its own records. A family admin manages the family and its member list, and members add rituals.
A super admin manages family accounts (list, activate, deactivate) and nothing else.

## Database design

Postgres on Supabase. The whole design is one file: `supabase/schema.sql`.

| Table | Purpose |
|---|---|
| `profiles` | One row per signed-in user: name, email, role (`super_admin`, `family_admin`, `member`) and the family they belong to. Created only by the sign-up RPCs, never written directly by the app. |
| `families` | One row per family: name, gotra, kuldevi, kuldevta, invite code, active flag. |
| `family_members` | Flat list of people in a family: name, relation as free text, phone. |
| `ritual_categories` | Main event categories and their phases. `family_id` null is a built-in one (8 seeded); a family's custom ones carry its `family_id`. |
| `rituals` | One recorded ritual: title, category, phase, samagri, steps, roles of relatives, audio paths. |
| `recipes` | Food for a ritual: name, ingredients, method. Always tied to one ritual. |
| storage bucket `ritual-audio` | Private bucket for folk song recordings, path `<family_id>/<ritual_id>/<filename>`. |

How the three requested changes are enforced:

1. No family tree. `family_members` has no parent, spouse or any other column linking one member to another. It is a list under a family name, and `relation` is plain text. A tree cannot be stored.
2. Super admin cannot read family data. Row-level security is on for every table, and every policy on `families`, `family_members`, `rituals`, `recipes`, custom `ritual_categories` and the audio bucket requires the row's family id to equal the caller's own family id. A check constraint on `profiles` forces a super admin's family id to be null, so no policy can match them. The only thing a super admin can call is `list_families_for_super_admin()`, which returns id, name, active and created date, and `set_family_active()`. This is a database rule, not an app screen rule: a super admin querying the tables directly gets zero rows.
3. Recipes under rituals. `recipes.ritual_id` is required and deletes with its ritual. There is no recipe without a ritual, so the app has no separate recipe section to show.

Other rules worth knowing: only the family admin can edit the family row and the member list; any member can add or edit rituals and recipes; a family admin cannot change the invite code or the active flag (a trigger restores them); deactivating a family blocks all its users from its content.

Notes for the app's Supabase code:

- `Ritual.toJson()` carries a nested `recipes` key that is not a column in `rituals`. Remove it before writing and save recipes to the `recipes` table with `ritual_id` and `family_id` added.
- `RitualCategory.toJson()` has no `family_id`. Add it when inserting a custom category.
- After `auth.signUp`, call `register_family(p_full_name, p_family_name)` or `join_family(p_full_name, p_invite_code)`. Both need a signed-in session.

## Supabase setup

1. Create a project at supabase.com.
2. Open the SQL editor, paste all of `supabase/schema.sql`, run it. It is written to be safe to run again.
3. In the project's API settings, copy the Project URL and the anon public key. The app needs these two values.
4. For the demo, turn off email confirmation in the Auth settings. With it on, sign-up returns no session and the two sign-up RPCs fail with "Not signed in" until the user confirms and signs in.
5. To create the super admin: sign that user up, then run the commented one-line `insert` at the top of `schema.sql` with their email.

## Build

Run `scripts/build-apk.sh`. Without Supabase values the app runs on local on-device data, which is enough for a demo.

## Unverified

- `schema.sql` has not been run against a Supabase project. The first run is the test.
- `scripts/build-apk.sh` and the way it takes the Supabase URL and anon key were not written when this file was drafted. Check the script for the exact names.
- The exact menu location of the email confirmation switch and the API keys in the Supabase dashboard is from memory, not checked against the current dashboard.
