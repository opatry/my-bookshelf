#!/usr/bin/env bash

set -euo pipefail

if [ -d "$1" ]; then
  find "$1" -type f -iname "*.jpg" -print0 | xargs -0 -n 1 -I '{}' "$0" {}
else
  image="$(cd "$(dirname "${1}")"; pwd)/$(basename "${1}")"

  geometry=$(identify -format "%w %h" "${image}")
  width=$(cut -d' ' -f1 <<< "${geometry}")
  target_width=575
  if [ "${width}" -gt "${target_width}" ]; then
    ratio=$(bc -l <<< "${target_width} * 100 / ${width}")
    magick "${image}" -resize "${ratio}%" tmp.jpg && mv tmp.jpg "${image}"
  fi
fi

