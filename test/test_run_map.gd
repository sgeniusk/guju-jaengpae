# 로그라이크 맵의 생성, 진행, 노드별 파도 연결을 검증한다.
extends TestCase

func test_generate_builds_three_choice_layers_and_boss() -> void:
	var run_map := RunMap.new()
	run_map.generate(42, 3)

	eq(run_map.total_layers(), 4, "선택 3막 + 보스 1막")
	for layer_idx in 3:
		eq(run_map.layers[layer_idx].size(), 2, "선택 막은 2노드")
	eq(run_map.layers[3].size(), 1, "마지막 막은 보스 1노드")
	eq(run_map.layers[3][0]["type"], RunMap.NodeType.BOSS, "마지막 노드는 보스")
	eq(run_map.layers[0][0]["id"], "L0N0", "노드 id는 막/인덱스 기반")

func test_generate_is_deterministic_for_same_seed() -> void:
	var first := RunMap.new()
	var second := RunMap.new()
	first.generate(42, 3)
	second.generate(42, 3)

	eq(_type_sequence(first.layers), _type_sequence(second.layers), "같은 seed는 같은 종류 시퀀스")

func test_progression_choose_complete_and_finish() -> void:
	var run_map := RunMap.new()
	run_map.generate(42, 3)
	var first_type: int = run_map.layers[0][0]["type"]

	eq(run_map.available().size(), 2, "초기 선택 막은 2노드")
	run_map.choose(0)
	eq(run_map.active_type(), first_type, "선택 노드 종류가 active_type")
	run_map.complete()
	eq(run_map.available(), run_map.layers[1], "완료 후 다음 막이 열림")

	while not run_map.finished():
		run_map.choose(0)
		run_map.complete()

	truthy(run_map.finished(), "모든 막 완료 후 finished")
	eq(run_map.available(), [], "finished면 선택 가능 노드 없음")
	eq(run_map.active_type(), -1, "완료 상태에는 active 노드 없음")

func test_waves_for_node_are_non_empty_and_scale_up() -> void:
	var battle_waves := WaveFactory.waves_for_node(RunMap.NodeType.BATTLE)
	var elite_waves := WaveFactory.waves_for_node(RunMap.NodeType.ELITE)
	var boss_waves := WaveFactory.waves_for_node(RunMap.NodeType.BOSS)
	var fallback_waves := WaveFactory.waves_for_node(-1)

	truthy(not battle_waves.is_empty(), "일반 노드는 기본 파도")
	truthy(not elite_waves.is_empty(), "정예 노드는 정예 파도")
	truthy(not boss_waves.is_empty(), "보스 노드는 보스 파도")
	truthy(not fallback_waves.is_empty(), "알 수 없는 노드는 기본 파도")
	truthy(_total_hp(elite_waves) > _total_hp(battle_waves), "정예 총 체력은 일반보다 큼")
	truthy(_total_hp(boss_waves) > _total_hp(elite_waves), "보스 총 체력은 정예보다 큼")

func _type_sequence(layers: Array) -> Array[int]:
	var out: Array[int] = []
	for layer in layers:
		for node in layer:
			out.append(node["type"])
	return out

func _total_hp(waves: Array) -> int:
	var total := 0
	for wave in waves:
		for unit in wave:
			total += unit.max_hp
	return total
