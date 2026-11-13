#!/usr/bin/env bash
# Re-render the favicon/PWA PNG sources (content/static/favicon*.png) from the
# SVG masters in this directory.
#
# Needs node + npm only at regeneration time (CI doesn't run this): sharp
# bundles librsvg, the only renderer here that parses Lucide's compact path
# syntax — ImageMagick's internal MSVG renderer chokes on it.
#
# Usage: raw/render_icons.sh
set -euo pipefail

raw_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out_dir="${raw_dir}/../content/static"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

cd "${work_dir}"
npm init --yes >/dev/null
npm install sharp --no-audit --no-fund >/dev/null

cat >render.js <<'NODE'
const path = require('path');
const sharp = require('sharp');

const [, , rawDir, outDir] = process.argv;
const jobs = [
  ['favicon.svg', 'favicon.png', 192],
  ['favicon-maskable.svg', 'favicon192-maskable.png', 192],
  ['favicon-maskable.svg', 'favicon512-maskable.png', 512],
];

(async () => {
  for (const [master, out, size] of jobs) {
    await sharp(path.join(rawDir, master), { density: 288 })
      .resize(size, size, { fit: 'fill' })
      .png({ compressionLevel: 9 })
      .toFile(path.join(outDir, out));
    console.log('wrote', out);
  }
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
NODE

node render.js "${raw_dir}" "${out_dir}"
