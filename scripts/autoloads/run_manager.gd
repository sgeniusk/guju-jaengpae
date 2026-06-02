# 현재 런의 상태를 보관하는 싱글톤. 씬을 다시 불러도(전투 반복) 보드·손패·경제가 유지된다. 순수 로직은 RunState/RewardPool에 위임.
extends Node

const _StageCadence := preload("res://scripts/run/stage_cadence.gd")

var state := RunState.new()

# 런이 아직 시작 안 됐으면 군주의 시작 덱으로 초기화한다.
func ensure_started(lord_id: StringName) -> void:
	if not state.started:
		state.start_run(CardLibrary.get_lord(lord_id), CardLibrary.catalog)

func get_deck() -> Array[StringName]:
	return state.board_card_ids()

func get_board() -> Dictionary:
	return state.board.duplicate()

func add_card(id: StringName) -> void:
	hand_add(id)

func hand_add(id: StringName) -> void:
	state.hand_add(id)

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

func stage_index() -> int:
	return state.stage_index

func is_boss_stage() -> bool:
	return _StageCadence.is_boss(state.stage_index)

func is_shop_stage() -> bool:
	return _StageCadence.is_shop(state.stage_index)

func shop_card_ids() -> Array[StringName]:
	return CardLibrary.catalog.purchasable_ids()

func shop_purchase(id: StringName) -> bool:
	var card := CardLibrary.get_card(id)
	if card == null:
		return false
	if get_gold() < card.cost:
		return false
	if not spend_gold(card.cost):
		return false
	hand_add(id)
	return true

func is_expand_stage() -> bool:
	return _StageCadence.is_expand(state.stage_index)

func difficulty_scale() -> float:
	return _StageCadence.difficulty_scale(state.stage_index)

func current_waves() -> Array:
	return WaveFactory.stage_waves(state.stage_index)

func advance_stage() -> void:
	state.advance_stage()

# 보상 후보 최대 n장.
func reward_candidates(n: int) -> Array[StringName]:
	return RewardPool.roll(CardLibrary.catalog, state.owned_card_ids(), n)

func reset_run() -> void:
	state = RunState.new()

func reset() -> void:
	reset_run()
