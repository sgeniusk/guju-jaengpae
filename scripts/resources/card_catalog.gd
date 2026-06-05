# 카드·군주 Resource를 id로 조회하는 카탈로그. 오토로드(CardLibrary)와 헤드리스 도구가 공유하는 순수 로직.
class_name CardCatalog
extends RefCounted

const CARDS_DIR := "res://resources/cards"
const LORDS_DIR := "res://resources/lords"
const _EdictCatalog := preload("res://scripts/run/edict_catalog.gd")
const _SquadProfile := preload("res://scripts/battle/squad_profile.gd")
const _TerrainPerkCatalog := preload("res://scripts/run/terrain_perk_catalog.gd")
const _StrategyDeckCatalog := preload("res://scripts/run/strategy_deck_catalog.gd")

const _REALM_SORT := {
	"mortal": 0,
	"heaven": 1,
	"demon": 2,
}
const _NATION_SORT := {
	"shu": 0,
	"wei": 1,
	"wu": 2,
}

const TERRAIN_SHU := &"terrain_shu_hometown"
const TERRAIN_WEI := &"terrain_wei_commandery"
const TERRAIN_WU := &"terrain_wu_waterway"

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
		var resource_path := resource_path_for_dir_entry(dir_path, f)
		if not dir.current_is_dir() and resource_path != "":
			var res = ResourceLoader.load(resource_path)
			if res != null and String(res.get("id")) != "":
				target[StringName(res.get("id"))] = res
		f = dir.get_next()
	dir.list_dir_end()

static func resource_path_for_dir_entry(dir_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return "%s/%s" % [dir_path, file_name]
	if file_name.ends_with(".tres.remap"):
		return "%s/%s" % [dir_path, file_name.trim_suffix(".remap")]
	return ""

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

func lord_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in lords.keys():
		ids.append(StringName(id))
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		return _lord_sort_less(a, b)
	)
	return ids

func lord_list() -> Array[LordData]:
	var out: Array[LordData] = []
	for id in lord_ids():
		var lord := get_lord(id)
		if lord != null:
			out.append(lord)
	return out

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

# 전술 런 덱 — 12장 전략 풀에서 매 교전마다 3장만 제시하고 1장을 배치한다.
func get_lord_strategy_deck(lord: LordData) -> Array[StringName]:
	return _StrategyDeckCatalog.deck_for_lord(lord)

func terrain_perk_id_for_lord(lord: LordData) -> StringName:
	return _TerrainPerkCatalog.id_for_lord(lord)

func terrain_perk_info(id: StringName) -> Dictionary:
	return _TerrainPerkCatalog.info(id)

# 군주 특성을 반영해 아군 유닛을 생성한다.
func build_player_unit(card_id: StringName, lane: int, x: float, lord: LordData, edicts: Array = [], squad_level: int = 1) -> BattleUnit:
	var card := get_card(card_id)
	if card == null or not (card is UnitCardData):
		return null
	var hp_mult := 1.0
	if lord != null and lord.trait_id == &"trait_rende" and card.card_type == "troop":
		hp_mult = 1.15
	var unit := BattleUnit.from_card(card, BattleUnit.Team.PLAYER, lane, x, hp_mult)
	_SquadProfile.apply_to_unit(unit, card, squad_level)
	if lord != null and lord.trait_id == &"trait_hopae" and card.troop_type == "cavalry":
		unit.attack = int(round(unit.attack * 1.25))
	if lord != null and lord.trait_id == &"trait_suseon" and (card.troop_type == "archer" or card.troop_type == "navy"):
		unit.attack = int(round(unit.attack * 1.20))
	var edict_attack_pct := _EdictCatalog.attack_pct(edicts)
	if edict_attack_pct > 0.0:
		unit.attack = int(round(unit.attack * (1.0 + edict_attack_pct)))
	return unit

# 영속 보드 블록을 전투 시작 위치의 아군 군세로 변환한다.
func build_board_army(board: Dictionary, lord: LordData, run_board_rows: int = RunState.BOARD_ROWS_START, edicts: Array = [], castle_key: String = "", terrain_perk_id: StringName = &"", board_levels: Dictionary = {}) -> Array[BattleUnit]:
	var army: Array[BattleUnit] = []
	var rows := clampi(run_board_rows, RunState.BOARD_ROWS_START, RunState.BOARD_ROWS_MAX)
	for row in rows:
		for col in BattleSim.COL_COUNT:
			var key := "%d:%d" % [col, row]
			if not board.has(key):
				continue
			var start := BattleSim.position_for_tile(col, row)
			var unit := build_player_unit(StringName(board[key]), col, start.x, lord, edicts, int(board_levels.get(key, 1)))
			if unit == null:
				continue
			unit.row = row
			unit.set_position(start.x, start.y)
			_TerrainPerkCatalog.apply_to_unit(unit, terrain_perk_id, col, row, castle_key)
			army.append(unit)
	return army

func _lord_sort_less(a: StringName, b: StringName) -> bool:
	var lord_a := get_lord(a)
	var lord_b := get_lord(b)
	var realm_a := _realm_sort_value(lord_a)
	var realm_b := _realm_sort_value(lord_b)
	if realm_a != realm_b:
		return realm_a < realm_b
	var nation_a := _nation_sort_value(lord_a)
	var nation_b := _nation_sort_value(lord_b)
	if nation_a != nation_b:
		return nation_a < nation_b
	return String(a) < String(b)

func _realm_sort_value(lord: LordData) -> int:
	if lord == null:
		return 999
	return int(_REALM_SORT.get(lord.realm, 999))

func _nation_sort_value(lord: LordData) -> int:
	if lord == null:
		return 999
	return int(_NATION_SORT.get(String(lord.nation), 999))
