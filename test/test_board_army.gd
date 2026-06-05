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

func test_build_board_army_respects_run_board_rows() -> void:
	if not _require_build_board_army():
		return
	var board := {
		"0:0": &"general_guanyu",
		"1:3": &"troop_archer",
		"2:5": &"troop_infantry",
	}
	var default_army: Array = cat.call("build_board_army", board, lord)
	eq(default_army.size(), 1, "기본 3행 변환은 확장 행을 스킵")
	var four_row_army: Array = cat.call("build_board_army", board, lord, 4)
	eq(four_row_army.size(), 2, "4행 변환은 row 3까지 포함")
	if four_row_army.size() == 2:
		_assert_unit_at_tile(four_row_army[1], &"troop_archer", 1, 3)
	var six_row_army: Array = cat.call("build_board_army", board, lord, 6)
	eq(six_row_army.size(), 3, "6행 변환은 row 5까지 포함")
	if six_row_army.size() == 3:
		_assert_unit_at_tile(six_row_army[2], &"troop_infantry", 2, 5)

func test_build_board_army_applies_squad_level_growth() -> void:
	if not _require_build_board_army():
		return
	var board := {"1:1": &"troop_archer"}
	var levels := {"1:1": 2}
	var army: Array = cat.call("build_board_army", board, lord, RunState.BOARD_ROWS_START, [], "", &"", levels)
	eq(army.size(), 1, "Lv.2 궁병 부대 생성")
	if army.size() != 1:
		return
	var archer: BattleUnit = army[0]
	eq(archer.squad_level, 2, "squad_level 운반")
	eq(archer.squad_count, 14, "궁병 Lv.2는 병력 14명")
	truthy(archer.max_hp > cat.get_card(&"troop_archer").max_hp, "병력 증가로 총 체력 증가")
	truthy(archer.attack > cat.get_card(&"troop_archer").attack, "레벨업으로 공격 증가")

func test_start_run_waits_for_manual_board_placement_before_building_army() -> void:
	if not _require_build_board_army():
		return
	var run := RunState.new()
	run.start_run(lord, cat)
	var army: Array = cat.call("build_board_army", run.board, lord)
	var hand := run.hand.duplicate()
	eq(army.size(), 0, "시작 보드는 비어 있어 군세가 없음")
	eq(run.hand.size(), RunState.HAND_DRAW_COUNT, "시작 카드는 3장 선택지로 수동 배치를 기다림")
	truthy(run.place_from_hand(0, "1:2"), "손패 첫 카드 수동 배치")
	army = cat.call("build_board_army", run.board, lord)
	eq(army.size(), 1, "배치한 보드 카드만 군세 생성")
	if army.size() == 1:
		_assert_unit_at_tile(army[0], hand[0], 1, 2)

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
