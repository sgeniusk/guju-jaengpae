# 다중 파도 전투 진행과 단일 파도 호환성을 검증한다.
extends TestCase

func test_default_waves_has_three_non_empty_waves() -> void:
	var waves := WaveFactory.default_waves()
	eq(waves.size(), 3, "기본 전투는 3파도")
	for wave in waves:
		truthy(not wave.is_empty(), "각 파도는 비어 있지 않아야 함")

func test_next_wave_spawns_without_declaring_win() -> void:
	var sim := BattleSim.new()
	sim.add_unit(_player("궁병", 0, 760.0, 100, 50, 0.1, "ranged", 0.0))
	sim.set_waves([
		[_enemy("첫 파도", 0, 900.0, 10, 0, 1.0, "melee", 0.0)],
		[_enemy("둘째 파도", 0, 900.0, 30, 0, 1.0, "melee", 0.0)],
	])

	sim.step(0.1)

	eq(sim.result, BattleSim.Result.ONGOING, "첫 파도 전멸 직후 승리하지 않음")
	eq(sim.wave_index, 2, "둘째 파도가 즉시 스폰됨")
	eq(sim.enemy_units.size(), 1, "새 파도 적이 채워짐")
	eq(sim.enemy_units[0].display_name, "둘째 파도", "스폰된 적은 다음 파도 소속")

func test_set_waves_requires_all_waves_for_win() -> void:
	var sim := BattleSim.new()
	sim.add_unit(_player("정예 궁병", 0, 760.0, 300, 80, 0.1, "ranged", 0.0))
	sim.set_waves([
		[_enemy("첫 파도", 0, 900.0, 20, 0, 1.0, "melee", 0.0)],
		[_enemy("마지막 파도", 0, 900.0, 20, 0, 1.0, "melee", 0.0)],
	])

	var result := sim.run_to_completion(0.1, 5.0)

	eq(result, BattleSim.Result.PLAYER_WIN, "마지막 파도까지 전멸하면 승리")
	eq(sim.wave_index, sim.wave_total, "종료 시 마지막 파도까지 스폰됨")
	eq(sim.wave_total, 2, "총 2파도 기록")
	truthy(sim.pending_waves.is_empty(), "승리 후 대기 파도 없음")

func test_single_wave_add_unit_path_still_wins() -> void:
	var sim := BattleSim.new()
	sim.add_unit(_player("검병", 0, 100.0, 50, 25, 1.0, "melee", 0.0))
	sim.add_unit(_enemy("약한 적", 0, 120.0, 20, 0, 1.0, "melee", 0.0))

	sim.step(0.1)

	eq(sim.result, BattleSim.Result.PLAYER_WIN, "set_waves 없이도 적 전멸 승리 유지")
	eq(sim.wave_total, 0, "단일 add_unit 경로는 파도 총량 없음")

func test_weak_player_loses_on_later_wave() -> void:
	var sim := BattleSim.new()
	sim.add_unit(_player("지친 병사", 0, 760.0, 10, 50, 1.0, "melee", 0.0))
	sim.set_waves([
		[_enemy("무해한 선봉", 0, 790.0, 5, 0, 1.0, "melee", 0.0)],
		[_enemy("강한 후속대", 0, 790.0, 100, 20, 1.0, "melee", 0.0)],
	])

	var result := sim.run_to_completion(0.1, 5.0)

	eq(result, BattleSim.Result.PLAYER_LOSE, "후속 파도에서 아군 전멸 시 패배")
	eq(sim.wave_index, 2, "후속 파도까지 진행됨")

func _player(
	display_name: String,
	lane: int,
	x: float,
	hp: int,
	attack: int,
	interval: float,
	attack_range: String,
	speed: float
) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.PLAYER, lane, x, display_name, hp, attack, interval, attack_range, speed)

func _enemy(
	display_name: String,
	lane: int,
	x: float,
	hp: int,
	attack: int,
	interval: float,
	attack_range: String,
	speed: float
) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.ENEMY, lane, x, display_name, hp, attack, interval, attack_range, speed)
