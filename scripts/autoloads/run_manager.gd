# 현재 런의 상태를 보관하는 싱글톤. 씬을 다시 불러도(전투 반복) 덱이 유지된다. 순수 로직은 RunState/RewardPool에 위임.
extends Node

var state := RunState.new()

# 런이 아직 시작 안 됐으면 군주의 시작 덱으로 초기화한다.
func ensure_started(lord_id: StringName) -> void:
	if not state.started:
		state.start_run(CardLibrary.get_lord(lord_id), CardLibrary.catalog)
		state.map.generate(_new_map_seed())

func get_deck() -> Array[StringName]:
	return state.deck

func add_card(id: StringName) -> void:
	state.add_card(id)

func available_nodes() -> Array:
	return state.map.available()

func choose_node(index: int) -> void:
	state.map.choose(index)

func complete_node() -> void:
	state.map.complete()

func active_node_type() -> int:
	return state.map.active_type()

func map_finished() -> bool:
	return state.map.finished()

# 보상 후보 최대 n장.
func reward_candidates(n: int) -> Array[StringName]:
	return RewardPool.roll(CardLibrary.catalog, state.deck, n)

func reset_run() -> void:
	state = RunState.new()

func reset() -> void:
	reset_run()

func _new_map_seed() -> int:
	return int(Time.get_ticks_usec() + randi())
