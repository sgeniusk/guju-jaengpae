# 상점 판매 목록과 구매 상태 변화를 검증한다.
extends TestCase

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	RunManager.reset_run()

func test_purchasable_ids_include_buildings_and_are_sorted() -> void:
	var ids := cat.purchasable_ids()
	truthy(ids.has(&"building_dunjeon"), "둔전은 상점 판매 목록에 포함")
	truthy(ids.has(&"building_mangru"), "망루는 상점 판매 목록에 포함")
	truthy(ids.has(&"scheme_raid"), "계략도 상점 판매 목록에 포함")
	truthy(ids.has(&"treasure_bingfashu"), "보패도 상점 판매 목록에 포함")
	eq(ids[0], &"troop_infantry", "가장 싼 보병이 먼저")
	eq(ids[1], &"troop_archer", "비용 2 병종이 다음")
	eq(ids[2], &"troop_cavalry", "비용 동률은 id순 정렬")

func test_card_ui_text_distinguishes_purchase_and_use_routes() -> void:
	var general := cat.get_card(&"general_zhaoyun")
	var troop := cat.get_card(&"troop_infantry")
	var building := cat.get_card(&"building_dunjeon")
	var scheme := cat.get_card(&"scheme_raid")
	var treasure := cat.get_card(&"treasure_bingfashu")

	eq(CardUiText.type_label(general), "장수", "장수 타입 라벨")
	eq(CardUiText.type_label(troop), "병종", "병종 타입 라벨")
	eq(CardUiText.type_label(building), "건물", "건물 타입 라벨")
	eq(CardUiText.type_label(scheme), "계략", "계략 타입 라벨")
	eq(CardUiText.type_label(treasure), "보패", "보패 타입 라벨")

	truthy(CardUiText.shop_route_label(general).contains("보드 배치"), "장수는 보드 배치 경로")
	truthy(CardUiText.shop_route_label(building).contains("건물 배치"), "건물은 건물 배치 경로")
	truthy(CardUiText.shop_route_label(scheme).contains("계략 발동"), "계략은 발동 경로")
	truthy(CardUiText.shop_route_label(treasure).contains("즉시 장착"), "보패는 즉시 장착 경로")
	falsy(CardUiText.shop_route_label(treasure).contains("손패"), "보패 구매 문구는 손패 경로와 분리")

	truthy(CardUiText.battle_brief(scheme).contains("계략 발동"), "계략 brief는 발동을 명시")
	truthy(CardUiText.battle_brief(treasure).contains("보패 장착"), "보패 brief는 장착을 명시")
	falsy(CardUiText.battle_brief(scheme).contains("scheme_"), "계략 UI brief는 내부 effect_id를 숨김")
	falsy(CardUiText.battle_brief(treasure).contains("treasure_"), "보패 UI brief는 내부 effect_id를 숨김")

func test_shop_purchase_with_enough_gold_spends_and_adds_to_hand() -> void:
	RunManager.ensure_started(&"lord_liubei")
	RunManager.add_gold(5)
	var before_gold := RunManager.get_gold()
	var before_hand := RunManager.get_hand().size()

	var ok := RunManager.shop_purchase(&"building_dunjeon")

	truthy(ok, "구매 성공")
	eq(RunManager.get_gold(), before_gold - 3, "비용만큼 골드 차감")
	eq(RunManager.get_hand().size(), before_hand + 1, "손패에 추가")
	eq(RunManager.get_hand()[-1], &"building_dunjeon", "구매 카드가 손패 끝에 들어감")

func test_shop_purchase_without_enough_gold_is_false_and_unchanged() -> void:
	RunManager.ensure_started(&"lord_liubei")
	var before_gold := RunManager.get_gold()
	var before_hand := RunManager.get_hand()

	var ok := RunManager.shop_purchase(&"building_mangru")

	falsy(ok, "골드 부족 구매 실패")
	eq(RunManager.get_gold(), before_gold, "골드 불변")
	eq(RunManager.get_hand(), before_hand, "손패 불변")

func test_shop_stage_cadence() -> void:
	for stage in [4, 8, 12]:
		RunManager.state.stage_index = stage
		truthy(RunManager.is_shop_stage(), "stage %d는 상점" % stage)
	for stage in [1, 5]:
		RunManager.state.stage_index = stage
		falsy(RunManager.is_shop_stage(), "stage %d는 상점 아님" % stage)
