# BattleSim의 그리드 승패 판정과 결정적 컬럼 교전 규칙을 검증한다.
extends TestCase

func test_enemy_at_base_loses_immediately() -> void:
	var sim := BattleSim.new()
	sim.add_unit(BattleUnit.make(BattleUnit.Team.ENEMY, 0, 0.0, "침입자", 10, 1, 1.0, "melee", 0.0))
	sim.step(0.1)
	eq(sim.result, BattleSim.Result.PLAYER_LOSE, "적이 기지에 닿으면 패배")

func test_no_defenders_loses_only_after_breakthrough() -> void:
	var sim := BattleSim.new()
	var enemy := BattleUnit.make(BattleUnit.Team.ENEMY, 0, 900.0, "사령병", 10, 1, 1.0, "melee", 300.0)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(sim.result, BattleSim.Result.ONGOING, "아군이 없어도 기지 도달 전에는 진행")
	truthy(enemy.x < 900.0, "빈 컬럼 적은 기지 방향으로 전진")
	var result := sim.run_to_completion(0.1, 10.0)
	eq(result, BattleSim.Result.PLAYER_LOSE, "빈 컬럼 적이 기지에 도달하면 패배")

func test_liubei_starting_deck_beats_wave_one() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(&"lord_liubei")
	var sim := BattleSim.new()
	var tile := 0
	for card_id in cat.get_lord_deck(lord):
		var col := tile % BattleSim.LANE_COUNT
		var row := tile / BattleSim.LANE_COUNT
		var unit := cat.build_player_unit(card_id, col, _grid_depth(row), lord)
		unit.row = row
		sim.add_unit(unit)
		tile += 1
	for enemy in WaveFactory.wave_one():
		sim.add_unit(enemy)
	var result := sim.run_to_completion(0.1, 120.0)
	eq(result, BattleSim.Result.PLAYER_WIN, "유비 시작 덱은 파도 1을 막아야 함")
	truthy(sim.enemy_units.is_empty(), "승리 후 적 전멸")

func test_melee_units_apply_damage_and_death() -> void:
	var sim := BattleSim.new()
	var player := BattleUnit.make(BattleUnit.Team.PLAYER, 0, _grid_depth(0), "검병", 50, 25, 1.0, "melee", 0.0)
	var enemy := BattleUnit.make(BattleUnit.Team.ENEMY, 0, _grid_depth(0) + 24.0, "약한 적", 20, 0, 1.0, "melee", 0.0)
	sim.add_unit(player)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(sim.enemy_units.size(), 0, "근접 공격으로 사망한 적 제거")
	eq(sim.result, BattleSim.Result.PLAYER_WIN, "적 사망 후 승리")
	eq(player.hp, 50, "공격력 0인 적은 피해를 주지 않음")

func test_player_only_wins_after_one_step() -> void:
	var sim := BattleSim.new()
	sim.add_unit(BattleUnit.make(BattleUnit.Team.PLAYER, 0, _grid_depth(1), "아군", 10, 1, 1.0, "melee", 0.0))
	sim.step(0.1)
	eq(sim.result, BattleSim.Result.PLAYER_WIN, "적이 없으면 승리")

func test_unit_cooldown_limits_attacks_until_interval_passes() -> void:
	var sim := BattleSim.new()
	var player := BattleUnit.make(BattleUnit.Team.PLAYER, 0, _grid_depth(1), "궁병", 100, 7, 1.0, "ranged", 0.0)
	var enemy := BattleUnit.make(BattleUnit.Team.ENEMY, 0, _grid_depth(1) + 80.0, "표적", 100, 0, 1.0, "melee", 0.0)
	sim.add_unit(player)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(enemy.hp, 93, "첫 step에서 1회 공격")
	for i in 4:
		sim.step(0.1)
	eq(enemy.hp, 93, "공격 간격 전에는 추가 피해 없음")
	truthy(player.cooldown > 0.0, "공격 간격이 아직 남아 있음")

func _grid_depth(row: int) -> float:
	var depths := [360.0, 240.0, 120.0]
	return depths[row]
