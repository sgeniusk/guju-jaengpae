# 병종 상성표와 일반공격 적용을 검증한다.
extends TestCase

func test_type_chart_triangle_and_neutral_pairs() -> void:
	almost(TypeChart.multiplier("cavalry", "archer"), 1.5, 0.001, "기병은 궁병에 강함")
	almost(TypeChart.multiplier("archer", "cavalry"), 0.75, 0.001, "궁병은 기병에 약함")
	almost(TypeChart.multiplier("infantry", "cavalry"), 1.5, 0.001, "보병은 기병에 강함")
	almost(TypeChart.multiplier("cavalry", "infantry"), 0.75, 0.001, "기병은 보병에 약함")
	almost(TypeChart.multiplier("archer", "infantry"), 1.5, 0.001, "궁병은 보병에 강함")
	almost(TypeChart.multiplier("infantry", "archer"), 0.75, 0.001, "보병은 궁병에 약함")
	almost(TypeChart.multiplier("crossbow", "infantry"), 1.5, 0.001, "노병은 보병에 강함")
	almost(TypeChart.multiplier("navy", "infantry"), 1.0, 0.001, "수군은 중립")
	almost(TypeChart.multiplier("fantasy", "cavalry"), 1.0, 0.001, "판타지는 중립")
	almost(TypeChart.multiplier("infantry", "infantry"), 1.0, 0.001, "동일 병종은 중립")

func test_battle_sim_applies_strong_multiplier_to_basic_attack() -> void:
	var sim := BattleSim.new()
	var attacker := _unit(BattleUnit.Team.PLAYER, "cavalry", 40)
	var target := _unit(BattleUnit.Team.ENEMY, "archer", 0)
	sim.add_unit(attacker)
	sim.add_unit(target)
	sim.step(0.1)
	eq(target.hp, 940, "기병 일반공격은 궁병에게 1.5배")

func test_battle_sim_applies_weak_multiplier_to_basic_attack() -> void:
	var sim := BattleSim.new()
	var attacker := _unit(BattleUnit.Team.PLAYER, "archer", 40)
	var target := _unit(BattleUnit.Team.ENEMY, "cavalry", 0)
	sim.add_unit(attacker)
	sim.add_unit(target)
	sim.step(0.1)
	eq(target.hp, 970, "궁병 일반공격은 기병에게 0.75배")

func test_from_card_carries_troop_type() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var card := cat.get_card(&"general_zhaoyun")
	var unit := BattleUnit.from_card(card, BattleUnit.Team.PLAYER, 0, 0.0)
	eq(unit.troop_type, "cavalry", "조운 카드 병종 운반")

func test_skill_damage_ignores_type_chart() -> void:
	var sim := BattleSim.new()
	var caster := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 100.0, "조운", 1000, 0, 999.0, "melee", 0.0, &"caster", &"skill_changban_charge", "cavalry")
	var target := BattleUnit.make(BattleUnit.Team.ENEMY, 0, 240.0, "요사 궁수", 1000, 0, 999.0, "melee", 0.0, &"", &"", "archer")
	sim.add_unit(caster)
	sim.add_unit(target)
	caster.skill_cooldown = 0.0
	sim.step(0.1)
	eq(target.hp, 940, "조운 스킬 피해 60은 상성 1.5배를 받지 않음")

func test_wave_factory_assigns_enemy_troop_types() -> void:
	var found := {
		"사령병": false,
		"사령 증원병": false,
		"요사 궁수": false,
		"마군 정예": false,
	}
	for wave in WaveFactory.default_waves():
		for unit: BattleUnit in wave:
			truthy(not unit.troop_type.is_empty(), "%s 병종 비어있지 않음" % unit.display_name)
			match unit.display_name:
				"사령병":
					eq(unit.troop_type, "infantry", "사령병 병종")
					found["사령병"] = true
				"사령 증원병":
					eq(unit.troop_type, "infantry", "사령 증원병 병종")
					found["사령 증원병"] = true
				"요사 궁수":
					eq(unit.troop_type, "archer", "요사 궁수 병종")
					found["요사 궁수"] = true
				"마군 정예":
					eq(unit.troop_type, "cavalry", "마군 정예 병종")
					found["마군 정예"] = true
	for key in found.keys():
		truthy(found[key], "%s 등장 확인" % key)

func _unit(team: int, troop_type: String, attack: int) -> BattleUnit:
	var x := 100.0 if team == BattleUnit.Team.PLAYER else 120.0
	return BattleUnit.make(team, 0, x, "검증 유닛", 1000, attack, 999.0, "melee", 0.0, &"", &"", troop_type)
