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
	eq(ids[0], &"troop_infantry", "가장 싼 보병이 먼저")
	eq(ids[1], &"building_dunjeon", "비용 동률은 id순 정렬")
	eq(ids[2], &"troop_archer", "동률 id순 다음 항목")

func test_shop_purchase_with_enough_gold_spends_and_adds_to_hand() -> void:
	RunManager.ensure_started(&"lord_liubei")
	RunManager.add_gold(5)
	var before_gold := RunManager.get_gold()
	var before_hand := RunManager.get_hand().size()

	var ok := RunManager.shop_purchase(&"building_dunjeon")

	truthy(ok, "구매 성공")
	eq(RunManager.get_gold(), before_gold - 2, "비용만큼 골드 차감")
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
