# AGENTS.md

Nanoc 4 static site (French personal bookshelf, https://lecture.opatry.net) deployed to Firebase Hosting.

## Ignore
- `output/`, `output.diff`, `tmp*` — local build artifacts.
- `raw/` — GIMP sources for favicons; CI ignores changes there.

## Commands
- `bundle install && bundle exec nanoc compile` — build; this is also the de-facto test (no unit-test suite).
- `bundle exec nanoc view` — serves `output/` with the default (dev) env.
- `bundle exec nanoc compile --env=prod` — prod build: HTML/CSS minified, covers thumbnailized via ImageMagick. Unrated books are DELETED in prod (dev keeps everything), so validate with the dev compile.
- Local build needs ImageMagick 7 (`magick`; `convert` fallback only on Linux) and Ruby ~3.4 (CI uses 3.4).
- Deploy is automatic: pushes to `main` are built and deployed to Firebase by GitHub Actions (`.github/workflows/build_deploy.yml`). Never deploy manually unless explicitly asked.

## Content model
- One book = `content/book/{author-slug}_{title-slug}.md` with YAML frontmatter: `uuid`, `isbn`, `title`, `author`, `rating` (1–10), `read_date`, `priority` (wish list), `ongoing`, `favorite`, `tags`, `linked_books` (series, by ISBN; backfilled reciprocally), `social: {sc, babelio}` (numeric profile IDs), `page_count`, `publication_year`. Body = French description.
- Cover: `content/cover/<isbn>.<ext>`; every cover must have a matching book and vice versa.
- `Rules` preprocess VALIDATES and raises on violations: books need `isbn`+`uuid`; `read_date` requires nonzero rating; `priority` (wish) XOR rated; `ongoing` forbids `read_date`/`rating`; max one ongoing book; `linked_books` ISBNs must resolve. A failed compile usually means a frontmatter violation — read the raised message.
- Missing `social`/cover fields only print warnings (🚫/⚠️ lines in compile output); fill SensCritique/Babelio IDs when known.
- Tag pages and calendar pages are generated in preprocess, not content files. Apostrophes in title/author are rewritten to `’` automatically.
- Site is French: UI strings in `strings/fr.yml` (I18n). Markdown pipeline: erb → french_typography → kramdown.

## Workflow
- Add books with `./fetch_book.sh "Title" "Author" [rating] [desc]` or a batch file `title | author | rating | description` (rating `X` or `X/Y`, normalized to /10). Requires `GOOGLE_BOOKS_API_KEY`; Google Books data is inaccurate — verify ISBN/cover manually (script prints Google Images/Amazon fallback links).
- New books are left untracked; `./commit_book.sh` commits each as `[book][<isbn>] "Title" by "Author"` with author date = `read_date`. Match this format.
- Branch per topic/book (e.g. `book/<author>_<slug>`); PRs merged to `main`; merging to `main` triggers the deploy.
- Shell scripts: keep `shellcheck`-clean — `.shellcheckrc` sets `enable=require-variable-braces`, so always write `${var}`, and `set -euo pipefail`.

## Commits
- When the user provides a plan or a bullet list, treat **each bullet as its own commit** — do not collapse several independent bullets into one commit.
- One commit = one coherent, self-contained change: app builds, UI is functional.
- The full loop for one bullet (implement + test + verify) is that bullet's commit; only bulk into one commit when bullets are truly inseparable parts of a single change.
- Be autonomous: commit after each logical step without waiting for user confirmation.
- Granularity: think like a reviewer — your commit history should tell the story of the plan, bullet by bullet.
- **No conventional commit format** (no `feat:`, `fix:`, etc.). Use concise, clear messages describing *what* changed, not *how*. (Book additions keep the `[book][<isbn>]` format.)
- Detailed messages only when linked to context: a discussion choice, a doc reference, a GitHub issue, evidence for a decision.
- Commit autonomy covers LOCAL commits on the current topic branch only: by default there is NO remote impact — never push, create/comment/merge PRs (`gh`), or deploy (Firebase) without an explicit ask (pushing `main` triggers the deploy).
