# 상태이상 모델과 전투 적용을 검증한다.
extends TestCase

func test_add_status_get_status_and_tick_expiry() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 100.0, "장수", 100, 10, 1.0, "melee", 0.0)
	var source := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 120.0, "시전자", 100, 10, 1.0, "melee", 0.0)
	unit.add_status("taunt", 2.5, 0.0, source)
	truthy(unit.has_status("taunt"), "도발 보유")
	var taunt: Dictionary = unit.get_status("taunt")
	eq(taunt["type"], "taunt", "상태 type 보존")
	almost(float(taunt["remaining"]), 2.5, 0.001, "상태 남은 시간")
	eq(taunt["source"], source, "상태 source 보존")
	unit.add_status("taunt", 1.0, 0.0, source)
	eq(unit.statuses.size(), 1, "같은 type은 중첩되지 않음")
	almost(float(unit.get_status("taunt")["remaining"]), 2.5, 0.001, "짧은 재적용은 남은 시간 유지")
	unit.tick_statuses(2.4)
	truthy(unit.has_status("taunt"), "만료 전 유지")
	unit.tick_statuses(0.1)
	falsy(unit.has_status("taunt"), "2.5초 후 만료")
	eq(unit.get_status("taunt"), {}, "없는 상태는 빈 Dictionary")

func test_effective_attack_applies_weaken_and_cap() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 100.0, "검병", 100, 100, 1.0, "melee", 0.0)
	eq(unit.effective_attack(), 100, "약화 없으면 원 공격력")
	unit.add_status("weaken", 2.5, 0.3)
	eq(unit.effective_attack(), 70, "30% 약화 적용")
	unit.add_status("weaken", 2.5, 2.0)
	eq(unit.effective_attack(), 10, "약화는 90%로 cap")

func test_taunt_forces_target_over_nearer_enemy() -> void:
	var sim := BattleSim.new()
	var taunter := _player_at(100.0, "장비")
	var nearer := _player_at(120.0, "가까운 아군")
	var enemy := _enemy_at(130.0)
	enemy.add_status("taunt", 2.5, 0.0, taunter)
	sim.add_unit(taunter)
	sim.add_unit(nearer)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(taunter.hp, 80, "도발 source가 공격받음")
	eq(nearer.hp, 100, "더 가까운 아군은 피해 없음")

func test_taunt_ignored_when_source_is_dead() -> void:
	var sim := BattleSim.new()
	var taunter := _player_at(100.0, "쓰러진 장비")
	var nearer := _player_at(120.0, "가까운 아군")
	var enemy := _enemy_at(130.0)
	taunter.take_damage(100)
	enemy.add_status("taunt", 2.5, 0.0, taunter)
	sim.add_unit(taunter)
	sim.add_unit(nearer)
	sim.add_unit(enemy)
	sim.step(0.1)
	eq(taunter.hp, 0, "죽은 source는 그대로")
	eq(nearer.hp, 80, "일반 최근접 타겟으로 복귀")

func _player_at(x: float, name: String) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.PLAYER, 0, x, name, 100, 0, 999.0, "melee", 0.0)

func _enemy_at(x: float) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.ENEMY, 0, x, "적", 100, 20, 999.0, "melee", 0.0)
