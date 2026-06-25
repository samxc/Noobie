
# Noobie

Noobie is a cross-platform Flutter app for international students arriving in
Australia without family or an established support network.

The current MVP focuses on practical settlement help:

- first-week setup checklist
- safe suburb decision prompts
- room inspection, scam-avoidance guidance and backend rental import plumbing
- places search for groceries, shopping, health, transport, community and fun
- guide-first assistant that answers from Noobie content before paid AI
- everyday Australian life tips
- emergency and support contacts
- saved checklist items

## Backend

The MVP now includes a PocketBase + Go/SQLite backend in `backend/`.

```sh
cd backend
go run ./cmd/noobie serve --http=127.0.0.1:8091
```

The backend provides:

- `/api/noobie/places/search`
- `/api/noobie/guides/search`
- `/api/noobie/assistant/ask`
- `/api/noobie/rentals/search`
- `/api/noobie/import/overpass`

Set `DOMAIN_API_TOKEN` only on the backend if you want live Domain rentals.
Without it, the backend returns realistic sample listings so the app stays
demoable. Set `NOOBIE_IMPORT_KEY` before running Overpass imports.

On startup, the backend also creates editable PocketBase admin collections:
`noobie_guides`, `noobie_places`, `noobie_place_categories`,
`noobie_guide_categories`, `noobie_checklists`, `noobie_states`,
`noobie_cities`, `noobie_translations`, `noobie_rental_sources`,
`noobie_assistant_answers` and `noobie_saved_items`.

The custom Noobie API reads from those PocketBase collections first, so content
edited in the admin dashboard can appear in the app immediately after saving.
The older local SQLite seed store remains as a fallback for development.

## Run locally

```sh
flutter pub get
flutter run -d chrome --dart-define=NOOBIE_API_BASE_URL=http://127.0.0.1:8091/api/noobie
```

## Build for cheap static hosting

```sh
flutter build web --release --dart-define=NOOBIE_API_BASE_URL=https://your-backend.example.com/api/noobie
```

Deploy the generated `build/web` directory to Netlify, Cloudflare Pages,
Firebase Hosting or GitHub Pages.

This repo includes `.github/workflows/flutter-web.yml`, which builds and
deploys to GitHub Pages on pushes to `main`. In GitHub, set Pages to use
GitHub Actions as the source. Add a repository variable named
`NOOBIE_API_BASE_URL` with your VPS backend URL before deploying publicly.

## Images

The MVP uses remote Unsplash photo URLs for the hero and room cards. Unsplash
images are free to use for commercial and non-commercial projects under the
Unsplash license. Replace these with licensed partner/agency images when live
listings are imported.
