# 전투 체감 계약을 계산하는 순수 helper.
class_name BattleFeel
extends RefCounted

const PLAYER_RALLY := "전군 돌격!"
const BOSS_RALLY := "결전 개시!"

static func visible_count_for_unit(unit: BattleUnit) -> int:
	if unit == null or not unit.is_alive() or unit.is_castle:
		return 0
	if WaveFactory.is_boss_name(unit.display_name):
		return 1
	if unit.retinue_count > 0:
		return 1 + mini(maxi(0, unit.retinue_count), 8)
	if unit.squad_count > 0:
		return mini(maxi(1, unit.squad_count), 14)
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
