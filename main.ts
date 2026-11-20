// gta6-clipper-01 entry (Node 22, standard library only): copies VIDEO.json from the repository root to
// /output/VIDEO.json, where the gate reads it. That is all the program has to do: the entry is the video
// itself — a vertical GTA 6 clip on YouTube whose views the house reads through the YouTube Data API.
// VIDEO.json names the video as {"url": "https://www.youtube.com/shorts/<id>"}.
//
// Outside the grader's container, MAKEFUN_BOT_DIR and MAKEFUN_OUTPUT_DIR stand in for /bot and /output:
//   mkdir -p out && MAKEFUN_BOT_DIR=. MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, mkdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const BOT_DIR = process.env.MAKEFUN_BOT_DIR ?? '/bot';
const OUTPUT_DIR = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

const source = join(BOT_DIR, 'VIDEO.json');

let parsed;
try {
  parsed = JSON.parse(readFileSync(source, 'utf8'));
} catch (err) {
  console.error(`VIDEO.json could not be read or parsed from ${source}: ${(err as Error).message}`);
  process.exit(1);
}
if (typeof parsed?.url !== 'string' || parsed.url.length === 0 || parsed.url.includes('<id>')) {
  console.error('VIDEO.json holds no real video url yet: expected {"url": "https://www.youtube.com/shorts/<id>"} with the placeholder replaced');
  process.exit(1);
}

mkdirSync(OUTPUT_DIR, { recursive: true });
copyFileSync(source, join(OUTPUT_DIR, 'VIDEO.json'));
