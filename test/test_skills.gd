# 장수 skill_id를 오픈필드 2D 전투 효과와 쿨다운으로 연결하는 순수 전투 검증.
extends TestCase

const GUANYU := &"skill_qinglong_strike"
const HUANGZHONG := &"skill_baibu_chuanyang"
const ZHUGELIANG := &"skill_qimen_bagua"
const ZHAOYUN := &"skill_changban_charge"
const ZHANGFEI := &"skill_changban_roar"
const CAOCAO := &"skill_wei_oppress"
const XIAHOUDUN := &"skill_wei_charge"
const SUNQUAN := &"skill_wu_decree"
const ZHOUYU := &"skill_wu_firewall"
const _SkillSystem := preload("res://scripts/battle/skill_system.gd")

func test_has_skill_and_cooldowns_match_table() -> void:
	eq(_SkillSystem.cooldown_for(GUANYU), 5.0, "관우 쿨다운")
	eq(_SkillSystem.cooldown_for(HUANGZHONG), 6.0, "황충 쿨다운")
	eq(_SkillSystem.cooldown_for(ZHUGELIANG), 7.0, "제갈량 쿨다운")
	eq(_SkillSystem.cooldown_for(ZHAOYUN), 6.0, "조운 쿨다운")
	eq(_SkillSystem.cooldown_for(ZHANGFEI), 6.0, "장비 쿨다운")
	eq(_SkillSystem.cooldown_for(CAOCAO), 6.0, "조조 쿨다운")
	eq(_SkillSystem.cooldown_for(XIAHOUDUN), 5.5, "하후돈 쿨다운")
	eq(_SkillSystem.cooldown_for(SUNQUAN), 7.0, "손권 쿨다운")
	eq(_SkillSystem.cooldown_for(ZHOUYU), 6.5, "주유 쿨다운")
	truthy(_SkillSystem.has_skill(GUANYU), "표에 있는 스킬 인식")
	truthy(_SkillSystem.has_skill(CAOCAO), "위압 스킬 인식")
	truthy(_SkillSystem.has_skill(ZHOUYU), "화공 스킬 인식")
	falsy(_SkillSystem.has_skill(&""), "빈 스킬 없음")
	falsy(_SkillSystem.has_skill(&"missing_skill"), "모르는 스킬 없음")
	eq(_SkillSystem.cooldown_for(&"missing_skill"), 0.0, "없는 스킬 쿨다운 0")

func test_guanyu_hits_nearest_two_enemies_by_2d_distance() -> void:
	var sim := BattleSim.new()
	var caster := _caster(GUANYU, 300.0, 300.0)
	var near := _enemy(0, 330.0, 300.0)
	var mid_other_col := _enemy(2, 330.0, 360.0)
	var far_same_col := _enemy(0, 600.0, 300.0)
	_add_ready(sim, caster, [near, mid_other_col, far_same_col])
	sim.step(0.05)
	eq(near.hp, 9919, "가까운 적 피해")
	eq(mid_other_col.hp, 9919, "다른 컬럼이어도 두 번째 가까운 적 피해")
	eq(far_same_col.hp, 9999, "세 번째 적 불변")
	_cast_recorded(sim, caster, GUANYU)

func test_add_unit_initializes_known_skill_cooldown() -> void:
	var sim := BattleSim.new()
	var caster := _caster(GUANYU, 300.0, 300.0)
	var troop := _caster(&"", 300.0, 300.0)
	sim.add_unit(caster)
	sim.add_unit(troop)
	eq(caster.skill_cooldown, 5.0, "스킬 보유 유닛 첫 쿨다운")
	eq(troop.skill_cooldown, 0.0, "스킬 없는 유닛 쿨다운 불변")

func test_huangzhong_hits_farthest_enemy_by_2d_distance() -> void:
	var sim := BattleSim.new()
	var caster := _caster(HUANGZHONG, 300.0, 300.0)
	var near := _enemy(0, 380.0, 300.0)
	var far := _enemy(2, 760.0, 450.0)
	_add_ready(sim, caster, [near, far])
	sim.step(0.05)
	eq(near.hp, 9999, "가까운 적 불변")
	eq(far.hp, 9889, "가장 먼 적 피해")
	_cast_recorded(sim, caster, HUANGZHONG)

