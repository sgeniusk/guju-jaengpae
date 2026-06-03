# 3×3 배치가 오픈필드 시작 진형 좌표로 해석되는지 검증한다.
extends TestCase

func test_position_for_tile_matches_spec_constants() -> void:
	var front_left := BattleSim.position_for_tile(0, 0)
	almost(front_left.x, 360.0, 0.001, "전열 row 0 x")
	almost(front_left.y, 150.0, 0.001, "좌측 col 0 y")
	var back_right := BattleSim.position_for_tile(2, 2)
	almost(back_right.x, 120.0, 0.001, "후열 row 2 x")
	almost(back_right.y, 450.0, 0.001, "우측 col 2 y")
	var expanded_front := BattleSim.position_for_tile(1, 5)
	almost(expanded_front.x, 720.0, 0.001, "확장 row 5 x")
	almost(expanded_front.y, 300.0, 0.001, "확장 row 5 중앙 y")
	eq(BattleSim.ROW_COUNT, 6, "BattleSim은 6행 좌표 상한을 안다")

func test_depth_for_row_keeps_legacy_start_x_alias() -> void:
	almost(BattleSim.depth_for_row(0), BattleSim.ROW_X[0], 0.001, "row 0 호환")
	almost(BattleSim.depth_for_row(2), BattleSim.ROW_X[2], 0.001, "row 2 호환")

func test_battle_unit_can_store_start_tile_position() -> void:
	var start := BattleSim.position_for_tile(1, 1)
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 1, start.x, "중앙", 100, 0, 1.0, "melee", 0.0, &"", &"", "infantry", 1, start.y)
	almost(unit.px, 240.0, 0.001, "중앙 row x")
	almost(unit.py, 300.0, 0.001, "중앙 col y")
	eq(unit.lane, 1, "lane은 시작 col 호환 필드")
	eq(unit.row, 1, "row는 시작 행 호환 필드")

func test_wave_factory_spawns_enemies_on_enemy_side_with_distributed_y() -> void:
	var seen_y := {}
	for enemy in WaveFactory.wave_one():
		almost(enemy.px, BattleSim.FIELD_W, 0.001, "적은 적 진영 x에서 등장")
		seen_y[int(enemy.py)] = true
	truthy(seen_y.has(150), "상단 측면 등장")
	truthy(seen_y.has(300), "중앙 측면 등장")
	truthy(seen_y.has(450), "하단 측면 등장")
