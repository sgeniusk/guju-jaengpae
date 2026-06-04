# v0.1 적 파도 정의 — 황건적이 사령(死靈)·요사 군세로 환상화된 적. 수집 카드가 아니라 BattleUnit을 직접 생성한다.
class_name WaveFactory
extends RefCounted

const _StageCadence := preload("res://scripts/run/stage_cadence.gd")
const _SkillSystem := preload("res://scripts/battle/skill_system.gd")

const ACT_LENGTH := 5
const MAX_TEMPLATE_ACT := 3
const BOSS_NAMES := ["마왕 동탁", "천공 장각", "귀신 여포"]

# 파도 1 — 적 진영 x=FIELD_W에서 y를 3개 측면으로 나눠 등장한다.
static func wave_one() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "사령병", 90, 14, 1.2, "melee", 34.0, "infantry"))
		units.append(_enemy_unit(lane, spawn_x, "사령병", 90, 14, 1.2, "melee", 34.0, "infantry"))
	units.append(_enemy_unit(1, spawn_x, "요사 궁수", 70, 20, 1.1, "ranged", 30.0, "archer", "strongest_ranged"))
	return units

static func default_waves() -> Array:
	return [
		wave_one(),
		_wave_two(),
		_wave_three(),
	]

static func act_for_stage(stage: int) -> int:
	return int((maxi(1, stage) - 1) / ACT_LENGTH) + 1

static func act_waves(act: int) -> Array:
	match _template_act(act):
		1:
			return default_waves()
		2:
			return _act_two_waves()
		_:
			return _act_three_waves()

static func is_boss_name(display_name: String) -> bool:
	return BOSS_NAMES.has(display_name)

static func stage_waves(stage: int) -> Array:
	var act := act_for_stage(stage)
	var waves := boss_waves(act) if _StageCadence.is_boss(stage) else act_waves(act)
	var scale: float = _StageCadence.difficulty_scale(stage)
	return _scaled_waves(waves, scale, scale)

static func boss_waves(act: int = 1) -> Array:
	var spawn_x := BattleSim.FIELD_W
	if _template_act(act) == 1:
		return [[
			_enemy_unit(1, spawn_x, "마왕 동탁", 2300, 48, 0.9, "melee", 28.0, "infantry", "highest_hp", _SkillSystem.BOSS_TYRANT_ROAR),
			_enemy_unit(0, spawn_x, "마군 호위", 170, 24, 1.0, "melee", 36.0, "infantry"),
			_enemy_unit(1, spawn_x, "마군 호위", 170, 24, 1.0, "melee", 36.0, "infantry"),
			_enemy_unit(2, spawn_x, "마군 호위", 170, 24, 1.0, "melee", 36.0, "infantry"),
			_enemy_unit(0, spawn_x, "요사 궁수", 130, 30, 0.95, "ranged", 30.0, "archer", "strongest_ranged"),
			_enemy_unit(2, spawn_x, "요사 궁수", 130, 30, 0.95, "ranged", 30.0, "archer", "strongest_ranged"),
	]]
	if _template_act(act) == 2:
		return [[
			_enemy_unit(1, spawn_x, "천공 장각", 2350, 42, 1.05, "ranged", 24.0, "archer", "backline", _SkillSystem.BOSS_SKY_THUNDER),
			_enemy_unit(0, spawn_x, "황건 부적병", 190, 22, 1.05, "melee", 34.0, "infantry", "highest_hp"),
			_enemy_unit(2, spawn_x, "황건 부적병", 190, 22, 1.05, "melee", 34.0, "infantry", "highest_hp"),
			_enemy_unit(0, spawn_x, "요사 술사", 150, 34, 0.95, "ranged", 28.0, "archer", "backline"),
			_enemy_unit(1, spawn_x, "요사 술사", 150, 34, 0.95, "ranged", 28.0, "archer", "backline"),
			_enemy_unit(2, spawn_x, "요사 명궁", 150, 36, 0.92, "ranged", 30.0, "archer", "strongest_ranged"),
		]]
	return [[
		_enemy_unit(1, spawn_x, "귀신 여포", 2750, 70, 0.78, "melee", 54.0, "cavalry", "lowest_hp", _SkillSystem.BOSS_WAR_GOD_CLEAVE),
		_enemy_unit(0, spawn_x, "흑기 방패대", 250, 30, 0.96, "melee", 34.0, "infantry", "highest_hp"),
		_enemy_unit(2, spawn_x, "흑기 방패대", 250, 30, 0.96, "melee", 34.0, "infantry", "highest_hp"),
		_enemy_unit(0, spawn_x, "흑기 기병", 220, 40, 0.86, "melee", 48.0, "cavalry", "lowest_hp"),
		_enemy_unit(1, spawn_x, "흑기 기병", 220, 40, 0.86, "melee", 48.0, "cavalry", "lowest_hp"),
		_enemy_unit(2, spawn_x, "흑기 기병", 220, 40, 0.86, "melee", 48.0, "cavalry", "lowest_hp"),
	]]

static func _wave_two() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "사령병", 105, 16, 1.2, "melee", 36.0, "infantry"))
		units.append(_enemy_unit(lane, spawn_x, "사령 증원병", 95, 15, 1.1, "melee", 38.0, "infantry"))
	units.append(_enemy_unit(0, spawn_x, "요사 궁수", 75, 21, 1.1, "ranged", 30.0, "archer", "strongest_ranged"))
	units.append(_enemy_unit(2, spawn_x, "요사 궁수", 75, 21, 1.1, "ranged", 30.0, "archer", "strongest_ranged"))
	return units

