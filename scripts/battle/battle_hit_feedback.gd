# 데미지 이벤트를 전투 타격 VFX 프로필로 바꾸는 순수 helper.
class_name BattleHitFeedback
extends RefCounted

const KIND_SPARK := "spark"
const KIND_CRIT := "crit"
const KIND_BURST := "burst"
const KIND_GROUND_DUST := "ground_dust"
const KIND_GROUND_RING := "ground_ring"

static func profiles_for_event(event: Dictionary) -> Array[Dictionary]:
	var amount := int(event.get("amount", 0))
	if amount <= 0:
		return []
	var kind := String(event.get("kind", "attack"))
	var is_crit := bool(event.get("is_crit", false))
	var out: Array[Dictionary] = []
	out.append(_spark_profile(kind, is_crit))
	if is_crit:
		out.append({
			"kind": KIND_CRIT,
			"color": Color(1.0, 0.18, 0.10, 0.58),
			"radius_x": 34.0,
			"radius_y": 14.0,
			"duration": 0.34,
			"scale": 1.75,
		})
	if kind == "skill" or kind == "scheme":
		out.append({
			"kind": KIND_BURST,
			"color": Color(0.72, 0.46, 1.0, 0.50) if kind == "skill" else Color(0.34, 0.88, 1.0, 0.46),
			"radius_x": 42.0,
			"radius_y": 18.0,
			"duration": 0.42,
			"scale": 1.90,
		})
	return out

static func ground_profiles_for_event(event: Dictionary) -> Array[Dictionary]:
	var amount := int(event.get("amount", 0))
	if amount <= 0:
		return []
	var kind := String(event.get("kind", "attack"))
	var is_crit := bool(event.get("is_crit", false))
	var attack_range := String(event.get("attack_range", "melee"))
	var strong := is_crit or kind == "skill" or kind == "scheme" or amount >= 40
	if kind == "attack" and attack_range == "ranged" and not strong:
		return []
	var out: Array[Dictionary] = []
	out.append({
		"kind": KIND_GROUND_DUST,
		"color": Color(0.70, 0.55, 0.35, 0.28) if kind == "attack" else Color(0.78, 0.58, 0.38, 0.34),
		"radius_x": 30.0 if not strong else 40.0,
		"radius_y": 7.0 if not strong else 9.0,
		"duration": 0.34 if not strong else 0.42,
		"scale": 1.45 if not strong else 1.72,
		"y_offset": 4.0,
	})
	if strong:
		out.append({
			"kind": KIND_GROUND_RING,
			"color": Color(1.0, 0.72, 0.28, 0.32) if kind == "attack" else Color(0.74, 0.48, 1.0, 0.30),
			"radius_x": 46.0 if not is_crit else 56.0,
			"radius_y": 11.0 if not is_crit else 13.0,
			"duration": 0.44 if not is_crit else 0.50,
			"scale": 1.82 if not is_crit else 2.05,
			"y_offset": 2.0,
		})
	return out

static func camera_shake_strength_for_event(event: Dictionary) -> float:
	var amount := int(event.get("amount", 0))
	if amount <= 0:
		return 0.0
	var kind := String(event.get("kind", "attack"))
	if kind == "skill" or kind == "scheme":
		return 0.72
	if bool(event.get("is_crit", false)):
		return 0.58
	if amount >= 45:
		return 0.46
	return 0.0

static func _spark_profile(kind: String, is_crit: bool) -> Dictionary:
	var color := Color(1.0, 0.82, 0.28, 0.86)
	if kind == "skill":
		color = Color(0.86, 0.58, 1.0, 0.88)
	elif kind == "scheme":
		color = Color(0.48, 0.94, 1.0, 0.84)
	elif is_crit:
		color = Color(1.0, 0.36, 0.12, 0.92)
	return {
		"kind": KIND_SPARK,
		"color": color,
		"radius_x": 18.0 if not is_crit else 24.0,
		"radius_y": 7.0 if not is_crit else 9.0,
		"duration": 0.24 if not is_crit else 0.30,
		"scale": 1.45 if not is_crit else 1.65,
	}
