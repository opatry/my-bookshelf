# Plan — Author pages ([issue #2](https://github.com/opatry/my-bookshelf/issues/2))

Working branch: `2-author-pages`, rebased on `main` (which already carries the
`last-readings` calendar weighting, `443363c`; author cloud weighting is the branch tip).
Rule of thumb: one numbered step below = one reviewable commit. Steps within a phase
are independent unless stated otherwise; phases are ordered because later ones build on
earlier changes (URL scheme, helpers, validations).

Legend: `- [ ]` = not started · `- [~]` = in progress · `- [x]` = done & committed

## Status of the issue today (baseline)

Done on the branch already:

- Per-author pages `/author/<slug>.html`, generated in preprocess (`generate_author_items`,
  `lib/helpers.rb`) with book cards + aggregated tags + bio blockquote.
- All-authors cloud `/author/index.html` (`content/all-authors.html.erb`): weighted tag
  cloud (log scale via `log_weight`, committed separately from the calendar work),
  GMail-style palette initials, book count.
- Author name clickable on book pages, book cards (incl. wishlist cards) and index ongoing
  book (apostrophe/accents handled via `author_slug`).
- Author picture replaces site profile picture on author pages (`layouts/default.html.erb`),
  `avatar-placeholder.png` fallback; page switches to `full` layout width.
- OGP: `og:type=profile` (`layouts/head_author.html.erb`), `book:author` now points to the
  absolute author page URL (`layouts/head_book.html.erb`).
- Tags of author's books listed on the author page (`layouts/author.html.erb`).

Not done: everything below.

---

## Phase A — Structural foundations (do first, changes ripple everywhere)

### A1. Pretty URLs: `/author/<slug>/` instead of `/author/<slug>.html`

Matches the rest of the site (`/book/<isbn>/`, `/tag/<name>/`, `/#/`) and is a
prerequisite for the generic view-transition pattern (B/A2) and for stable OGP URLs.

- [ ] `Rules`, `compile '/author/*'`: write `"#{item.identifier.without_exts}/index.html"`
      (the `route '/all-authors.*'` → `/author/index.html` already fits this scheme).
- [ ] Verify every link site-wide uses `item.path` (cloud, `layouts/book.html.erb`,
      `layouts/book_card.html.erb`, both index pages, `head_book` absolute URL,
      `api/v1` items & `static/search.js` if they reference authors) — click through with
      `bundle exec nanoc view`: index → cloud → author page → book page → back.
- [ ] Dev **and** prod compile both green: `bundle exec nanoc compile` and
      `bundle exec nanoc compile --env=prod`.

Commit: `Use directory-style URLs for author pages`

### A2. Extract the palette/initials helpers out of the ERB

The `Digest::MD5` / `hsl_to_hex` / `luminance` block is defined inline in
`content/all-authors.html.erb` (~60 lines executed at compile time, global scope).

- [ ] Move to `lib/helpers.rb`: e.g. `avatar_fallback_colors(name)` returning
      `[background, foreground]`, plus a small `avatar_initials(name)` (first letter,
      accent/apostrophe-aware — reuse `author_slug` transliteration thinking).
- [ ] `content/all-authors.html.erb` renders through the helper (markup unchanged:
      `--avatar-fallback-*` CSS vars on `.tag-pic`).
- [ ] Behavior-preserving: diff `output/author/index.html` before/after.

Commit: `Move author avatar fallback color logic into helpers`

### A3. Author uniqueness: slug-collision validation + alias support

Issue bullet: “Ensure no identical author have different version
(ex: `Madeleine Wickham (alias Sophie Kinsella)`)”. Currently two distinct author strings
that transliterate to the same slug silently clash (`FIXME` in `generate_author_items`).

- [ ] In `Rules` preprocess (where the other validations raise): raise when two distinct
      `book[:author]` strings resolve to the same slug, message naming both variants.
- [ ] Config-driven normalization: `@config[:author][<canonical-slug>]` gains
      `aliases: [ "Variant Name", … ]` (after D5: in the canonical md frontmatter instead);
      build a variant→canonical map consumed by
      `generate_author_items` (group books under canonical) **and**
      `author_item_identifier(author)` (so every card/link resolves to the canonical page).
- [ ] Author page title displays canonical; consider `<title>` + a line
      “aussi connu sous le nom de …” in the page.
- [ ] Test by temporarily adding an alias pair to two existing books; remove before commit.

Commit: `Resolve author aliases through config and fail on slug collisions`

---

## Phase B — Make each author page complete

### B1. Render external links on the author page (SensCritique / Babelio / Wikipedia)

Values already live in `@config[:author]` and are used only for OG metas today.

