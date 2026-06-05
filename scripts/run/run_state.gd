# 한 런의 변경 가능한 상태 — 군주, 스테이지, 영속 보드·손패·골드, 파도 진행도. 순수 로직(헤드리스 테스트 가능).
class_name RunState
extends RefCounted

const HAND_MAX := 3
const HAND_DRAW_COUNT := 3
const BOARD_COLS := 3
const BOARD_ROWS_START := 3
const BOARD_ROWS_MAX := 6
const CARD_LEVEL_MAX := 5
const WELL_GOLD := 10
const SAVE_VERSION := "1.2.0"
const SAVE_MAJOR_VERSION := 1

var lord_id: StringName = &""
var board: Dictionary = {}
var board_levels: Dictionary = {}
var hand: Array[StringName] = []
var draw_pile: Array[StringName] = []
var gold: int = 0
var board_rows: int = BOARD_ROWS_START
var stage_index: int = 1
var wave_index: int = 0
var started: bool = false
var command_points: int = 12
var edicts: Array[StringName] = []
var treasures: Array[StringName] = []
var castle_key: String = ""
var terrain_perk_id: StringName = &""
var deploy_cards_played: int = 0
var deploy_stage_index: int = 0

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
	board_levels.clear()
	hand.clear()
	draw_pile.clear()
	gold = 0
	board_rows = BOARD_ROWS_START
	stage_index = 1
	var starting_cards := catalog.get_lord_strategy_deck(lord)
	for card_id in starting_cards:
		draw_pile.append(card_id)
	draw_to_hand(HAND_DRAW_COUNT)
	wave_index = 0
	command_points = 12
	edicts.clear()
	treasures.clear()
	castle_key = ""
	terrain_perk_id = catalog.terrain_perk_id_for_lord(lord)
	deploy_cards_played = 0
	deploy_stage_index = stage_index
	started = true

func is_block_free(key: String) -> bool:
	return block_keys().has(key) and not board.has(key) and key != castle_key

func board_full() -> bool:
	var reserved := 1 if castle_key != "" else 0
	return board.size() + reserved >= board_capacity()

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
	board_levels[block_key] = 1
	hand.remove_at(hand_index)
	return true

func can_upgrade_from_hand(hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= hand.size():
		return false
	var key := find_board_key_for_card(hand[hand_index])
	return key != "" and board_level(key) < CARD_LEVEL_MAX

func upgrade_from_hand(hand_index: int) -> String:
	if not can_upgrade_from_hand(hand_index):
		return ""
	var card_id := hand[hand_index]
	var key := find_board_key_for_card(card_id)
	board_levels[key] = board_level(key) + 1
	hand.remove_at(hand_index)
	return key

func find_board_key_for_card(card_id: StringName) -> String:
	for key in block_keys():
		if board.has(key) and StringName(board[key]) == card_id:
			return key
	return ""

func board_level(block_key: String) -> int:
	if not board.has(block_key):
		return 0
	return clampi(int(board_levels.get(block_key, 1)), 1, CARD_LEVEL_MAX)

func board_levels_copy() -> Dictionary:
	var out := {}
	for key in board.keys():
		out[String(key)] = board_level(String(key))
	return out

func prepare_deploy_hand() -> bool:
	if deploy_stage_index == stage_index:
		return false
	_recycle_hand_to_draw_pile()
	draw_to_hand(HAND_DRAW_COUNT)
	deploy_cards_played = 0
	deploy_stage_index = stage_index
	return true

func draw_to_hand(target_size: int = HAND_DRAW_COUNT) -> int:
	var before := hand.size()
	var clamped_target := maxi(0, target_size)
	while hand.size() < clamped_target and not draw_pile.is_empty():
		hand.append(draw_pile.pop_front())
	return hand.size() - before

func can_place_deploy_card() -> bool:
	return deploy_cards_played <= 0

func mark_deploy_card_played() -> void:
	deploy_cards_played += 1

func has_castle() -> bool:
	return castle_key != "" and block_keys().has(castle_key)

func can_place_castle(key: String) -> bool:
	return castle_key == "" and block_keys().has(key) and not board.has(key)

func set_castle_key(key: String) -> bool:
	if not can_place_castle(key):
		return false
	castle_key = key
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
	var ids: Array[StringName] = []
	for key in block_keys():
		if not board.has(key):
			continue
		for _i in board_level(key):
			ids.append(StringName(board[key]))
	for id in hand:
		ids.append(id)
	for id in draw_pile:
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
		"board_levels": _board_levels_to_dict(),
		"hand": _string_array(hand),
		"draw_pile": _string_array(draw_pile),
		"gold": gold,
		"board_rows": board_rows,
		"stage_index": stage_index,
		"wave_index": wave_index,
		"started": started,
		"command_points": command_points,
		"edicts": _string_array(edicts),
		"treasures": _string_array(treasures),
		"castle_key": castle_key,
		"terrain_perk_id": String(terrain_perk_id),
		"deploy_cards_played": deploy_cards_played,
		"deploy_stage_index": deploy_stage_index,
	}

