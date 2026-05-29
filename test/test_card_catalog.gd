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
	eq(cat.cards.size(), 10, "카드 10장 로드")
	eq(cat.lords.size(), 1, "군주 1명 로드")

func test_get_card_known_and_unknown() -> void:
	not_null(cat.get_card(&"general_guanyu"), "관우 카드 조회")
	is_null(cat.get_card(&"missing_card"), "없는 카드 조회")

func test_lord_deck_has_generals_then_troops() -> void:
	var deck := cat.get_lord_deck(lord)
	eq(deck.size(), 6, "유비 시작 덱 6장")
	eq(deck[0], &"general_guanyu", "장수 1")
	eq(deck[1], &"general_zhangfei", "장수 2")
	eq(deck[2], &"general_zhugeliang", "장수 3")
	eq(deck[3], &"troop_infantry", "병종 1")
	eq(deck[4], &"troop_archer", "병종 2")
	eq(deck[5], &"troop_cavalry", "병종 3")
