# 위·오 진영 활성화 검증 — 신규 군주·장수 카드 로드, 진영 일치, player_faction() 반환.
extends TestCase

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	RunManager.reset_run()

func test_new_lords_load_with_expected_nation() -> void:
	var caocao := cat.get_lord(&"lord_caocao")
	var sunquan := cat.get_lord(&"lord_sunquan")
	not_null(caocao, "조조 군주 로드")
	not_null(sunquan, "손권 군주 로드")
	eq(caocao.nation, &"wei", "조조 진영 위")
	eq(sunquan.nation, &"wu", "손권 진영 오")

func test_new_lord_decks_are_non_empty() -> void:
	var caocao := cat.get_lord(&"lord_caocao")
	var sunquan := cat.get_lord(&"lord_sunquan")
	truthy(cat.get_lord_deck(caocao).size() > 0, "조조 시작 덱 비어있지 않음")
	truthy(cat.get_lord_deck(sunquan).size() > 0, "손권 시작 덱 비어있지 않음")

func test_new_general_cards_load_with_matching_nation() -> void:
	var expected := {
		&"general_caocao": &"wei",
		&"general_xiahoudun": &"wei",
		&"general_sunquan": &"wu",
		&"general_zhouyu": &"wu",
	}
	for card_id in expected:
		var card := cat.get_card(card_id)
		not_null(card, "%s 카드 로드" % card_id)
		eq(card.nation, expected[card_id], "%s 진영 일치" % card_id)

func test_player_faction_matches_started_lord() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	eq(RunManager.player_faction(), &"shu", "촉 군주 → shu")

	RunManager.reset_run()
	RunManager.ensure_started(&"lord_caocao")
	eq(RunManager.player_faction(), &"wei", "위 군주 → wei")

	RunManager.reset_run()
	RunManager.ensure_started(&"lord_sunquan")
	eq(RunManager.player_faction(), &"wu", "오 군주 → wu")

func test_player_faction_falls_back_to_shu_when_unstarted() -> void:
	RunManager.reset_run()
	eq(RunManager.player_faction(), &"shu", "군주 미설정 시 shu 폴백")
