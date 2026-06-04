# 전투 HUD가 표시할 순수 상태값을 계산한다.
class_name BattleHudState
extends RefCounted

const START_YEAR := 32
const LOOKAHEAD_COUNT := 7

static func stage_year(stage: int) -> int:
	return START_YEAR + maxi(0, stage)

static func stage_nodes(current_stage: int, count: int = LOOKAHEAD_COUNT) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var safe_current := maxi(1, current_stage)
	for offset in maxi(0, count):
		var stage := safe_current + offset
		var kind := StageCadence.node_kind(stage)
		out.append({
			"stage": stage,
			"kind": kind,
			"icon": node_icon(kind),
			"label": "%d년" % stage_year(stage),
			"is_current": offset == 0,
		})
	return out

static func node_icon(kind: String) -> String:
	match kind:
		"boss":
			return "♛"
		"shop":
			return "상"
		"edict":
			return "령"
		"expand":
			return "+"
		"elite":
			return "정"
		"event":
			return "?"
		_:
			return "전"

static func speed_delta(delta: float, speed: float, paused: bool, in_battle: bool) -> float:
	if paused or not in_battle:
		return 0.0
	return maxf(0.0, delta) * maxf(0.0, speed)

static func castle_ratio(castle: BattleUnit) -> float:
	if castle == null:
		return 0.0
	return clampf(castle.hp_ratio(), 0.0, 1.0)

static func champion_state(enemy_units: Array) -> Dictionary:
	var champion: BattleUnit = null
	for unit in enemy_units:
		var enemy := unit as BattleUnit
		if enemy != null and enemy.is_alive() and WaveFactory.is_boss_name(enemy.display_name):
			champion = enemy
			break
	if champion == null:
		for unit in enemy_units:
			var enemy := unit as BattleUnit
			if enemy == null or not enemy.is_alive():
				continue
			if champion == null or enemy.max_hp > champion.max_hp:
				champion = enemy
	if champion == null:
		return {
			"active": false,
			"label": "챔피언",
			"ratio": 0.0,
		}
	return {
		"active": true,
		"label": champion.display_name,
		"ratio": clampf(champion.hp_ratio(), 0.0, 1.0),
	}

static func enemy_force_ratio(enemy_count: int, seen_max: int, wave_index: int, wave_total: int) -> float:
	if seen_max > 0:
		return clampf(float(maxi(0, enemy_count)) / float(seen_max), 0.0, 1.0)
	if wave_total > 0:
		return clampf(float(maxi(0, wave_total - wave_index + 1)) / float(wave_total), 0.0, 1.0)
	return 0.0
