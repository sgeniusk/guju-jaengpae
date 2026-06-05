# 성 방어 목표의 생성, 표적화, 승패 조건을 검증한다.
extends TestCase

func test_add_castle_creates_static_inner_objective() -> void:
	var sim := BattleSim.new()
	var castle := _add_castle(sim)
	if castle == null:
		return
	not_null(sim.get("castle"), "시뮬레이션이 성 참조를 보유")
	eq(sim.get("castle"), castle, "반환된 성과 보유 성이 같음")
	truthy(bool(castle.get("is_castle")), "성 식별 플래그")
	eq(castle.team, BattleUnit.Team.PLAYER, "성은 플레이어 표적")
	eq(castle.attack, 0, "성은 공격하지 않음")
	almost(castle.move_speed, 0.0, 0.001, "성은 이동하지 않음")
	truthy(castle.px < BattleSim.ROW_X[BattleSim.ROW_COUNT - 1], "성은 배치보다 안쪽에 있음")
	almost(castle.py, BattleSim.FIELD_H * 0.5, 0.001, "성은 중앙에 고정")
	var before := castle.position()
	sim.step(0.5)
	almost(castle.px, before.x, 0.001, "step 이후 성 x 불변")
	almost(castle.py, before.y, 0.001, "step 이후 성 y 불변")

func test_add_castle_at_uses_selected_tile_position() -> void:
	var sim := BattleSim.new()
	truthy(sim.has_method("add_castle_at"), "BattleSim.add_castle_at API")
	if not sim.has_method("add_castle_at"):
		return
	var tile := BattleSim.position_for_tile(2, 1)
	var castle = sim.call("add_castle_at", tile.x, tile.y, 900)
	if castle == null or not (castle is BattleUnit):
		_add_failure("add_castle_at은 BattleUnit을 반환해야 함")
		return
	almost(castle.px, tile.x, 0.001, "성 x는 선택 타일")
	almost(castle.py, tile.y, 0.001, "성 y는 선택 타일")
	eq(castle.max_hp, 900, "선택 성 HP 반영")

func test_enemy_attacks_castle_when_no_other_targets() -> void:
	var sim := BattleSim.new()
	var castle := _add_castle(sim, 120)
	if castle == null:
		return
	var enemy := _unit(BattleUnit.Team.ENEMY, 1, castle.px + BattleSim.MELEE_REACH - 2.0, castle.py, "성문 돌격병", 100, 30, 0.1, "melee", 0.0)
	sim.add_unit(enemy)

	sim.step(0.1)

	eq(castle.hp, 90, "다른 표적이 없으면 적이 성을 공격")
	eq(sim.result, BattleSim.Result.ONGOING, "성 생존 중에는 진행")

func test_castle_destroyed_decides_loss() -> void:
	var sim := BattleSim.new()
	var castle := _add_castle(sim, 40)
	if castle == null:
		return
	var enemy := _unit(BattleUnit.Team.ENEMY, 1, castle.px + BattleSim.MELEE_REACH - 2.0, castle.py, "공성병", 100, 50, 0.1, "melee", 0.0)
	sim.add_unit(enemy)

	var result := sim.run_to_completion(0.1, 2.0)

	eq(result, BattleSim.Result.PLAYER_LOSE, "성 파괴가 패배 조건")
	falsy(castle.is_alive(), "패배 시 성 파괴")

func test_enemy_wipe_decides_win_with_castle_alive() -> void:
	var sim := BattleSim.new()
	var castle := _add_castle(sim, 1200)
	if castle == null:
		return
	var defender := _unit(BattleUnit.Team.PLAYER, 1, 320.0, 300.0, "수비대", 100, 80, 0.1, "ranged", 0.0)
	var enemy := _unit(BattleUnit.Team.ENEMY, 1, 450.0, 300.0, "약한 적", 50, 0, 999.0, "melee", 0.0)
	sim.add_unit(defender)
	sim.add_unit(enemy)

	var result := sim.run_to_completion(0.1, 2.0)

	eq(result, BattleSim.Result.PLAYER_WIN, "적 군세 전멸이 승리 조건")
	truthy(castle.is_alive(), "승리 시 성 생존")

func test_player_army_wipe_is_not_loss_while_castle_lives() -> void:
	var sim := BattleSim.new()
	var castle := _add_castle(sim, 1200)
	if castle == null:
		return
	var decoy := _unit(BattleUnit.Team.PLAYER, 1, 360.0, 300.0, "전멸할 수비병", 10, 0, 999.0, "melee", 0.0)
	var enemy := _unit(BattleUnit.Team.ENEMY, 1, 390.0, 300.0, "돌격병", 100, 20, 0.1, "melee", 0.0)
	sim.add_unit(decoy)
	sim.add_unit(enemy)

	sim.step(0.1)

	falsy(decoy.is_alive(), "비-성 아군은 전멸")
	truthy(castle.is_alive(), "성은 생존")
	eq(sim.result, BattleSim.Result.ONGOING, "성 생존 중 유닛 전멸은 즉시 패배가 아님")

func test_full_deck_with_castle_vs_default_waves_settles() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(&"lord_liubei")
	var sim := BattleSim.new()
	var castle := _add_castle(sim, 1200)
	if castle == null:
		return
	_add_starting_deck(sim, cat, lord)
	sim.set_waves(WaveFactory.default_waves())

	var result := sim.run_to_completion(0.1, 120.0)

	ne(result, BattleSim.Result.ONGOING, "기본 파도는 승패 중 하나로 결판")
	truthy((result == BattleSim.Result.PLAYER_WIN and castle.is_alive()) or (result == BattleSim.Result.PLAYER_LOSE and not castle.is_alive()), "결과는 적 전멸 또는 성 파괴와 정합")

func _add_castle(sim: BattleSim, hp: int = 1200) -> BattleUnit:
	truthy(sim.has_method("add_castle"), "BattleSim.add_castle API")
	if not sim.has_method("add_castle"):
		return null
	var castle = sim.call("add_castle", hp)
	if castle == null or not (castle is BattleUnit):
		_add_failure("add_castle은 BattleUnit을 반환해야 함")
		return null
	return castle

func _add_starting_deck(sim: BattleSim, cat: CardCatalog, lord: LordData) -> void:
	var tile := 0
	for card_id in cat.get_lord_deck(lord):
		var col := tile % BattleSim.LANE_COUNT
		var row := int(tile / BattleSim.LANE_COUNT)
		var start := BattleSim.position_for_tile(col, row)
		var unit := cat.build_player_unit(card_id, col, start.x, lord)
		unit.row = row
		unit.set_position(start.x, start.y)
		sim.add_unit(unit)
		tile += 1

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
