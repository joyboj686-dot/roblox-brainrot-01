// BRAINROT RUSH — a working make.fun roblox-brainrot-01 entry (Node 22, stdlib only).
// The game is this directory's Rojo project, built into game.rbxl with
// `rojo build default.project.json --output game.rbxl`. This entrypoint packages
// the place, its source, its screenshots and PLAY.json into /output and writes
// /output/dossier.json with the vendored make.fun library, which the judge reads.
//
// Output names are restricted to letters, digits, _ . - (the grader fails an entry
// with any other character in a copied filename), so src/ and screenshots/ are copied
// without any file or directory whose name starts with a dot (.gitkeep, .DS_Store, .git).
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// cpSync's filter: drop every file and directory whose name begins with a dot.
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

// The scorer's own caps (reference/gate.json). text_max_bytes shapes the dossier
// bytes; the rest refuse an entry the scorer would refuse (too many/oversized
// screenshots, or a place that is too big in instances or script source/paths).
const DOSSIER_CAPS = {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
};

function packageEntry(): void {
  copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
  copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
  cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
  mkdirSync(join(out, 'screenshots'), { recursive: true });
  if (existsSync(join(here, 'screenshots'))) {
    cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
  }
  writeFileSync(join(out, 'dossier.json'), buildDossier(out, DOSSIER_CAPS));
}

packageEntry();