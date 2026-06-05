# feat-041 — Battle Feel Pass

## Goal
Make the MVP loop read as two armies clashing from the first combat.

## Player Promise
- First combat shows an enemy front, not a single defense target.
- Starting combat gives an immediate rally cue.
- Both armies feel grouped into squads while BattleSim remains deterministic.
- Early combat still resolves quickly.

## Contract
- Stage 1 normal encounter spawns at least three enemy squads across multiple lanes.
- Early enemy squads are individually weaker so the first fight remains winnable and fast.
- Headless metrics report player, enemy, and total visible soldiers.
- Battle start VFX is view-only and does not mutate BattleSim state.

## Non-Goals
- No new card schema fields.
- No playable heaven or demon faction expansion.
- No per-soldier simulation rewrite.
- No final numeric balance lock.

## Evidence
- `./init.sh` green.
- Unit tests cover first encounter density and visible force metrics.
- `tools/playtest_loop_smoke.gd` prints first-five-stage metrics.
