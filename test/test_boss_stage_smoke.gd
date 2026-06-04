# 보스 스테이지가 WaveFactory -> BattleSim 순수 경로에서 끝까지 결판나는지 검증한다.
extends TestCase

const _SkillSystem := preload("res://scripts/battle/skill_system.gd")

func test_each_boss_stage_runs_as_pure_simulation() -> void:
	for boss_case in _boss_cases():
		var stage := int(boss_case["stage"])
		var sim := BattleSim.new()
		var castle := sim.add_castle(12000, "테스트 성")
		_add_overpowered_test_army(sim)

		sim.set_waves(WaveFactory.stage_waves(stage))
		eq(sim.wave_total, 1, "stage %d 보스는 단일 파도" % stage)
		var boss := _first_boss(sim.enemy_units)
		not_null(boss, "stage %d 보스 유닛 존재" % stage)
		if boss == null:
			continue
		eq(boss.display_name, String(boss_case["name"]), "stage %d 보스 이름" % stage)
		eq(boss.target_rule, String(boss_case["target_rule"]), "stage %d 보스 표적 규칙" % stage)
		eq(boss.skill_id, StringName(boss_case["skill_id"]), "stage %d 보스 스킬" % stage)

		boss.skill_cooldown = 0.0
		sim.step(0.05)
		truthy(_last_cast_has(sim, StringName(boss_case["skill_id"])), "stage %d 보스 스킬이 순수 sim에서 발동 가능" % stage)

		var result := sim.run_to_completion(0.1, 180.0)
		eq(result, BattleSim.Result.PLAYER_WIN, "stage %d 보스 순수 sim 승리" % stage)
		truthy(castle.is_alive(), "stage %d 승리 후 성 생존" % stage)
		truthy(sim.enemy_units.is_empty(), "stage %d 승리 후 적 전멸" % stage)

func _boss_cases() -> Array:
	return [
		{
			"stage": 5,
			"name": "마왕 동탁",
			"target_rule": "highest_hp",
			"skill_id": _SkillSystem.BOSS_TYRANT_ROAR,
		},
		{
			"stage": 10,
			"name": "천공 장각",
			"target_rule": "backline",
			"skill_id": _SkillSystem.BOSS_SKY_THUNDER,
		},
		{
			"stage": 15,
			"name": "귀신 여포",
			"target_rule": "lowest_hp",
			"skill_id": _SkillSystem.BOSS_WAR_GOD_CLEAVE,
		},
	]

func _add_overpowered_test_army(sim: BattleSim) -> void:
	var index := 0
	for row in range(3, 6):
		for col in BattleSim.COL_COUNT:
			var start := BattleSim.position_for_tile(col, row)
			var unit := BattleUnit.make(
				BattleUnit.Team.PLAYER,
				col,
				start.x,
				"테스트 정예 %d" % index,
				5000,
				320,
				0.35,
				"ranged",
				120.0,
				&"",
				&"",
				"infantry",
				row,
				start.y
			)
			sim.add_unit(unit)
			index += 1

func _first_boss(units: Array) -> BattleUnit:
	for unit: BattleUnit in units:
		if WaveFactory.is_boss_name(unit.display_name):
			return unit
	return null

func _last_cast_has(sim: BattleSim, skill_id: StringName) -> bool:
	for cast in sim.last_skill_casts:
		if StringName(cast.get("skill_id", &"")) == skill_id:
			return true
	return false
