# feat-040 — Fun Reset: Squad Card Army Loop

## Goal
Make the first five stages feel like Three Kingdoms armies clashing, not a slow defense prototype.

## Player Promise
- Pick a lord.
- Pick the castle location first.
- See exactly three card choices.
- Play one card.
- Watch a fast clash between visible squads.
- Receive one meaningful growth choice.
- Repeat with upgraded squads, terrain synergies, and clearer army identity.

## Contract
- A stage cannot begin combat before the castle is placed.
- A stage cannot play more than one hand card.
- Troop cards represent squads, starting at 8 to 10 visible soldiers.
- Duplicate troop cards upgrade the existing squad through Lv.5.
- General cards are smaller than the old hero sprites and render with retinue soldiers.
- Enemy armies spawn as grouped squads before clash, not as a defense trickle.
- A normal early encounter should resolve in 12 to 25 simulated seconds at x2 default speed.
- The UI must show whether a card places a new squad, upgrades an existing squad, casts a scheme, or places a building.

## Non-Goals
- No online features.
- No new heaven or demon nation ids before canon approval.
- No one-sim-object-per-soldier rewrite.
- No full balance lock before the new loop is playable.

## Evidence
- `./init.sh` green.
- `tools/playtest_loop_smoke.gd` prints first-five-stage metrics.
- Screenshot bundle includes deployment, clash, reward, and upgrade states.