func from_dict(data: Dictionary) -> bool:
	if _payload_major_version(data) > SAVE_MAJOR_VERSION:
		return false
	lord_id = StringName(String(data.get("lord_id", "")))
	board = _board_from_dict(data.get("board", {}))
	board_levels = _board_levels_from_dict(data.get("board_levels", {}), board)
	hand = _string_name_array(data.get("hand", []))
	draw_pile = _string_name_array(data.get("draw_pile", []))
	gold = int(data.get("gold", 0))
	board_rows = clampi(int(data.get("board_rows", BOARD_ROWS_START)), BOARD_ROWS_START, BOARD_ROWS_MAX)
	stage_index = maxi(1, int(data.get("stage_index", 1)))
	wave_index = maxi(0, int(data.get("wave_index", 0)))
	started = bool(data.get("started", false))
	command_points = int(data.get("command_points", 12))
	edicts = _string_name_array(data.get("edicts", []))
	treasures = _string_name_array(data.get("treasures", []))
	castle_key = String(data.get("castle_key", ""))
	if not block_keys().has(castle_key):
		castle_key = ""
	terrain_perk_id = StringName(String(data.get("terrain_perk_id", "")))
	deploy_cards_played = maxi(0, int(data.get("deploy_cards_played", 0)))
	deploy_stage_index = maxi(0, int(data.get("deploy_stage_index", stage_index)))
	if not data.has("draw_pile"):
		_migrate_legacy_oversized_hand()
	_sanitize_board_levels()
	return true

func _recycle_hand_to_draw_pile() -> void:
	if hand.is_empty():
		return
	for card_id in hand:
		draw_pile.append(card_id)
	hand.clear()

func _migrate_legacy_oversized_hand() -> void:
	if hand.size() <= HAND_DRAW_COUNT:
		return
	var kept: Array[StringName] = []
	var overflow: Array[StringName] = []
	for idx in hand.size():
		if idx < HAND_DRAW_COUNT:
			kept.append(hand[idx])
		else:
			overflow.append(hand[idx])
	hand = kept
	for card_id in overflow:
		draw_pile.append(card_id)

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

func _board_levels_to_dict() -> Dictionary:
	var out := {}
	for key in board.keys():
		out[String(key)] = board_level(String(key))
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

static func _board_levels_from_dict(value, board_value: Dictionary) -> Dictionary:
	var out := {}
	for key in board_value.keys():
		out[String(key)] = 1
	if not (value is Dictionary):
		return out
	for key in (value as Dictionary).keys():
		var text_key := String(key)
		if not board_value.has(text_key):
			continue
		out[text_key] = clampi(int((value as Dictionary)[key]), 1, CARD_LEVEL_MAX)
	return out

func _sanitize_board_levels() -> void:
	var next := {}
	for key in board.keys():
		next[String(key)] = board_level(String(key))
	board_levels = next

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