- [ ] In `layouts/author.html.erb`, render a chip row reusing the book-page pattern
      (`layouts/book.html.erb:80–105`: icon from `@config[:social][…][:icon_identifier]`,
      `--social-tint-color`). Author config stores full URLs already, so no prefix juggling.
- [ ] Wikipedia icon: add a `static` wikipedia SVG (or reuse lucide) + tint entry.
- [ ] Missing platforms are skipped silently (config sparse by design until D3 lands).

Commit: `Show SensCritique, Babelio and Wikipedia links on author pages`

### B2. GMail-style initials fallback on author pages (not just the cloud)

Today a page-less author shows `avatar-placeholder.png`; issue asks to define the proper
fallback — decision made: palette initials everywhere, placeholder PNG only as the last
resort (e.g. og:image needs a real file: keep PNG or generate nothing).

- [ ] `layouts/default.html.erb`: when `is_author_page && @item[:avatar].nil?`, render
      `<span class="profile-picture author-fallback" style=…>` with initials from A2
      helpers instead of `<img>`; same 128px geometry as `.author-picture`.
- [ ] CSS in `content/static/style.css`: `.author-fallback` (circle, centered, font-size
      relative to avatar size).
- [ ] `head_author.html.erb`: `og:image` omitted when no picture (crawlers fall back fine).

Commit: `Use palette initials as author avatar fallback on author pages`

### B3. OGP `profile:` correctness

`profile:last_name` currently holds the full name (TODO in `head_author.html.erb`).

- [ ] Decide: (a) add `given_name:` / `family_name:` keys in author config (Wikidata P735 /
      P734 can supply them, see D2) or (b) simplify to `profile:username` = slug.
      Suggested: (b) now, (a) opportunistically via the fetch script later.
- [ ] Add `<meta property="og:url">` = absolute author URL; keep `og:title` = author name.
- [ ] Non-prefetchable duplicate: also emit matching `twitter:`/plain metas if trivial.

Commit: `Fix OGP profile metadata on author pages`

### B4. Bio & attribution conventions

Config bios are placeholders (“Voici un exemple…”). Licensing matters for anything copied.

- [ ] Convention for bios: ~1–3 sentences. From Wikipedia → `bio_source: wikipedia`
      (renders a short “Wikipédia, CC BY-SA 4.0” attribution link after the blockquote);
      own words → no source key, no attribution line.
- [ ] Decide: `bio:` plain text (today, rendered as blockquote) or allow limited markdown.
- [ ] Attribution markup + i18n string in `strings/fr.yml`.

Commits: `Add bio attribution support to author pages` (+ one per curation batch, see D)

---

## Phase C — Site integration

### C1. Proper entry point to “all authors”

Kill the `<h1>TOUS LES AUTEURS</h1>` stub in `content/index.html.erb`.

- [ ] Established pattern is `title-more` (cf. tag pages): add
      `link_to('👤 Tous les auteurs', @items['/all-authors.*'])` to the index heading(s)
      and to the wishlist page heading; author pages get the same link in their title
      (symmetry with “Toutes les étiquettes” on author tag section).
- [ ] Remove the stub h1.

Commit: `Link to all authors from index and wishlist headings`

### C2. Generalize `view-transition.js` (issue bullet: “trying to make the pattern more generic”)

- [ ] After A1: replace `bookPagePattern` with a keyed section pattern —
      `new URLPattern('/:kind(book|author)/:key/?', window.origin)`; keep book-specific
      cover morph gated on `kind == 'book'`.
- [ ] Avatar morph: fire whenever both sides have `.profile-picture` (i.e. every page);
      consider naming the cloud's `.tag-pic` with the same transient
      `viewTransitionName` so cloud → author morphs initials/photo smoothly.
- [ ] Manual matrix check in `nanoc view`: index↔book, index↔author, cloud↔author,
      author↔its books, wishlist→author.

Commit: `Generalize view transition URL patterns to author pages`

### C3. Author cloud polish (leftover FIXMEs)

- [ ] Natural sort on author names in `author_tag_cloud` (ignore leading “Les/Le/”,
      accents; Ruby has no native natural sort — a small comparator on `Sortable` name or
      reuse `sortable_label` thinking from titles).
- [ ] Optional: sort mode by weight (not just alpha) — decide during impl; `title-more`
      `:target` toggle à la `#only-favorites` if cheap, else skip.

Commit: `Sort author cloud naturally by author name`

---

## Phase D — Content pipeline: gathering author knowledge

Verified facts (probed live 2026-11-13): Wikidata `P3630` (Babelio author ID) matches the
hand-verified config value for Beigbeder (`2200`); `P14412` (SensCritique person) exists but
is sparsely filled; fr.wikipedia REST `page/summary` returns a usable 1–3 sentence extract +
thumbnail (the config picture for Beigbeder is exactly that image). License: extracts are
CC BY-SA → attribution via B4; Commons photos keep their own credits (store file page URL).

