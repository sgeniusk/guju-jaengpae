# 전투 중 한 유닛의 런타임 상태. UnitCardData(아군) 또는 적 파도에서 생성되어 컬럼과 depth 위에서 교전한다.
class_name BattleUnit
extends RefCounted

enum Team { PLAYER, ENEMY }

var card_id: StringName = &""
var display_name: String = ""
var team: int = Team.PLAYER
var lane: int = 0             # 기존 lane 필드를 col 의미로 유지한다.
var row: int = -1             # 아군 배치 행. 0 = 전방, 2 = 후방, 적은 -1.
var x: float = 0.0            # 컬럼 내 depth. 0 = 플레이어 기지, BattleSim.LANE_LENGTH = 적 진입점
var max_hp: int = 1
var hp: int = 1
var attack: int = 0
var attack_interval: float = 1.0
var attack_range: String = "melee"
var troop_type: String = "infantry"
var move_speed: float = 40.0
var cooldown: float = 0.0     # 다음 공격까지 남은 시간(초)
var skill_id: StringName = &""
var skill_cooldown: float = 0.0
var statuses: Array = []

static func make(p_team: int, p_lane: int, p_x: float, p_name: String, p_hp: int, p_atk: int, p_interval: float, p_range: String, p_speed: float, p_card_id: StringName = &"", p_skill_id: StringName = &"", p_troop_type: String = "infantry", p_row: int = -1) -> BattleUnit:
	var u := BattleUnit.new()
	u.team = p_team
	u.lane = p_lane
	u.row = p_row
	u.x = p_x
	u.display_name = p_name
	u.max_hp = maxi(1, p_hp)
	u.hp = u.max_hp
	u.attack = maxi(0, p_atk)
	u.attack_interval = maxf(0.05, p_interval)
	u.attack_range = p_range
	u.troop_type = p_troop_type
	u.move_speed = maxf(0.0, p_speed)
	u.card_id = p_card_id
	u.skill_id = p_skill_id
	return u

static func from_card(card: UnitCardData, p_team: int, p_lane: int, p_x: float, hp_mult: float = 1.0, p_row: int = -1) -> BattleUnit:
	return make(p_team, p_lane, p_x, card.display_name, int(round(card.max_hp * hp_mult)), card.attack, card.attack_interval, card.attack_range, card.move_speed, card.id, card.skill_id, card.troop_type, p_row)

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)

func hp_ratio() -> float:
	return float(hp) / float(max_hp) if max_hp > 0 else 0.0

func add_status(type: String, duration: float, magnitude: float, source: BattleUnit = null) -> void:
	if type.is_empty() or duration <= 0.0:
		return
	for i in statuses.size():
		var status: Dictionary = statuses[i]
		if String(status.get("type", "")) != type:
			continue
		status["remaining"] = maxf(float(status.get("remaining", 0.0)), duration)
		status["magnitude"] = magnitude
		status["source"] = source
		statuses[i] = status
		return
	statuses.append({
		"type": type,
		"remaining": duration,
		"magnitude": magnitude,
		"source": source,
	})

func tick_statuses(delta: float) -> void:
	var next_statuses: Array = []
	for status: Dictionary in statuses:
		var remaining := float(status.get("remaining", 0.0)) - delta
		if remaining <= 0.000001:
			continue
		status["remaining"] = remaining
		next_statuses.append(status)
	statuses = next_statuses

func has_status(type: String) -> bool:
	return not get_status(type).is_empty()

func get_status(type: String) -> Dictionary:
	for status: Dictionary in statuses:
		if String(status.get("type", "")) == type and float(status.get("remaining", 0.0)) > 0.0:
			return status.duplicate()
	return {}

func effective_attack() -> int:
	var weaken := get_status("weaken")
	if weaken.is_empty():
		return attack
	var weaken_mag := clampf(float(weaken.get("magnitude", 0.0)), 0.0, 0.9)
	return maxi(0, int(round(attack * (1.0 - weaken_mag))))

func taunt_source() -> BattleUnit:
	var taunt := get_status("taunt")
	if taunt.is_empty():
		return null
	return taunt.get("source", null)
