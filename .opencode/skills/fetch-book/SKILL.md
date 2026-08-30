---
name: fetch-book
description: Fetch and enrich book metadata from Google Books, SensCritique, and Babelio into a Nanoc book markdown file. Use when the user provides a book title and author to add to the reading list.
---

## What I do

I orchestrate the full book-fetching workflow: gather metadata from Google Books and Babelio, grab a cover, infer tags from the existing taxonomy, and produce a complete French markdown file in `content/book/`.

**This project is entirely in French.** Titles, descriptions, tags, and UI text are French; always query with `langRestrict=fr` and use the French tag names from the existing taxonomy.

Helper scripts live in `scripts/` (`scripts/fetch/` for lookups, `scripts/tools/` for maintenance). Run them from the repo root.

## Workflow

### Step 1 — Google Books

```bash
./scripts/fetch/google_books.sh "TITLE" "AUTHOR"
```

Creates the book file in `content/book/` with base fields (ISBN, title, author, page_count, publication_year, description, cover) and downloads the cover to `content/cover/{isbn}.jpg`. The script retries transient API errors (503) up to 3 times with backoff. If GBooks fails entirely, continue with manual lookups.

Note: GBooks is often inaccurate — every field is a candidate for correction in Step 6.

### Step 2 — SensCritique

1. `websearch` for `"TITLE" "AUTHOR" site:senscritique.com`
2. The SensCritique ID is in the URL, e.g. `…/livre/titre/12345678` → `12345678`.
3. No need to fetch the page; the URL is enough.

### Step 3 — Babelio

**NEVER `webfetch` Babelio directly — it rejects non-browser clients (curl/`webfetch`) with a 403 security check.** Use the browser-driven helper:

```bash
./scripts/fetch/babelio.rb "TITLE" "AUTHOR"           # → URL + Babelio ID
./scripts/fetch/babelio.rb "TITLE" "AUTHOR" --meta    # + ISBN, page count, date, éditeur, étiquettes, résumé
```

The helper (Ruby + Ferrum, headless Chrome) calls Babelio's own autocomplete endpoint (`aj_recherche.php`) from within a real session and matches title + author. If that fails, it walks the author's `/bibliographie` page. **It never fetches the Babelio book page for press quotes** — press quotes come from local reasoning only (Step 6).

When you don't run the helper, `websearch` for `site:babelio.com TITLE AUTHOR`; snippets give the ID (from the URL) and often ISBN/page count. The **rating** is never used.

**Conflict rules** (also applied in Step 6):
- **Page count**: prefer **Babelio** over GBooks when they disagree.
- **Publication year**: use the **oldest** year among sources, and when in doubt prefer the **French edition** year, not the original-language one.
- **Étiquettes** (e.g. ROMAN NOIR) are tag *hints only* — always remap them onto the existing taxonomy (Step 4), never verbatim.

### Step 4 — Tags

**Only use tags from the existing taxonomy.** Read it from the cache with `./scripts/tools/list_tags.sh`:
- First use in a session (cache missing/stale): `./scripts/tools/list_tags.sh --force`
- After writing the book file, refresh the cache: `./scripts/tools/list_tags.sh --add content/book/{file}.md`

Ignore genre labels that don't belong in the taxonomy (Roman, Littérature française/étrangère, Jeunesse, Nouvelle, Poésie, Théâtre, BD, Manga, Essai, Classique, etc.). Infer tags from facts: polar → `Policier`, thriller → `Thriller`, sci-fi → `Sci-fi`, fantasy → `Fantasy`, etc., plus country/region (Japan → `Japon`, Italy → `Italie`) and themes when relevant. When unsure, leave a tag off.

### Step 5 — Cover

**Covers come from only two sources: the GBooks API (default) or Amazon.** Never fetch covers from any other source (no Google Images, no Babelio, no publisher sites, no scraping).

1. Default: use the cover that `google_books.sh` already downloaded to `content/cover/{isbn}.jpg`.
2. Only if the GBooks cover is poor/missing, try Amazon: `https://www.amazon.fr/s?k={title}+{author}&i=stripbooks` (first result usually has a good cover).
3. Save to `content/cover/{isbn}.jpg`. Covers are resized to 575px width at build time, so any reasonable size works.

**Avoid over-fetching covers.** Do not repeatedly try alternate sources or hunt exhaustively for the "perfect" cover — one quick GBooks lookup (already done) plus at most one Amazon check is enough. If GBooks already produced a reasonable cover, keep it as-is; only reach for Amazon when it's clearly poor or missing.

### Step 6 — Generate the markdown file

Read the generated file and enrich/clean it into the final form:

```yaml
---
uuid: {uuid}
isbn: '{isbn}'
title: "{title}"
author: "{author}"
priority: 1
tags:
  - Tag1
  - Tag2
social:
  sc: '{senscritique_id}'
  babelio: '{babelio_id}'
page_count: {page_count}
publication_year: {publication_year}
---
```

Conventions:
- **Apostrophes**: typographic `’` (curly), never straight `'`, in titles and body.
- **ISBN**: always a quoted string (`'9782000000000'`).
- **Tags**: one per line with `- `, French, from the taxonomy.
- **Social IDs**: numeric strings; empty string if not found.
- **Priority**: 1 for wished books.
- **Page count / publication year**: apply the Babelio conflict rules (Step 3).
- **Description**: French, proofread — coherent grammar, curly apostrophes, proper capitalization, no leftover `REF:` placeholder (remove the temporary `REF:` line `google_books.sh` adds).
- **Press quotes — local reasoning only.** Once the metadata from Google Books, SensCritique, and Babelio is gathered, read the assembled `content/book/*.md` file and reason about it **locally**: if the description itself contains attributed editorial quotes (« … » with a publication or author), pull them out of the description and render them in an `### À propos` section at the end of the body, one `quote_markup` block per quote. **Never scrape or search elsewhere for press quotes.**

  ```erb
  ### À propos

  <%= quote_markup(
    text: "…",
    author: "…"
  ) %>
  ```

- **Duplicates**: never create a duplicate book file — check `content/book/{author_slug}_{title_slug}.md` first.

## File locations

- Books: `content/book/{author_slug}_{title_slug}.md`
- Covers: `content/cover/{isbn}.jpg`
- Lookups: `scripts/fetch/google_books.sh`, `scripts/fetch/babelio.rb`
- Tools: `scripts/tools/list_tags.sh`, `scripts/tools/commit_book.sh`, `scripts/tools/normalize_images.sh`, `scripts/tools/check_spelling.sh`
- Tags cache: `.book_tags` (gitignored, managed by `list_tags.sh`)

## Notes

- Build: `bundle exec nanoc compile`. Deploy is not done from here.
- The whole site is French; never mix in English UI text.