### D1. `fetch_author.sh` (mirrors `fetch_book.sh` ergonomics) — **DONE**

- [x] Input: `./fetch_author.sh "Author Name" ["Next" …]` (or file, one name per line) →
      prints a YAML block for `@config[:author]` plus verification links; writes nothing
      (homonym risk is real: “Dan Brown” ≠ the spy novelist… verify every pick).
- [x] Chain: Wikidata `wbsearchentities` (fr) → QID; scoring: frwiki sitelink +2,
      P106 ∈ {Q36180 écrivain, Q6625963 romancier, Q49757 poète, Q28389 scénariste} +2,
      exact label match +1 — ⚠️ item-type claim values are `{"id":"Q…"}` objects
      (`datavalue.value.id`), only external IDs are plain strings.
- [x] `shellcheck`-clean (`${var}`, `set -euo pipefail` per AGENTS.md); no API key
      (Wikimedia APIs are public); mandatory `User-Agent`, sequential ~1 req/s,
      one 30s backoff retry on 429, responses cached under git-ignored `tmp/`.
- [x] `picture` = frwiki summary image URL for now + a `# photo file page` comment with the
      Commons page URL (license/portrait check before accepting); D2 replaces hotlinks with
      local files.
- [x] Documented in AGENTS.md “Workflow” section.
- [ ] `bio_source: wikipedia` (CC BY-SA) + `wikidata:` anchor keys are emitted; consuming
      them (`given_name`/`family_name` P735/P734, birth/death rendering) still B3/optional.

Commit: `Add fetch_author.sh to bootstrap author metadata from Wikidata/Wikipedia`

### D2. Photo download & storage

Hotlinked `upload.wikimedia.org/thumb/...` URLs rot; prod pipeline wants local files.

- [ ] Store curated photos in `content/static/authors/<slug>.<ext>`; config `picture:`
      becomes the item identifier (already supported: `head_author` resolves identifiers
      via `@items[picture]`, and `default.html.erb` `avatar.is_a?(String)` logic must be
      revisited to distinguish URL-string vs identifier — use identifier convention only).
- [ ] `Rules`: compile `/static/authors/*` with the `avatar_size` thumbnail reps
      (default 128, compact 48) so author pages and (future) micro-avatars reuse the
      existing `:default`/`:compact` machinery; needs ImageMagick, same as covers.
- [ ] Every downloaded file needs its license recorded: sidecar comment or `source:` key
      pointing at the Commons file page (also feeds an attribution tooltip later); D5 moves
      this key into the per-author md frontmatter.

Commit: `Store author pictures locally with thumbnail reps`

### D3. Batch & curation workflow

- [ ] Batch mode: `grep -h '^author:' content/book/*.md | sort -u` (~153 authors today) →
      loop D1 printing candidates into a scratch `tmp/authors-candidates.yaml`
      (ignored by git).
- [ ] Human pass, priority-first: favorites' authors → multi-book authors (cloud weight ≥
      3) → wishlist authors → long tail. Remaining authors stay on the initials fallback —
      that's a designed state, not a failure.
- [ ] Curated batches commit as `[authors] fill metadata for <N> authors` (a handful per
      commit so review stays sane); alias discoveries feed A3's `aliases:`. Paste target is
      `nanoc.yaml` until D5 lands, then `content/meta/authors/<slug>.md`.
- [ ] Expectation: Wikipedia has ~60–80% of the French-market authors in the shelf; the
      rest: manual one-liners (own words) or none.

### D4. SensCritique/Babelio coverage

- [ ] For authors missing from Wikidata ids: manual search on the two sites, paste full URL
      into config (same format as the generated ones); `sc:` pattern from book `social:`
      IDs is `senscritique.com/contact/<slug>/<numeric-id>`.
- [ ] Nice-to-have later: cross-check book `social.sc` pages — the author/contact ID is in
      those profile URLs sometimes (harvest without scraping).

### D5. Author metadata as items: `content/meta/authors/<slug>.md` replaces the `@config[:author]` blob

Rationale (decided 2026-11-13, after the first 10-author curation batch): bios/pictures/links are
*content*, not site config; the single `nanoc.yaml` blob conflicts with the branch-per-book/PR
workflow (every curation batch edits the same file region → merge-conflict magnet); per-author md
reuses the machinery books already have — Rules validation, orthogonal diffs, item model,
`commit_book.sh`-like story. **Pages stay generated** (books = source of truth for the author
roster); metadata files are merge inputs, created lazily (uncurated authors have no file —
initials fallback stays a designed state, ~10% of files at first).

