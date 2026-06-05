# 보드의 상대 배치를 전투 시작 전술 보너스로 바꾸는 순수 helper.
class_name FormationTactics
extends RefCounted

const META_BASE_ATTACK := &"formation_base_attack"
const META_BONUS_PCT := &"formation_bonus_pct"
const META_TAGS := &"formation_tags"

const COMMAND_ATTACK_PCT := 0.10
const SCREEN_ATTACK_PCT := 0.15
const FLANK_ATTACK_PCT := 0.10

const TAG_COMMAND := "지휘"
const TAG_SCREEN := "엄호"
const TAG_FLANK := "측면"

static func apply_to_army(army: Array) -> void:
	for unit in army:
		if _is_candidate(unit):
			_ensure_base_attack(unit)
	for unit in army:
		if not _is_candidate(unit):
			continue
		var base_attack := int(unit.get_meta(META_BASE_ATTACK, unit.attack))
		var summary := summary_for_unit(unit, army)
		var attack_pct := float(summary.get("attack_pct", 0.0))
		unit.attack = maxi(0, int(round(float(base_attack) * (1.0 + attack_pct))))
		unit.set_meta(META_BONUS_PCT, attack_pct)
		unit.set_meta(META_TAGS, summary.get("tags", []))

static func summary_for_unit(unit: BattleUnit, army: Array) -> Dictionary:
	var tags: Array[String] = []
	var attack_pct := 0.0
	if not _is_candidate(unit):
		return {
			"attack_pct": 0.0,
			"attack_mult": 1.0,
			"tags": tags,
		}
	if _is_troop(unit) and _has_adjacent_general(unit, army):
		attack_pct += COMMAND_ATTACK_PCT
		tags.append(TAG_COMMAND)
	if unit.attack_range == "ranged" and _has_front_melee_screen(unit, army):
		attack_pct += SCREEN_ATTACK_PCT
		tags.append(TAG_SCREEN)
	if unit.troop_type == "cavalry" and _is_flank_lane(unit.lane):
		attack_pct += FLANK_ATTACK_PCT
		tags.append(TAG_FLANK)
	return {
		"attack_pct": attack_pct,
		"attack_mult": 1.0 + attack_pct,
		"tags": tags,
	}

static func tags_for_unit(unit: BattleUnit, army: Array = []) -> Array[String]:
	if unit == null:
		return []
	if unit.has_meta(META_TAGS):
		return _string_tags(unit.get_meta(META_TAGS))
	if army.is_empty():
		return []
	return _string_tags(summary_for_unit(unit, army).get("tags", []))

static func tag_text_for_unit(unit: BattleUnit, army: Array = []) -> String:
	return join_tags(tags_for_unit(unit, army))

static func preview_for_unit(unit: BattleUnit, army: Array, card_name: String = "") -> Dictionary:
	if not _is_candidate(unit):
		return {}
	var summary := summary_for_unit(unit, army)
	var tags := _string_tags(summary.get("tags", []))
	var attack_pct := float(summary.get("attack_pct", 0.0))
	if tags.is_empty() or attack_pct <= 0.0:
		return {}
	var label := preview_label(tags, attack_pct)
	var name := card_name if not card_name.is_empty() else unit.display_name
	return {
		"tags": tags,
		"attack_pct": attack_pct,
		"label": label,
		"tooltip": "%s 배치 — %s로 공격 +%d%%" % [name, join_tags(tags), int(round(attack_pct * 100.0))],
	}

static func preview_label(tags: Array[String], attack_pct: float) -> String:
	if tags.is_empty() or attack_pct <= 0.0:
		return ""
	return "%s +%d%%" % [join_tags(tags), int(round(attack_pct * 100.0))]

static func join_tags(tags: Array[String]) -> String:
	var out := ""
	for tag in tags:
		if not out.is_empty():
			out += "/"
		out += tag
	return out

static func _ensure_base_attack(unit: BattleUnit) -> void:
	if unit == null or unit.has_meta(META_BASE_ATTACK):
		return
	unit.set_meta(META_BASE_ATTACK, unit.attack)

static func _is_candidate(value) -> bool:
	if value == null or not (value is BattleUnit):
		return false
	var unit: BattleUnit = value
	return unit.team == BattleUnit.Team.PLAYER and not unit.is_castle and unit.row >= 0

static func _has_adjacent_general(unit: BattleUnit, army: Array) -> bool:
	if unit == null or unit.row < 0:
		return false
	for value in army:
		if not _is_candidate(value):
			continue
		var ally: BattleUnit = value
		if ally == unit or not _is_general(ally):
			continue
		if absi(ally.lane - unit.lane) + absi(ally.row - unit.row) == 1:
			return true
	return false

static func _has_front_melee_screen(unit: BattleUnit, army: Array) -> bool:
	if unit == null:
		return false
	for value in army:
		if not _is_candidate(value):
			continue
		var ally: BattleUnit = value
		if ally == unit or ally.lane != unit.lane:
			continue
		if ally.attack_range == "ranged":
			continue
		if ally.px > unit.px + 0.001:
			return true
	return false

static func _is_general(unit: BattleUnit) -> bool:
	return unit != null and (unit.controllable or String(unit.card_id).begins_with("general_"))

static func _is_troop(unit: BattleUnit) -> bool:
	return unit != null and String(unit.card_id).begins_with("troop_")

static func _is_flank_lane(lane: int) -> bool:
	return lane == 0 or lane == BattleSim.COL_COUNT - 1

static func _string_tags(value) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(String(item))
	return out
