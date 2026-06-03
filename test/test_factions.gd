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

func test_hopae_trait_buffs_cavalry_attack_only() -> void:
	var caocao := cat.get_lord(&"lord_caocao")
	var cavalry := cat.build_player_unit(&"troop_cavalry", 0, 0.0, caocao)
	var infantry := cat.build_player_unit(&"troop_infantry", 1, 0.0, caocao)
	var xiahoudun := cat.build_player_unit(&"general_xiahoudun", 2, 0.0, caocao)
	not_null(cavalry, "위 기병 생성")
	not_null(infantry, "위 보병 생성")
	not_null(xiahoudun, "위 기병 장수 생성")
	eq(cavalry.attack, 38, "호패 기병 공격력 25% 증가")
	eq(infantry.attack, 16, "호패 비기병 병종 공격력 불변")
	eq(xiahoudun.attack, 58, "호패 기병 장수도 병종 기준 보정")

func test_suseon_trait_buffs_archer_and_navy_attack_only() -> void:
	var sunquan := cat.get_lord(&"lord_sunquan")
	var archer := cat.build_player_unit(&"troop_archer", 0, 0.0, sunquan)
	var navy := cat.build_player_unit(&"troop_navy", 1, 0.0, sunquan)
	var infantry := cat.build_player_unit(&"troop_infantry", 2, 0.0, sunquan)
	var zhouyu := cat.build_player_unit(&"general_zhouyu", 0, 0.0, sunquan)
	not_null(archer, "오 궁병 생성")
	not_null(navy, "오 수군 생성")
	not_null(infantry, "오 보병 생성")
	not_null(zhouyu, "오 궁병 장수 생성")
	eq(archer.attack, 26, "수전 궁병 공격력 20% 증가")
	eq(navy.attack, 24, "수전 수군 공격력 20% 증가")
	eq(infantry.attack, 16, "수전 보병 공격력 불변")
	eq(zhouyu.attack, 55, "수전 궁병 장수도 병종 기준 보정")

func test_rende_hp_trait_still_applies_without_attack_buff() -> void:
	var liubei := cat.get_lord(&"lord_liubei")
	var infantry := cat.build_player_unit(&"troop_infantry", 0, 0.0, liubei)
	not_null(infantry, "촉 보병 생성")
	eq(infantry.max_hp, 161, "인덕 병종 체력 15% 증가 유지")
	eq(infantry.attack, 16, "인덕은 공격력 보정 없음")
