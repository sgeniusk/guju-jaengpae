# WaveFactory의 stage 기반 act 템플릿 선택을 검증한다.
extends TestCase

const _SkillSystem := preload("res://scripts/battle/skill_system.gd")

func test_act_for_stage_uses_five_stage_acts() -> void:
	eq(WaveFactory.act_for_stage(0), 1, "0 이하 stage는 act 1로 보정")
	eq(WaveFactory.act_for_stage(1), 1, "stage 1은 act 1")
	eq(WaveFactory.act_for_stage(5), 1, "첫 보스까지 act 1")
	eq(WaveFactory.act_for_stage(6), 2, "stage 6부터 act 2")
	eq(WaveFactory.act_for_stage(10), 2, "두 번째 보스까지 act 2")
	eq(WaveFactory.act_for_stage(11), 3, "stage 11부터 act 3")

func test_stage_one_keeps_existing_default_wave_shape() -> void:
	var waves := WaveFactory.stage_waves(1)
	eq(waves.size(), 3, "stage 1은 기존 기본 3파도")
	eq((waves[0] as Array)[0].display_name, "사령병", "stage 1 첫 적 이름 유지")
	eq((waves[0] as Array)[0].max_hp, 90, "stage 1은 난이도 배율 1.0")
	eq((waves[2] as Array)[(waves[2] as Array).size() - 1].display_name, "마군 정예", "stage 1 세 번째 파도 정예 유지")

func test_stage_six_uses_act_two_combat_template() -> void:
	var waves := WaveFactory.stage_waves(6)
	var names := _unit_names(waves)
	truthy(names.has("마군 창병"), "act 2 일반 파도는 마군 창병 포함")
	truthy(names.has("마군 돌격대"), "act 2 일반 파도는 돌격대 포함")
	falsy(names.has("사령 증원병"), "act 2 일반 파도는 act 1 증원병 템플릿을 쓰지 않음")
	truthy(_has_unit_with_rule(waves, "마군 돌격대", "lowest_hp"), "act 2 돌격대는 low HP 표적 압박")

func test_stage_ten_boss_wave_uses_act_two_context() -> void:
	var waves := WaveFactory.stage_waves(10)
	eq(waves.size(), 1, "보스 stage는 단일 보스 파도")
	var boss: BattleUnit = (waves[0] as Array)[0]
	eq(boss.display_name, "천공 장각", "stage 10은 장각 보스")
	eq(boss.target_rule, "backline", "장각은 후열 압박")
	eq(boss.skill_id, _SkillSystem.BOSS_SKY_THUNDER, "장각은 천뢰 스킬")
	var names := _unit_names(waves)
	truthy(names.has("황건 부적병"), "act 2 보스 파도는 부적병 호위 포함")
	truthy(names.has("요사 명궁"), "act 2 보스 파도는 명궁 호위 포함")

func test_first_elite_encounter_keeps_ranged_pressure_fast_but_not_spiky() -> void:
	var encounter: Array = WaveFactory.stage_encounter_waves(7)[0]
	var elite := _find_unit(encounter, "마군 정예")
	var archer := _find_unit(encounter, "요사 명궁")
	not_null(elite, "첫 정예 근접 유닛")
	not_null(archer, "첫 정예 원거리 유닛")
	if elite == null or archer == null:
		return
	eq(elite.max_hp, 416, "정예 기병 HP는 stage 7 배율 반영")
	eq(archer.max_hp, 96, "명궁 HP는 첫 정예 템포에 맞게 낮춤")
	eq(archer.attack, 35, "명궁 공격은 성을 과도하게 녹이지 않음")

func test_three_boss_stages_have_distinct_bosses_rules_and_skills() -> void:
	var stage_five: BattleUnit = (WaveFactory.stage_waves(5)[0] as Array)[0]
	var stage_ten: BattleUnit = (WaveFactory.stage_waves(10)[0] as Array)[0]
	var stage_fifteen: BattleUnit = (WaveFactory.stage_waves(15)[0] as Array)[0]
	eq(stage_five.display_name, "마왕 동탁", "첫 보스 동탁")
	eq(stage_five.target_rule, "highest_hp", "동탁은 최대 체력 표적")
	eq(stage_five.skill_id, _SkillSystem.BOSS_TYRANT_ROAR, "동탁 스킬")
	eq(stage_ten.display_name, "천공 장각", "두 번째 보스 장각")
	eq(stage_ten.target_rule, "backline", "장각 target_rule")
	eq(stage_ten.skill_id, _SkillSystem.BOSS_SKY_THUNDER, "장각 스킬")
	eq(stage_fifteen.display_name, "귀신 여포", "세 번째 보스 여포")
	eq(stage_fifteen.target_rule, "lowest_hp", "여포 target_rule")
	eq(stage_fifteen.skill_id, _SkillSystem.BOSS_WAR_GOD_CLEAVE, "여포 스킬")
	truthy(WaveFactory.is_boss_name(stage_ten.display_name), "장각은 보스 이름으로 등록")
	truthy(WaveFactory.is_boss_name(stage_fifteen.display_name), "여포는 보스 이름으로 등록")

func test_later_acts_reuse_last_available_template_until_more_bosses_exist() -> void:
	var act_three := WaveFactory.stage_waves(11)
	var later := WaveFactory.stage_waves(16)
	truthy(_unit_names(act_three).has("요사 술사"), "act 3 템플릿은 술사 포함")
	truthy(_unit_names(later).has("요사 술사"), "후속 act는 새 보스/세력 추가 전까지 마지막 템플릿 재사용")

func _unit_names(waves: Array) -> Array[String]:
	var out: Array[String] = []
	for wave in waves:
		for unit: BattleUnit in wave:
			if not out.has(unit.display_name):
				out.append(unit.display_name)
	return out

func _has_unit_with_rule(waves: Array, display_name: String, target_rule: String) -> bool:
	for wave in waves:
		for unit: BattleUnit in wave:
			if unit.display_name == display_name and unit.target_rule == target_rule:
				return true
	return false

func _find_unit(units: Array, display_name: String) -> BattleUnit:
	for unit: BattleUnit in units:
		if unit.display_name == display_name:
			return unit
	return null
