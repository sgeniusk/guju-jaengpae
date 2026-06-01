# 영속 보드 위 건물 카드의 경제 생산과 전투 시작 오라를 계산하는 순수 헬퍼.
class_name BoardEconomy
extends RefCounted

static func buildings_on_board(board: Dictionary, catalog: CardCatalog) -> Array:
	var buildings := []
	if catalog == null:
		return buildings
	for key in RunState.block_keys():
		if not board.has(key):
			continue
		var parsed := _parse_key(key)
		if parsed.x < 0 or parsed.y < 0:
			continue
		var card := catalog.get_card(StringName(board[key]))
		if card == null or String(card.get("card_type")) != "building":
			continue
		buildings.append({
			"key": key,
			"col": int(parsed.x),
			"row": int(parsed.y),
			"card": card,
		})
	return buildings

static func gold_per_sec(board: Dictionary, catalog: CardCatalog) -> int:
	var total := 0
	for entry in buildings_on_board(board, catalog):
		var card: CardData = entry.get("card", null)
		if card != null:
			total += maxi(0, int(card.get("gold_per_sec")))
	return total

static func apply_auras(army: Array, board: Dictionary, catalog: CardCatalog) -> void:
	var aura_buildings := []
	for entry in buildings_on_board(board, catalog):
		var card: CardData = entry.get("card", null)
		if card == null:
			continue
		var pct := maxf(0.0, float(card.get("aura_attack_pct")))
		if pct <= 0.0:
			continue
		aura_buildings.append({
			"col": int(entry.get("col", -99)),
			"row": int(entry.get("row", -99)),
			"pct": pct,
			"radius": maxi(0, int(card.get("aura_radius"))),
		})
	if aura_buildings.is_empty():
		return
	for unit in army:
		if unit == null or not (unit is BattleUnit) or unit.is_castle:
			continue
		if unit.row < 0:
			continue
		var bonus := 0.0
		for aura in aura_buildings:
			if _chebyshev(unit.lane, unit.row, int(aura.get("col", -99)), int(aura.get("row", -99))) <= int(aura.get("radius", 0)):
				bonus += float(aura.get("pct", 0.0))
		if bonus > 0.0:
			unit.attack = maxi(0, int(round(unit.attack * (1.0 + bonus))))

static func _parse_key(key: String) -> Vector2i:
	var parts := key.split(":")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	if not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i(-1, -1)
	var col := int(parts[0])
	var row := int(parts[1])
	if col < 0 or row < 0:
		return Vector2i(-1, -1)
	return Vector2i(col, row)

static func _chebyshev(a_col: int, a_row: int, b_col: int, b_row: int) -> int:
	return maxi(absi(a_col - b_col), absi(a_row - b_row))
