# 타겟 규칙의 순수 선택과 BattleSim 통합 우선순위를 검증한다.
extends TestCase

const _TargetRules := preload("res://scripts/battle/target_rules.gd")

func test_nearest_rule_picks_closest_enemy() -> void:
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "melee")
	var near_enemy := _unit(BattleUnit.Team.ENEMY, 140.0, 300.0, "가까운 적", 100, 10, "melee")
	var far_enemy := _unit(BattleUnit.Team.ENEMY, 260.0, 300.0, "먼 적", 100, 10, "melee")

	eq(_TargetRules.pick("nearest", attacker, [far_enemy, near_enemy]), near_enemy, "nearest는 2D 최근접")

func test_backline_rule_picks_farthest_enemy() -> void:
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "melee")
	var near_enemy := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "가까운 적", 100, 10, "melee")
	var far_enemy := _unit(BattleUnit.Team.ENEMY, 260.0, 300.0, "후열 적", 100, 10, "melee")

	eq(_TargetRules.pick("backline", attacker, [near_enemy, far_enemy]), far_enemy, "backline은 최원거리")

func test_strongest_ranged_picks_highest_attack_ranged_enemy() -> void:
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "melee")
	var melee_strong := _unit(BattleUnit.Team.ENEMY, 120.0, 300.0, "강한 근접", 100, 99, "melee")
	var ranged_weak := _unit(BattleUnit.Team.ENEMY, 150.0, 300.0, "약한 원거리", 100, 12, "ranged")
	var ranged_strong := _unit(BattleUnit.Team.ENEMY, 260.0, 300.0, "강한 원거리", 100, 25, "ranged")

	eq(_TargetRules.pick("strongest_ranged", attacker, [melee_strong, ranged_weak, ranged_strong]), ranged_strong, "원거리 중 공격력 최대")

func test_strongest_ranged_falls_back_to_nearest_without_ranged_enemy() -> void:
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "melee")
	var near_enemy := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "가까운 근접", 100, 10, "melee")
	var far_enemy := _unit(BattleUnit.Team.ENEMY, 260.0, 300.0, "먼 근접", 100, 99, "melee")

	eq(_TargetRules.pick("strongest_ranged", attacker, [far_enemy, near_enemy]), near_enemy, "원거리 없으면 최근접")

func test_lowest_hp_rule_picks_current_lowest_hp() -> void:
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "melee")
	var wounded := _unit(BattleUnit.Team.ENEMY, 260.0, 300.0, "마무리 표적", 100, 10, "melee")
	wounded.take_damage(75)
	var healthy := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "튼튼한 적", 100, 10, "melee")

	eq(_TargetRules.pick("lowest_hp", attacker, [healthy, wounded]), wounded, "lowest_hp는 현재 hp 최소")

func test_highest_hp_rule_picks_highest_max_hp() -> void:
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "melee")
	var tank := _unit(BattleUnit.Team.ENEMY, 260.0, 300.0, "탱커", 300, 10, "melee")
	var bruiser := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "일반병", 120, 10, "melee")
	tank.take_damage(250)

	eq(_TargetRules.pick("highest_hp", attacker, [bruiser, tank]), tank, "highest_hp는 max_hp 최대")

func test_rule_ties_break_by_nearest_enemy() -> void:
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "melee")
	var near_ranged := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "가까운 원거리", 100, 30, "ranged")
	var far_ranged := _unit(BattleUnit.Team.ENEMY, 260.0, 300.0, "먼 원거리", 100, 30, "ranged")

	eq(_TargetRules.pick("strongest_ranged", attacker, [far_ranged, near_ranged]), near_ranged, "동률은 최근접")

func test_dead_enemies_are_ignored() -> void:
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "melee")
	var dead_near := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "죽은 적", 100, 99, "ranged")
	dead_near.take_damage(100)
	var alive_far := _unit(BattleUnit.Team.ENEMY, 260.0, 300.0, "산 적", 100, 10, "melee")

	eq(_TargetRules.pick("strongest_ranged", attacker, [dead_near, alive_far]), alive_far, "죽은 적 제외 후 fallback")

func test_backline_unit_attacks_far_enemy_in_battle_sim() -> void:
	var sim := BattleSim.new()
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "후열 다이브", 100, 10, "ranged", "backline")
	var near_enemy := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "가까운 적", 100, 0, "melee")
	var far_enemy := _unit(BattleUnit.Team.ENEMY, 250.0, 300.0, "후열 적", 100, 0, "melee")
	sim.add_unit(attacker)
	sim.add_unit(near_enemy)
	sim.add_unit(far_enemy)

	sim.step(0.1)

	eq(far_enemy.hp, 90, "backline 규칙으로 먼 적 공격")
	eq(near_enemy.hp, 100, "가까운 적은 피해 없음")

func test_from_card_carries_target_rule_and_default_is_nearest() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var zhaoyun := BattleUnit.from_card(cat.get_card(&"general_zhaoyun"), BattleUnit.Team.PLAYER, 0, 300.0)
	var infantry := BattleUnit.from_card(cat.get_card(&"troop_infantry"), BattleUnit.Team.PLAYER, 0, 300.0)
	var blank_card := UnitCardData.new()
	blank_card.id = &"blank"
	blank_card.display_name = "기본 카드"
	blank_card.card_type = "troop"
	var blank_unit := BattleUnit.from_card(blank_card, BattleUnit.Team.PLAYER, 0, 300.0)

	eq(zhaoyun.target_rule, "backline", "조운 target_rule 운반")
	eq(infantry.target_rule, "nearest", "보병 target_rule 운반")
	eq(blank_unit.target_rule, "nearest", "미지정 기본값 nearest")

func test_commanded_target_overrides_target_rule_for_controllable_unit() -> void:
	var sim := BattleSim.new()
	var hero := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "장수", 100, 10, "ranged", "backline")
	hero.controllable = true
	var commanded := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "지정 표적", 100, 0, "melee")
	var backline := _unit(BattleUnit.Team.ENEMY, 250.0, 300.0, "후열 표적", 100, 0, "melee")
	hero.commanded_target = commanded
	sim.add_unit(hero)
	sim.add_unit(commanded)
	sim.add_unit(backline)

	sim.step(0.1)

	eq(commanded.hp, 90, "장수 지정 표적이 규칙보다 우선")
	eq(backline.hp, 100, "규칙 표적은 피해 없음")

func test_taunt_overrides_target_rule() -> void:
	var sim := BattleSim.new()
	var attacker := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "공격자", 100, 10, "ranged", "backline")
	var taunter := _unit(BattleUnit.Team.ENEMY, 130.0, 300.0, "도발자", 100, 0, "melee")
	var backline := _unit(BattleUnit.Team.ENEMY, 250.0, 300.0, "후열 표적", 100, 0, "melee")
	attacker.add_status("taunt", 1.0, 0.0, taunter)
	sim.add_unit(attacker)
	sim.add_unit(taunter)
	sim.add_unit(backline)

	sim.step(0.1)

	eq(taunter.hp, 90, "도발이 규칙보다 우선")
	eq(backline.hp, 100, "규칙 표적은 피해 없음")

func _unit(
	team: int,
	px: float,
	py: float,
	display_name: String,
	hp: int,
	attack: int,
	attack_range: String,
	target_rule: String = "nearest"
) -> BattleUnit:
	var unit := BattleUnit.make(team, 0, px, display_name, hp, attack, 999.0, attack_range, 0.0, &"", &"", "infantry", -1, py)
	unit.target_rule = target_rule
	return unit
