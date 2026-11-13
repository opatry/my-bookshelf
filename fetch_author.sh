#!/usr/bin/env bash
#
# Draft author metadata for the @config[:author] section of nanoc.yaml, from public
# Wikimedia APIs. Output is PRINTED for a human to review & paste — this script never
# touches nanoc.yaml (Wikidata search can pick homonyms; pictures & bios need a glance).
#
# Usage:
#   ./fetch_author.sh "Author Name" ["Next Author" ...]
#   ./fetch_author.sh authors.txt        # one author name per line, '#' lines ignored
#
# Sources (public, no API key, UA-tagged, sequential ~1 req/s with local caching):
#   - Wikidata wbsearchentities + Special:EntityData: frwiki sitelink, P18 (picture),
#     P3630 (Babelio author id), P14412 (SensCritique person id), P742 (pseudonyms),
#     P569/P570 (birth/death)
#   - fr.wikipedia REST summary: 1-paragraph bio extract + original image URL
#
# Licensing: bio extracts are CC BY-SA 4.0 (keep the emitted bio_source: wikipedia &
# attribute when displayed); Wikidata descriptions are CC0; Commons files carry their own
# credit — check the emitted picture_source: file page before accepting a photo.

set -euo pipefail

origin=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit

readonly user_agent="my-bookshelf fetch_author/1.0 (+https://lecture.opatry.net)"
readonly wikidata_api="https://www.wikidata.org/w/api.php"
readonly wikidata_entity="https://www.wikidata.org/wiki/Special:EntityData"
readonly wikipedia_summary="https://fr.wikipedia.org/api/rest_v1/page/summary"
readonly cache_dir="${origin}/tmp/authors-cache"

# occupation QIDs (all Wikidata-verified) marking a search hit as author-like; extend when needed
readonly author_occupations='["Q36180","Q6625963","Q49757","Q28389"]'
# bio kept ≤ that many words, trimmed on a sentence boundary (og:description uses ~50 too)
readonly bio_max_words=50

mkdir -p "${cache_dir}"

urlencode() {
  printf %s "${1}" | jq -sRr @uri
}

hash_str() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum | cut -d' ' -f1
  else
    md5 -q
  fi
}

# GET a JSON URL, with cache & minimal politeness (sequential, UA required by Wikimedia
# policy, one 30s backoff retry on 429). Prints body; fails non-zero on any error.
fetch_json() {
  local url="${1}"
  local cache
  cache="${cache_dir}/$(printf %s "${url}" | hash_str).json"

  if [[ -f "${cache}" ]]; then
    cat "${cache}"
    return
  fi

  local http_code attempt=1
  while :; do
    http_code=$(curl -s -o "${cache}.part" -w '%{http_code}' -A "${user_agent}" -- "${url}") || http_code="000"
    case "${http_code}" in
      200)
        mv "${cache}.part" "${cache}"
        cat "${cache}"
        return
        ;;
      429)
        if [[ "${attempt}" -lt 2 ]]; then
          echo " ⚠︎ rate limited (429), backing off 30s…" >&2
          sleep 30
          attempt=2
          continue
        fi
        ;;
    esac
    rm -f "${cache}.part"
    echo " ✗ HTTP ${http_code} for ${url}" >&2
    return 1
  done
}

