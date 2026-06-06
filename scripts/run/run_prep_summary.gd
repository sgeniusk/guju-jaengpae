# 런맵에서 전투 진입 직전 보여줄 준비 상태를 계산하는 순수 UI helper.
class_name RunPrepSummary
extends RefCounted

static func for_run(board: Dictionary, board_levels: Dictionary, hand: Array, castle_key: String, capacity: int, catalog: CardCatalog) -> Dictionary:
	var max_level_by_card := _max_level_by_card(board, board_levels)
	var upgrade_candidates := 0
	var place_candidates := 0
	var unit_candidates := 0
	var building_candidates := 0
	var scheme_candidates := 0
	var unknown_candidates := 0

	for id in hand:
		var card_id := StringName(id)
		var card := catalog.get_card(card_id) if catalog != null else null
		if card == null:
			unknown_candidates += 1
			continue
		var card_type := String(card.get("card_type"))
		if card is UnitCardData:
			var current_level := int(max_level_by_card.get(card_id, 0))
			if current_level > 0 and current_level < RunState.CARD_LEVEL_MAX:
				upgrade_candidates += 1
			else:
				place_candidates += 1
				unit_candidates += 1
		elif card_type == "building":
			place_candidates += 1
			building_candidates += 1
		elif card_type == "scheme":
			scheme_candidates += 1
		else:
			unknown_candidates += 1

	var castle_selected := not castle_key.is_empty()
	var title := "전투 준비 — 손패 %d장 중 1장" % hand.size()
	var detail := "성 위치: %s · 군세 %d/%d · 증원 후보 %d장 · 배치 후보 %d장 · 계략 %d장" % [
		_block_label(castle_key) if castle_selected else "미선택",
		board.size(),
		capacity,
		upgrade_candidates,
		place_candidates,
		scheme_candidates,
	]
	var tooltip := "전투 화면에서 성 위치를 고른 뒤 손패 %d장 중 한 장만 배치, 증원, 계략, 우물 중 하나로 사용합니다.\n%s\n증원 후보 %d장, 새 배치 후보 %d장, 계략 %d장입니다." % [
		hand.size(),
		"성 위치는 %s입니다." % _block_label(castle_key) if castle_selected else "성 위치는 아직 정하지 않았습니다.",
		upgrade_candidates,
		place_candidates,
		scheme_candidates,
	]
	if unknown_candidates > 0:
		tooltip += "\n정보를 불러오지 못한 손패 %d장이 있습니다." % unknown_candidates

	return {
		"title": title,
		"detail": detail,
		"tooltip": tooltip,
		"board_count": board.size(),
		"capacity": capacity,
		"hand_size": hand.size(),
		"castle_selected": castle_selected,
		"upgrade_candidates": upgrade_candidates,
		"place_candidates": place_candidates,
		"unit_candidates": unit_candidates,
		"building_candidates": building_candidates,
		"scheme_candidates": scheme_candidates,
		"unknown_candidates": unknown_candidates,
	}

static func _max_level_by_card(board: Dictionary, board_levels: Dictionary) -> Dictionary:
	var out := {}
	for key in board.keys():
		var text_key := String(key)
		var card_id := StringName(board[key])
		var level := clampi(int(board_levels.get(text_key, board_levels.get(key, 1))), 1, RunState.CARD_LEVEL_MAX)
		out[card_id] = maxi(int(out.get(card_id, 0)), level)
	return out

static func _block_label(block_key: String) -> String:
	var parts := block_key.split(":")
	if parts.size() != 2:
		return block_key
	return "%d열 %d행" % [int(parts[0]) + 1, int(parts[1]) + 1]