static func _wave_three() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "사령병", 115, 18, 1.15, "melee", 38.0, "infantry"))
	units.append(_enemy_unit(0, spawn_x, "요사 궁수", 85, 24, 1.0, "ranged", 32.0, "archer", "strongest_ranged"))
	units.append(_enemy_unit(2, spawn_x, "요사 궁수", 85, 24, 1.0, "ranged", 32.0, "archer", "strongest_ranged"))
	units.append(_enemy_unit(1, spawn_x, "마군 정예", 190, 32, 1.0, "melee", 42.0, "cavalry"))
	return units

static func _act_two_waves() -> Array:
	return [
		_act_two_wave_one(),
		_act_two_wave_two(),
		_act_two_wave_three(),
	]

static func _act_two_wave_one() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "마군 창병", 110, 18, 1.15, "melee", 36.0, "infantry"))
	units.append(_enemy_unit(0, spawn_x, "요사 명궁", 85, 24, 1.0, "ranged", 30.0, "archer", "strongest_ranged"))
	units.append(_enemy_unit(2, spawn_x, "요사 명궁", 85, 24, 1.0, "ranged", 30.0, "archer", "strongest_ranged"))
	return units

static func _act_two_wave_two() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "마군 창병", 120, 20, 1.1, "melee", 38.0, "infantry"))
		units.append(_enemy_unit(lane, spawn_x, "마군 돌격대", 105, 25, 0.95, "melee", 44.0, "cavalry", "lowest_hp"))
	units.append(_enemy_unit(1, spawn_x, "요사 명궁", 95, 28, 0.95, "ranged", 30.0, "archer", "strongest_ranged"))
	return units

static func _act_two_wave_three() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "마군 방패대", 155, 22, 1.05, "melee", 34.0, "infantry", "highest_hp"))
	units.append(_enemy_unit(0, spawn_x, "마군 돌격대", 125, 30, 0.9, "melee", 46.0, "cavalry", "lowest_hp"))
	units.append(_enemy_unit(2, spawn_x, "마군 돌격대", 125, 30, 0.9, "melee", 46.0, "cavalry", "lowest_hp"))
	units.append(_enemy_unit(1, spawn_x, "요사 명궁", 110, 32, 0.9, "ranged", 30.0, "archer", "strongest_ranged"))
	return units

static func _act_three_waves() -> Array:
	return [
		_act_three_wave_one(),
		_act_three_wave_two(),
		_act_three_wave_three(),
	]

static func _act_three_wave_one() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "흑기 방패대", 150, 24, 1.0, "melee", 34.0, "infantry", "highest_hp"))
	units.append(_enemy_unit(1, spawn_x, "요사 술사", 120, 34, 0.92, "ranged", 28.0, "archer", "backline"))
	return units

static func _act_three_wave_two() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "흑기 기병", 145, 34, 0.88, "melee", 48.0, "cavalry", "lowest_hp"))
	units.append(_enemy_unit(0, spawn_x, "요사 술사", 125, 36, 0.9, "ranged", 28.0, "archer", "backline"))
	units.append(_enemy_unit(2, spawn_x, "요사 술사", 125, 36, 0.9, "ranged", 28.0, "archer", "backline"))
	return units

static func _act_three_wave_three() -> Array[BattleUnit]:
	var spawn_x := BattleSim.FIELD_W
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "흑기 방패대", 180, 28, 0.96, "melee", 34.0, "infantry", "highest_hp"))
		units.append(_enemy_unit(lane, spawn_x, "흑기 기병", 150, 38, 0.86, "melee", 50.0, "cavalry", "lowest_hp"))
	units.append(_enemy_unit(1, spawn_x, "요사 술사", 150, 42, 0.86, "ranged", 28.0, "archer", "backline"))
	return units

static func _template_act(act: int) -> int:
	return mini(maxi(1, act), MAX_TEMPLATE_ACT)

static func _scaled_wave(wave: Array, hp_mult: float, attack_mult: float) -> Array[BattleUnit]:
	var out: Array[BattleUnit] = []
	for unit: BattleUnit in wave:
		out.append(BattleUnit.make(
			unit.team,
			unit.lane,
			unit.x,
			unit.display_name,
			int(round(unit.max_hp * hp_mult)),
			int(round(unit.attack * attack_mult)),
			unit.attack_interval,
			unit.attack_range,
			unit.move_speed,
			unit.card_id,
			unit.skill_id,
			unit.troop_type,
			unit.row,
			unit.py,
			false,
			unit.target_rule
		))
	return out

static func _scaled_waves(waves: Array, hp_mult: float, attack_mult: float) -> Array:
	var out: Array = []
	for wave in waves:
		out.append(_scaled_wave(wave, hp_mult, attack_mult))
	return out

static func _enemy_unit(lane: int, x: float, display_name: String, hp: int, attack: int, interval: float, attack_range: String, speed: float, troop_type: String, target_rule: String = "nearest", skill_id: StringName = &"") -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.ENEMY, lane, x, display_name, hp, attack, interval, attack_range, speed, &"", skill_id, troop_type, -1, BattleSim.start_y_for_col(lane), false, target_rule)
