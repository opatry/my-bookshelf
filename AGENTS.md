# Book Reading List — Les lectures d'Olivier

Personal book reading list website built with Nanoc (Ruby static site generator), deployed to Firebase Hosting.

**All content is in French** — book titles, descriptions, tags, and UI text.

## Project structure

- `content/book/*.md` — Book entries (markdown with YAML frontmatter)
- `content/cover/*.jpg` — Book covers, named `{isbn}.jpg`
- `content/static/` — Site assets (CSS, JS, images)
- `layouts/` — ERB templates for pages
- `lib/` — Ruby helpers and Nanoc filters
- `Rules` — Nanoc compilation/routing rules
- `nanoc.yaml` — Nanoc config (site URL: `https://lecture.opatry.net`)
- `output/` — Generated site (do not edit directly)

## Key scripts

All helper scripts live under `scripts/` (run from the repo root).

- `scripts/fetch/google_books.sh` — Fetches book metadata from Google Books API. Usage: `./scripts/fetch/google_books.sh "title" "author" [rating] [description]`
- `scripts/fetch/babelio.rb` — Looks up a book on Babelio (URL + ID) via the site's autocomplete endpoint driven by headless Chrome (Ferrum, read-only, needs Chrome + `bundle install`). Usage: `./scripts/fetch/babelio.rb "title" "author" [--meta]`
- `scripts/tools/list_tags.sh` — Manages the gitignored `.book_tags` cache (`--add FILE...` after a book, `--force` to rebuild)
- `scripts/tools/commit_book.sh` — Git commit helper for book additions
- `scripts/tools/normalize_images.sh` — Image normalization
- `scripts/tools/check_spelling.sh` — French typo check (aspell)

## Book file format

```yaml
---
uuid: {uuid}
isbn: '{isbn13}'
title: "{French title}"
author: "{Author name}"
rating: 7              # 1-10, absent for wished books
read_date: 2025-01-15  # only for read books
priority: 1            # only for wished books (1=highest)
tags:
  - Tag1
  - Tag2
social:
  sc: '{senscritique_id}'
  babelio: '{babelio_id}'
page_count: {page_count}
publication_year: {publication_year}
---

Optional description in French.
```

## Tag conventions

Tags are French-language, organized by:
- **Themes**: Amour, Famille, Guerre, Humour, Psychologie, etc.
- **Countries/regions**: Etats-Unis, Japon, Corée, Bretagne, Normandie, etc. (foreign: country-level only; France: region-level, no departments)
- **Genres**: Policier, Thriller, Sci-fi, Fantasy, Fantastique, etc.

Use only existing tags from the unique tags list (`./scripts/tools/list_tags.sh`, gitignored `.book_tags` cache). See `tags-ignore.yml` for Babelio tags that should not be imported.

## Build

```bash
bundle exec nanoc compile
```

Requires: Ruby, Bundler, ImageMagick (`magick`).

Never deploy on your own.

## Conventions

- Apostrophes in titles: use curly quotes `’` not straight one `'`
- ISBN: always quoted as string in frontmatter
- The `fetch-book` skill (`.opencode/skills/fetch-book/SKILL.md`) orchestrates the full book addition workflow
