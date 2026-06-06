# 전투 체감 계약을 계산하는 순수 helper.
class_name BattleFeel
extends RefCounted

const PLAYER_RALLY := "전군 돌격!"
const BOSS_RALLY := "결전 개시!"
const TROOP_VISIBLE_CAP := 18
const RETINUE_VISIBLE_CAP := 10
const RALLY_SFX_ID := &"rally"
const ADVANCE_DUST_PER_SIDE_LANE := 3
const ADVANCE_DUST_TOTAL := BattleSim.COL_COUNT * 2 * ADVANCE_DUST_PER_SIDE_LANE
const GROUND_CLASH_TOTAL := BattleSim.COL_COUNT
const CLASH_PRESSURE_MIN := 6
const CLASH_PRESSURE_MAX := 14

static func visible_count_for_unit(unit: BattleUnit) -> int:
	if unit == null or not unit.is_alive() or unit.is_castle:
		return 0
	if WaveFactory.is_boss_name(unit.display_name):
		return 1
	if unit.retinue_count > 0:
		return 1 + mini(maxi(0, unit.retinue_count), RETINUE_VISIBLE_CAP)
	if unit.squad_count > 0:
		return mini(maxi(1, unit.squad_count), TROOP_VISIBLE_CAP)
	return 1

static func force_metrics(units: Array) -> Dictionary:
	var alive_units := 0
	var visible_soldiers := 0
	var lanes := {}
	var has_ranged := false
	for entry in units:
		var unit := entry as BattleUnit
		if unit == null or not unit.is_alive() or unit.is_castle:
			continue
		alive_units += 1
		visible_soldiers += visible_count_for_unit(unit)
		lanes[unit.lane] = true
		if unit.attack_range == "ranged":
			has_ranged = true
	return {
		"units": alive_units,
		"visible_soldiers": visible_soldiers,
		"lanes": lanes.size(),
		"has_ranged": has_ranged,
	}

static func has_army_front(units: Array, min_units: int = 3, min_lanes: int = 2, min_visible: int = 18) -> bool:
	var metrics := force_metrics(units)
	return int(metrics.get("units", 0)) >= min_units \
		and int(metrics.get("lanes", 0)) >= min_lanes \
		and int(metrics.get("visible_soldiers", 0)) >= min_visible

static func rally_text(stage: int, enemy_units: Array) -> String:
	for entry in enemy_units:
		var unit := entry as BattleUnit
		if unit != null and WaveFactory.is_boss_name(unit.display_name):
			return BOSS_RALLY
	if stage <= 1:
		return PLAYER_RALLY
	return "군세 충돌!"

static func rally_sfx_id(_stage: int, _enemy_units: Array) -> StringName:
	return RALLY_SFX_ID

static func rally_line(stage: int, player_units: Array, enemy_units: Array) -> String:
	var profile := clash_profile(player_units, enemy_units)
	return "%s  아군 %d · 적 %d" % [
		rally_text(stage, enemy_units),
		int(profile.get("player_visible", 0)),
		int(profile.get("enemy_visible", 0)),
	]

static func clash_profile(player_units: Array, enemy_units: Array) -> Dictionary:
	var player := force_metrics(player_units)
	var enemy := force_metrics(enemy_units)
	var player_visible := int(player.get("visible_soldiers", 0))
	var enemy_visible := int(enemy.get("visible_soldiers", 0))
	var total_visible := player_visible + enemy_visible
	var lane_count := maxi(int(player.get("lanes", 0)), int(enemy.get("lanes", 0)))
	var intensity := clampf(float(total_visible - 20) / 42.0, 0.45, 1.0)
	var pressure_count := clampi(CLASH_PRESSURE_MIN + int(round(float(CLASH_PRESSURE_MAX - CLASH_PRESSURE_MIN) * intensity)), CLASH_PRESSURE_MIN, CLASH_PRESSURE_MAX)
	return {
		"player_visible": player_visible,
		"enemy_visible": enemy_visible,
		"total_visible": total_visible,
		"lanes": lane_count,
		"intensity": intensity,
		"pressure_count": pressure_count,
	}

static func advance_dust_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	for lane in BattleSim.COL_COUNT:
		var y := BattleSim.start_y_for_col(lane)
		for step in ADVANCE_DUST_PER_SIDE_LANE:
			var step_f := float(step)
			var lane_offset := _lane_dust_offset(lane, step)
			markers.append({
				"side": "player",
				"lane": lane,
				"field": Vector2(322.0 + step_f * 62.0, y + lane_offset),
				"scale": 1.0 + step_f * 0.14,
			})
			markers.append({
				"side": "enemy",
				"lane": lane,
				"field": Vector2(778.0 - step_f * 62.0, y - lane_offset),
				"scale": 1.0 + step_f * 0.14,
			})
	return markers

static func ground_clash_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	for lane in BattleSim.COL_COUNT:
		markers.append({
			"lane": lane,
			"field": Vector2(555.0, BattleSim.start_y_for_col(lane)),
			"radius_x": 54.0,
			"radius_y": 8.0,
		})
	return markers

static func clash_pressure_markers(profile: Dictionary) -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	var intensity := clampf(float(profile.get("intensity", 0.45)), 0.45, 1.0)
	var count := clampi(int(profile.get("pressure_count", CLASH_PRESSURE_MIN)), CLASH_PRESSURE_MIN, CLASH_PRESSURE_MAX)
	for index in count:
		var lane := index % BattleSim.COL_COUNT
		var lane_y := BattleSim.start_y_for_col(lane)
		var rank := index / BattleSim.COL_COUNT
		var side_shift := -1.0 if index % 2 == 0 else 1.0
		markers.append({
			"lane": lane,
			"field": Vector2(555.0 + side_shift * (12.0 + float(rank) * 5.0), lane_y + _lane_dust_offset(lane, rank)),
			"radius_x": 22.0 + intensity * 22.0,
			"radius_y": 6.0 + intensity * 5.0,
			"alpha": 0.20 + intensity * 0.22,
			"intensity": intensity,
		})
	return markers

static func _lane_dust_offset(lane: int, step: int) -> float:
	var lane_bias := float(lane - 1) * 6.0
	var step_bias := -5.0 + float(step) * 5.0
	return lane_bias + step_bias
