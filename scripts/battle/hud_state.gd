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

static func combat_summary(phase_key: String, stage: int, wave_index: int, wave_total: int, ally_visible: int, enemy_visible: int, speed: float, paused: bool, auto_enabled: bool) -> Dictionary:
	var parts := PackedStringArray()
	parts.append("전황 — %s" % _phase_label(phase_key))
	parts.append("%d스테이지" % maxi(1, stage))
	var wave := _wave_label(wave_index, wave_total)
	if not wave.is_empty():
		parts.append(wave)
	parts.append("아군 %d" % maxi(0, ally_visible))
	parts.append("적 %d" % maxi(0, enemy_visible))
	parts.append(_speed_label(speed, paused))
	if auto_enabled:
		parts.append("auto")
	var text := _join(parts, " · ")
	var tooltip := PackedStringArray([
		text,
		"아군/적 숫자는 현재 화면에 살아 있는 병력 수 기준입니다.",
		"파도는 이번 교전 묶음의 진행도입니다." if wave_total > 0 else "배치 단계에서는 파도 정보가 열리지 않습니다.",
	])
	return {
		"text": text,
		"tooltip": _join(tooltip, "\n"),
		"phase": phase_key,
		"stage": maxi(1, stage),
		"wave": wave,
		"ally_visible": maxi(0, ally_visible),
		"enemy_visible": maxi(0, enemy_visible),
		"speed": _speed_label(speed, paused),
		"auto": auto_enabled,
	}

static func _phase_label(phase_key: String) -> String:
	match phase_key:
		"battle":
			return "교전"
		"done":
			return "결과"
		_:
			return "배치 준비"

static func _wave_label(wave_index: int, wave_total: int) -> String:
	if wave_total <= 0:
		return ""
	return "파도 %d/%d" % [clampi(wave_index, 1, wave_total), wave_total]

static func _speed_label(speed: float, paused: bool) -> String:
	if paused:
		return "정지"
	return "×%d" % int(round(clampf(speed, 1.0, 3.0)))

static func _join(parts: PackedStringArray, separator: String) -> String:
	var out := ""
	for idx in parts.size():
		if idx > 0:
			out += separator
		out += parts[idx]
	return out
