#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
SHOT_DIR="${SHOT_DIR:-/tmp/guju-visual-qa}"
SHOOT_STAGE="${SHOOT_STAGE:-5}"
SHOP_STAGE="${SHOP_STAGE:-4}"
LORDS="${LORDS:-lord_liubei lord_caocao lord_sunquan}"

mkdir -p "$SHOT_DIR"

SCENE="res://scenes/screens/lord_select.tscn" SHOT_KIND="lord_select" SHOT_DIR="$SHOT_DIR" "$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_scene.tscn

for lord in $LORDS; do
	LORD="$lord" SHOOT_STAGE="$SHOOT_STAGE" SHOT_DIR="$SHOT_DIR" "$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_battle.tscn
	LORD="$lord" SHOP_STAGE="$SHOP_STAGE" SHOT_DIR="$SHOT_DIR" "$GODOT_BIN" --path "$ROOT_DIR" --scene res://tools/shoot_shop.tscn
done

printf 'Visual QA screenshots: %s\n' "$SHOT_DIR"
