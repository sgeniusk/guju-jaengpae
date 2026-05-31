# 전투 유닛의 데이터 기반 표적 규칙을 결정적으로 선택한다.
class_name TargetRules
extends RefCounted

static func pick(rule: String, actor: BattleUnit, foes: Array) -> BattleUnit:
	var alive := _alive_foes(foes)
	if actor == null or alive.is_empty():
		return null
	match rule:
		"backline":
			return _pick_by_score(actor, alive, func(foe: BattleUnit) -> float: return actor.distance_to(foe), true)
		"strongest_ranged":
			var ranged := alive.filter(func(foe: BattleUnit) -> bool: return foe.attack_range == "ranged")
			if ranged.is_empty():
				return _nearest(actor, alive)
			return _pick_by_score(actor, ranged, func(foe: BattleUnit) -> float: return float(foe.attack), true)
		"lowest_hp":
			return _pick_by_score(actor, alive, func(foe: BattleUnit) -> float: return float(foe.hp), false)
		"highest_hp":
			return _pick_by_score(actor, alive, func(foe: BattleUnit) -> float: return float(foe.max_hp), true)
		_:
			return _nearest(actor, alive)

static func _alive_foes(foes: Array) -> Array[BattleUnit]:
	var alive: Array[BattleUnit] = []
	for foe in foes:
		if foe != null and foe is BattleUnit and foe.is_alive():
			alive.append(foe)
	return alive

static func _nearest(actor: BattleUnit, foes: Array[BattleUnit]) -> BattleUnit:
	return _pick_by_score(actor, foes, func(foe: BattleUnit) -> float: return actor.distance_to(foe), false)

static func _pick_by_score(actor: BattleUnit, foes: Array[BattleUnit], score_fn: Callable, prefer_high: bool) -> BattleUnit:
	var best: BattleUnit = null
	var best_score := -INF if prefer_high else INF
	var best_distance := INF
	for foe in foes:
		var score := float(score_fn.call(foe))
		var distance := actor.distance_to(foe)
		var better_score := score > best_score if prefer_high else score < best_score
		if best == null or better_score or (is_equal_approx(score, best_score) and distance < best_distance):
			best = foe
			best_score = score
			best_distance = distance
	return best
