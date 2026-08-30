# ror/ — Rails bookshelf app

Rails 8 migration of the Nanoc static bookshelf. See `PLAN.md` for the full plan,
scope decisions, data model, and rationale.

## Stack & commands

- Ruby 3.4, Rails 8, SQLite.
- Active Storage (local disk) for covers + `image_processing` variants.
- Minitest (Rails default).

```bash
# from the ror/ directory
bin/rails server          # run the app
bin/rails test            # run the full test suite
bin/rails console         # interactive console
bin/rails db:migrate      # apply schema changes
bin/rails runner '...'    # run a snippet
```

## Committing (important)

Commit small, coherent, self-contained increments. Use the granularity of the
TODO list as a guide — one TODO item ≈ one commit:

- One logical change per commit (one fix, one feature, one data-layer change, one page).
- Each commit must be in a working, value-adding state (the app boots; `bin/rails test` green for the scope touched; `rubocop` clean).
- Keep data-layer changes (migration + model + tests) separate from UI/feature changes.
- Docs (`PLAN.md`, `AGENTS.md`) and i18n string additions deserve their own commits when standalone.
- If a diff mixes unrelated changes or is hard to review, split it.

## i18n rule (important)

**All UI text goes in `config/locales/fr.yml`.** Default locale is `fr`.
Never hardcode French (or any language) strings in controllers, views, or models —
always use `t('.key')`/`I18n.t`. This keeps the whole UI localizable.

## Data model & status

- `User` — identity/ownership of reviews (auth in Phase 2; Phase 1 has a seeded default user).
- `Book` — bibliographic definition, unique ISBN, shared across users. `has_one_attached :cover`.
- `Tag` — French taxonomy label, belongs to Book (via `BookTag` join).
- `Review` — personal layer per user+book; unique `(user_id, book_id)`.
  - `status` enum: `read` / `wishlist` / `ongoing`.
- `Series` — a named saga for "À lire aussi" (linked books); `Book.series_id` nullable.

Invariants:
- read ⇒ requires `rating`; ongoing ⇒ no `rating`/`read_date`; wishlist ⇒ carries `priority`.
- unique ISBN, unique tag name/slug, unique `(user, book)` review.

## Routing

Idiomatic Rails `resources`; legacy Nanoc paths dropped (no redirects for now).
- Public: root, `books`, `last_readings`, `wishlist`, `tags`, `calendar/:year`, `feed`, `search`.
- Book URL: `/books/:id` with optional slug helper (`/books/:id-:slug`).
- Admin: `/admin` namespace (`Admin::*` controllers) — Phase 1 has **no authentication**.

## Search architecture

- `SearchController#index` returns **JSON** (matches by title/author/tag).
- Client JS fetches on input and renders a live dropdown (direct feedback).
- Server-side, RoR-idiomatic — no client-side search library.

## Covers / variants

Cover sizes (from original `nanoc.yaml`): `mini` 50 / `medium` 75 / `default` 150 /
`showcase` 300 px. Implement as Active Storage variants.

## Sanitization / typography

Applied on save (see service objects under `app/services/`):
- trim whitespace; curly apostrophe `’` (not straight `'`);
- `...` → `…`; em-dash `—`; French non-breaking spaces before `; ! ? :`.

## Testing

Minitest + fixtures. Must be green before any change is considered done: `bin/rails test`.

## Phases

- Phase 1 (current): deployable, single default user, admin scaffold, full public site, search, i18n, tests.
- Phase 2 (future): real auth + per-user review scoping, multi-user admin.
- Phase 3 (context only): Google Books API enrichment, cover search, Babelio/SensCritique prefill.
