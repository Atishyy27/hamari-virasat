# Hamari Virasat: web

The public site (`/`), the family book (`/family`) and the operator console (`/admin`). React + Vite, no router or CSS framework.

```bash
npm run dev     # http://localhost:5173, proxies /api to the server on :5001
npm run build
npm run lint
```

The family book and operator console talk to the Express API in `../server`, so run that too (`npm run dev:server` from the repo root).

## Layout

```text
src/
├── main.jsx, App.jsx        # entry and the three routes
├── api/client.js            # every API call; throws ApiError with a readable message
├── context/SessionContext   # signed-in user and family, token in localStorage
├── lib/router.jsx           # tiny pushState router (usePath, navigate, Link)
├── lib/rituals.js           # converts API ritual rows to and from the form
├── data/exampleFamily.js    # the sample Mishra family on the landing page (always labelled Example)
├── components/              # DiyaLogo, layout/SiteHeader, SiteFooter, AppShell
├── pages/landing/           # HeroSpread, ExampleLedger, Privacy, Elders, Pricing
├── pages/family/            # AuthPanel, RitualsTab, RitualForm, MembersTab
├── pages/admin/             # operator console
└── styles/                  # tokens, base, ledger (shared parts), site, app
```

## Deploying

Set `VITE_API_URL` at build time to the deployed API, for example `https://api.example.com/api`. Without it the site calls `/api` on its own host, which only works behind the dev proxy or a matching rewrite. The server's `CORS_ORIGIN` must allow the site's origin.
