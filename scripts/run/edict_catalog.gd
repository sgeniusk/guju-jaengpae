# 왕의 칙령 id와 누적 전역 보정치를 제공하는 코드 레지스트리.
class_name EdictCatalog
extends RefCounted

const MIGHT := &"edict_might"
const ECONOMY := &"edict_economy"
const FORTIFY := &"edict_fortify"

const EDICTS := {
	MIGHT: {"name": "군세(軍勢)", "desc": "전 아군 공격력 +10%", "attack_pct": 0.10},
	ECONOMY: {"name": "재정(財政)", "desc": "골드 획득 +20%", "gold_pct": 0.20},
	FORTIFY: {"name": "축성(築城)", "desc": "성 HP +15%", "castle_hp_pct": 0.15},
}

static func attack_pct(edicts: Array) -> float:
	return _sum_pct(edicts, "attack_pct")

static func gold_pct(edicts: Array) -> float:
	return _sum_pct(edicts, "gold_pct")

static func castle_hp_pct(edicts: Array) -> float:
	return _sum_pct(edicts, "castle_hp_pct")

static func all_ids() -> Array[StringName]:
	return [MIGHT, ECONOMY, FORTIFY]

static func info(id) -> Dictionary:
	return EDICTS.get(StringName(id), {}).duplicate()

static func _sum_pct(edicts: Array, key: String) -> float:
	var total := 0.0
	for id in edicts:
		var data: Dictionary = EDICTS.get(StringName(id), {})
		total += float(data.get(key, 0.0))
	return total
