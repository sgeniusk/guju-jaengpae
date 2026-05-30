# 장수 skill_id를 그리드 컬럼 전투 효과와 쿨다운으로 연결하는 순수 전투 검증.
extends TestCase

const GUANYU := &"skill_qinglong_strike"
const HUANGZHONG := &"skill_baibu_chuanyang"
const ZHUGELIANG := &"skill_qimen_bagua"
const ZHAOYUN := &"skill_changban_charge"
const ZHANGFEI := &"skill_changban_roar"
const _SkillSystem := preload("res://scripts/battle/skill_system.gd")

func test_has_skill_and_cooldowns_match_table() -> void:
	eq(_SkillSystem.cooldown_for(GUANYU), 5.0, "관우 쿨다운")
	eq(_SkillSystem.cooldown_for(HUANGZHONG), 6.0, "황충 쿨다운")
	eq(_SkillSystem.cooldown_for(ZHUGELIANG), 7.0, "제갈량 쿨다운")
	eq(_SkillSystem.cooldown_for(ZHAOYUN), 6.0, "조운 쿨다운")
	eq(_SkillSystem.cooldown_for(ZHANGFEI), 6.0, "장비 쿨다운")
	truthy(_SkillSystem.has_skill(GUANYU), "표에 있는 스킬 인식")
	falsy(_SkillSystem.has_skill(&""), "빈 스킬 없음")
	falsy(_SkillSystem.has_skill(&"missing_skill"), "모르는 스킬 없음")
	eq(_SkillSystem.cooldown_for(&"missing_skill"), 0.0, "없는 스킬 쿨다운 0")

func test_guanyu_hits_nearest_two_enemies_in_same_column() -> void:
	var sim := BattleSim.new()
	var caster := _caster(GUANYU, _grid_depth(1))
	var near := _enemy(0, _grid_depth(1) + 30.0)
	var mid := _enemy(0, _grid_depth(0))
	var far := _enemy(0, _grid_depth(0) + 180.0)
	_add_ready(sim, caster, [near, mid, far])
	sim.step(0.05)
	eq(near.hp, 9919, "가까운 적 피해")
	eq(mid.hp, 9919, "두 번째 가까운 적 피해")
	eq(far.hp, 9999, "세 번째 적 불변")
	_cast_recorded(sim, caster, GUANYU)

func test_add_unit_initializes_known_skill_cooldown() -> void:
	var sim := BattleSim.new()
	var caster := _caster(GUANYU, _grid_depth(1))
	var troop := _caster(&"", _grid_depth(1))
	sim.add_unit(caster)
	sim.add_unit(troop)
	eq(caster.skill_cooldown, 5.0, "스킬 보유 유닛 첫 쿨다운")
	eq(troop.skill_cooldown, 0.0, "스킬 없는 유닛 쿨다운 불변")

func test_huangzhong_hits_farthest_enemy_in_same_column() -> void:
	var sim := BattleSim.new()
	var caster := _caster(HUANGZHONG, _grid_depth(2))
	var near := _enemy(0, _grid_depth(1))
	var far := _enemy(0, _grid_depth(0) + 240.0)
	_add_ready(sim, caster, [near, far])
	sim.step(0.05)
	eq(near.hp, 9999, "가까운 적 불변")
	eq(far.hp, 9889, "가장 먼 적 피해")
	_cast_recorded(sim, caster, HUANGZHONG)

func test_zhugeliang_hits_all_enemies_only_in_same_column() -> void:
	var sim := BattleSim.new()
	var caster := _caster(ZHUGELIANG, _grid_depth(1))
	var same_a := _enemy(0, _grid_depth(1) + 80.0)
	var same_b := _enemy(0, _grid_depth(0) + 160.0)
	var other_col := _enemy(1, _grid_depth(1) + 80.0)
	_add_ready(sim, caster, [same_a, same_b, other_col])
	sim.step(0.05)
	eq(same_a.hp, 9954, "같은 컬럼 적 A 피해")
	eq(same_b.hp, 9954, "같은 컬럼 적 B 피해")
	eq(other_col.hp, 9999, "다른 컬럼 적 불변")
	_cast_recorded(sim, caster, ZHUGELIANG)

func test_zhaoyun_virtual_charge_hits_enemies_on_path_without_leaving_tile() -> void:
	var sim := BattleSim.new()
	var start_depth := _grid_depth(1)
	var caster := _caster(ZHAOYUN, start_depth)
	var on_path := _enemy(0, start_depth + 150.0)
	var past_path := _enemy(0, start_depth + 260.0)
	var other_col := _enemy(1, start_depth + 150.0)
	_add_ready(sim, caster, [on_path, past_path, other_col])
	sim.step(0.05)
	almost(caster.x, start_depth, 0.001, "조운은 배치 타일을 유지")
	eq(on_path.hp, 9939, "경로 내 적 피해")
	eq(past_path.hp, 9999, "경로 밖 적 불변")
	eq(other_col.hp, 9999, "다른 컬럼 적 불변")
	_cast_recorded(sim, caster, ZHAOYUN)

