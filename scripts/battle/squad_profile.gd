# UnitCardData + level을 전투용 분대 수치로 바꾸는 순수 helper.
class_name SquadProfile
extends RefCounted

const LEVEL_MAX := RunState.CARD_LEVEL_MAX

static func for_card(card: UnitCardData, level: int) -> Dictionary:
	if card == null:
		return {}
	var clamped := clampi(level, 1, LEVEL_MAX)
	var out := {
		"level": clamped,
		"squad_count": 1,
		"retinue_count": 0,
		"hp_mult": 1.0,
		"attack_mult": 1.0,
		"interval_mult": 1.0,
		"speed_mult": 1.0,
		"body_scale": 1.0,
		"label": "Lv.%d" % clamped,
	}
	if card.card_type == "troop":
		var base_count := base_squad_count(card.troop_type)
		var squad_count := base_count + (clamped - 1) * 4
		out["squad_count"] = squad_count
		out["hp_mult"] = float(squad_count) / float(base_count)
		out["attack_mult"] = 1.0 + float(clamped - 1) * 0.28
		out["interval_mult"] = maxf(0.55 / maxf(0.05, card.attack_interval), 1.0 - float(clamped - 1) * 0.04)
		out["speed_mult"] = 1.12
		out["body_scale"] = 0.74
		out["label"] = "Lv.%d 분대 %d" % [clamped, squad_count]
	elif card.card_type == "general":
		out["retinue_count"] = 5 + (clamped - 1) * 2
		out["hp_mult"] = 1.0 + float(clamped - 1) * 0.16
		out["attack_mult"] = 1.0 + float(clamped - 1) * 0.20
		out["speed_mult"] = 1.10
		out["body_scale"] = 0.68
		out["label"] = "Lv.%d 호위 %d" % [clamped, int(out["retinue_count"])]
	return out

static func apply_to_unit(unit: BattleUnit, card: UnitCardData, level: int) -> void:
	if unit == null or card == null:
		return
	var profile := for_card(card, level)
	if profile.is_empty():
		return
	unit.squad_level = int(profile.get("level", 1))
	unit.squad_count = int(profile.get("squad_count", 1))
	unit.retinue_count = int(profile.get("retinue_count", 0))
	unit.max_hp = maxi(1, int(round(float(unit.max_hp) * float(profile.get("hp_mult", 1.0)))))
	unit.hp = unit.max_hp
	unit.attack = maxi(0, int(round(float(unit.attack) * float(profile.get("attack_mult", 1.0)))))
	unit.move_speed = maxf(0.0, unit.move_speed * float(profile.get("speed_mult", 1.0)))
	unit.attack_interval = maxf(0.55, unit.attack_interval * float(profile.get("interval_mult", 1.0)))

static func base_squad_count(troop_type: String) -> int:
	match troop_type:
		"cavalry":
			return 8
		"navy":
			return 9
		"fantasy":
			return 6
		_:
			return 10
