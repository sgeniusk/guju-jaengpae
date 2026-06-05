# 진형 전술 helper와 CardCatalog 군세 변환 경로를 검증한다.
extends TestCase

const _FormationTactics := preload("res://scripts/run/formation_tactics.gd")

var cat: CardCatalog
var lord: LordData

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	lord = cat.get_lord(&"lord_liubei")

func test_adjacent_general_commands_troop_attack() -> void:
	var solo := _single_unit_attack(&"troop_infantry", "1:0")
	var army := cat.build_board_army({
		"1:0": &"troop_infantry",
		"1:1": &"general_guanyu",
	}, lord)
	var infantry := _find_unit(army, &"troop_infantry")
	not_null(infantry, "보병 생성")
	if infantry == null:
		return
	truthy(infantry.attack > solo, "장수 인접 보병은 지휘 공격 보너스")
	eq(_FormationTactics.tags_for_unit(infantry, army), [_FormationTactics.TAG_COMMAND], "지휘 태그")

func test_ranged_unit_behind_melee_gets_screen_attack() -> void:
	var solo := _single_unit_attack(&"troop_archer", "1:1")
	var army := cat.build_board_army({
		"1:0": &"troop_infantry",
		"1:1": &"troop_archer",
	}, lord)
	var archer := _find_unit(army, &"troop_archer")
	not_null(archer, "궁병 생성")
	if archer == null:
		return
	truthy(archer.attack > solo, "앞 열 근접 아군 뒤 궁병은 엄호 공격 보너스")
	eq(_FormationTactics.tags_for_unit(archer, army), [_FormationTactics.TAG_SCREEN], "엄호 태그")

func test_cavalry_on_edge_lane_gets_flank_attack() -> void:
	var center := _single_unit_attack(&"troop_cavalry", "1:0")
	var edge := _single_unit_attack(&"troop_cavalry", "0:0")
	truthy(edge > center, "가장자리 기병은 측면 공격 보너스")
	var army := cat.build_board_army({"0:0": &"troop_cavalry"}, lord)
	var cavalry := _find_unit(army, &"troop_cavalry")
	not_null(cavalry, "기병 생성")
	if cavalry == null:
		return
	eq(_FormationTactics.tags_for_unit(cavalry, army), [_FormationTactics.TAG_FLANK], "측면 태그")

func test_spaced_ranged_unit_has_no_tactic_bonus() -> void:
	var solo := _single_unit_attack(&"troop_archer", "1:1")
	var army := cat.build_board_army({
		"0:0": &"troop_infantry",
		"1:1": &"troop_archer",
	}, lord)
	var archer := _find_unit(army, &"troop_archer")
	not_null(archer, "궁병 생성")
	if archer == null:
		return
	eq(archer.attack, solo, "같은 열 앞 근접 아군이 없으면 엄호 없음")
	eq(_FormationTactics.tags_for_unit(archer, army), [], "전술 태그 없음")

func test_apply_to_army_is_idempotent() -> void:
	var army := cat.build_board_army({
		"1:0": &"troop_infantry",
		"1:1": &"general_guanyu",
	}, lord)
	var infantry := _find_unit(army, &"troop_infantry")
	not_null(infantry, "보병 생성")
	if infantry == null:
		return
	var once := infantry.attack
	_FormationTactics.apply_to_army(army)
	eq(infantry.attack, once, "전술 재계산은 중첩 곱셈하지 않음")

func _single_unit_attack(card_id: StringName, key: String) -> int:
	var army := cat.build_board_army({key: card_id}, lord)
	var unit := _find_unit(army, card_id)
	return unit.attack if unit != null else -1

func _find_unit(army: Array, card_id: StringName) -> BattleUnit:
	for unit in army:
		if unit != null and unit.card_id == card_id:
			return unit
	return null
