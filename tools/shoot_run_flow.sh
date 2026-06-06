#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
SHOT_DIR="${SHOT_DIR:-/tmp/guju-run-flow-qa}"
LORDS="${LORDS:-lord_liubei lord_caocao lord_sunquan}"
FLOW_STAGES="${FLOW_STAGES:-1 3 4 5}"

mkdir -p "$SHOT_DIR"

for lord in $LORDS; do
	for stage in $FLOW_STAGES; do
		LORD="$lord" RUN_STAGE="$stage" SHOT_DIR="$SHOT_DIR" "$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_run_map.tscn
	done
done

printf 'Run flow UI screenshots: %s\n' "$SHOT_DIR"
