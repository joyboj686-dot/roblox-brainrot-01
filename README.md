# Brainrot Rush — make.fun roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/joyboj686-dot/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/joyboj686-dot/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

A bright, colourful 3D Roblox **brainrot collection game** built for the
[make.fun roblox-brainrot-01 bounty](https://make.fun/c/roblox-brainrot-01)
($1,000, top 50 paid) — original characters and world, no copies.

## The game

**BRAINROT RUSH** is a Steal-a-Brainrot collect-em-up in a sunny plaza.

- A central **Brainrot Belt** loops meme characters past your base. Click one
  you can afford and it waddles off to stand on a free pad.
- **12 original absurd characters** across 6 rarities (Sir Barksalot, Captain
  Croissant, DJ Pickle, Professor Noodle, Turbo Toilet, Banana Knight, Grandma
  Glizzy, Lord Llama Latte, Agent Avocado, King Ketchup, Quantum Quokka, Baron
  von Burrito), each with a cost and a $/s earning rate shown on a floating
  label.
- **Mutations** — GOLDEN (x2), RAINBOW (x5), VOID (x10) — roll when a brainrot
  spawns and multiply its earnings.
- **THE BRAINROT WAVE** sweeps the map every 90s; get inside your base safe
  zone or lose 25% of your coins.
- **Stealing** — grab a rival's brainrot and carry it home, but a base LOCK
  blocks you (30s, 60s cooldown) and stolen brainrots can be re-stolen.
- **Rebirth** past $1,000,000 lifetime earnings for a permanent x2 multiplier.
- **Economy** — start with $100, sell brainrots back for 50%, escalating belt
  speed and rarer spawns over time.

## How it's built

- **Luau + Rojo**. `src/shared/Config.luau` is the single source of truth for
  the roster, economy and plaza layout. Server modules each do one job
  (`WorldBuilder`, `BrainrotService`, `EconomyService`, `WaveService`,
  `StealService`, `init.server`); the client is `src/client/Game.client.luau`.
- Build the place: `rojo build default.project.json --output game.rbxl`
- Emit the entry: `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts`

## Studio steps still needed (owner)

The screenshots in `screenshots/` are data-driven renders of the game's own
layout data, made because no Roblox Studio runs on this Linux build VM. Before
submitting, the account owner must:

1. Open `game.rbxl` in Roblox Studio and play-test it.
2. Publish the experience **Public** and put the real place/universe ids into
   `PLAY.json` (it currently holds the starter's zeros).
3. Replace the three screenshots with real Studio captures and upload the icon
   + thumbnail on the Creator Dashboard.

See `NOTES.md` for the coordinator's notes.