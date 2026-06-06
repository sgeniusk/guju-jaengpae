#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
SHOT_DIR="${SHOT_DIR:-$ROOT_DIR/docs/reports/phase6-ui-screens}"
LORDS="${LORDS:-lord_liubei lord_caocao lord_sunquan}"
FLOW_STAGES="${FLOW_STAGES:-1 3 4 5}"
BATTLE_STAGE="${BATTLE_STAGE:-5}"
SHOP_STAGE="${SHOP_STAGE:-4}"
RESULT_LORD="${RESULT_LORD:-lord_liubei}"
RESULT_LOSS_STAGE="${RESULT_LOSS_STAGE:-3}"
RESULT_WIN_STAGE="${RESULT_WIN_STAGE:-15}"
FIRST_BOARD_LORD="${FIRST_BOARD_LORD:-lord_liubei}"
FIRST_BOARD_STAGE="${FIRST_BOARD_STAGE:-1}"
SHOOT_FIGHT_FRAMES="${SHOOT_FIGHT_FRAMES:-560}"

mkdir -p "$SHOT_DIR"

SCENE="res://scenes/screens/lord_select.tscn" \
	SHOT_KIND="lord_select" \
	SHOT_DIR="$SHOT_DIR" \
	"$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_scene.tscn

LORD="$FIRST_BOARD_LORD" \
	SHOOT_STAGE="$FIRST_BOARD_STAGE" \
	SHOT_DIR="$SHOT_DIR" \
	"$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_first_board_states.tscn

for lord in $LORDS; do
	for stage in $FLOW_STAGES; do
		LORD="$lord" \
			RUN_STAGE="$stage" \
			SHOT_DIR="$SHOT_DIR" \
			"$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_run_map.tscn
	done

	LORD="$lord" \
		SHOOT_STAGE="$BATTLE_STAGE" \
		SHOOT_FIGHT_FRAMES="$SHOOT_FIGHT_FRAMES" \
		SHOT_DIR="$SHOT_DIR" \
		"$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_battle.tscn

	LORD="$lord" \
		SHOP_STAGE="$SHOP_STAGE" \
		SHOT_DIR="$SHOT_DIR" \
		"$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_shop.tscn
done

LORD="$RESULT_LORD" \
	SHOOT_STAGE="$RESULT_LOSS_STAGE" \
	SHOOT_FORCE_RESULT="loss" \
	SHOT_DIR="$SHOT_DIR" \
	"$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_battle.tscn

LORD="$RESULT_LORD" \
	SHOOT_STAGE="$RESULT_WIN_STAGE" \
	SHOOT_FORCE_RESULT="win" \
	SHOT_DIR="$SHOT_DIR" \
	"$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_battle.tscn

"$PYTHON_BIN" "$ROOT_DIR/tools/validate_screenshot_bundle.py" "$SHOT_DIR" \
	--lords $LORDS \
	--flow-stages $FLOW_STAGES \
	--battle-stage "$BATTLE_STAGE" \
	--shop-stage "$SHOP_STAGE" \
	--result-lord "$RESULT_LORD" \
	--result-loss-stage "$RESULT_LOSS_STAGE" \
	--result-win-stage "$RESULT_WIN_STAGE" \
	--first-board-lord "$FIRST_BOARD_LORD" \
	--first-board-stage "$FIRST_BOARD_STAGE"

printf 'UI screenshot bundle: %s\n' "$SHOT_DIR"
