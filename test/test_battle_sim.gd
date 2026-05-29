# BattleSim의 승패 판정과 결정적 교전 규칙을 검증한다.
extends TestCase

func test_enemy_at_base_loses_immediately() -> void:
	var sim := BattleSim.new()
	sim.add_unit(BattleUnit.make(BattleUnit.Team.ENEMY, 0, 0.0, "침입자", 10, 1, 1.0, "melee", 0.0))
	sim.step(0.1)
	eq(sim.result, BattleSim.Result.PLAYER_LOSE, "적이 기지에 닿으면 패배")

func test_enemy_only_loses_after_one_step() -> void:
	var sim := BattleSim.new()
	sim.add_unit(BattleUnit.make(BattleUnit.Team.ENEMY, 0, 900.0, "사령병", 10, 1, 1.0, "melee", 0.0))
	sim.step(0.1)
	eq(sim.result, BattleSim.Result.PLAYER_LOSE, "아군이 없으면 패배")

func test_liubei_starting_deck_beats_wave_one() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(&"lord_liubei")
	var sim := BattleSim.new()
	var lane := 0
	for card_id in cat.get_lord_deck(lord):
		sim.add_unit(cat.build_player_unit(card_id, lane, 40.0 + lane * 10.0, lord))
		lane = (lane + 1) % BattleSim.LANE_COUNT
	for enemy in WaveFactory.wave_one():
		sim.add_unit(enemy)
	var result := sim.run_to_completion(0.1, 120.0)
	eq(result, BattleSim.Result.PLAYER_WIN, "유비 시작 덱은 파도 1을 막아야 함")
	truthy(sim.enemy_units.is_empty(), "승리 후 적 전멸")

func test_melee_units_apply_damage_and_death() -> void:
	var sim := BattleSim.new()
	var player := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 100.0, "검병", 50, 25, 1.0, "melee", 0.0)
	var enemy := BattleUnit.make(BattleUnit.Team.ENEMY, 0, 120.0, "약한 적", 20, 0, 1.0, "melee", 0.0)
	sim.add_unit(player)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(sim.enemy_units.size(), 0, "근접 공격으로 사망한 적 제거")
	eq(sim.result, BattleSim.Result.PLAYER_WIN, "적 사망 후 승리")
	eq(player.hp, 50, "공격력 0인 적은 피해를 주지 않음")

func test_player_only_wins_after_one_step() -> void:
	var sim := BattleSim.new()
	sim.add_unit(BattleUnit.make(BattleUnit.Team.PLAYER, 0, 100.0, "아군", 10, 1, 1.0, "melee", 0.0))
	sim.step(0.1)
	eq(sim.result, BattleSim.Result.PLAYER_WIN, "적이 없으면 승리")

func test_unit_cooldown_limits_attacks_until_interval_passes() -> void:
	var sim := BattleSim.new()
	var player := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 100.0, "궁병", 100, 7, 1.0, "ranged", 0.0)
	var enemy := BattleUnit.make(BattleUnit.Team.ENEMY, 0, 120.0, "표적", 100, 0, 1.0, "melee", 0.0)
	sim.add_unit(player)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(enemy.hp, 93, "첫 step에서 1회 공격")
	for i in 4:
		sim.step(0.1)
	eq(enemy.hp, 93, "공격 간격 전에는 추가 피해 없음")
	truthy(player.cooldown > 0.0, "공격 간격이 아직 남아 있음")
