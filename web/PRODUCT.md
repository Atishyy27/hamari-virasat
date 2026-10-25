# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Indian families, across regions, languages and traditions, who want to keep their own riti-riwaj written down before it is lost. Hindi-speaking North Indian families are the first worked example, not the boundary.

The buyer is usually a younger family member (a son, daughter or grandchild) who signs the family up and pays. The knowledge sits with the elders: grandparents and parents who know the rituals, the samagri, the songs and who does what, and who may find apps hard to use. The product has to work for both: the organiser who runs it and the elder who supplies the memory.

The web site is a public site for these families to understand the product, trust it with private family knowledge, and buy.

## Product Purpose

Each family records its own rituals in a private, shared archive: the samagri, the steps in order, the roles of relatives, the food made for it (recipes always sit under a ritual) and the folk songs as audio. The archive can be printed as a physical heirloom book.

Success is a family that has its traditions recorded in one place, kept private, and in a form the next generation can follow and the elders recognise as theirs.

## Positioning

- **Private by database rule, not by promise.** Every family sees only its own records. Row-level security ties every row to the caller's family. The platform's own super admin cannot read any family's rituals, recipes, members or audio: their profile is forbidden a family id, and all they can see is a family's name, active flag and created date.
- **No family tree.** Members are a flat list under the family with relation as plain text. A tree cannot be stored, so the product never ranks or arranges relatives.
- **Rituals first.** Recipes and songs belong to a ritual; there is no separate recipe app or social feed.
- **Elder help as a service, not just software.** Grandchildren can type what elders dictate, voice notes sent on WhatsApp are added to the archive, and the team can phone elders and take the rituals down for the family.

## Operating Context

- Roles: family admin (manages the family and member list), member (adds and edits rituals and recipes), super admin (activates or deactivates family accounts, nothing else).
- Joining: a family admin registers the family; others join with the family's invite code.
- Family record: name, gotra, kuldevi, kuldevta.
- Ritual categories: 8 built-in categories with phases, plus a family's own custom ones.
- The core product is a Flutter mobile app (iOS and Android). The web site sells it and includes a web version of the family space.
- The printed book is ordered from the recorded archive.

## Capabilities and Constraints

Confirmed offers (real, can be stated as fact):

- Pilot price: ₹299 to preserve a ritual.
- Full Family Heirloom Edition: ₹2,499, including the printed book.
- Printed heirloom book: cloth-bound, gold-foil edition.
- Elder help: WhatsApp voice notes archived; phone dictation by the team.
- Money-back guarantee: full refund if the family elders are not touched by the documented book.

Technical facts: React + Vite site (`web/`), Express API (`server/`), Postgres on Supabase with RLS (`supabase/schema.sql`). Audio lives in a private storage bucket per family and ritual.

Open decisions:

- Whether the super admin console and the database security inspector stay on the public site, or move behind a separate operator route. They exist today as live proof of the privacy rules.
- Languages beyond Hindi and English for interface and content.

## Brand Commitments

- Name: Hamari Virasat (हमारी विरासत). Existing tagline: "Stories that live beyond generations".
- Logo: the diya mark (`src/components/DiyaLogo.jsx`).
- Hindi (Devanagari) alongside English for cultural terms: riti-riwaj, samagri, vidhi, lok geet, samskaras, gotra, kuldevi.
- Voice: reverent, warm, and plain about privacy. "Made with reverence in India."

## Evidence on Hand

- Demo family data: "Mishra Parivar, Varanasi" in `src/data/mockHeritageData.js`. This is sample data and must always read as an example, never as a real customer.
- Images and app screens: `public/assets/images`, `public/assets/screens`; full page captures in `../ui-screenshots/`.
- The privacy rules themselves, provable from `schema.sql` (zero rows returned to a super admin).
- None yet: testimonials, customer counts, press, ratings or partner logos. Future work must not invent them.

## Product Principles

1. **The family owns its memory.** Privacy is shown through checkable fact, not reassurance copy.
2. **Elders are the source; the product adapts to them.** Voice, dictation and help by phone come before forms.
3. **Ritual is the unit.** Everything (food, songs, roles) hangs off a ritual the family actually performs.
4. **No hierarchy among relatives.** Nothing ranks, trees or scores family members.
5. **Every tradition is the family's own.** No single region's practice is presented as the correct one.

## Accessibility & Inclusion

Elders are a core audience: readable type sizes, strong contrast, large targets and simple flows matter for any surface they touch. Content mixes Devanagari and Latin script, so both must render well together. Other Indian scripts may follow.
