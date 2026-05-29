# v0.1 적 파도 정의 — 황건적이 사령(死靈)·요사 군세로 환상화된 적. 수집 카드가 아니라 BattleUnit을 직접 생성한다.
class_name WaveFactory
extends RefCounted

# 파도 1 — 각 레인에 사령병(근접) 2기, 가운데 레인에 요사 궁수(원거리) 1기.
static func wave_one() -> Array[BattleUnit]:
	var spawn_x := BattleSim.LANE_LENGTH
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(BattleUnit.make(BattleUnit.Team.ENEMY, lane, spawn_x, "사령병", 90, 14, 1.2, "melee", 34.0))
		units.append(BattleUnit.make(BattleUnit.Team.ENEMY, lane, spawn_x - 70.0, "사령병", 90, 14, 1.2, "melee", 34.0))
	units.append(BattleUnit.make(BattleUnit.Team.ENEMY, 1, spawn_x - 35.0, "요사 궁수", 70, 20, 1.1, "ranged", 30.0))
	return units

static func default_waves() -> Array:
	return [
		wave_one(),
		_wave_two(),
		_wave_three(),
	]

static func _wave_two() -> Array[BattleUnit]:
	var spawn_x := BattleSim.LANE_LENGTH
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(BattleUnit.make(BattleUnit.Team.ENEMY, lane, spawn_x, "사령병", 105, 16, 1.2, "melee", 36.0))
		units.append(BattleUnit.make(BattleUnit.Team.ENEMY, lane, spawn_x - 85.0, "사령 증원병", 95, 15, 1.1, "melee", 38.0))
	units.append(BattleUnit.make(BattleUnit.Team.ENEMY, 0, spawn_x - 45.0, "요사 궁수", 75, 21, 1.1, "ranged", 30.0))
	units.append(BattleUnit.make(BattleUnit.Team.ENEMY, 2, spawn_x - 45.0, "요사 궁수", 75, 21, 1.1, "ranged", 30.0))
	return units

static func _wave_three() -> Array[BattleUnit]:
	var spawn_x := BattleSim.LANE_LENGTH
	var units: Array[BattleUnit] = []
	for lane in BattleSim.LANE_COUNT:
		units.append(BattleUnit.make(BattleUnit.Team.ENEMY, lane, spawn_x, "사령병", 115, 18, 1.15, "melee", 38.0))
	units.append(BattleUnit.make(BattleUnit.Team.ENEMY, 0, spawn_x - 80.0, "요사 궁수", 85, 24, 1.0, "ranged", 32.0))
	units.append(BattleUnit.make(BattleUnit.Team.ENEMY, 2, spawn_x - 80.0, "요사 궁수", 85, 24, 1.0, "ranged", 32.0))
	units.append(BattleUnit.make(BattleUnit.Team.ENEMY, 1, spawn_x - 35.0, "마군 정예", 190, 32, 1.0, "melee", 42.0))
	return units
