#!/usr/bin/env bash
# Re-render every committed icon from the two SVG masters in this directory.
#
# Needs node + npm only at regeneration time: CI never runs this (the rendered
# files are committed), and it installs sharp in a temporary directory because
# sharp bundles librsvg, the renderer that parses Lucide's compact path syntax.
#
#   app-icon.svg  full-bleed 512 grid, no radius -> every PWA raster, the
#                 maskable one and the apple-touch icon included
#   favicon.svg   rounded 64 grid -> favicon.ico (16, 32 and 48px frames) and
#                 the served /static/favicon.svg
#
# Both are copied from the book nook app's icon masters, colour aside: one
# square ground for the things a launcher will mask, one rounded tile for the
# fixed square of a browser tab. Each output size is rasterised from the vector
# at that size, never scaled from another raster.
#
# The script measures what it wrote: an opaque red ground at the corners and at
# the middle of every edge, no transparent band, no white frame. A bad icon
# fails the run instead of being committed unnoticed, and the numbers are
# printed so a regeneration can be reviewed.
#
# Usage: raw/render_icons.sh
set -euo pipefail

raw_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out_dir="${raw_dir}/../content/static"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

cd "${work_dir}"
npm init --yes >/dev/null
npm install sharp sharp-ico --no-audit --no-fund >/dev/null

cat >render.js <<'NODE'
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { encode: encodeIco } = require('sharp-ico');

const [, , rawDir, outDir] = process.argv;

/** The site red, and the one colour every icon's ground has to reach. */
const ACCENT = { r: 0x73, g: 0x1b, b: 0x15 };

/**
 * Rasterise at 4x the shipping size and let Lanczos reduce it, so the stroke
 * curve is drawn as vector geometry rather than guessed at the final size.
 */
const SUPERSAMPLE = 4;

/** What gets written, and from which master. */
const RASTERS = [
  ['app-icon.svg', 'pwa-64x64.png', 64],
  ['app-icon.svg', 'pwa-192x192.png', 192],
  ['app-icon.svg', 'pwa-512x512.png', 512],
  ['app-icon.svg', 'maskable-icon-512x512.png', 512],
  ['app-icon.svg', 'apple-touch-icon-180x180.png', 180],
];

/** The frames inside favicon.ico, each rendered from the vector at its own size. */
const FAVICON_FRAMES = [16, 32, 48];

async function render(master, size) {
  const source = fs.readFileSync(path.join(rawDir, master));
  return sharp(source, { density: 72 * SUPERSAMPLE })
    .resize(size, size, { fit: 'fill', kernel: 'lanczos3' })
    // The masters paint their own ground; flattening is the guarantee that no
    // future edit to a master can hand a launcher a translucent edge.
    .flatten({ background: ACCENT })
    .png({ compressionLevel: 9 })
    .toBuffer();
}

/** Size, edges and area of an output, measured rather than assumed. */
async function measure(buffer) {
  const { data, info } = await sharp(buffer).ensureAlpha().raw().toBuffer({
    resolveWithObject: true,
  });
  const at = (x, y) => {
    const i = (y * info.width + x) * info.channels;
    return { r: data[i], g: data[i + 1], b: data[i + 2], a: data[i + 3] };
  };
  const pixels = info.width * info.height;
  let transparent = 0;
  let white = 0;
  for (let i = 0; i < data.length; i += info.channels) {
    if (data[i + 3] < 16) {
      transparent++;
    } else if (data[i] > 235 && data[i + 1] > 235 && data[i + 2] > 235) {
      white++;
    }
  }
  return {
    width: info.width,
    height: info.height,
    at,
    transparent: Math.round((transparent / pixels) * 1000) / 10,
    white: Math.round((white / pixels) * 1000) / 10,
  };
}

/** An edge pixel is the ground when it is opaque and within a hair of the accent. */
function isGround(pixel) {
  return (
    pixel.a === 255 &&
    Math.abs(pixel.r - ACCENT.r) <= 12 &&
    Math.abs(pixel.g - ACCENT.g) <= 12 &&
    Math.abs(pixel.b - ACCENT.b) <= 12
  );
}

const rgba = (p) => `rgba(${p.r},${p.g},${p.b},${p.a})`;

async function main() {
  const failures = [];
  const written = [];

  for (const [master, file, size] of RASTERS) {
    const buffer = await render(master, size);
    const report = await measure(buffer);
    const { width, height } = report;

    // Corners and edge midpoints: the two failures this family shipped were a
    // band along two edges and a white frame, neither of which a "mostly red"
    // percentage would have caught.
    const edges = [
      ['top left', 0, 0],
      ['top edge', width >> 1, 0],
      ['top right', width - 1, 0],
      ['left edge', 0, height >> 1],
      ['right edge', width - 1, height >> 1],
      ['bottom left', 0, height - 1],
      ['bottom edge', width >> 1, height - 1],
      ['bottom right', width - 1, height - 1],
    ];
    for (const [where, x, y] of edges) {
      const pixel = report.at(x, y);
      if (!isGround(pixel)) {
        failures.push(`${file}: ${where} is ${rgba(pixel)}, not the accent edge to edge`);
      }
    }
    if (report.transparent > 0.5) {
      failures.push(
        `${file}: ${report.transparent}% is transparent, so a launcher composites its own background behind it`,
      );
    }
    if (report.white > 25) {
      failures.push(`${file}: ${report.white}% is white, which is a frame nobody asked for`);
    }

    await fs.promises.writeFile(path.join(outDir, file), buffer);
    written.push(file);
    console.log(
      `  ${file.padEnd(28)} ${`${width}x${height}`.padEnd(10)} transparent ${String(report.transparent).padStart(5)}%  white ${String(report.white).padStart(5)}%`,
    );
  }

  const frames = [];
  for (const size of FAVICON_FRAMES) {
    frames.push(await render('favicon.svg', size));
  }
  await fs.promises.writeFile(path.join(outDir, 'favicon.ico'), encodeIco(frames));
  written.push('favicon.ico');
  console.log(
    `  ${'favicon.ico'.padEnd(28)} frames ${FAVICON_FRAMES.join(', ')}px, each rendered from favicon.svg`,
  );

  if (failures.length > 0) {
    throw new Error(
      `${failures.length} icon(s) are wrong, they were written so the numbers can be read but must not be committed:\n  ${failures.join('\n  ')}`,
    );
  }
  console.log(`\n${written.length} icons written and measured.`);
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});
NODE

node render.js "${raw_dir}" "${out_dir}"

# The tab tile is served as committed: one master, one copy, byte for byte.
cp "${raw_dir}/favicon.svg" "${out_dir}/favicon.svg"
echo "  favicon.svg                  copied from raw/favicon.svg"
