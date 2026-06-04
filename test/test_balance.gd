# Phase 7 밸런스 패스의 핵심 수치 계약을 한곳에서 잠근다.
extends TestCase

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()

func test_difficulty_curve_reaches_final_boss_without_spiking() -> void:
	almost(StageCadence.difficulty_scale(1), 1.00, 0.0001, "1스테이지 기준 배율")
	almost(StageCadence.difficulty_scale(5), 1.40, 0.0001, "첫 보스 배율")
	almost(StageCadence.difficulty_scale(15), 2.40, 0.0001, "최종 보스 배율")
	truthy(StageCadence.difficulty_scale(15) < 2.50, "15스테이지가 과도한 배율로 치솟지 않음")

func test_edict_values_are_small_stackable_global_perks() -> void:
	almost(EdictCatalog.attack_pct([&"edict_might"]), 0.10, 0.0001, "군세 단일 공격 보정")
	almost(EdictCatalog.attack_pct([&"edict_might", &"edict_might"]), 0.20, 0.0001, "군세 중복 누적")
	almost(EdictCatalog.gold_pct([&"edict_economy"]), 0.20, 0.0001, "재정 골드 보정")
	almost(EdictCatalog.castle_hp_pct([&"edict_fortify"]), 0.15, 0.0001, "축성 성 HP 보정")

func test_building_values_support_economy_without_domination() -> void:
	var dunjeon := cat.get_card(&"building_dunjeon") as BuildingCardData
	not_null(dunjeon, "둔전 카드 로드")
	if dunjeon == null:
		return
	eq(dunjeon.cost, 3, "둔전 비용")
	eq(dunjeon.gold_per_sec, 1, "둔전 골드 생산")
	truthy(dunjeon.gold_per_sec < dunjeon.cost, "둔전은 즉시 비용을 압도하지 않음")

	var mangru := cat.get_card(&"building_mangru") as BuildingCardData
	not_null(mangru, "망루 카드 로드")
	if mangru == null:
		return
	eq(mangru.cost, 4, "망루 비용")
	almost(mangru.aura_attack_pct, 0.10, 0.0001, "망루 오라 공격 보정")
	eq(mangru.aura_radius, 1, "망루 오라 반경")

func test_scheme_levy_recovers_gold_without_shop_arbitrage() -> void:
	var levy := cat.get_card(&"scheme_levy") as SchemeCardData
	not_null(levy, "징발 카드 로드")
	if levy == null:
		return
	eq(levy.cost, 4, "징발 비용")
	eq(levy.value, 6, "징발 골드 획득량")
	truthy(levy.value <= levy.cost + 2, "상점 구매 후 즉시 큰 골드 차익을 만들지 않음")

	var result := SchemeCatalog.resolve(levy)
	truthy(result.get("ok", false), "징발 효과 해석")
	eq((result.get("run", {}) as Dictionary).get("gold_delta", 0), 6, "징발 run 골드 변경")
	eq(result.get("battle", {}), {}, "징발은 전투 입력 없음")

func test_treasure_values_stay_in_small_persistent_slots() -> void:
	var bingfashu := cat.get_card(&"treasure_bingfashu") as TreasureCardData
	var jinyin := cat.get_card(&"treasure_jinyin") as TreasureCardData
	var qianliyan := cat.get_card(&"treasure_qianliyan") as TreasureCardData
	not_null(bingfashu, "병법서 로드")
	not_null(jinyin, "금인 로드")
	not_null(qianliyan, "천리안 로드")
	if bingfashu == null or jinyin == null or qianliyan == null:
		return

	eq(bingfashu.cost, 5, "병법서 비용")
	eq(bingfashu.value, 10, "병법서 공격 보정 값")
	eq(bingfashu.stack_limit, 2, "병법서 중첩 한계")
	eq(jinyin.cost, 4, "금인 비용")
	eq(jinyin.value, 20, "금인 골드 보정 값")
	eq(qianliyan.cost, 4, "천리안 비용")
	eq(qianliyan.value, 1, "천리안 보상 선택지 보정")

	var mods := TreasureCatalog.modifiers([bingfashu.id, bingfashu.id, jinyin.id, qianliyan.id], cat)
	almost((mods.get("battle", {}) as Dictionary).get("attack_pct", 0.0), 0.20, 0.0001, "병법서 2개 공격 보정 합산")
	almost((mods.get("economy", {}) as Dictionary).get("gold_pct", 0.0), 0.20, 0.0001, "금인 골드 보정")
	eq((mods.get("reward", {}) as Dictionary).get("bonus_choices", 0), 1, "천리안 보상 보정")