func test_zhugeliang_hits_enemies_in_radius_around_nearest_target() -> void:
	var sim := BattleSim.new()
	var caster := _caster(ZHUGELIANG, 300.0, 300.0)
	var cluster_a := _enemy(0, 380.0, 300.0)
	var cluster_b := _enemy(2, 450.0, 360.0)
	var far := _enemy(1, 800.0, 300.0)
	_add_ready(sim, caster, [cluster_a, cluster_b, far])
	sim.step(0.05)
	eq(cluster_a.hp, 9954, "대상 반경 적 A 피해")
	eq(cluster_b.hp, 9954, "대상 반경 적 B 피해")
	eq(far.hp, 9999, "반경 밖 적 불변")
	_cast_recorded(sim, caster, ZHUGELIANG)

func test_zhaoyun_virtual_charge_hits_enemies_on_forward_2d_path_without_moving() -> void:
	var sim := BattleSim.new()
	var caster := _caster(ZHAOYUN, 240.0, 300.0)
	var on_path := _enemy(0, 390.0, 350.0)
	var past_path := _enemy(0, 500.0, 300.0)
	var side_path := _enemy(2, 390.0, 390.0)
	_add_ready(sim, caster, [on_path, past_path, side_path])
	sim.step(0.05)
	almost(caster.px, 240.0, 0.001, "조운은 배치 위치 x를 유지")
	almost(caster.py, 300.0, 0.001, "조운은 배치 위치 y를 유지")
	eq(on_path.hp, 9939, "전방 경로 내 적 피해")
	eq(past_path.hp, 9999, "전방 길이 밖 적 불변")
	eq(side_path.hp, 9999, "경로 폭 밖 적 불변")
	_cast_recorded(sim, caster, ZHAOYUN)

func test_zhaoyun_virtual_charge_hits_path_near_enemy_side() -> void:
	var sim := BattleSim.new()
	var caster := _caster(ZHAOYUN, 900.0, 300.0)
	var on_path := _enemy(0, 980.0, 300.0)
	_add_ready(sim, caster, [on_path])
	sim.step(0.05)
	almost(caster.px, 900.0, 0.001, "조운은 전방 경로 피해 후에도 위치 유지")
	eq(on_path.hp, 9939, "적 진영 근처 경로 내 적 피해")

func test_zhangfei_hits_radius_enemies_and_applies_taunt_weaken() -> void:
	var sim := BattleSim.new()
	var caster := _caster(ZHANGFEI, 300.0, 300.0, 300)
	caster.take_damage(120)
	var near_a := _enemy(0, 380.0, 300.0)
	var near_b := _enemy(2, 430.0, 430.0)
	var far := _enemy(1, 620.0, 300.0)
	_add_ready(sim, caster, [near_a, near_b, far])
	sim.step(0.05)
	eq(near_a.hp, 9974, "반경 내 적 A 피해")
	eq(near_b.hp, 9974, "반경 내 적 B 피해")
	eq(far.hp, 9999, "반경 밖 적 불변")
	truthy(near_a.has_status("taunt"), "반경 내 적 A 도발")
	truthy(near_a.has_status("weaken"), "반경 내 적 A 약화")
	eq(near_a.taunt_source(), caster, "도발 source는 장비")
	almost(float(near_a.get_status("weaken")["magnitude"]), 0.3, 0.001, "약화 배율")
	truthy(near_b.has_status("taunt"), "반경 내 적 B 도발")
	truthy(near_b.has_status("weaken"), "반경 내 적 B 약화")
	falsy(far.has_status("taunt"), "반경 밖 적 도발 없음")
	falsy(far.has_status("weaken"), "반경 밖 적 약화 없음")
	eq(caster.hp, 180, "자가 회복 없음")

func test_caocao_oppress_hits_radius_enemies_and_applies_only_weaken() -> void:
	var sim := BattleSim.new()
	var caster := _caster(CAOCAO, 300.0, 300.0)
	var near_a := _enemy(0, 380.0, 300.0)
	var near_b := _enemy(2, 430.0, 390.0)
	var far := _enemy(1, 500.0, 300.0)
	_add_ready(sim, caster, [near_a, near_b, far])
	sim.step(0.05)
	eq(near_a.hp, 9954, "위압 반경 내 적 A 피해")
	eq(near_b.hp, 9954, "위압 반경 내 적 B 피해")
	eq(far.hp, 9999, "위압 반경 밖 적 불변")
	truthy(near_a.has_status("weaken"), "반경 내 적 A 약화")
	almost(float(near_a.get_status("weaken")["magnitude"]), 0.3, 0.001, "위압 약화 배율")
	falsy(near_a.has_status("taunt"), "위압은 도발 없음")
	falsy(far.has_status("weaken"), "반경 밖 적 약화 없음")
	_cast_recorded(sim, caster, CAOCAO)

