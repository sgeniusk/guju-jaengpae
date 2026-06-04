# 계략 effect_id를 결정적인 전투 입력/런 변경으로 해석하는 순수 레지스트리.
class_name SchemeCatalog
extends RefCounted

const EFFECT_DAMAGE_ENEMY := &"scheme_damage_enemy"
const EFFECT_GAIN_GOLD := &"scheme_gain_gold"
const EFFECT_FORTIFY_CASTLE := &"scheme_fortify_castle"

const EFFECTS := {
	EFFECT_DAMAGE_ENEMY: {
		"name": "기습",
		"target_policy": "enemy",
		"battle_key": "damage_enemy",
	},
	EFFECT_GAIN_GOLD: {
		"name": "징발",
		"target_policy": "none",
		"run_key": "gold_delta",
	},
	EFFECT_FORTIFY_CASTLE: {
		"name": "수축",
		"target_policy": "none",
		"battle_key": "castle_hp_delta",
	},
}

static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in EFFECTS.keys():
		ids.append(StringName(id))
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b)
	)
	return ids

static func has_effect(effect_id: StringName) -> bool:
	return EFFECTS.has(effect_id)

static func info(effect_id: StringName) -> Dictionary:
	if not EFFECTS.has(effect_id):
		return {}
	return (EFFECTS[effect_id] as Dictionary).duplicate(true)

static func resolve(card: SchemeCardData, context: Dictionary = {}) -> Dictionary:
	if card == null:
		return _failure(&"", "missing_card")
	var effect_id := card.effect_id
	if not EFFECTS.has(effect_id):
		return _failure(effect_id, "unknown_effect")
	var result := {
		"ok": true,
		"effect_id": effect_id,
		"context": context.duplicate(true),
		"battle": {},
		"run": {},
	}
	match effect_id:
		EFFECT_DAMAGE_ENEMY:
			result["battle"] = {
				"damage_enemy": {
					"target_policy": _target_policy_for(card),
					"amount": maxi(0, card.value),
				},
			}
		EFFECT_GAIN_GOLD:
			result["run"] = {
				"gold_delta": maxi(0, card.value),
			}
		EFFECT_FORTIFY_CASTLE:
			result["battle"] = {
				"castle_hp_delta": maxi(0, card.value),
			}
	return result

static func _target_policy_for(card: SchemeCardData) -> String:
	if card.target_policy == "" or card.target_policy == "none":
		return String(EFFECTS[card.effect_id].get("target_policy", "none"))
	return card.target_policy

static func _failure(effect_id: StringName, reason: String) -> Dictionary:
	return {
		"ok": false,
		"effect_id": effect_id,
		"reason": reason,
		"battle": {},
		"run": {},
	}
