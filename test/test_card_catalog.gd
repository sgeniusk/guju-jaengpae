# CardCatalog의 로드, 조회, 덱 구성, 군주 특성 적용을 검증한다.
extends TestCase

var cat: CardCatalog
var lord: LordData

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	lord = cat.get_lord(&"lord_liubei")

func test_build_player_unit_applies_lord_trait_only_to_troops() -> void:
	var infantry := cat.build_player_unit(&"troop_infantry", 0, 0.0, lord)
	var guanyu := cat.build_player_unit(&"general_guanyu", 1, 0.0, lord)
	not_null(infantry, "보병 유닛 생성")
	not_null(guanyu, "관우 유닛 생성")
	eq(infantry.max_hp, 161, "인덕으로 병종 체력 15% 증가")
	eq(guanyu.max_hp, 320, "장수 체력은 보정하지 않음")

func test_catalog_loads_expected_counts() -> void:
	eq(cat.cards.size(), 20, "비건물 카드 20장 로드")
	eq(cat.lords.size(), 3, "군주 3명 로드")

func test_catalog_accepts_export_remap_dir_entries() -> void:
	eq(
		CardCatalog.resource_path_for_dir_entry("res://resources/cards", "troop_infantry.tres.remap"),
		"res://resources/cards/troop_infantry.tres",
		"export .tres.remap 항목은 원본 리소스 경로로 로드"
	)
	eq(
		CardCatalog.resource_path_for_dir_entry("res://resources/cards", "troop_infantry.tres"),
		"res://resources/cards/troop_infantry.tres",
		"editor .tres 항목도 유지"
	)
	eq(CardCatalog.resource_path_for_dir_entry("res://resources/cards", "README.md"), "", "비리소스 파일 제외")

func test_lord_catalog_order_is_stable_for_selection_ui() -> void:
	eq(cat.lord_ids(), [&"lord_liubei", &"lord_caocao", &"lord_sunquan"], "군주 선택 UI 기본 순서")
	var names: Array[String] = []
	for loaded_lord in cat.lord_list():
		names.append(loaded_lord.display_name)
	eq(names, ["유비", "조조", "손권"], "군주 목록은 id 순서와 같은 표시 순서")

func test_get_card_known_and_unknown() -> void:
	not_null(cat.get_card(&"general_guanyu"), "관우 카드 조회")
	is_null(cat.get_card(&"missing_card"), "없는 카드 조회")

func test_initial_scheme_and_treasure_cards_use_registered_effects() -> void:
	for id in [&"scheme_raid", &"scheme_levy", &"scheme_fortify"]:
		var card := cat.get_card(id)
		not_null(card, "%s 계략 카드 로드" % id)
		truthy(card is SchemeCardData, "%s는 SchemeCardData" % id)
		truthy(SchemeCatalog.has_effect(card.effect_id), "%s effect registry 연결" % id)
	for id in [&"treasure_bingfashu", &"treasure_jinyin", &"treasure_qianliyan"]:
		var card := cat.get_card(id)
		not_null(card, "%s 보패 카드 로드" % id)
		truthy(card is TreasureCardData, "%s는 TreasureCardData" % id)
		truthy(TreasureCatalog.has_effect(card.effect_id), "%s effect registry 연결" % id)

func test_lord_deck_has_generals_then_troops() -> void:
	var deck := cat.get_lord_deck(lord)
	eq(deck.size(), 6, "유비 시작 덱 6장")
	eq(deck[0], &"general_guanyu", "장수 1")
	eq(deck[1], &"general_zhangfei", "장수 2")
	eq(deck[2], &"general_zhugeliang", "장수 3")
	eq(deck[3], &"troop_infantry", "병종 1")
	eq(deck[4], &"troop_archer", "병종 2")
	eq(deck[5], &"troop_cavalry", "병종 3")