func test_xiahoudun_charge_hits_forward_rectangle() -> void:
	var sim := BattleSim.new()
	var caster := _caster(XIAHOUDUN, 240.0, 300.0)
	var on_path := _enemy(0, 460.0, 365.0)
	var past_path := _enemy(0, 500.0, 300.0)
	var side_path := _enemy(2, 380.0, 370.1)
	var behind := _enemy(1, 220.0, 300.0)
	_add_ready(sim, caster, [on_path, past_path, side_path, behind])
	sim.step(0.05)
	eq(on_path.hp, 9924, "발돌 전방 직사각형 내 적 피해")
	eq(past_path.hp, 9999, "발돌 전방 길이 밖 적 불변")
	eq(side_path.hp, 9999, "발돌 폭 밖 적 불변")
	eq(behind.hp, 9999, "발돌 후방 적 불변")
	_cast_recorded(sim, caster, XIAHOUDUN)

func test_sunquan_decree_hits_highest_max_hp_enemy() -> void:
	var sim := BattleSim.new()
	var caster := _caster(SUNQUAN, 300.0, 300.0)
	var bruiser := _enemy(0, 360.0, 300.0, 1400)
	var tank := _enemy(1, 760.0, 300.0, 2200)
	var wounded := _enemy(2, 380.0, 360.0, 1800)
	wounded.take_damage(900)
	_add_ready(sim, caster, [bruiser, tank, wounded])
	sim.step(0.05)
	eq(bruiser.hp, 1400, "결단 낮은 max_hp 적 불변")
	eq(tank.hp, 2070, "결단 max_hp 최고 적 피해")
	eq(wounded.hp, 900, "결단 현재 hp가 낮아도 max_hp 기준")
	_cast_recorded(sim, caster, SUNQUAN)

func test_zhouyu_firewall_hits_enemies_in_radius_around_nearest_target() -> void:
	var sim := BattleSim.new()
	var caster := _caster(ZHOUYU, 300.0, 300.0)
	var center := _enemy(0, 380.0, 300.0)
	var cluster := _enemy(2, 520.0, 430.0)
	var far := _enemy(1, 620.0, 300.0)
	_add_ready(sim, caster, [center, cluster, far])
	sim.step(0.05)
	eq(center.hp, 9934, "화공 중심 적 피해")
	eq(cluster.hp, 9934, "화공 반경 내 적 피해")
	eq(far.hp, 9999, "화공 반경 밖 적 불변")
	_cast_recorded(sim, caster, ZHOUYU)

func test_cooldown_resets_and_blocks_recast_before_interval() -> void:
	var sim := BattleSim.new()
	var caster := _caster(GUANYU, 300.0, 300.0)
	var target := _enemy(0, 330.0, 300.0)
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
	var unit := BattleUnit.from_card(card, BattleUnit.Team.PLAYER, 0, 300.0)
	eq(unit.skill_id, GUANYU, "관우 카드 skill_id 운반")

func test_wei_wu_general_cards_carry_skill_ids() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	eq(BattleUnit.from_card(cat.get_card(&"general_caocao"), BattleUnit.Team.PLAYER, 0, 300.0).skill_id, CAOCAO, "조조 카드 skill_id 운반")
	eq(BattleUnit.from_card(cat.get_card(&"general_xiahoudun"), BattleUnit.Team.PLAYER, 0, 300.0).skill_id, XIAHOUDUN, "하후돈 카드 skill_id 운반")
	eq(BattleUnit.from_card(cat.get_card(&"general_sunquan"), BattleUnit.Team.PLAYER, 0, 300.0).skill_id, SUNQUAN, "손권 카드 skill_id 운반")
	eq(BattleUnit.from_card(cat.get_card(&"general_zhouyu"), BattleUnit.Team.PLAYER, 0, 300.0).skill_id, ZHOUYU, "주유 카드 skill_id 운반")

func _caster(skill_id: StringName, px: float, py: float, hp := 9999) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.PLAYER, 0, px, "시전자", hp, 0, 999.0, "melee", 0.0, &"caster", skill_id, "infantry", -1, py)

func _enemy(lane: int, px: float, py: float, hp := 9999) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.ENEMY, lane, px, "표적", hp, 0, 999.0, "melee", 0.0, &"", &"", "infantry", -1, py)

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
	almost(float(sim.last_skill_casts[0].get("px", -1.0)), caster.px, 0.001, "시전자 x 기록")
	almost(float(sim.last_skill_casts[0].get("py", -1.0)), caster.py, 0.001, "시전자 y 기록")
