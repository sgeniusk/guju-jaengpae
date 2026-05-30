# 그리드 전장 배치, 돌파, 컬럼 방어 규칙을 검증한다.
extends TestCase

func test_player_unit_stays_on_deployed_tile_depth() -> void:
	var sim := BattleSim.new()
	var player := BattleUnit.make(BattleUnit.Team.PLAYER, 0, _grid_depth(1), "고정 수비병", 100, 10, 1.0, "melee", 120.0)
	var other_column_enemy := BattleUnit.make(BattleUnit.Team.ENEMY, 1, BattleSim.LANE_LENGTH, "다른 컬럼 적", 100, 0, 1.0, "melee", 0.0)
	sim.add_unit(player)
	sim.add_unit(other_column_enemy)

	sim.step(0.5)

	almost(player.x, _grid_depth(1), 0.001, "아군은 표적이 없어도 행군하지 않음")
	eq(sim.result, BattleSim.Result.ONGOING, "다른 컬럼 적이 남아 있으면 전투 진행")

func test_enemy_advances_down_column_toward_base() -> void:
	var sim := BattleSim.new()
	var player := BattleUnit.make(BattleUnit.Team.PLAYER, 0, _grid_depth(2), "후방 수비병", 100, 0, 999.0, "melee", 0.0)
	var enemy := BattleUnit.make(BattleUnit.Team.ENEMY, 0, BattleSim.LANE_LENGTH, "전진 적", 100, 0, 1.0, "melee", 80.0)
	sim.add_unit(player)
	sim.add_unit(enemy)

	sim.step(0.5)

	truthy(enemy.x < BattleSim.LANE_LENGTH, "적 depth는 기지 방향으로 감소")
	almost(player.x, _grid_depth(2), 0.001, "아군 depth는 불변")

func test_empty_column_breakthrough_causes_player_loss() -> void:
	var sim := BattleSim.new()
	sim.add_unit(BattleUnit.make(BattleUnit.Team.PLAYER, 0, _grid_depth(0), "왼쪽 수비병", 100, 0, 999.0, "melee", 0.0))
	sim.add_unit(BattleUnit.make(BattleUnit.Team.ENEMY, 2, BattleSim.LANE_LENGTH, "빈 컬럼 침입자", 100, 0, 1.0, "melee", 250.0))

	var result := sim.run_to_completion(0.1, 10.0)

	eq(result, BattleSim.Result.PLAYER_LOSE, "수비 없는 컬럼은 돌파 패배")

func test_defended_column_clears_wave_without_breakthrough() -> void:
	var sim := BattleSim.new()
	sim.add_unit(BattleUnit.make(BattleUnit.Team.PLAYER, 1, _grid_depth(0), "강한 수비병", 300, 100, 0.2, "ranged", 0.0))
	sim.set_waves([
		[
			BattleUnit.make(BattleUnit.Team.ENEMY, 1, _grid_depth(0) + 120.0, "공격대", 80, 0, 1.0, "melee", 0.0),
		]
	])

	var result := sim.run_to_completion(0.1, 5.0)

	eq(result, BattleSim.Result.PLAYER_WIN, "막힌 컬럼은 적 전멸로 파도 클리어")
	truthy(sim.enemy_units.is_empty(), "승리 후 적 없음")

func _grid_depth(row: int) -> float:
	var depths := [360.0, 240.0, 120.0]
	return depths[row]