func test_zhaoyun_virtual_charge_clamps_path_at_far_end() -> void:
	var sim := BattleSim.new()
	var caster := _caster(ZHAOYUN, 900.0)
	var on_path := _enemy(0, 980.0)
	_add_ready(sim, caster, [on_path])
	sim.step(0.05)
	almost(caster.x, 900.0, 0.001, "조운은 clamp 후에도 배치 위치 유지")
	eq(on_path.hp, 9939, "clamp된 경로 내 적 피해")

func test_zhangfei_hits_all_same_column_enemies_and_applies_taunt_weaken() -> void:
	var sim := BattleSim.new()
	var caster := _caster(ZHANGFEI, _grid_depth(1), 300)
	caster.take_damage(120)
	var same_a := _enemy(0, _grid_depth(1) + 80.0)
	var same_b := _enemy(0, _grid_depth(0) + 160.0)
	var other_col := _enemy(1, _grid_depth(1) + 80.0)
	_add_ready(sim, caster, [same_a, same_b, other_col])
	sim.step(0.05)
	eq(same_a.hp, 9974, "같은 컬럼 적 A 피해")
	eq(same_b.hp, 9974, "같은 컬럼 적 B 피해")
	eq(other_col.hp, 9999, "다른 컬럼 적 불변")
	truthy(same_a.has_status("taunt"), "같은 컬럼 적 A 도발")
	truthy(same_a.has_status("weaken"), "같은 컬럼 적 A 약화")
	eq(same_a.taunt_source(), caster, "도발 source는 장비")
	almost(float(same_a.get_status("weaken")["magnitude"]), 0.3, 0.001, "약화 배율")
	truthy(same_b.has_status("taunt"), "같은 컬럼 적 B 도발")
	truthy(same_b.has_status("weaken"), "같은 컬럼 적 B 약화")
	falsy(other_col.has_status("taunt"), "다른 컬럼 적 도발 없음")
	falsy(other_col.has_status("weaken"), "다른 컬럼 적 약화 없음")
	eq(caster.hp, 180, "자가 회복 없음")

func test_cooldown_resets_and_blocks_recast_before_interval() -> void:
	var sim := BattleSim.new()
	var caster := _caster(GUANYU, _grid_depth(1))
	var target := _enemy(0, _grid_depth(1) + 30.0)
	_add_ready(sim, caster, [target])
	sim.step(0.05)
	eq(target.hp, 9919, "첫 발동 피해")
	eq(caster.skill_cooldown, _SkillSystem.cooldown_for(GUANYU), "발동 후 쿨다운 리셋")
	sim.step(1.0)
	eq(target.hp, 9919, "쿨다운 전 재발동 없음")
	eq(sim.last_skill_casts.size(), 0, "재발동 기록 없음")

func test_from_card_carries_skill_id() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var card := cat.get_card(&"general_guanyu")
	var unit := BattleUnit.from_card(card, BattleUnit.Team.PLAYER, 0, _grid_depth(1))
	eq(unit.skill_id, GUANYU, "관우 카드 skill_id 운반")

func _caster(skill_id: StringName, x: float, hp := 9999) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.PLAYER, 0, x, "시전자", hp, 0, 999.0, "melee", 0.0, &"caster", skill_id)

func _enemy(lane: int, x: float) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.ENEMY, lane, x, "표적", 9999, 0, 999.0, "melee", 0.0)

func _add_ready(sim: BattleSim, caster: BattleUnit, enemies: Array) -> void:
	sim.add_unit(caster)
	for enemy in enemies:
		sim.add_unit(enemy)
	caster.skill_cooldown = 0.0

func _cast_recorded(sim: BattleSim, caster: BattleUnit, skill_id: StringName) -> void:
	eq(sim.last_skill_casts.size(), 1, "스킬 발동 기록 1개")
	eq(sim.last_skill_casts[0]["caster"], caster, "시전자 기록")
	eq(sim.last_skill_casts[0]["skill_id"], skill_id, "스킬 id 기록")
	eq(sim.last_skill_casts[0]["lane"], caster.lane, "호환 레인 기록")
	eq(sim.last_skill_casts[0].get("col", -1), caster.lane, "컬럼 기록")

func _grid_depth(row: int) -> float:
	var depths := [360.0, 240.0, 120.0]
	return depths[row]
