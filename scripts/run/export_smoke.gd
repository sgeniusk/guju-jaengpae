extends RefCounted

const MODE_ENV := "GUJU_EXPORT_SMOKE"
const LORD_ENV := "GUJU_EXPORT_SMOKE_LORD"
const MODE_FIRST_BATTLE := "first_battle"
const DEFAULT_LORD_ID := &"lord_liubei"

static func is_first_battle_requested() -> bool:
	return OS.get_environment(MODE_ENV).strip_edges().to_lower() == MODE_FIRST_BATTLE

static func lord_id() -> StringName:
	var raw := OS.get_environment(LORD_ENV).strip_edges()
	if raw == "":
		return DEFAULT_LORD_ID
	return StringName(raw)

static func ensure_first_battle_board() -> Dictionary:
	if not RunManager.has_castle():
		var castle_key := _first_empty_block()
		if castle_key != "" and not RunManager.set_castle_key(castle_key):
			return {
				"ok": false,
				"source": "castle_failed",
				"castle_key": castle_key,
			}
	var existing_key := _first_unit_board_key()
	if existing_key != "":
		if RunManager.can_place_deploy_card():
			RunManager.state.mark_deploy_card_played()
		return {
			"ok": true,
			"source": "existing",
			"block_key": existing_key,
			"board_size": RunManager.get_board().size(),
		}

	var hand := RunManager.get_hand()
	for hand_index in hand.size():
		var card_id: StringName = hand[hand_index]
		var card := CardLibrary.get_card(card_id)
		if card == null or not (card is UnitCardData):
			continue
		for block_key in RunState.block_keys_for(RunManager.get_board_rows()):
			if RunManager.get_board().has(block_key):
				continue
			if block_key == RunManager.get_castle_key():
				continue
			if RunManager.place_from_hand(hand_index, block_key):
				return {
					"ok": true,
					"source": "hand",
					"block_key": block_key,
					"card_id": String(card_id),
					"card_name": card.display_name,
					"hand_index": hand_index,
					"board_size": RunManager.get_board().size(),
				}

	return {
		"ok": false,
		"source": "none",
		"hand_size": hand.size(),
		"board_size": RunManager.get_board().size(),
	}

static func log_marker(marker: String, data: Dictionary = {}) -> void:
	print("GUJU_EXPORT_SMOKE %s %s" % [marker, JSON.stringify(data)])

static func fail_and_quit(tree: SceneTree, reason: String, data: Dictionary = {}) -> void:
	var payload := data.duplicate(true)
	payload["reason"] = reason
	log_marker("failed", payload)
	if tree != null:
		tree.quit(1)

static func _first_unit_board_key() -> String:
	var board := RunManager.get_board()
	for block_key in RunState.block_keys_for(RunManager.get_board_rows()):
		if not board.has(block_key):
			continue
		var card := CardLibrary.get_card(StringName(board[block_key]))
		if card is UnitCardData:
			return block_key
	return ""

static func _first_empty_block() -> String:
	var board := RunManager.get_board()
	for block_key in RunState.block_keys_for(RunManager.get_board_rows()):
		if board.has(block_key):
			continue
		return block_key
	return ""
