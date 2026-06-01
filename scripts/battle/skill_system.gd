# 장수 skill_id를 결정적 전투 효과로 해석하는 순수 스킬 레지스트리.
class_name SkillSystem
extends RefCounted

const QINGLONG_STRIKE := &"skill_qinglong_strike"
const BAIBU_CHUANYANG := &"skill_baibu_chuanyang"
const QIMEN_BAGUA := &"skill_qimen_bagua"
const CHANGBAN_CHARGE := &"skill_changban_charge"
const CHANGBAN_ROAR := &"skill_changban_roar"

const COOLDOWNS := {
	QINGLONG_STRIKE: 5.0,
	BAIBU_CHUANYANG: 6.0,
	QIMEN_BAGUA: 7.0,
	CHANGBAN_CHARGE: 6.0,
	CHANGBAN_ROAR: 6.0,
}

static func has_skill(skill_id: StringName) -> bool:
	return COOLDOWNS.has(skill_id)

static func cooldown_for(skill_id: StringName) -> float:
	return float(COOLDOWNS.get(skill_id, 0.0))

static func has_target(caster: BattleUnit, sim: BattleSim) -> bool:
	return not _alive_enemies(caster, sim).is_empty()

static func cast(caster: BattleUnit, sim: BattleSim) -> void:
	if caster == null or sim == null or not caster.is_alive():
		return
	match caster.skill_id:
		QINGLONG_STRIKE:
			_cast_qinglong_strike(caster, sim)
		BAIBU_CHUANYANG:
			_cast_baibu_chuanyang(caster, sim)
		QIMEN_BAGUA:
			_cast_qimen_bagua(caster, sim)
		CHANGBAN_CHARGE:
			_cast_changban_charge(caster, sim)
		CHANGBAN_ROAR:
			_cast_changban_roar(caster, sim)

static func _cast_qinglong_strike(caster: BattleUnit, sim: BattleSim) -> void:
	var targets := _alive_enemies(caster, sim)
	targets.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
		return caster.distance_to(a) < caster.distance_to(b)
	)
	for i in mini(2, targets.size()):
		targets[i].take_damage(80)
		_record_damage_event(sim, targets[i], 80)

static func _cast_baibu_chuanyang(caster: BattleUnit, sim: BattleSim) -> void:
	var targets := _alive_enemies(caster, sim)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
		return caster.distance_to(a) > caster.distance_to(b)
	)
	targets[0].take_damage(110)
	_record_damage_event(sim, targets[0], 110)

static func _cast_qimen_bagua(caster: BattleUnit, sim: BattleSim) -> void:
	var targets := _alive_enemies(caster, sim)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
		return caster.distance_to(a) < caster.distance_to(b)
	)
	var center := targets[0].position()
	for target in targets:
		if target.position().distance_to(center) <= 180.0:
			target.take_damage(45)
			_record_damage_event(sim, target, 45)

static func _cast_changban_charge(caster: BattleUnit, sim: BattleSim) -> void:
	var forward := Vector2.RIGHT if caster.team == BattleUnit.Team.PLAYER else Vector2.LEFT
	for target in _alive_enemies(caster, sim):
		var offset := target.position() - caster.position()
		var forward_distance := offset.dot(forward)
		var side_distance := absf(offset.y)
		if forward_distance >= 0.0 and forward_distance <= 220.0 and side_distance <= 70.0:
			target.take_damage(60)
			_record_damage_event(sim, target, 60)

static func _cast_changban_roar(caster: BattleUnit, sim: BattleSim) -> void:
	for target in _alive_enemies(caster, sim):
		if caster.distance_to(target) <= 220.0:
			target.take_damage(25)
			_record_damage_event(sim, target, 25)
			target.add_status("taunt", 2.5, 0.0, caster)
			target.add_status("weaken", 2.5, 0.3, caster)

static func _record_damage_event(sim: BattleSim, target: BattleUnit, amount: int) -> void:
	if sim == null or target == null:
		return
	sim.last_damage_events.append({
		"target": target,
		"amount": amount,
		"px": target.px,
		"py": target.py,
		"team": target.team,
		"is_crit": false,
		"kind": "skill",
	})

static func _alive_enemies(caster: BattleUnit, sim: BattleSim) -> Array[BattleUnit]:
	var targets: Array[BattleUnit] = []
	if caster == null or sim == null:
		return targets
	var foes := sim.enemy_units if caster.team == BattleUnit.Team.PLAYER else sim.player_units
	for foe in foes:
		if foe.is_alive():
			targets.append(foe)
	return targets
