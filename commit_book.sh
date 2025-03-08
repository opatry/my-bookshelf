#!/usr/bin/env bash

set -euo pipefail

origin=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit

new_books=$(cd "${origin}/content/book" && git ls-files -o --exclude-standard --full-name)

for book in ${new_books}; do
  name="$(basename "${book}" .md)"
  git add "${book}"
  git add "${origin}/content/cover/${name}."*

  title=$(grep "^title:\ *" < "${book}")
  title=${title#"title: "}
  author=$(grep "^author:\ *" < "${book}")
  author=${author#"author: "}
  isbn="${name}"
  commit_msg="[book][${isbn}] ${title} by ${author}"

  # use book read date as Git author date (not committer date on purpose)
  book_read_date=$(grep "read_date" "${book}" | cut -d' ' -f2 -f3) || book_read_date=$(date "+%Y-%m-%d")
  git commit --date="${book_read_date}" -m "${commit_msg}"
done
