# 영웅 조작 표적 지정 규칙을 순수 전투 시뮬레이션에서 검증한다.
extends TestCase

func test_commanded_target_overrides_nearest_enemy_for_hero() -> void:
	var sim := BattleSim.new()
	var hero := _unit(BattleUnit.Team.PLAYER, 300.0, 300.0, "장수", 100, 10, 999.0, "ranged", 0.0, true)
	var near_enemy := _unit(BattleUnit.Team.ENEMY, 330.0, 300.0, "가까운 적", 100, 0, 999.0, "melee", 0.0, false)
	var far_enemy := _unit(BattleUnit.Team.ENEMY, 500.0, 300.0, "지정 적", 100, 0, 999.0, "melee", 0.0, false)
	hero.set("commanded_target", far_enemy)
	sim.add_unit(hero)
	sim.add_unit(near_enemy)
	sim.add_unit(far_enemy)
	sim.step(0.1)
	eq(far_enemy.hp, 90, "장수는 더 먼 지정 표적을 공격")
	eq(near_enemy.hp, 100, "가까운 적은 피해 없음")

func test_dead_commanded_target_falls_back_to_nearest_enemy() -> void:
	var sim := BattleSim.new()
	var hero := _unit(BattleUnit.Team.PLAYER, 300.0, 300.0, "장수", 100, 10, 999.0, "ranged", 0.0, true)
	var near_enemy := _unit(BattleUnit.Team.ENEMY, 330.0, 300.0, "가까운 적", 100, 0, 999.0, "melee", 0.0, false)
	var dead_enemy := _unit(BattleUnit.Team.ENEMY, 500.0, 300.0, "죽은 지정 적", 100, 0, 999.0, "melee", 0.0, false)
	dead_enemy.take_damage(100)
	hero.set("commanded_target", dead_enemy)
	sim.add_unit(hero)
	sim.add_unit(near_enemy)
	sim.add_unit(dead_enemy)
	sim.step(0.1)
	eq(near_enemy.hp, 90, "죽은 지정 표적은 무시하고 최근접 공격")
	eq(dead_enemy.hp, 0, "죽은 지정 표적은 그대로")

func test_non_controllable_unit_ignores_commanded_target() -> void:
	var sim := BattleSim.new()
	var troop := _unit(BattleUnit.Team.PLAYER, 300.0, 300.0, "병종", 100, 10, 999.0, "ranged", 0.0, false)
	var near_enemy := _unit(BattleUnit.Team.ENEMY, 330.0, 300.0, "가까운 적", 100, 0, 999.0, "melee", 0.0, false)
	var far_enemy := _unit(BattleUnit.Team.ENEMY, 500.0, 300.0, "지정 적", 100, 0, 999.0, "melee", 0.0, false)
	troop.set("commanded_target", far_enemy)
	sim.add_unit(troop)
	sim.add_unit(near_enemy)
	sim.add_unit(far_enemy)
	sim.step(0.1)
	eq(near_enemy.hp, 90, "병종은 수동 지정이 있어도 최근접 공격")
	eq(far_enemy.hp, 100, "병종의 지정 표적은 피해 없음")

func test_from_card_marks_generals_controllable_only() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var general := BattleUnit.from_card(cat.get_card(&"general_guanyu"), BattleUnit.Team.PLAYER, 0, 300.0)
	var troop := BattleUnit.from_card(cat.get_card(&"troop_infantry"), BattleUnit.Team.PLAYER, 0, 300.0)
	truthy(general.get("controllable") == true, "장수 카드는 조작 가능")
	truthy(troop.get("controllable") == false, "병종 카드는 조작 불가")

func test_switching_commanded_target_does_not_reset_attack_cooldown() -> void:
	var sim := BattleSim.new()
	var hero := _unit(BattleUnit.Team.PLAYER, 300.0, 300.0, "장수", 100, 10, 1.0, "ranged", 0.0, true)
	var first_enemy := _unit(BattleUnit.Team.ENEMY, 330.0, 300.0, "첫 표적", 100, 0, 999.0, "melee", 0.0, false)
	var second_enemy := _unit(BattleUnit.Team.ENEMY, 500.0, 300.0, "새 표적", 100, 0, 999.0, "melee", 0.0, false)
	hero.set("commanded_target", first_enemy)
	sim.add_unit(hero)
	sim.add_unit(first_enemy)
	sim.add_unit(second_enemy)
	sim.step(0.1)
	eq(first_enemy.hp, 90, "첫 공격은 지정 표적에 적용")
	truthy(hero.cooldown > 0.0, "공격 후 쿨다운 진행")
	hero.set("commanded_target", second_enemy)
	sim.step(0.1)
	eq(second_enemy.hp, 100, "표적 변경은 즉시 추가 공격을 만들지 않음")
	truthy(hero.cooldown > 0.0, "표적 변경 후에도 쿨다운 유지")

func _unit(
	team: int,
	px: float,
	py: float,
	display_name: String,
	hp: int,
	attack: int,
	interval: float,
	attack_range: String,
	speed: float,
	controllable: bool
) -> BattleUnit:
	var unit := BattleUnit.make(team, 0, px, display_name, hp, attack, interval, attack_range, speed, &"", &"", "infantry", -1, py)
	unit.set("controllable", controllable)
	return unit
