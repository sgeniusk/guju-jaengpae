# 한 런의 변경 가능한 상태 — 군주, 스테이지, 영속 보드·손패·골드, 파도 진행도. 순수 로직(헤드리스 테스트 가능).
class_name RunState
extends RefCounted

const HAND_MAX := 3
const BOARD_COLS := 3
const BOARD_ROWS_START := 3
const BOARD_ROWS_MAX := 6
const WELL_GOLD := 10
const SAVE_VERSION := "1.0.0"
const SAVE_MAJOR_VERSION := 1

var lord_id: StringName = &""
var board: Dictionary = {}
var hand: Array[StringName] = []
var gold: int = 0
var board_rows: int = BOARD_ROWS_START
var stage_index: int = 1
var wave_index: int = 0
var started: bool = false
var command_points: int = 12
var edicts: Array[StringName] = []
var treasures: Array[StringName] = []

static func block_keys_for(rows: int) -> Array[String]:
	var keys: Array[String] = []
	var clamped_rows := clampi(rows, BOARD_ROWS_START, BOARD_ROWS_MAX)
	for row in clamped_rows:
		for col in BOARD_COLS:
			keys.append("%d:%d" % [col, row])
	return keys

func block_keys() -> Array[String]:
	return block_keys_for(board_rows)

func board_capacity() -> int:
	return board_rows * BOARD_COLS

func start_run(lord: LordData, catalog: CardCatalog) -> void:
	lord_id = lord.id if lord != null else &""
	board.clear()
	hand.clear()
	gold = 0
	board_rows = BOARD_ROWS_START
	stage_index = 1
	var starting_cards := catalog.get_lord_deck(lord)
	for card_id in starting_cards:
		hand.append(card_id)
	wave_index = 0
	command_points = 12
	edicts.clear()
	treasures.clear()
	started = true

func is_block_free(key: String) -> bool:
	return block_keys().has(key) and not board.has(key)

func board_full() -> bool:
	return board.size() >= board_capacity()

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

func consume_from_hand(hand_index: int) -> StringName:
	if hand_index < 0 or hand_index >= hand.size():
		return &""
	var card_id: StringName = hand[hand_index]
	hand.remove_at(hand_index)
	return card_id

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
	for id in treasures:
		ids.append(id)
	return ids

func add_treasure(id: StringName) -> void:
	treasures.append(id)

func treasure_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in treasures:
		out.append(id)
	return out

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

func add_edict(id: StringName) -> void:
	edicts.append(id)

func expand_board() -> bool:
	if board_rows >= BOARD_ROWS_MAX:
		return false
	board_rows += 1
	return true

func advance_stage() -> void:
	stage_index += 1

func to_dict() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"lord_id": String(lord_id),
		"board": _board_to_dict(),
		"hand": _string_array(hand),
		"gold": gold,
		"board_rows": board_rows,
		"stage_index": stage_index,
		"wave_index": wave_index,
		"started": started,
		"command_points": command_points,
		"edicts": _string_array(edicts),
		"treasures": _string_array(treasures),
	}

func from_dict(data: Dictionary) -> bool:
	if _payload_major_version(data) > SAVE_MAJOR_VERSION:
		return false
	lord_id = StringName(String(data.get("lord_id", "")))
	board = _board_from_dict(data.get("board", {}))
	hand = _string_name_array(data.get("hand", []))
	gold = int(data.get("gold", 0))
	board_rows = clampi(int(data.get("board_rows", BOARD_ROWS_START)), BOARD_ROWS_START, BOARD_ROWS_MAX)
	stage_index = maxi(1, int(data.get("stage_index", 1)))
	wave_index = maxi(0, int(data.get("wave_index", 0)))
	started = bool(data.get("started", false))
	command_points = int(data.get("command_points", 12))
	edicts = _string_name_array(data.get("edicts", []))
	treasures = _string_name_array(data.get("treasures", []))
	return true

static func _payload_major_version(data: Dictionary) -> int:
	var raw_version = data.get("save_version", SAVE_VERSION)
	if raw_version is int or raw_version is float:
		return maxi(0, int(raw_version))
	var text := String(raw_version)
	if text == "":
		return SAVE_MAJOR_VERSION
	return maxi(0, int(text.split(".", false, 1)[0]))

func _board_to_dict() -> Dictionary:
	var out := {}
	for key in board.keys():
		out[String(key)] = String(board[key])
	return out

static func _board_from_dict(value) -> Dictionary:
	var out := {}
	if not (value is Dictionary):
		return out
	for key in (value as Dictionary).keys():
		var card_id := String((value as Dictionary)[key])
		if card_id != "":
			out[String(key)] = StringName(card_id)
	return out

static func _string_array(values: Array) -> Array:
	var out: Array = []
	for value in values:
		out.append(String(value))
	return out

static func _string_name_array(value) -> Array[StringName]:
	var out: Array[StringName] = []
	if not (value is Array):
		return out
	for item in value:
		var text := String(item)
		if text != "":
			out.append(StringName(text))
	return out
