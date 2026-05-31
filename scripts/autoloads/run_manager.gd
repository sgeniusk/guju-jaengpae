# 현재 런의 상태를 보관하는 싱글톤. 씬을 다시 불러도(전투 반복) 보드·손패·경제가 유지된다. 순수 로직은 RunState/RewardPool에 위임.
extends Node

var state := RunState.new()

# 런이 아직 시작 안 됐으면 군주의 시작 덱으로 초기화한다.
func ensure_started(lord_id: StringName) -> void:
	if not state.started:
		state.start_run(CardLibrary.get_lord(lord_id), CardLibrary.catalog)
		state.map.generate(_new_map_seed())

func get_deck() -> Array[StringName]:
	return state.board_card_ids()

func get_board() -> Dictionary:
	return state.board.duplicate()

func add_card(id: StringName) -> void:
	state.add_card(id)

func get_hand() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in state.hand:
		out.append(id)
	return out

func get_gold() -> int:
	return state.gold

func place_from_hand(hand_index: int, block_key: String) -> bool:
	return state.place_from_hand(hand_index, block_key)

func discard_from_hand(hand_index: int) -> bool:
	return state.discard_from_hand(hand_index)

func add_gold(n: int) -> void:
	state.add_gold(n)

func spend_gold(n: int) -> bool:
	return state.spend_gold(n)

func board_full() -> bool:
	return state.board_full()

func get_command_points() -> int:
	return state.command_points if state != null else 12

func add_command_points(n: int) -> void:
	state.add_command_points(n)

func available_nodes() -> Array:
	return state.map.available()

func choose_node(index: int) -> void:
	state.map.choose(index)

func complete_node() -> void:
	state.map.complete()

func active_node_type() -> int:
	return state.map.active_type()

func active_is_battle() -> bool:
	return RunMap.is_battle(active_node_type())

func map_finished() -> bool:
	return state.map.finished()

func node_label(node_type: int) -> String:
	match node_type:
		RunMap.NodeType.BATTLE:
			return "전투"
		RunMap.NodeType.ELITE:
			return "정예"
		RunMap.NodeType.REWARD:
			return "보상"
		RunMap.NodeType.SUPPLY:
			return "보급"
		RunMap.NodeType.BOSS:
			return "보스"
		_:
			return "전투"

# 보상 후보 최대 n장.
func reward_candidates(n: int) -> Array[StringName]:
	return RewardPool.roll(CardLibrary.catalog, state.owned_card_ids(), n)

func reset_run() -> void:
	state = RunState.new()

func reset() -> void:
	reset_run()

func _new_map_seed() -> int:
	return int(Time.get_ticks_usec() + randi())