- [ ] One file per curated author under `content/meta/authors/` (namespace deliberately kept
      distinct from generated `/author/<slug>.*` identifiers):
      frontmatter = the exact block `fetch_author.sh` prints today (`wikidata`, `picture`,
      `picture_source`, `bio_source`, `wikipedia`, `babelio`, `sc`, `aliases`),
      body = bio in markdown (escapes the YAML-string quoting dance, allows longer notes later).
- [ ] `Rules`: exclude `/meta/authors/*` from compile/route so curated data never becomes a page.
- [ ] `lib/helpers.rb` `generate_author_items` and `layouts/head_author.html.erb`: replace
      `@config[:author][slug]` lookups by `@items["/meta/authors/<slug>.*"]`; render the file
      body as the bio block instead of the injected `> bio` string.
- [ ] Validation in `Rules`, mirroring the book checks: fail on a `meta/authors` file whose slug
      matches no shelf author (stale or typo'd — warn vs raise decided at impl); extend the A3
      slug-collision check across `aliases:` declared in frontmatter.
- [ ] Migrate the current 10 `nanoc.yaml` entries to md files, then delete the `author:` blob.
- [ ] Update `fetch_author.sh` closing guidance + AGENTS.md Workflow/Content-model lines to the
      new paste destination; optionally a `commit_author.sh` with `[author][<QID>]` message
      format mirroring `[book][<isbn>]`.

Commit: `Store author metadata as md items instead of nanoc.yaml config blob`

---

## Phase E — The “fancy display” (issue: cover grid + hover overlay card)

Deliberately last: pure additive UI, benefits from everything above being stable.

### E1. Covers mosaic mode on author pages

- [ ] Second render of the existing card list as a mosaic: grid of `-medium` covers
      (`aspect-ratio`, `object-fit: cover`), no JS; the `<a>` wraps each cover.
- [ ] Toggle via the site's established `:target` mechanism (cf. `#only-favorites` on
      last-readings): `#mosaique` anchor + two `title-more` links; or CSS-only default for
      ≥4-book authors if simpler — decide during impl, keep one source of card data
      (`reps[:card].compiled_content(snapshot: :card)` reuse).

Commit: `Add covers mosaic toggle on author pages`

### E2. Hover/focus overlay with the full card

- [ ] Overlay = the existing card markup, absolutely positioned over the cover cell,
      `opacity/transform` transition on `:hover, :focus-within`; cover link stays clickable.
- [ ] Guard: `@media (hover: hover)` (touch = no overlay) + `prefers-reduced-motion`.
- [ ] a11y: overlay reachable by keyboard (the card contains the same links — avoid
      duplicate tab stops; hide overlay content from AT when closed, e.g.
      `visibility: hidden`).

Commit: `Reveal full book card over cover on author mosaic hover`

---

## Phase F — Housekeeping before opening the PR

- [ ] `Rules:174` leftover `filter :thumbnailize … #unless @config[:dev]` — decide keep vs
      restore guard (dev currently thumbnailizes avatars; intentional or WIP noise?).
- [ ] `layouts/book_card.html.erb` else-branch uses `@item[:author]` while siblings use
      `item[:author]` — same value in this context, but align for consistency.
- [ ] Rebase onto `main` again if it moved (already done once after the calendar weighting
      was cherry-picked to main as `443363c`; `origin/2-author-pages` still holds the
      pre-rebase history — syncing it needs `--force-with-lease`, only when explicitly asked).
- [ ] Validate both builds green: dev compile + `--env=prod` compile (prod deletes unrated
      non-wish books — re-check author cloud weights & per-author counts read sensibly
      after deletion, and that wish-only authors still resolve everywhere).
- [ ] `nanoc view` manual pass (see C2 matrix) + mobile spot-check (CSS media queries).
- [ ] Update issue #2 checkboxes with links to the commits; note what's intentionally
      deferred (D3 = ongoing content work, not code).

---

## Dependency graph

```
A1 ──► C2            A2 ──► B2            A3 ──► (D3 aliases)
A1 ──► B3 og:url     A1,A2 ──► C3         D1 ──► D2 ──► D3 ──► D4
D1,D2 ──► D5 (metadata→md items: run it after a few curation batches, not mid-batch)
everything above ──► E1 ──► E2 ──► F
```

## Decision points to reconfirm when implementing

1. B3: `profile:username` only (now) vs `given_name`/`family_name` config keys (later).
2. C3: alphabetical-only cloud or alpha/weight toggle.
3. E1: `:target` toggle vs automatic mosaic for prolific authors.
4. D2: attribution surfacing — tooltip, footer line, or config-only for now.
5. Bios in other languages (e.g. Kuo-li Chang, Mia Couto): French Wikipedia missing →
   is an English-sourced translated one acceptable, or leave blank?
