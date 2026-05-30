# 오픈필드 2D 난전의 좌표, 이동, 타겟팅, 전멸 승패를 검증한다.
extends TestCase

func test_start_formation_maps_grid_to_2d_field() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 2, BattleSim.ROW_X[0], "전열", 100, 0, 1.0, "melee", 0.0, &"", &"", "infantry", 0, BattleSim.COL_Y[2])
	almost(unit.px, 360.0, 0.001, "row 0은 전방 x=360")
	almost(unit.py, 450.0, 0.001, "col 2는 측면 y=450")
	almost(unit.x, unit.px, 0.001, "호환 x는 px를 따른다")

func test_both_sides_move_and_converge_until_melee_range() -> void:
	var sim := BattleSim.new()
	var player := _unit(BattleUnit.Team.PLAYER, 0, 120.0, 300.0, "아군", 120, 0, 999.0, "melee", 80.0)
	var enemy := _unit(BattleUnit.Team.ENEMY, 1, 900.0, 300.0, "적", 120, 0, 999.0, "melee", 80.0)
	sim.add_unit(player)
	sim.add_unit(enemy)

	sim.step(1.0)

	truthy(player.px > 120.0, "아군도 적 방향으로 전진")
	truthy(enemy.px < 900.0, "적도 아군 방향으로 전진")
	truthy(player.distance_to(enemy) < 780.0, "두 유닛 사이 2D 거리가 줄어듦")
	eq(sim.result, BattleSim.Result.ONGOING, "전멸 전에는 진행")

func test_nearest_target_uses_2d_distance_without_column_filter() -> void:
	var sim := BattleSim.new()
	var archer := _unit(BattleUnit.Team.PLAYER, 0, 360.0, 300.0, "궁병", 100, 10, 999.0, "ranged", 0.0)
	var nearer_other_column := _unit(BattleUnit.Team.ENEMY, 2, 460.0, 300.0, "가까운 다른 컬럼", 100, 0, 999.0, "melee", 0.0)
	var farther_same_column := _unit(BattleUnit.Team.ENEMY, 0, 620.0, 300.0, "먼 같은 컬럼", 100, 0, 999.0, "melee", 0.0)
	sim.add_unit(archer)
	sim.add_unit(nearer_other_column)
	sim.add_unit(farther_same_column)

	sim.step(0.1)

	eq(nearer_other_column.hp, 90, "2D 최근접 적을 먼저 공격")
	eq(farther_same_column.hp, 100, "같은 컬럼이어도 더 멀면 공격받지 않음")

func test_army_wipe_decides_win_and_loss_without_base_breakthrough() -> void:
	var win_sim := BattleSim.new()
	win_sim.add_unit(_unit(BattleUnit.Team.PLAYER, 0, 360.0, 300.0, "강한 아군", 100, 50, 0.1, "ranged", 0.0))
	win_sim.add_unit(_unit(BattleUnit.Team.ENEMY, 2, 420.0, 450.0, "약한 적", 20, 0, 999.0, "melee", 0.0))
	eq(win_sim.run_to_completion(0.1, 2.0), BattleSim.Result.PLAYER_WIN, "적 전멸이면 승리")

	var lose_sim := BattleSim.new()
	lose_sim.add_unit(_unit(BattleUnit.Team.PLAYER, 0, 360.0, 150.0, "약한 아군", 20, 0, 999.0, "melee", 0.0))
	lose_sim.add_unit(_unit(BattleUnit.Team.ENEMY, 2, 420.0, 150.0, "강한 적", 100, 50, 0.1, "ranged", 0.0))
	eq(lose_sim.run_to_completion(0.1, 2.0), BattleSim.Result.PLAYER_LOSE, "아군 전멸이면 패배")

func _unit(
	team: int,
	lane: int,
	px: float,
	py: float,
	display_name: String,
	hp: int,
	attack: int,
	interval: float,
	attack_range: String,
	speed: float
) -> BattleUnit:
	return BattleUnit.make(team, lane, px, display_name, hp, attack, interval, attack_range, speed, &"", &"", "infantry", -1, py)
