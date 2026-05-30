# BattleSim의 오픈필드 승패 판정과 결정적 2D 교전 규칙을 검증한다.
extends TestCase

func test_no_player_army_loses_immediately() -> void:
	var sim := BattleSim.new()
	sim.add_unit(_unit(BattleUnit.Team.ENEMY, 0, 900.0, 300.0, "침입자", 10, 1, 1.0, "melee", 0.0))
	sim.step(0.1)
	eq(sim.result, BattleSim.Result.PLAYER_LOSE, "아군 군세가 없으면 패배")

func test_liubei_starting_deck_beats_wave_one() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(&"lord_liubei")
	var sim := BattleSim.new()
	_add_starting_deck(sim, cat, lord)
	for enemy in WaveFactory.wave_one():
		sim.add_unit(enemy)
	var result := sim.run_to_completion(0.1, 120.0)
	eq(result, BattleSim.Result.PLAYER_WIN, "유비 시작 덱은 오픈필드 파도 1을 막아야 함")
	truthy(sim.enemy_units.is_empty(), "승리 후 적 전멸")

func test_melee_units_apply_damage_and_death() -> void:
	var sim := BattleSim.new()
	var player := _unit(BattleUnit.Team.PLAYER, 0, 300.0, 300.0, "검병", 50, 25, 1.0, "melee", 0.0)
	var enemy := _unit(BattleUnit.Team.ENEMY, 2, 324.0, 300.0, "약한 적", 20, 0, 1.0, "melee", 0.0)
	sim.add_unit(player)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(sim.enemy_units.size(), 0, "근접 공격으로 사망한 적 제거")
	eq(sim.result, BattleSim.Result.PLAYER_WIN, "적 사망 후 승리")
	eq(player.hp, 50, "공격력 0인 적은 피해를 주지 않음")

func test_player_only_wins_after_one_step() -> void:
	var sim := BattleSim.new()
	sim.add_unit(_unit(BattleUnit.Team.PLAYER, 0, 300.0, 300.0, "아군", 10, 1, 1.0, "melee", 0.0))
	sim.step(0.1)
	eq(sim.result, BattleSim.Result.PLAYER_WIN, "적이 없으면 승리")

func test_unit_cooldown_limits_attacks_until_interval_passes() -> void:
	var sim := BattleSim.new()
	var player := _unit(BattleUnit.Team.PLAYER, 0, 300.0, 300.0, "궁병", 100, 7, 1.0, "ranged", 0.0)
	var enemy := _unit(BattleUnit.Team.ENEMY, 2, 380.0, 450.0, "표적", 100, 0, 1.0, "melee", 0.0)
	sim.add_unit(player)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(enemy.hp, 93, "첫 step에서 1회 공격")
	for i in 4:
		sim.step(0.1)
	eq(enemy.hp, 93, "공격 간격 전에는 추가 피해 없음")
	truthy(player.cooldown > 0.0, "공격 간격이 아직 남아 있음")

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
