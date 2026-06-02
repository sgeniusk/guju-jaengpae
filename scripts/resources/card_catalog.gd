# 카드·군주 Resource를 id로 조회하는 카탈로그. 오토로드(CardLibrary)와 헤드리스 도구가 공유하는 순수 로직.
class_name CardCatalog
extends RefCounted

const CARDS_DIR := "res://resources/cards"
const LORDS_DIR := "res://resources/lords"

var cards: Dictionary = {}   # StringName -> CardData
var building_cards: Dictionary = {}   # StringName -> BuildingCardData
var lords: Dictionary = {}   # StringName -> LordData

func load_all() -> void:
	cards.clear()
	building_cards.clear()
	lords.clear()
	_load_cards_dir(CARDS_DIR)
	_load_dir(LORDS_DIR, lords)

func _load_cards_dir(dir_path: String) -> void:
	var loaded: Dictionary = {}
	_load_dir(dir_path, loaded)
	for id in loaded.keys():
		var card: CardData = loaded[id]
		if card != null and String(card.get("card_type")) == "building":
			building_cards[id] = card
		else:
			cards[id] = card

func _load_dir(dir_path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("카탈로그 디렉토리 열기 실패: %s" % dir_path)
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".tres"):
			var res = ResourceLoader.load(dir_path + "/" + f)
			if res != null and String(res.get("id")) != "":
				target[StringName(res.get("id"))] = res
		f = dir.get_next()
	dir.list_dir_end()

func get_card(id: StringName) -> CardData:
	return cards.get(id, building_cards.get(id, null))

func purchasable_ids() -> Array[StringName]:
	var seen := {}
	for id in cards.keys():
		seen[StringName(id)] = true
	for id in building_cards.keys():
		seen[StringName(id)] = true

	var ids: Array[StringName] = []
	for id in seen.keys():
		ids.append(StringName(id))
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		var card_a := get_card(a)
		var card_b := get_card(b)
		var cost_a := card_a.cost if card_a != null else 0
		var cost_b := card_b.cost if card_b != null else 0
		if cost_a == cost_b:
			return String(a) < String(b)
		return cost_a < cost_b
	)
	return ids

func get_lord(id: StringName) -> LordData:
	return lords.get(id, null)

# 군주의 시작 덱을 카드 id 배열로 (장수 먼저, 병종 다음)
func get_lord_deck(lord: LordData) -> Array[StringName]:
	var deck: Array[StringName] = []
	if lord == null:
		return deck
	for g in lord.starting_general_ids:
		deck.append(StringName(g))
	for t in lord.starting_troop_ids:
		deck.append(StringName(t))
	return deck

# 군주 특성을 반영해 아군 유닛을 생성한다. (인덕 = 병종 시작 체력 +15%)
func build_player_unit(card_id: StringName, lane: int, x: float, lord: LordData) -> BattleUnit:
	var card := get_card(card_id)
	if card == null or not (card is UnitCardData):
		return null
	var hp_mult := 1.0
	if lord != null and lord.trait_id == &"trait_rende" and card.card_type == "troop":
		hp_mult = 1.15
	return BattleUnit.from_card(card, BattleUnit.Team.PLAYER, lane, x, hp_mult)

# 영속 보드 블록을 전투 시작 위치의 아군 군세로 변환한다.
func build_board_army(board: Dictionary, lord: LordData) -> Array[BattleUnit]:
	var army: Array[BattleUnit] = []
	for row in BattleSim.ROW_COUNT:
		for col in BattleSim.COL_COUNT:
			var key := "%d:%d" % [col, row]
			if not board.has(key):
				continue
			var start := BattleSim.position_for_tile(col, row)
			var unit := build_player_unit(StringName(board[key]), col, start.x, lord)
			if unit == null:
				continue
			unit.row = row
			unit.set_position(start.x, start.y)
			army.append(unit)
	return army
