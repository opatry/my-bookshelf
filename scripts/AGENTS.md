# Scripts — Conventions

Guidelines for all shell scripts under `scripts/`.

## Executability

Every `scripts/**/*.sh` must be executable from anywhere (not rely on relative
working directory). Use `chmod +x` and always the following bootstrap pattern:

```bash
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit
origin=$(cd "${script_dir}/../.." && pwd) || exit
```

`origin` is the repo root; use it for all repo-relative paths.

## Variable naming

Never use UPPERCASE for script variables or constants. UPPERCASE is reserved for
environment variables (e.g. `PATH`, `LANG`, `LC_ALL`, `GOOGLE_BOOKS_API_KEY`).
Use lowercase snake_case for everything else.

## Linting

Shell scripts must pass `shellcheck` (see `.shellcheckrc` at the repo root for
the shared configuration). Run it after any change:

```bash
shellcheck scripts/**/*.sh
```

`shellcheck` must be installed (e.g. `brew install shellcheck`).
