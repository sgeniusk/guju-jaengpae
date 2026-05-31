# feat-008 맵 노드 다양화와 런 지휘력 상태를 검증한다.
extends TestCase

func test_node_type_has_five_named_kinds() -> void:
	for key in ["BATTLE", "ELITE", "REWARD", "SUPPLY", "BOSS"]:
		truthy(RunMap.NodeType.has(key), "NodeType.%s 존재" % key)

func test_is_battle_classifies_combat_and_non_combat_nodes() -> void:
	var is_battle := Callable(RunMap, "is_battle")
	truthy(is_battle.is_valid(), "RunMap.is_battle 헬퍼 존재")
	if not is_battle.is_valid():
		return
	truthy(is_battle.call(RunMap.NodeType.get("BATTLE")), "BATTLE은 전투")
	truthy(is_battle.call(RunMap.NodeType.get("ELITE")), "ELITE는 전투")
	truthy(is_battle.call(RunMap.NodeType.get("BOSS")), "BOSS는 전투")
	falsy(is_battle.call(RunMap.NodeType.get("REWARD")), "REWARD는 비전투")
	falsy(is_battle.call(RunMap.NodeType.get("SUPPLY")), "SUPPLY는 비전투")

func test_generate_is_deterministic_and_can_include_non_battle_nodes() -> void:
	var first := RunMap.new()
	var second := RunMap.new()
	first.generate(77, 3)
	second.generate(77, 3)
	eq(_type_sequence(first.layers), _type_sequence(second.layers), "같은 seed는 같은 노드 종류")

	var sample := RunMap.new()
	sample.generate(77, 3)
	for layer_idx in 3:
		eq(sample.layers[layer_idx].size(), 2, "선택 막은 2노드")
	eq(sample.layers[3].size(), 1, "마지막 막은 보스 1노드")
	eq(sample.layers[3][0]["type"], RunMap.NodeType.get("BOSS"), "마지막 노드는 보스")

	var found_non_battle := false
	for seed in 40:
		var run_map := RunMap.new()
		run_map.generate(seed, 3)
		if _has_non_battle_node(run_map.layers, 3):
			found_non_battle = true
	truthy(found_non_battle, "여러 seed 중 비전투 노드가 등장")

func test_run_state_command_points_default_and_addition() -> void:
	var run := RunState.new()
	truthy(_has_property(run, "command_points"), "RunState.command_points 존재")
	truthy(run.has_method("add_command_points"), "RunState.add_command_points 존재")
	if not _has_property(run, "command_points") or not run.has_method("add_command_points"):
		return
	eq(run.get("command_points"), 12, "새 런 지휘력 기본값")
	run.call("add_command_points", 3)
	eq(run.get("command_points"), 15, "보급 후 지휘력 증가")
	eq(RunState.new().get("command_points"), 12, "새 RunState는 기본값으로 복귀")

func test_run_manager_command_points_api_resets_with_new_run_state() -> void:
	RunManager.reset_run()
	eq(RunManager.get_command_points(), 12, "RunManager 지휘력 기본값")
	RunManager.add_command_points(3)
	eq(RunManager.get_command_points(), 15, "RunManager 보급 위임")
	RunManager.reset_run()
	eq(RunManager.get_command_points(), 12, "reset_run 후 지휘력 기본값")

func test_reward_flow_adds_card_and_removes_it_from_eligible() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var run := RunState.new()
	run.start_run(cat.get_lord(&"lord_liubei"), cat)
	truthy(run.has_method("owned_card_ids"), "RunState.owned_card_ids 존재")
	truthy(run.has_method("hand_add"), "RunState.hand_add 존재")
	if not run.has_method("owned_card_ids") or not run.has_method("hand_add"):
		return
	var eligible := RewardPool.eligible(cat, run.owned_card_ids())
	var picked: StringName = eligible[0]
	var before: int = run.owned_card_ids().size()

	run.hand_add(picked)

	eq(run.owned_card_ids().size(), before + 1, "REWARD 해결 후 owned +1")
	truthy(run.has_card(picked), "획득 카드 보유")
	falsy(RewardPool.eligible(cat, run.owned_card_ids()).has(picked), "획득 카드는 후보에서 제외")

func _type_sequence(layers: Array) -> Array[int]:
	var out: Array[int] = []
	for layer in layers:
		for node in layer:
			out.append(node["type"])
	return out

func _has_non_battle_node(layers: Array, normal_layers: int) -> bool:
	for layer_idx in normal_layers:
		for node in layers[layer_idx]:
			var node_type: int = node["type"]
			if node_type == RunMap.NodeType.get("REWARD") or node_type == RunMap.NodeType.get("SUPPLY"):
				return true
	return false

func _has_property(obj: Object, property_name: String) -> bool:
	for property in obj.get_property_list():
		if String(property["name"]) == property_name:
			return true
	return false
