# Plan — Migration of the Nanoc bookshelf to Ruby on Rails

This document captures the plan, scope decisions, data model, and conventions for
migrating the static Nanoc site (`/Users/opatry/work/book-reading`) to a dynamic
Rails application living in this `ror/` directory. It is the durable, source-of-truth
reference: a fresh session can read this file to recover the full context.

Referenced source material (original static site):
- `content/book/*.md` — book entries (frontmatter + markdown description)
- `content/*.html.erb` — page templates
- `layouts/*.html.erb` — layouts
- `lib/helpers.rb`, `Rules`, `nanoc.yaml` — generation logic, routing, config

---

## 1. Scope decisions (locked)

### Keep
- **Series / "À lire aussi"** — linked-books concept keeps its own entity and rendering.
- **Search** — kept, but rewritten as a **server-side, RoR-idiomatic AJAX search**
  (the controller returns JSON; the client formats into a live dropdown with direct
  feedback). This **replaces** the previous Fuse.js client-side approach.
- **i18n everywhere** — all UI text lives in `config/locales/fr.yml`; default locale
  `fr`. No hardcoded French strings in code or views.
- **Tag belongs to Book** (bibliographic/definitional, not per-user).
- **Active Storage for covers** (local disk storage) with variants.
- **Full public site** faithful to the static version (minus removed items).
- French typography/sanitization on save (curly `’`, `…`, non-breaking spaces, em-dash).

### Drop / out of scope
- **Tabulator table** (client-side grid) and its dependency.
- **`index-noscript`** page (no longer needed without Tabulator).
- **`/api/v1/books.json`** companion endpoint for the Android app (removed from scope).
- **Legacy routing/URL schemes** — use idiomatic Rails `resources`. Public book URL is
  `/books/:id` with an optional slug appended as a friendly help (`/books/:id-:slug`).
  Legacy paths are deliberately dropped; no redirection for now (add later if needed).
- **Fuse.js / CDN search JS** — replaced by server-side search.

### Phases
- **Phase 1 (in scope now, deployable & usable):** data model, admin editor (Rails
  scaffold, no authentication, acting on a single seeded default user), full public
  site, search, i18n, tests. Deployable on its own — **does not block on Phase 2**.
- **Phase 2 (later, NOT implemented):** real authentication (`has_secure_password`,
  sessions, `current_user`), per-user review ownership/scoping, multi-user admin.
- **Phase 3 (context/memory only, NOT implemented):** enrich book addition with the
  Google Books API, cover search, Babelio/SensCritique prefill — future admin helpers.

---

## 2. Data model & relationships

```
User ──< Review >── Book ──< BookTag >── Tag
                        └──< Series (self-referencing "À lire aussi")
Book ──< (? a book belongs to an optional Series)
```

### Entities

**User** — identity & ownership of reviews.
- `name`, `email` (unique), `password_digest`.
- Auth (and `has_secure_password`) arrives in Phase 2; Phase 1 seeds one default user.

**Book** — bibliographic definition, unique per ISBN. Shared across users.
- `isbn` (string, unique), `title`, `author`, `page_count`, `publication_year`,
  `description` (markdown), `senscritique_id`, `babelio_id`, `series_id` (nullable).
- Has one `cover` attachment (Active Storage).

**Tag** — French taxonomy label (belongs to **Book**).
- `name` (unique), `slug` (unique).

**BookTag** — join between Book and Tag. Unique `(book_id, tag_id)`.

**Review** — personal reading data per user+book. Unique `(user_id, book_id)`.
- `status` (enum): `read`, `wishlist`, `ongoing`.
- `rating` (1–10), `read_date` (date), `priority` (wishlist ordering), `favorite` (bool).

**Series** — a named series for "À lire aussi" (linked books).
- `name` (unique). Books link to a series; a series groups the books of that saga.

### Invariants (ported from Nanoc `Rules` preprocess)

- A **read** review requires a `rating` (1–10) — no read review without a rating.
- An **ongoing** review excludes `rating` and `read_date`.
- A **wishlist** review carries `priority`; a read review does not need one.
- `isbn`, `tag.name`, and `(user_id, book_id)` review pairs are unique.
- `isbn` follows the ISBN-13 subformat check (basic validation; not a full checksum).
- Covers: a `Book` may have a cover; cover variants come from `nanoc.yaml` sizes.

---

## 3. Rails commands used

```bash
rails new ror \
  --skip-docker --skip-action-mailer --skip-action-cable --skip-active-storage \
  --skip-jbuilder --skip-hotwire --skip-kamal --skip-thruster --skip-solid --skip-ci

# re-enable Active Storage (was skipped at rails new)
#   config/application.rb: uncomment require "active_storage/engine"
#   add image_processing to Gemfile, then:
bin/rails active_storage:install

bin/rails g model User name email:uniq password_digest
bin/rails g model Tag name:uniq slug:uniq
bin/rails g model Series name:uniq
bin/rails g model Book isbn:string:uniq title author page_count:integer \
            publication_year:integer description:text senscritique_id:string \
            babelio_id:string series:references
bin/rails g model BookTag book:references tag:references
bin/rails g model Review user:references book:references status:integer \
            rating:integer read_date:date priority:integer favorite:boolean
bin/rails db:migrate
```

Public controllers: `Home`, `Books` (show), `LastReadings` (index), `Wishlist`
(index), `Tags` (index/show), `Calendar` (show), `Feed` (index → atom), `Search`
(index → JSON).

Admin (Phase 1, no auth): `/admin` namespace — `Dashboard`, `Books` (CRUD +
tags/cover/series/social IDs), `Reviews`, `Tags`, `Series`.

---

## 4. Cover handling

- `Book.has_one_attached :cover`.
- Variants/sizes (from the original `nanoc.yaml`) — used for preview rendering:
  - `mini` = 50px
  - `medium` = 75px
  - `default` = 150px
  - `showcase` = 300px (mainly for the "ongoing" book on the home page)

---

## 5. i18n

- Default locale `:fr`; all UI strings in `config/locales/fr.yml`.
- Test helpers assert no hardcoded French in view/controller text.
- French pluralization (`books.count`, `pages.count`) via i18n plural keys.

---

## 6. Testing

- Minitest (Rails default) + fixtures.
- Coverage:
  - Model validations & invariants.
  - Service objects (typography/sanitization, search).
  - All public + admin + search controllers.
  - View helpers/interactors (page-count labels, star/status formatting).
  - Routing.
- Run: `bin/rails test`.

---

## 7. AGENTS.md

See `ror/AGENTS.md` — the operational conventions (commands, i18n rule, data model,
routing, search architecture, testing, phases) for anyone (or any agent) working in
this `ror/` app.
