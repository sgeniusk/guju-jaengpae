# 건물 카드의 보드 경제와 전투 진입 전 오라 적용을 검증한다.
extends TestCase

var cat: CardCatalog
var lord: LordData
var economy

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	lord = cat.get_lord(&"lord_liubei")
	var script = load("res://scripts/run/board_economy.gd")
	economy = script.new() if script != null else null

func test_gold_per_sec_sums_buildings_on_board() -> void:
	if not _require_economy():
		return
	var board := {
		"0:0": &"building_dunjeon",
		"1:0": &"general_guanyu",
		"2:2": &"building_dunjeon",
	}
	eq(economy.gold_per_sec(board, cat), 10, "둔전 2개는 초당 10골드")
	var buildings: Array = economy.buildings_on_board(board, cat)
	eq(buildings.size(), 2, "건물 카드만 보드 경제 대상")
	if buildings.size() == 2:
		eq(buildings[0].get("key", ""), "0:0", "건물 순회는 보드 키 순서로 결정적")
		eq(buildings[0].get("col", -1), 0, "건물 col 파싱")
		eq(buildings[0].get("row", -1), 0, "건물 row 파싱")

func test_apply_auras_buffs_only_units_inside_radius() -> void:
	if not _require_economy():
		return
	var board := {
		"0:0": &"building_mangru",
		"1:0": &"troop_infantry",
		"1:1": &"troop_archer",
		"2:2": &"troop_cavalry",
	}
	var nearby := _unit_at(&"troop_infantry", 1, 0)
	var diagonal := _unit_at(&"troop_archer", 1, 1)
	var outside := _unit_at(&"troop_cavalry", 2, 2)
	var army: Array[BattleUnit] = [nearby, diagonal, outside]
	economy.apply_auras(army, board, cat)
	eq(nearby.effective_attack(), 18, "망루 체비셰프 반경 1 안의 유닛 공격력 +12% 반올림")
	eq(diagonal.effective_attack(), 25, "대각선 반경 1 안의 유닛 공격력 +12% 반올림")
	eq(outside.effective_attack(), 30, "망루 반경 밖 유닛 공격력 불변")

func test_build_board_army_excludes_buildings() -> void:
	var board := {
		"0:0": &"building_dunjeon",
		"1:0": &"general_guanyu",
		"2:0": &"building_mangru",
		"0:1": &"troop_infantry",
	}
	var army := cat.build_board_army(board, lord)
	eq(army.size(), 2, "건물은 BattleSim 군세에 들어가지 않음")
	for unit in army:
		ne(unit.card_id, &"building_dunjeon", "둔전 제외")
		ne(unit.card_id, &"building_mangru", "망루 제외")

func test_building_cards_do_not_change_battlesim_result_without_aura_application() -> void:
	var board := {
		"0:0": &"building_dunjeon",
		"1:0": &"general_guanyu",
		"2:0": &"building_mangru",
		"0:1": &"troop_infantry",
		"1:1": &"troop_archer",
	}
	var army := cat.build_board_army(board, lord)
	var sim := BattleSim.new()
	for unit in army:
		sim.add_unit(unit)
	sim.add_unit(BattleUnit.make(BattleUnit.Team.ENEMY, 2, 900.0, "침입자", 30, 1, 1.0, "melee", 0.0, &"", &"", "infantry", -1, 300.0))
	eq(sim.run_to_completion(0.1, 30.0), BattleSim.Result.PLAYER_WIN, "건물 포함 보드도 기존 BattleSim 승패 규칙으로 처리")

func _require_economy() -> bool:
	not_null(economy, "BoardEconomy 로드")
	return economy != null

func _unit_at(card_id: StringName, col: int, row: int) -> BattleUnit:
	var start := BattleSim.position_for_tile(col, row)
	var unit := cat.build_player_unit(card_id, col, start.x, lord)
	unit.row = row
	unit.set_position(start.x, start.y)
	return unit
