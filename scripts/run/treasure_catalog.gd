# 보패 effect_id를 런 지속 보정치로 해석하는 순수 레지스트리.
class_name TreasureCatalog
extends RefCounted

const EFFECT_ATTACK_PCT := &"treasure_attack_pct"
const EFFECT_GOLD_PCT := &"treasure_gold_pct"
const EFFECT_REWARD_BONUS := &"treasure_reward_bonus"

const EFFECTS := {
	EFFECT_ATTACK_PCT: {
		"name": "병법서",
		"channel": "battle",
		"key": "attack_pct",
		"percent": true,
	},
	EFFECT_GOLD_PCT: {
		"name": "금인",
		"channel": "economy",
		"key": "gold_pct",
		"percent": true,
	},
	EFFECT_REWARD_BONUS: {
		"name": "천리안",
		"channel": "reward",
		"key": "bonus_choices",
		"percent": false,
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

static func has_effect(id: StringName) -> bool:
	return EFFECTS.has(id)

static func info(id: StringName) -> Dictionary:
	return EFFECTS.get(id, {}).duplicate(true)

static func resolve(card: TreasureCardData) -> Dictionary:
	if card == null:
		return _failure(&"", "missing_card")
	if not has_effect(card.effect_id):
		return _failure(card.effect_id, "unknown_effect")
	var effect := info(card.effect_id)
	var channel := String(effect.get("channel", ""))
	var key := String(effect.get("key", ""))
	var value: Variant = int(card.value)
	if bool(effect.get("percent", false)):
		value = float(card.value) / 100.0
	var battle := {}
	var economy := {}
	var reward := {}
	if channel == "battle":
		battle[key] = value
	elif channel == "economy":
		economy[key] = value
	elif channel == "reward":
		reward[key] = value
	return {
		"ok": true,
		"effect_id": card.effect_id,
		"name": String(effect.get("name", "")),
		"battle": battle,
		"economy": economy,
		"reward": reward,
	}

static func modifiers(treasure_ids: Array, catalog: CardCatalog) -> Dictionary:
	var out := {
		"battle": {},
		"economy": {},
		"reward": {},
	}
	if catalog == null:
		return out
	for id in treasure_ids:
		var card := catalog.get_card(StringName(id))
		if card == null or not (card is TreasureCardData):
			continue
		var result := resolve(card)
		if not bool(result.get("ok", false)):
			continue
		_sum_channel(out, "battle", result.get("battle", {}))
		_sum_channel(out, "economy", result.get("economy", {}))
		_sum_channel(out, "reward", result.get("reward", {}))
	return out

static func _sum_channel(out: Dictionary, channel: String, values: Dictionary) -> void:
	if values.is_empty():
		return
	var target: Dictionary = out.get(channel, {})
	for key in values.keys():
		var previous: Variant = target.get(key, 0)
		target[key] = previous + values[key]
	out[channel] = target

static func _failure(effect_id: StringName, reason: String) -> Dictionary:
	return {
		"ok": false,
		"effect_id": effect_id,
		"reason": reason,
		"battle": {},
		"economy": {},
		"reward": {},
	}
