# 한 런의 변경 가능한 상태 — 군주, 스테이지, 영속 보드·손패·골드, 파도 진행도. 순수 로직(헤드리스 테스트 가능).
class_name RunState
extends RefCounted

const HAND_MAX := 3
const BOARD_BLOCKS := 9
const WELL_GOLD := 10

var lord_id: StringName = &""
var board: Dictionary = {}
var hand: Array[StringName] = []
var gold: int = 0
var stage_index: int = 1
var wave_index: int = 0
var started: bool = false
var command_points: int = 12

static func block_keys() -> Array[String]:
	var keys: Array[String] = []
	for row in 3:
		for col in 3:
			keys.append("%d:%d" % [col, row])
	return keys

func start_run(lord: LordData, catalog: CardCatalog) -> void:
	lord_id = lord.id if lord != null else &""
	board.clear()
	hand.clear()
	gold = 0
	stage_index = 1
	var starting_cards := catalog.get_lord_deck(lord)
	for card_id in starting_cards:
		hand.append(card_id)
	wave_index = 0
	command_points = 12
	started = true

func is_block_free(key: String) -> bool:
	return block_keys().has(key) and not board.has(key)

func board_full() -> bool:
	return board.size() >= BOARD_BLOCKS

func first_free_block():
	for key in block_keys():
		if is_block_free(key):
			return key
	return null

func place_from_hand(hand_index: int, block_key: String) -> bool:
	if hand_index < 0 or hand_index >= hand.size():
		return false
	if not is_block_free(block_key):
		return false
	board[block_key] = hand[hand_index]
	hand.remove_at(hand_index)
	return true

func discard_from_hand(hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= hand.size():
		return false
	hand.remove_at(hand_index)
	gold += WELL_GOLD
	return true

func hand_add(card_id: StringName) -> void:
	hand.append(card_id)

func hand_over_limit() -> bool:
	return hand.size() > HAND_MAX

func board_card_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key in block_keys():
		if board.has(key):
			ids.append(StringName(board[key]))
	return ids

func owned_card_ids() -> Array[StringName]:
	var ids := board_card_ids()
	for id in hand:
		ids.append(id)
	return ids

func add_gold(n: int) -> void:
	if n > 0:
		gold += n

func spend_gold(n: int) -> bool:
	if n < 0 or gold < n:
		return false
	gold -= n
	return true

func has_card(id: StringName) -> bool:
	return owned_card_ids().has(id)

func add_card(id: StringName) -> void:
	hand_add(id)

func advance_stage() -> void:
	stage_index += 1
