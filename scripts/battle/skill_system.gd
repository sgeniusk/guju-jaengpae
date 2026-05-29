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
	return not _same_lane_enemies(caster, sim).is_empty()

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
	var targets := _same_lane_enemies(caster, sim)
	targets.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
		return absf(a.x - caster.x) < absf(b.x - caster.x)
	)
	for i in mini(2, targets.size()):
		targets[i].take_damage(80)

static func _cast_baibu_chuanyang(caster: BattleUnit, sim: BattleSim) -> void:
	var targets := _same_lane_enemies(caster, sim)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
		return absf(a.x - caster.x) > absf(b.x - caster.x)
	)
	targets[0].take_damage(110)

static func _cast_qimen_bagua(caster: BattleUnit, sim: BattleSim) -> void:
	for target in _same_lane_enemies(caster, sim):
		target.take_damage(45)

static func _cast_changban_charge(caster: BattleUnit, sim: BattleSim) -> void:
	var from_x := caster.x
	var dir := 1.0 if caster.team == BattleUnit.Team.PLAYER else -1.0
	caster.x = clampf(caster.x + dir * 220.0, 0.0, BattleSim.LANE_LENGTH)
	var lo := minf(from_x, caster.x)
	var hi := maxf(from_x, caster.x)
	for target in _same_lane_enemies(caster, sim):
		if target.x >= lo and target.x <= hi:
			target.take_damage(60)

static func _cast_changban_roar(caster: BattleUnit, sim: BattleSim) -> void:
	for target in _same_lane_enemies(caster, sim):
		target.take_damage(25)
	caster.hp = mini(caster.max_hp, caster.hp + 80)

static func _same_lane_enemies(caster: BattleUnit, sim: BattleSim) -> Array[BattleUnit]:
	var targets: Array[BattleUnit] = []
	if caster == null or sim == null:
		return targets
	var foes := sim.enemy_units if caster.team == BattleUnit.Team.PLAYER else sim.player_units
	for foe in foes:
		if foe.is_alive() and foe.lane == caster.lane:
			targets.append(foe)
	return targets
