#!/bin/bash

# list_tags.sh
# Manages the gitignored .book_tags cache: the unique sorted list of tags
# from the `tags:` frontmatter arrays of content/book/*.md.
#
# Usage:
#   ./scripts/tools/list_tags.sh                 # print the cache (build it if missing)
#   ./scripts/tools/list_tags.sh --add FILE...   # merge tags from given book file(s) into the cache
#   ./scripts/tools/list_tags.sh --force         # rebuild the cache from all book files

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit
origin=$(cd "${script_dir}/../.." && pwd) || exit

cache_file="${origin}/.book_tags"
books_dir="${origin}/content/book"

ruby_script='
require "yaml"
files = ARGV
files.each do |file|
  text = File.read(file)
  frontmatter = text.split(/^---\s*$/, 3)[1]
  next if frontmatter.nil?
  begin
    data = YAML.safe_load(frontmatter, permitted_classes: [Date])
  rescue Psych::Exception
    warn "⚠  Cannot parse frontmatter of #{file}"
    next
  end
  next if data.nil?
  Array(data["tags"]).each do |tag|
    puts tag.to_s
  end
end
'

usage() {
    echo "Usage:"
    echo "  $0                       # print unique tags (build cache if missing)"
    echo "  $0 --add FILE...         # merge tags from given book file(s) into the cache"
    echo "  $0 --force               # rebuild the cache from all book files"
}

case "${1:-}" in
  --force)
    ruby -e "${ruby_script}" "${books_dir}"/*.md | sort -u > "${cache_file}"
    sort -u "${cache_file}"
    ;;
  --add)
    shift
    if [ "$#" -eq 0 ]; then
        echo "Error: --add requires at least one book file." >&2
        usage
        exit 1
    fi
    for file in "$@"; do
        if [ ! -f "${file}" ]; then
            echo "Error: file not found: ${file}" >&2
            exit 1
        fi
    done
    if [ ! -f "${cache_file}" ]; then
        ruby -e "${ruby_script}" "${books_dir}"/*.md > "${cache_file}"
    fi
    { sort -u "${cache_file}"; ruby -e "${ruby_script}" "$@"; } \
        | sort -u > "${cache_file}.tmp" && mv "${cache_file}.tmp" "${cache_file}"
    sort -u "${cache_file}"
    ;;
  -h|--help)
    usage
    ;;
  "")
    if [ ! -f "${cache_file}" ]; then
        ruby -e "${ruby_script}" "${books_dir}"/*.md > "${cache_file}"
    fi
    sort -u "${cache_file}"
    ;;
  *)
    echo "Error: unknown argument: $1" >&2
    usage
    exit 1
    ;;
esac