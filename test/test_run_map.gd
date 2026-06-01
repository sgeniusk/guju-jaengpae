# 선형 스테이지 진행과 stage 기반 파도 연결을 검증한다.
extends TestCase

func before_each() -> void:
	RunManager.reset_run()

func test_run_state_starts_at_stage_one_and_advances_linearly() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var run := RunState.new()
	run.start_run(cat.get_lord(&"lord_liubei"), cat)

	eq(run.stage_index, 1, "start_run은 stage 1")
	run.advance_stage()
	eq(run.stage_index, 2, "advance_stage는 +1")
	run.advance_stage()
	eq(run.stage_index, 3, "반복 호출은 선형 증가")

func test_run_state_no_longer_owns_branch_map() -> void:
	var run := RunState.new()
	falsy(_has_property(run, "map"), "RunState.map 제거")
	eq(run.command_points, 12, "지휘력 기본값은 유지")

func test_run_manager_exposes_linear_stage_api() -> void:
	RunManager.ensure_started(&"lord_liubei")
	eq(RunManager.stage_index(), 1, "초기 stage")
	falsy(RunManager.is_boss_stage(), "stage 1은 보스 아님")
	falsy(RunManager.is_shop_stage(), "stage 1은 상점 아님")
	falsy(RunManager.is_expand_stage(), "stage 1은 확장 아님")
	almost(RunManager.difficulty_scale(), 1.0, 0.0001, "stage 1 배율")
	truthy(not RunManager.current_waves().is_empty(), "현재 파도 제공")

	RunManager.advance_stage()
	RunManager.advance_stage()
	RunManager.advance_stage()
	eq(RunManager.stage_index(), 4, "stage 4 도달")
	truthy(RunManager.is_shop_stage(), "stage 4는 상점 예측자만 true")
	falsy(RunManager.is_boss_stage(), "stage 4는 보스 아님")

	RunManager.advance_stage()
	eq(RunManager.stage_index(), 5, "stage 5 도달")
	truthy(RunManager.is_boss_stage(), "stage 5는 보스")
	truthy(RunManager.is_expand_stage(), "stage 5는 확장 예측자")
	almost(RunManager.difficulty_scale(), 1.48, 0.0001, "stage 5 배율")

func test_branch_run_manager_methods_are_removed() -> void:
	for method in [
		"available_nodes",
		"choose_node",
		"complete_node",
		"active_node_type",
		"active_is_battle",
		"map_finished",
		"node_label",
		"add_command_points",
	]:
		falsy(RunManager.has_method(method), "%s 제거" % method)

func test_stage_waves_scale_default_waves_by_stage() -> void:
	var stage_one := WaveFactory.stage_waves(1)
	var stage_three := WaveFactory.stage_waves(3)

	eq(stage_one.size(), 3, "일반 stage는 기본 3파도")
	eq(stage_three.size(), 3, "비보스 stage도 기본 3파도")
	truthy(_total_hp(stage_three) > _total_hp(stage_one), "stage 증가로 hp 증가")
	truthy(_total_attack(stage_three) > _total_attack(stage_one), "stage 증가로 공격 증가")
	eq(_total_hp(stage_three), _total_hp(WaveFactory.stage_waves(3)), "같은 stage hp 결정적")
	eq(_total_attack(stage_three), _total_attack(WaveFactory.stage_waves(3)), "같은 stage 공격 결정적")

func test_boss_stage_uses_scaled_boss_wave() -> void:
	var stage_four := WaveFactory.stage_waves(4)
	var stage_five := WaveFactory.stage_waves(5)
	var base_boss := WaveFactory.boss_waves()

	eq(stage_four.size(), 3, "stage 4는 기본 파도")
	eq(stage_five.size(), 1, "stage 5는 보스 파도")
	truthy(_total_hp(stage_five) > _total_hp(base_boss), "보스 파도도 stage 배율 적용")
	truthy(_total_attack(stage_five) > _total_attack(base_boss), "보스 공격도 stage 배율 적용")

func _total_hp(waves: Array) -> int:
	var total := 0
	for wave in waves:
		for unit in wave:
			total += unit.max_hp
	return total

func _total_attack(waves: Array) -> int:
	var total := 0
	for wave in waves:
		for unit in wave:
			total += unit.attack
	return total

func _has_property(obj: Object, property_name: String) -> bool:
	for property in obj.get_property_list():
		if String(property["name"]) == property_name:
			return true
	return false
