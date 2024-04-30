#!/usr/bin/env bash

set -euo pipefail

origin=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit

new_books=$(cd "${origin}/content/book" && git ls-files -o --exclude-standard --full-name)

for book in ${new_books}; do
  name="$(basename "${book}")"
  name="${name%.*}"
  git add "${book}"
  git add "${origin}/content/cover/${name}."*

  title=$(grep "^title:\ *" < "${book}")
  title=${title#"title: "}
  author=$(grep "^author:\ *" < "${book}")
  author=${author#"author: "}
  isbn=$(grep "^isbn:\ *" < "${book}")
  isbn=${isbn#"isbn: "}
  isbn=$(cut -d'"' -f2 <<< "${isbn}")
  commit_msg="[book][${isbn}] ${title} by ${author}"

  git commit -m "${commit_msg}"
done
