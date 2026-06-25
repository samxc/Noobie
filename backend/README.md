# Noobie Backend

PocketBase-powered backend for the Noobie MVP. It uses SQLite for app data, PocketBase for auth/admin/file features, and custom endpoints for places, guides, rentals and the guide-first assistant.

## Run Locally

```sh
go run ./cmd/noobie serve --http=127.0.0.1:8091
```

The API is served under `http://127.0.0.1:8091/api/noobie`.

## Environment

- `NOOBIE_DATA_DIR`: SQLite and PocketBase data directory. Defaults to `./data`.
- `NOOBIE_IMPORT_KEY`: required for `/api/noobie/import/overpass`.
- `DOMAIN_API_TOKEN`: optional Domain API token. If omitted, rental search returns realistic samples.
- `OVERPASS_ENDPOINT`: optional Overpass endpoint override for testing/self-hosting.

## Live Rental Data

The backend is already shaped for a real rental feed through
`/api/noobie/rentals/search`. Keep rental credentials on the backend only; the
Flutter app should never receive listing API tokens.

Recommended first integration:

1. Create a Domain Developer account and project.
2. Request/enable access to Agents & Listings with residential listing search.
3. Store the production access token as `DOMAIN_API_TOKEN` on the VPS.
4. Smoke test:

   ```sh
   curl -X POST http://127.0.0.1:8091/api/noobie/rentals/search \
     -H 'Content-Type: application/json' \
     -d '{"suburb":"Sydney","max_weekly_rent":420}'
   ```

5. Verify imported listings include price, address, image, bedrooms, bathrooms,
   source URL where available, inspection times where available, and safe fallback
   text when fields are missing.

REA/realestate.com.au is a possible later integration, but it usually requires
partner onboarding, issued client credentials and customer/agency integrations,
so Domain is the faster MVP path.

## Endpoints

- `GET /api/noobie/health`
- `GET /api/noobie/states`
- `GET /api/noobie/cities?state=NSW`
- `GET /api/noobie/place-categories`
- `GET /api/noobie/places/search?state=NSW&city=Sydney&category=groceries&q=coles`
- `GET /api/noobie/guides/search?q=gp&state=NSW`
- `GET /api/noobie/checklists`
- `GET /api/noobie/map-link?name=Woolworths&lat=-33.8731&lng=151.2061`
- `POST /api/noobie/assistant/ask` with `{"question":"What is a GP?","state":"NSW"}`
- `POST /api/noobie/rentals/search` with `{"suburb":"Sydney","max_weekly_rent":420}`
- `POST /api/noobie/import/overpass` with header `X-Noobie-Import-Key` and `{"city_id":"sydney","category_id":"groceries","radius_meters":5000}`

## PocketBase Admin Collections

On startup, the server creates and seeds `noobie_*` collections in the
PocketBase dashboard. The custom API reads from those collections first, so
admin edits to guides, places, categories and checklists are reflected by the
Flutter app. The standalone SQLite seed store remains as a local fallback.

## Deploy Cheaply

Use Docker Compose on a small VPS:

```sh
NOOBIE_IMPORT_KEY=change-me docker compose up -d --build
```

Run `scripts/backup.sh` nightly from cron or systemd timer to keep a compressed copy of SQLite/PocketBase data.
