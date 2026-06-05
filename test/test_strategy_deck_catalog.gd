extends TestCase

const StrategyDeckCatalog := preload("res://scripts/run/strategy_deck_catalog.gd")

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()

func test_each_faction_strategy_pool_has_twelve_cards_and_three_card_opening() -> void:
	for lord_id in [&"lord_liubei", &"lord_caocao", &"lord_sunquan"]:
		var lord := cat.get_lord(lord_id)
		var deck := StrategyDeckCatalog.deck_for_lord(lord)
		eq(deck.size(), StrategyDeckCatalog.TARGET_POOL_SIZE, "%s 전략 풀 12장" % String(lord_id))
		var run := RunState.new()
		run.start_run(lord, cat)
		eq(run.hand.size(), RunState.HAND_DRAW_COUNT, "%s 시작 손패 3장" % String(lord_id))
		eq(run.draw_pile.size(), StrategyDeckCatalog.TARGET_POOL_SIZE - RunState.HAND_DRAW_COUNT, "%s 남은 전략 더미 9장" % String(lord_id))

func test_strategy_pool_contains_army_and_support_classes() -> void:
	var deck := StrategyDeckCatalog.deck_for_lord(cat.get_lord(&"lord_liubei"))
	var counts := StrategyDeckCatalog.class_counts(deck, cat)
	truthy(int(counts.get("general", 0)) >= 3, "장수 선택지가 있다")
	truthy(int(counts.get("troop", 0)) >= 4, "중복 증원 가능한 병종 풀이 있다")
	truthy(int(counts.get("building", 0)) >= 2, "건물/타워 역할이 있다")
	truthy(int(counts.get("scheme", 0)) >= 2, "계략 선택지가 있다")
	eq(int(counts.get("unknown", 0)), 0, "전략 풀의 모든 id는 Resource로 로드된다")

func test_card_catalog_delegates_strategy_pool() -> void:
	var lord := cat.get_lord(&"lord_liubei")
	eq(cat.get_lord_strategy_deck(lord), StrategyDeckCatalog.deck_for_lord(lord), "CardCatalog는 전략 덱 helper와 동일")
