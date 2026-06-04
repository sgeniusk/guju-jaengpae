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
	eq(RunManager.stage_node_kind(), "combat", "stage 1 effective node_kind")
	falsy(RunManager.is_boss_stage(), "stage 1은 보스 아님")
	falsy(RunManager.is_shop_stage(), "stage 1은 상점 아님")
	falsy(RunManager.is_expand_stage(), "stage 1은 확장 아님")
	falsy(RunManager.is_elite_stage(), "stage 1은 정예 아님")
	falsy(RunManager.is_event_stage(), "stage 1은 사건 아님")
	almost(RunManager.difficulty_scale(), 1.0, 0.0001, "stage 1 배율")
	truthy(not RunManager.current_waves().is_empty(), "현재 파도 제공")

	RunManager.advance_stage()
	RunManager.advance_stage()
	RunManager.advance_stage()
	eq(RunManager.stage_index(), 4, "stage 4 도달")
	truthy(RunManager.is_shop_stage(), "stage 4는 상점 예측자만 true")
	falsy(RunManager.is_boss_stage(), "stage 4는 보스 아님")
	eq(RunManager.stage_node_kind(), "shop", "stage 4 effective node_kind")

	RunManager.advance_stage()
	eq(RunManager.stage_index(), 5, "stage 5 도달")
	truthy(RunManager.is_boss_stage(), "stage 5는 보스")
	truthy(RunManager.is_expand_stage(), "stage 5는 확장 예측자")
	eq(RunManager.stage_node_kind(), "boss", "stage 5는 보스가 확장보다 우선")
	almost(RunManager.difficulty_scale(), 1.40, 0.0001, "stage 5 배율")

	RunManager.advance_stage()
	RunManager.advance_stage()
	eq(RunManager.stage_index(), 7, "stage 7 도달")
	truthy(RunManager.is_elite_stage(), "stage 7은 정예 예측자")
	eq(RunManager.stage_node_kind(), "elite", "stage 7 effective node_kind")
	truthy(not RunManager.current_waves().is_empty(), "정예도 전투 파도 경로를 유지")

	for _i in range(4):
		RunManager.advance_stage()
	eq(RunManager.stage_index(), 11, "stage 11 도달")
	truthy(RunManager.is_event_stage(), "stage 11은 사건 예측자")
	eq(RunManager.stage_node_kind(), "event", "stage 11 effective node_kind")

func test_first_fifteen_stages_mix_major_run_nodes() -> void:
	RunManager.ensure_started(&"lord_liubei")
	var sequence: Array[String] = []
	var seen := {}
	var expand_stages: Array[int] = []
	var event_resolved := false
	var shop_purchases := 0

	for stage in range(1, 16):
		eq(RunManager.stage_index(), stage, "stage 순회")
		var kind := RunManager.stage_node_kind()
		sequence.append(kind)
		seen[kind] = true

		if ["combat", "elite", "boss"].has(kind):
			truthy(not RunManager.current_waves().is_empty(), "전투 node는 파도 존재")
		if kind == "edict":
			truthy(RunManager.add_edict(&"edict_might"), "칙령 node는 edict를 누적")
		elif kind == "shop":
			RunManager.add_gold(999)
			truthy(_buy_first_shop_card(), "상점 node는 카드 구매 가능")
			shop_purchases += 1
		elif kind == "event":
			var before_gold := RunManager.get_gold()
			RunManager.add_gold(20)
			eq(RunManager.get_gold(), before_gold + 20, "사건 node는 골드 보상")
			event_resolved = true
		elif kind == "boss":
			truthy(RunManager.is_expand_stage(), "보스 stage는 확장 예측자")
			if RunManager.get_board_rows() < RunState.BOARD_ROWS_MAX:
				truthy(RunManager.expand_board(), "보스 node는 보드 확장 보상")
				expand_stages.append(stage)

		if stage < 15:
			RunManager.advance_stage()

	eq(sequence, [
		"combat",
		"combat",
		"edict",
		"shop",
		"boss",
		"edict",
		"elite",
		"shop",
		"edict",
		"boss",
		"event",
		"edict",
		"combat",
		"elite",
		"boss",
	], "첫 15스테이지 런 node mix")
	for kind in ["combat", "shop", "edict", "boss", "elite", "event"]:
		truthy(seen.has(kind), "%s node 포함" % kind)
	eq(expand_stages, [5, 10, 15], "보스 3회가 확장 3회를 제공")
	eq(RunManager.get_board_rows(), RunState.BOARD_ROWS_MAX, "stage 15까지 보드 최대 행")
	eq(RunManager.get_edicts().size(), 4, "stage 3/6/9/12 칙령 누적")
	eq(shop_purchases, 2, "stage 4/8 상점 구매")
	truthy(event_resolved, "stage 11 사건 해결")
	truthy(RunManager.is_final_boss_stage(), "stage 15는 최종 보스")

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

func _buy_first_shop_card() -> bool:
	for id in RunManager.shop_card_ids():
		if RunManager.shop_purchase(id):
			return true
	return false

func _has_property(obj: Object, property_name: String) -> bool:
	for property in obj.get_property_list():
		if String(property["name"]) == property_name:
			return true
	return false
