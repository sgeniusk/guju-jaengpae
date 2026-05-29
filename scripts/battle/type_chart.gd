# 병종 상성표를 순수 배수로 제공한다.
class_name TypeChart
extends RefCounted

const STRONG := 1.5
const WEAK := 0.75
const NEUTRAL := 1.0

const _MULTIPLIERS := {
	"infantry": {
		"cavalry": STRONG,
		"archer": WEAK,
		"crossbow": WEAK,
	},
	"cavalry": {
		"archer": STRONG,
		"crossbow": STRONG,
		"infantry": WEAK,
	},
	"archer": {
		"infantry": STRONG,
		"cavalry": WEAK,
	},
	"crossbow": {
		"infantry": STRONG,
		"cavalry": WEAK,
	},
}

static func multiplier(attacker_type: String, defender_type: String) -> float:
	if not _MULTIPLIERS.has(attacker_type):
		return NEUTRAL
	return float(_MULTIPLIERS[attacker_type].get(defender_type, NEUTRAL))
