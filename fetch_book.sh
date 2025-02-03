#!/usr/bin/env bash

set -euo pipefail

origin=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit

escape_url() {
  printf %s "$1" | jq -sRr @uri
}

trim() {
  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "$1"
}

parseNumber() {
  echo "$1" | tr ',' '.' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

if [ $# -eq 1 ] && [ -f "$1" ]; then
  filename=$(basename "$1")
  if [ "${filename##*.}" = "docx" ]; then
    echo "Provided file is a .docx, converting to text"
    filename_b=$(basename "$1" .docx)
    echo "filename_b=$filename_b"
    # unzip -p "$1" word/document.xml | sed -e 's/<\/w:p>/ /g; s/<[^>]\{1,\}>/ /g; s/[^[:print:]]\{1,\}/ /g'
    docx2txt.sh "$1"
    file="${PWD}/${filename_b}.txt"
    cd "$(dirname "$1")"
    mv "${filename_b}.txt" "${file}"
    echo "--------"
    echo "STOP will most probably need post processing of resulting ${file} to follow requirements"
    echo ""
    echo "title | author | rating | description"
    echo ""
    echo " Where title & author are mandatory, rating falls back to 0 (unrated) and description is optional"
    echo " Rating can be X/Y or X, rating value is always converted to 10 upper bound (3 is then 3/10, 3.5/5 is then 7/10)"
    echo "--------"
    exit 1
  else
    file="$1"
  fi

  echo "Reading book information from file ${file}"
  pivot=0
  page_size=20
  limit=$((pivot+page_size))
  line_nb=0
  # FIXME ensure last line is properly read even if no newline at the end
  while IFS= read -r line; do
    [ -z "${line}" ] && continue

    echo ""
    echo "${line_nb} ---------------"
    line_nb=$((line_nb+1))

    # there are Google API rate limits, doing by batch can help iterating until limit is ignored
    [ ${line_nb} -lt "${pivot}" ] && continue
    [ ${line_nb} -gt "${limit}" ] && break

    title=$(trim "$(cut -d'|' -f1 <<< "${line}")")
    author=$(trim "$(cut -d'|' -f2 <<< "${line}")")
    rating_str=$(echo "${line}" | cut -d'|' -f3)
    if [ -n "${rating_str}" ]; then
      rating_value=$(parseNumber "$(cut -d/ -f1 <<< "${rating_str}")")
      echo "rating_value=$rating_value"
      rating_upper_bound=$(parseNumber "$(cut -d/ -f2 <<< "${rating_str}")")
      # we want rating to be in [0-10]
      rating=$(bc <<< "${rating_value} * 10 / ${rating_upper_bound}")
    else
      rating=0
    fi
    description=$(trim "$(cut -d'|' -f4 <<< "${line}")")

    # call ourselves with values instead of file
    "${BASH_SOURCE[0]}" "${title}" "${author}" "${rating}" "${description}"
  done < "${file}"
elif [ $# -eq 0 ] || [ $# -gt 4 ]; then
  echo "Usage:"
  echo " either $0 \"title\" \"author\" [rating] [description]"
  echo "  - rating is an integer in [0-10] (0 means unrated)"
  echo " or $0 file.txt"
  echo "  where file.txt contains lines with the following format:"
  echo "    title|author|rating|description"
  echo "    rating is an integer in [0-10] (0 means unrated)"
  echo "    rating can also be value/upper (e.g. 3/5) to be converted to a 10-based rating"
  exit 1
else
  if [ -z "${3:-""}" ] || [ "${3:-"0"}" = "0" ]; then
    rating="0 # TBD"
  else
    rating=${3}
  fi

  if [ -z "${4:-""}" ]; then
    description=""
  else
    description="${4}"
  fi

  mkdir -p "${origin}/content/book"
  mkdir -p "${origin}/content/cover"

  book_title_query=$(trim "$(tr "[:upper:]" "[:lower:]" <<< "${1}")")
  book_author_query=$(trim "$(tr "[:upper:]" "[:lower:]" <<< "${2}")")

  book_query="'${book_title_query}' by '${book_author_query}'"

  echo "Query book information for ${book_query}"

  book_data=$(curl -s --get \
        --data "key=${GOOGLE_BOOKS_API_KEY}" \
        --data "langRestrict=fr" \
        --data-urlencode "q=${book_title_query} by ${book_author_query}" \
        'https://www.googleapis.com/books/v1/volumes' \
        -H 'Accept: application/json')

  isbn=""
  if [ "$(jq -r .totalItems <<< "${book_data}")" -gt 0 ]; then
    selected_volume=$(jq -r 'first(.items[] | select(.volumeInfo.industryIdentifiers[] | select(.type == "ISBN_13")))' <<< "${book_data}")
    title="$(jq -r .volumeInfo.title <<< "${selected_volume}")"
    author="$(jq -r .volumeInfo.authors[0] <<< "${selected_volume}")"
    echo "Retrieved some book information for ${book_query}: '${title}' by '${author}'"
    isbn="$(jq -r '.volumeInfo.industryIdentifiers[] | select(.type == "ISBN_13") | .identifier' <<< "${selected_volume}")"
    if [ "${isbn}" = "null" ] || [ -z "${isbn}" ]; then
      isbn=""
    else
      echo "Found ISBN 13 '${isbn}'"
    fi

    if [ -z "${description}" ]; then
      description="$(jq -r '.volumeInfo.description' <<< "${selected_volume}")"
    fi
    cover_full_url=$(jq -r .volumeInfo.imageLinks.thumbnail <<< "${selected_volume}")
    if [ "${cover_full_url}" = "null" ] || [ -z "${cover_full_url}" ]; then
      echo " ⚠︎ Can't find book cover for ${book_query} (ISBN: ${isbn})"
    else
      cover_short_url=$(cut -d'&' -f1 <<< "${cover_full_url}")
      cover_clean_url="${cover_short_url}&printsec=frontcover&img=1&source=gbs_api"
      # FIXME what about non JPEG files?
      cover_file="${origin}/content/cover/${isbn}.jpg"
      if [ -f "${cover_file}" ]; then
        echo "Cover already downloaded for ${book_query} (ISBN: ${isbn})"
      elif [ -n "${isbn}" ]; then
        echo "Downloading cover for ${book_query} (${isbn})"
        echo "Cover URL: ${cover_clean_url}"
        curl -s "${cover_clean_url}" > "${cover_file}"
      else
        echo "Won't try to download cover for ${book_query}, no ISBN to store result"
      fi
      echo "Cover available: ${cover_file}"
    fi

    cover_query=$(escape_url "${book_title_query} ${book_author_query}")
    echo "Not satisfied with the cover? You can try to find the cover on:"
    echo " - Google image: https://www.google.fr/search?q=${cover_query}&udm=2"
    echo " - Amazon: https://www.amazon.fr/s?k=${cover_query}&i=stripbooks"
  fi

  if [ -z "${isbn}" ]; then
    echo "Can't find any book or ISBN for ${book_query}"
    title="${book_title_query}"
    author="${book_author_query}"
    isbn="?????????????"
  fi

  # book file (markdown)
  book_file="${origin}/content/book/${isbn}.md"
  if [ ! -f "${book_file}" ]; then
    uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    echo "Creating a new book ${book_file} for '${title}' by '${author}'"
    echo "---
uuid: ${uuid}
REF: \"${book_query}\"
title: \"${title}\"
author: \"${author}\"
rating: ${rating}
read_date: $(date "+%Y-%m-%d") # TBD
isbn: \"${isbn}\"
---

${description}
" > "${book_file}"
  else
    echo "Book ${book_file} already exists"
    head -n 8 "${book_file}"
  fi
fi