# YAML double-quote a scalar (bios may contain ", backslashes, colons…)
yaml_str() {
  local escaped
  escaped=$(printf %s "${1}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
  printf '"%s"' "${escaped}"
}

# Keep at most bio_max_words words, cutting on the last sentence terminator in that
# window; append an ellipsis when truncated without finding one.
trim_bio() {
  awk -v max="${bio_max_words}" '
    BEGIN { RS = "\0" }
    {
      n = split($0, w, /[ \t\r\n]+/)
      if (n <= max) { gsub(/[ \t\r\n]+/, " "); print; exit }
      s = ""
      for (i = 1; i <= max; i++) s = s (i > 1 ? " " : "") w[i]
      for (j = length(s); j > 0; j--) {
        c = substr(s, j, 1)
        if (c == "." || c == "!" || c == "?") { print substr(s, 1, j); exit }
      }
      print s "…"
    }' <<< "${1}"
}

# Reproduce the site's own slug (lib/helpers.rb author_slug under fr locale) so the
# emitted config key is guaranteed to match what generate_author_items looks up.
slug_of() {
  bundle exec ruby -I "${origin}/lib" -e '
    require "nanoc"; require "i18n"
    I18n.available_locales = [:fr]; I18n.default_locale = :fr; I18n.locale = :fr
    def use_helper(*); end
    require "helpers"
    puts author_slug(ARGV[0])
  ' "${1}" 2>/dev/null
}

# score = frwiki sitelink +2, author-like occupation +2, exact label match +1
score_entity() { # $1 = compact entity json, $2 = author name
  jq -r --argjson occ "${author_occupations}" --arg name "${2}" '
    def norm: ascii_downcase | gsub("\\s+"; " ");
    def extids: map(.mainsnak.datavalue?.value | if type == "object" then .id else . end);
    (if .sitelinks.frwiki then 2 else 0 end) +
    (if ([.claims.P106[]?] | extids | any(. as $o | $occ | any(. == $o))) then 2 else 0 end) +
    (if ((.labels.fr.value // .labels.en.value // "") | norm) == ($name | norm) then 1 else 0 end)
  ' <<< "${1}"
}

entity_label() { # $1 = compact entity json
  jq -r '[(.labels.fr.value // .labels.en.value // "?"), (.descriptions.fr.value // .descriptions.en.value // "")] | join(" — ")' <<< "${1}"
}

process_author() {
  local name="${1}"
  local slug
  slug=$(slug_of "${name}")

  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "${name}  →  config key: ${slug}"

  local search_json ids qid ent compact best="" best_qid="" best_score=-1 score
  search_json=$(fetch_json "${wikidata_api}?action=wbsearchentities&search=$(urlencode "${name}")&language=fr&uselang=fr&type=item&limit=5&format=json")
  ids=$(jq -r '[.search[].id][:3] | join(" ")' <<< "${search_json}")

  if [[ -z "${ids// /}" ]]; then
    echo " ✗ no Wikidata search hit — manual search: https://www.wikidata.org/w/index.php?search=$(urlencode "${name}")"
    return 1
  fi

  echo " candidates:"
  for qid in ${ids}; do
    ent=$(fetch_json "${wikidata_entity}/${qid}.json") || { echo "   (fetch failed for ${qid})"; continue; }
    compact=$(jq -c '.entities | to_entries[0].value' <<< "${ent}")
    score=$(score_entity "${compact}" "${name}")
    echo "   ${qid} — $(entity_label "${compact}")  [score ${score}]"
    if [[ "${score}" -gt "${best_score}" ]]; then
      best_score="${score}"
      best="${compact}"
      best_qid="${qid}"
    fi
  done

  if [[ -z "${best}" ]]; then
    echo " ✗ all candidate fetches failed"
    return 1
  fi

  echo " ✔ picked ${best_qid} (score ${best_score}) — https://www.wikidata.org/wiki/${best_qid}"
  if [[ "${best_score}" -lt 4 ]]; then
    echo " ⚠︎ low score — verify this is your author (homonyms likely at score ≤ 3)!"
  fi

  local frwiki_title description babelio sc file picture wikipedia bio born died
  frwiki_title=$(jq -r '.sitelinks.frwiki.title // empty' <<< "${best}")
  description=$(jq -r '(.descriptions.fr.value // .descriptions.en.value) // empty' <<< "${best}")
  babelio=$(jq -r '.claims.P3630[0].mainsnak.datavalue?.value // empty' <<< "${best}")
  sc=$(jq -r '.claims.P14412[0].mainsnak.datavalue?.value // empty' <<< "${best}")
  file=$(jq -r '.claims.P18[0].mainsnak.datavalue?.value // empty' <<< "${best}")
  born=$(jq -r '.claims.P569[0].mainsnak.datavalue?.value.time // empty' <<< "${best}" | grep -oE '[0-9]{4}' | head -n1 || true)
  died=$(jq -r '.claims.P570[0].mainsnak.datavalue?.value.time // empty' <<< "${best}" | grep -oE '[0-9]{4}' | head -n1 || true)

  bio="" ; picture="" ; wikipedia=""
  if [[ -n "${frwiki_title}" ]]; then
    local summary
    wikipedia="https://fr.wikipedia.org/wiki/$(urlencode "${frwiki_title}")"
    if summary=$(fetch_json "${wikipedia_summary}/$(urlencode "${frwiki_title}")" 2>/dev/null); then
      bio=$(jq -r '.extract // empty' <<< "${summary}" | tr -d '\n')
      picture=$(jq -r '(.original_image.source // .thumbnail.source // "") | sub("\\?.*"; "")' <<< "${summary}")
    fi
  fi

  echo " draft — review then paste into nanoc.yaml under 'author:':"
  local line
  line="  wikidata: ${best_qid}"
  [[ -n "${born}" ]] && line="${line}  # né en ${born}"
  [[ -n "${died}" ]] && line="${line}  # mort en ${died}"
  echo "${line}"
  if [[ -n "${bio}" ]]; then
    echo "  bio: $(yaml_str "$(trim_bio "${bio}")")  # CC BY-SA — display attribution required"
    echo "  bio_source: wikipedia"
  elif [[ -n "${description}" ]]; then
    echo "  # no fr.wikipedia article; CC0 one-liner to rewrite in own words: ${description}"
  else
    echo "  # no bio found (no frwiki sitelink, no description)"
  fi
  if [[ -n "${picture}" ]]; then
    echo "  picture: $(yaml_str "${picture}")"
  elif [[ -n "${file}" ]]; then
    echo "  # picture candidate on Commons only: https://commons.wikimedia.org/wiki/File:$(urlencode "${file}")"
  else
    echo "  # no picture (initials fallback will be used)"
  fi
  if [[ -n "${file}" ]]; then
    echo "  # photo file page (verify it is a portrait & the license): https://commons.wikimedia.org/wiki/File:$(urlencode "${file}")"
  fi
  [[ -n "${wikipedia}" ]] && echo "  wikipedia: $(yaml_str "${wikipedia}")"
  if [[ -n "${babelio}" ]]; then
    echo "  babelio: \"https://www.babelio.com/auteur/x/${babelio}\""
  else
    echo "  # babelio not on Wikidata — manual check: https://www.babelio.com/recherche.php?mots=$(urlencode "${name}")"
  fi
  if [[ -n "${sc}" ]]; then
    echo "  sc: \"https://www.senscritique.com/contact/x/${sc}\"  # verify URL"
  else
    echo "  # senscritique not on Wikidata — manual check: https://www.senscritique.com/recherche?query=$(urlencode "${name}")"
  fi

  # pseudonyms (P742) → aliases candidates, labels resolved in one request
  local alias_ids aliases=""
  alias_ids=$(jq -r '[.claims.P742[]?.mainsnak.datavalue?.value | if type == "object" then .id else . end | select(test("^Q[0-9]+$"))] | join("|")' <<< "${best}")
  if [[ -n "${alias_ids}" ]]; then
    local alias_json
    if alias_json=$(fetch_json "${wikidata_api}?action=wbgetentities&ids=${alias_ids}&props=labels&languages=fr|en&format=json" 2>/dev/null); then
      aliases=$(jq -r '[.entities[].labels | (.fr.value // .en.value) // empty] | join(", ")' <<< "${alias_json}")
    fi
    echo "  aliases: [${aliases}]  # from P742 pseudonym claims — canonical mapping is plan step A3"
  else
    echo "  aliases: []"
  fi
  return 0
}

main() {
  if [[ $# -eq 0 ]]; then
    sed -n '3,23p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1
  fi

  local names=()
  if [[ $# -eq 1 && -f "${1}" ]]; then
    echo "Reading author names from file ${1}"
    local line
    while IFS= read -r line || [[ -n "${line}" ]]; do
      line="${line%%#*}"
      [[ -z "$(printf %s "${line}" | tr -d '[:space:]')" ]] && continue
      names+=("$(printf %s "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")
    done < "${1}"
  else
    names=("$@")
  fi

  local total="${#names[@]}" processed=0 failed=0 name
  for name in "${names[@]}"; do
    processed=$((processed + 1))
    echo ""
    echo "[${processed}/${total}]"
    process_author "${name}" || failed=$((failed + 1))
    sleep 0.5
  done

  echo ""
  echo "Done: $((processed - failed)) ok, ${failed} failed of ${total}."
  echo "Next: paste reviewed blocks under 'author:' in nanoc.yaml (keys must match"
  echo "the printed config key exactly), then validate with:"
  echo "  bundle exec nanoc compile"
}

main "$@"
