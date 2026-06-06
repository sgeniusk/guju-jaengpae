# 데미지 이벤트 노출이 전투 결과를 바꾸지 않고 실제 피해와 일치하는지 검증한다.
extends TestCase

const GUANYU := &"skill_qinglong_strike"

func test_attack_damage_event_matches_hp_loss_and_crit_fields() -> void:
	var sim := BattleSim.new()
	var attacker := _unit(BattleUnit.Team.PLAYER, 0, 300.0, 300.0, "검병", 100, 10, 1.0, "melee", 0.0, "infantry")
	var target := _unit(BattleUnit.Team.ENEMY, 0, 324.0, 300.0, "기병", 100, 0, 1.0, "melee", 0.0, "cavalry")
	sim.add_unit(attacker)
	sim.add_unit(target)
	var before_hp := target.hp

	sim.step(0.1)

	var event := _first_positive_event_for(sim.last_damage_events, target)
	not_null(event, "일반공격 양수 피해 이벤트 존재")
	eq(event.get("target"), target, "피격 대상 기록")
	eq(event.get("amount"), before_hp - target.hp, "이벤트 피해량은 실제 HP 손실")
	eq(event.get("amount"), 15, "상성 배수 피해량 기록")
	eq(event.get("team"), BattleUnit.Team.ENEMY, "피격 팀 기록")
	eq(event.get("kind"), "attack", "일반공격 kind 기록")
	eq(event.get("attacker"), attacker, "공격자 기록")
	eq(event.get("attacker_team"), BattleUnit.Team.PLAYER, "공격자 팀 기록")
	eq(event.get("attack_range"), "melee", "공격 사거리 종류 기록")
	truthy(bool(event.get("is_crit", false)), "강상성은 크리 표시")
	almost(float(event.get("px", 0.0)), target.px, 0.001, "피격 x 기록")
	almost(float(event.get("py", 0.0)), target.py, 0.001, "피격 y 기록")
	almost(float(event.get("attacker_px", 0.0)), attacker.px, 0.001, "공격자 x 기록")
	almost(float(event.get("attacker_py", 0.0)), attacker.py, 0.001, "공격자 y 기록")

func test_damage_events_clear_each_step() -> void:
	var sim := BattleSim.new()
	var attacker := _unit(BattleUnit.Team.PLAYER, 0, 300.0, 300.0, "궁병", 100, 7, 1.0, "ranged", 0.0, "archer")
	var target := _unit(BattleUnit.Team.ENEMY, 0, 380.0, 300.0, "표적", 100, 0, 1.0, "melee", 0.0, "infantry")
	sim.add_unit(attacker)
	sim.add_unit(target)

	sim.step(0.1)
	truthy(not _positive_events(sim.last_damage_events).is_empty(), "첫 step 공격 기록")
	sim.step(0.1)
	eq(sim.last_damage_events.size(), 0, "다음 step 시작 때 이전 이벤트 clear")

func test_skill_damage_events_match_actual_hp_loss() -> void:
	var sim := BattleSim.new()
	var caster := _unit(BattleUnit.Team.PLAYER, 0, 300.0, 300.0, "관우", 9999, 0, 999.0, "melee", 0.0, "infantry", GUANYU)
	var near := _unit(BattleUnit.Team.ENEMY, 0, 330.0, 300.0, "가까운 적", 9999, 0, 999.0, "melee", 0.0, "infantry")
	var mid := _unit(BattleUnit.Team.ENEMY, 0, 360.0, 300.0, "두 번째 적", 9999, 0, 999.0, "melee", 0.0, "infantry")
	var far := _unit(BattleUnit.Team.ENEMY, 0, 700.0, 300.0, "먼 적", 9999, 0, 999.0, "melee", 0.0, "infantry")
	sim.add_unit(caster)
	sim.add_unit(near)
	sim.add_unit(mid)
	sim.add_unit(far)
	caster.skill_cooldown = 0.0
	var near_before := near.hp
	var mid_before := mid.hp
	var far_before := far.hp

	sim.step(0.05)

	var skill_total := 0
	for event in sim.last_damage_events:
		if String(event.get("kind", "")) == "skill":
			skill_total += int(event.get("amount", 0))
			eq(event.get("team"), BattleUnit.Team.ENEMY, "스킬 피격 팀 기록")
			falsy(bool(event.get("is_crit", true)), "스킬 이벤트는 기본 크리 아님")
	eq(skill_total, (near_before - near.hp) + (mid_before - mid.hp) + (far_before - far.hp), "스킬 이벤트 합은 실제 HP 손실 합")

func test_observing_damage_events_does_not_change_completion_result() -> void:
	var direct := _duel_sim()
	var observed := _duel_sim()

	var direct_result := direct.run_to_completion(0.1, 20.0)
	var observed_result := _run_to_completion_observing_events(observed, 0.1, 20.0)

	eq(observed_result, direct_result, "이벤트를 읽어도 완주 결과 동일")
	eq(observed.player_units.size(), direct.player_units.size(), "완주 후 아군 수 동일")
	eq(observed.enemy_units.size(), direct.enemy_units.size(), "완주 후 적군 수 동일")
	eq(_remaining_hp(observed.player_units), _remaining_hp(direct.player_units), "완주 후 아군 HP 합 동일")
	eq(_remaining_hp(observed.enemy_units), _remaining_hp(direct.enemy_units), "완주 후 적군 HP 합 동일")

func _run_to_completion_observing_events(sim: BattleSim, dt: float, max_time: float) -> int:
	var t := 0.0
	var observed_total := 0
	while not sim.is_over() and t < max_time:
		sim.step(dt)
		for event in sim.last_damage_events:
			observed_total += int(event.get("amount", 0))
		t += dt
	truthy(observed_total > 0, "관찰 경로에서 이벤트를 실제로 읽음")
	return sim.result

func _duel_sim() -> BattleSim:
	var sim := BattleSim.new()
	sim.add_unit(_unit(BattleUnit.Team.PLAYER, 0, 300.0, 300.0, "아군", 130, 18, 0.5, "melee", 0.0, "infantry"))
	sim.add_unit(_unit(BattleUnit.Team.ENEMY, 0, 324.0, 300.0, "적", 95, 11, 0.5, "melee", 0.0, "cavalry"))
	return sim

func _remaining_hp(units: Array[BattleUnit]) -> int:
	var total := 0
	for unit in units:
		total += unit.hp
	return total

func _first_positive_event_for(events: Array, target: BattleUnit) -> Dictionary:
	for event in events:
		if event.get("target") == target and int(event.get("amount", 0)) > 0:
			return event
	return {}

func _positive_events(events: Array) -> Array:
	var out := []
	for event in events:
		if int(event.get("amount", 0)) > 0:
			out.append(event)
	return out

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
	speed: float,
	troop_type: String,
	skill_id: StringName = &""
) -> BattleUnit:
	return BattleUnit.make(team, lane, px, display_name, hp, attack, interval, attack_range, speed, &"", skill_id, troop_type, -1, py)
