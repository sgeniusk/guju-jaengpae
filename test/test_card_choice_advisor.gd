# 카드 선택 추천 헬퍼가 현재 런 맥락을 읽어 선택 이유를 만든다.
extends TestCase

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()

func test_duplicate_unit_on_board_is_upgrade_candidate() -> void:
	var ctx := CardChoiceAdvisor.context(
		{"0:0": &"troop_archer"},
		{"0:0": 2},
		[],
		0,
		cat
	)
	var advice := CardChoiceAdvisor.advice_for_card(cat.get_card(&"troop_archer"), ctx)

	eq(advice.get("label"), "증원 후보", "동일 유닛은 증원 추천")
	truthy(String(advice.get("detail")).contains("Lv.2 -> Lv.3"), "현재 레벨과 다음 레벨 표시")
	truthy(CardChoiceAdvisor.line_for_card(cat.get_card(&"troop_archer"), ctx).contains("추천 — 증원 후보"), "추천 line 제공")
	truthy(CardChoiceAdvisor.comparison_line_for_card(cat.get_card(&"troop_archer"), ctx).contains("비교 — 기존 부대 Lv.2 -> Lv.3"), "증원 비교 line 제공")
	truthy(CardChoiceAdvisor.comparison_tooltip_for_card(cat.get_card(&"troop_archer"), ctx).contains("새 칸을 쓰지 않고"), "증원 비교 tooltip 제공")

func test_first_general_and_troop_strengthen_frontline() -> void:
	var empty_ctx := CardChoiceAdvisor.context({}, {}, [], 0, cat)
	var general_advice := CardChoiceAdvisor.advice_for_card(cat.get_card(&"general_guanyu"), empty_ctx)
	var troop_advice := CardChoiceAdvisor.advice_for_card(cat.get_card(&"troop_infantry"), empty_ctx)

	eq(general_advice.get("label"), "지휘 핵심", "첫 장수는 지휘 핵심")
	eq(troop_advice.get("label"), "전열 보강", "초기 병종은 전열 보강")
	truthy(CardChoiceAdvisor.comparison_line_for_card(cat.get_card(&"general_guanyu"), empty_ctx).contains("장수 0 -> 1"), "첫 장수 비교")
	truthy(CardChoiceAdvisor.comparison_line_for_card(cat.get_card(&"troop_infantry"), empty_ctx).contains("전투 유닛 0 -> 1"), "첫 병종 비교")

func test_buildings_explain_economy_and_firepower_roles() -> void:
	var ctx := CardChoiceAdvisor.context(
		{"0:0": &"troop_infantry", "1:0": &"troop_archer"},
		{"0:0": 1, "1:0": 1},
		[],
		9,
		cat
	)

	eq(CardChoiceAdvisor.advice_for_card(cat.get_card(&"building_dunjeon"), ctx).get("label"), "경제 확장", "둔전은 경제 추천")
	eq(CardChoiceAdvisor.advice_for_card(cat.get_card(&"building_mangru"), ctx).get("label"), "화력 거점", "망루는 화력 추천")
	truthy(CardChoiceAdvisor.comparison_line_for_card(cat.get_card(&"building_dunjeon"), ctx).contains("건물 0 -> 1"), "건물 수 비교")

func test_scheme_and_treasure_explain_immediate_or_persistent_value() -> void:
	var ctx := CardChoiceAdvisor.context({}, {}, [], 0, cat)

	eq(CardChoiceAdvisor.advice_for_card(cat.get_card(&"scheme_raid"), ctx).get("label"), "즉시 한 수", "공격 계략 추천")
	eq(CardChoiceAdvisor.advice_for_card(cat.get_card(&"treasure_qianliyan"), ctx).get("label"), "보상 확장", "보상 보패 추천")
	eq(CardChoiceAdvisor.advice_for_card(cat.get_card(&"treasure_bingfashu"), ctx).get("label"), "지속 화력", "화력 보패 추천")
	truthy(CardChoiceAdvisor.comparison_line_for_card(cat.get_card(&"scheme_raid"), ctx).contains("손패 0 -> 1"), "계략 손패 비교")
	truthy(CardChoiceAdvisor.comparison_line_for_card(cat.get_card(&"treasure_qianliyan"), ctx).contains("보패 즉시 장착"), "보패 장착 비교")

func test_shop_mode_marks_unaffordable_cards() -> void:
	var ctx := CardChoiceAdvisor.context({}, {}, [], 0, cat)
	var advice := CardChoiceAdvisor.advice_for_card(cat.get_card(&"building_mangru"), ctx, CardChoiceAdvisor.MODE_SHOP)

	eq(advice.get("label"), "자금 부족", "상점에서 골드 부족 표시")
	truthy(String(advice.get("detail")).contains("금 더 필요"), "부족 골드 설명")
	truthy(CardChoiceAdvisor.tooltip_for_card(cat.get_card(&"building_mangru"), ctx, CardChoiceAdvisor.MODE_SHOP).contains("추천 — 자금 부족"), "tooltip 추천 표시")

func test_ranked_ids_put_upgrade_and_stronger_advice_first() -> void:
	var ctx := CardChoiceAdvisor.context(
		{"0:0": &"troop_archer"},
		{"0:0": 2},
		[],
		99,
		cat
	)
	var ranked := CardChoiceAdvisor.ranked_ids(
		[&"scheme_raid", &"building_dunjeon", &"troop_archer"],
		ctx,
		cat,
		CardChoiceAdvisor.MODE_REWARD
	)

	eq(ranked[0], &"troop_archer", "증원 후보가 가장 먼저")
	eq(ranked[1], &"building_dunjeon", "경제 확장은 즉시 계략보다 먼저")
	eq(ranked[2], &"scheme_raid", "낮은 점수는 뒤로")

func test_shop_ranking_keeps_unaffordable_cards_late() -> void:
	var ctx := CardChoiceAdvisor.context({}, {}, [], 2, cat)
	var ranked := CardChoiceAdvisor.ranked_ids(
		[&"building_mangru", &"troop_infantry", &"troop_archer"],
		ctx,
		cat,
		CardChoiceAdvisor.MODE_SHOP
	)

	eq(ranked[0], &"troop_infantry", "살 수 있는 전열 보강 카드가 먼저")
	eq(ranked[1], &"troop_archer", "동점은 기존 순서 유지")
	eq(ranked[2], &"building_mangru", "살 수 없는 카드는 뒤로")
