# 보드 상태에서 전투 시작 군세를 만드는 순수 헬퍼와 RunManager 보드 브리지를 검증한다.
extends TestCase

var cat: CardCatalog
var lord: LordData

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	lord = cat.get_lord(&"lord_liubei")

func test_build_board_army_places_units_at_board_tile_positions() -> void:
	if not _require_build_board_army():
		return
	var board := {
		"0:0": &"general_guanyu",
		"1:2": &"troop_archer",
	}
	var army: Array = cat.call("build_board_army", board, lord)
	eq(army.size(), 2, "유효한 보드 카드 2장은 유닛 2개")
	if army.size() != 2:
		return
	var guanyu: BattleUnit = army[0]
	var archer: BattleUnit = army[1]
	_assert_unit_at_tile(guanyu, &"general_guanyu", 0, 0)
	_assert_unit_at_tile(archer, &"troop_archer", 1, 2)
	truthy(guanyu.controllable, "장수 카드는 영웅 조작 가능")
	falsy(archer.controllable, "병종 카드는 영웅 조작 불가")
	eq(guanyu.target_rule, cat.get_card(&"general_guanyu").target_rule, "장수 target_rule 운반")
	eq(archer.target_rule, cat.get_card(&"troop_archer").target_rule, "병종 target_rule 운반")

func test_build_board_army_skips_empty_invalid_and_unknown_blocks() -> void:
	if not _require_build_board_army():
		return
	eq(cat.call("build_board_army", {}, lord), [], "빈 보드는 빈 군세")
	var board := {
		"bad": &"general_guanyu",
		"3:0": &"troop_archer",
		"1:x": &"troop_cavalry",
		"2:1": &"missing_card",
		"0:1": &"troop_infantry",
	}
	var army: Array = cat.call("build_board_army", board, lord)
	eq(army.size(), 1, "잘못된 블록키와 없는 카드는 스킵")
	if army.size() == 1:
		_assert_unit_at_tile(army[0], &"troop_infantry", 0, 1)

func test_start_run_waits_for_manual_board_placement_before_building_army() -> void:
	if not _require_build_board_army():
		return
	var run := RunState.new()
	run.start_run(lord, cat)
	var army: Array = cat.call("build_board_army", run.board, lord)
	var deck := cat.get_lord_deck(lord)
	eq(army.size(), 0, "시작 보드는 비어 있어 군세가 없음")
	eq(run.hand, deck, "시작 카드는 손패에서 수동 배치를 기다림")
	truthy(run.place_from_hand(0, "1:2"), "손패 첫 카드 수동 배치")
	army = cat.call("build_board_army", run.board, lord)
	eq(army.size(), 1, "배치한 보드 카드만 군세 생성")
	if army.size() == 1:
		_assert_unit_at_tile(army[0], deck[0], 1, 2)

func test_run_manager_get_board_returns_copy_of_current_board() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	truthy(RunManager.has_method("get_board"), "RunManager.get_board 존재")
	if not RunManager.has_method("get_board"):
		return
	var board: Dictionary = RunManager.call("get_board")
	eq(board.size(), 0, "시작 런 보드 빈 칸")
	eq(board, RunManager.state.board, "get_board는 현재 보드 내용 반환")
	board["0:0"] = &"mutated_card"
	falsy(RunManager.state.board.has("0:0"), "반환 보드 수정은 런 상태를 바꾸지 않음")

func _require_build_board_army() -> bool:
	truthy(cat.has_method("build_board_army"), "CardCatalog.build_board_army 존재")
	return cat.has_method("build_board_army")

func _assert_unit_at_tile(unit: BattleUnit, card_id: StringName, col: int, row: int) -> void:
	var expected := BattleSim.position_for_tile(col, row)
	not_null(unit, "%s 유닛 생성" % card_id)
	if unit == null:
		return
	eq(unit.card_id, card_id, "card_id 운반")
	eq(unit.team, BattleUnit.Team.PLAYER, "아군 유닛")
	eq(unit.lane, col, "lane 필드는 보드 col")
	eq(unit.row, row, "row 필드는 보드 row")
	almost(unit.px, expected.x, 0.001, "position_for_tile x")
	almost(unit.py, expected.y, 0.001, "position_for_tile y")
