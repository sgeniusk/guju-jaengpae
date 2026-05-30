# v0.1 적 파도 정의 — 황건적이 사령(死靈)·요사 군세로 환상화된 적. 수집 카드가 아니라 BattleUnit을 직접 생성한다.
class_name WaveFactory
extends RefCounted

# 파도 1 — 각 컬럼에 사령병(근접) 2기, 가운데 컬럼에 요사 궁수(원거리) 1기.
static func wave_one() -> Array[BattleUnit]:
	var spawn_x := BattleSim.LANE_LENGTH
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "사령병", 90, 14, 1.2, "melee", 34.0, "infantry"))
		units.append(_enemy_unit(lane, spawn_x, "사령병", 90, 14, 1.2, "melee", 34.0, "infantry"))
	units.append(_enemy_unit(1, spawn_x, "요사 궁수", 70, 20, 1.1, "ranged", 30.0, "archer"))
	return units

static func default_waves() -> Array:
	return [
		wave_one(),
		_wave_two(),
		_wave_three(),
	]

static func waves_for_node(node_type: int) -> Array:
	match node_type:
		RunMap.NodeType.BATTLE:
			return default_waves()
		RunMap.NodeType.ELITE:
			return elite_waves()
		RunMap.NodeType.BOSS:
			return boss_waves()
		_:
			return default_waves()

static func elite_waves() -> Array:
	return [
		_scaled_wave(wave_one(), 1.15, 1.10),
		_scaled_wave(_wave_two(), 1.2, 1.15),
		_scaled_wave(_wave_three(), 1.25, 1.2),
	]

static func boss_waves() -> Array:
	var spawn_x := BattleSim.LANE_LENGTH
	return [[
		_enemy_unit(1, spawn_x, "마왕 동탁", 2300, 48, 0.9, "melee", 28.0, "infantry"),
		_enemy_unit(0, spawn_x, "마군 호위", 170, 24, 1.0, "melee", 36.0, "infantry"),
		_enemy_unit(1, spawn_x, "마군 호위", 170, 24, 1.0, "melee", 36.0, "infantry"),
		_enemy_unit(2, spawn_x, "마군 호위", 170, 24, 1.0, "melee", 36.0, "infantry"),
		_enemy_unit(0, spawn_x, "요사 궁수", 130, 30, 0.95, "ranged", 30.0, "archer"),
		_enemy_unit(2, spawn_x, "요사 궁수", 130, 30, 0.95, "ranged", 30.0, "archer"),
	]]

static func _wave_two() -> Array[BattleUnit]:
	var spawn_x := BattleSim.LANE_LENGTH
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "사령병", 105, 16, 1.2, "melee", 36.0, "infantry"))
		units.append(_enemy_unit(lane, spawn_x, "사령 증원병", 95, 15, 1.1, "melee", 38.0, "infantry"))
	units.append(_enemy_unit(0, spawn_x, "요사 궁수", 75, 21, 1.1, "ranged", 30.0, "archer"))
	units.append(_enemy_unit(2, spawn_x, "요사 궁수", 75, 21, 1.1, "ranged", 30.0, "archer"))
	return units

static func _wave_three() -> Array[BattleUnit]:
	var spawn_x := BattleSim.LANE_LENGTH
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(_enemy_unit(lane, spawn_x, "사령병", 115, 18, 1.15, "melee", 38.0, "infantry"))
	units.append(_enemy_unit(0, spawn_x, "요사 궁수", 85, 24, 1.0, "ranged", 32.0, "archer"))
	units.append(_enemy_unit(2, spawn_x, "요사 궁수", 85, 24, 1.0, "ranged", 32.0, "archer"))
	units.append(_enemy_unit(1, spawn_x, "마군 정예", 190, 32, 1.0, "melee", 42.0, "cavalry"))
	return units

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
			unit.row
		))
	return out

static func _enemy_unit(lane: int, x: float, display_name: String, hp: int, attack: int, interval: float, attack_range: String, speed: float, troop_type: String) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.ENEMY, lane, x, display_name, hp, attack, interval, attack_range, speed, &"", &"", troop_type)
