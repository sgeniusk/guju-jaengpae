# RunState와 RewardPool의 덱 변경 및 보상 후보 규칙을 검증한다.
extends TestCase

var cat: CardCatalog
var lord: LordData
var run: RunState

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	lord = cat.get_lord(&"lord_liubei")
	run = RunState.new()
	run.start_run(lord, cat)

func test_add_card_updates_deck_and_removes_from_eligible() -> void:
	var elig := RewardPool.eligible(cat, run.deck)
	var picked: StringName = elig[0]
	var before := run.deck.size()
	run.add_card(picked)
	eq(run.deck.size(), before + 1, "획득 후 덱 크기 증가")
	truthy(run.has_card(picked), "획득 카드 보유")
	var after := RewardPool.eligible(cat, run.deck)
	eq(after.size(), elig.size() - 1, "후보 수 감소")
	falsy(after.has(picked), "획득 카드는 후보에서 제외")

func test_eligible_excludes_deck_and_is_deterministic() -> void:
	var elig := RewardPool.eligible(cat, run.deck)
	var elig_again := RewardPool.eligible(cat, run.deck)
	eq(elig.size(), 4, "시작 덱 제외 후 후보 4장")
	eq(elig, elig_again, "같은 입력의 후보 순서 결정적")
	for id in elig:
		falsy(run.deck.has(id), "덱에 있는 카드는 후보가 아님")

func test_roll_returns_requested_count_when_pool_has_enough() -> void:
	var roll := RewardPool.roll(cat, run.deck, 3)
	eq(roll.size(), 3, "3장 보상 후보")

func test_start_run_sets_initial_deck_and_started() -> void:
	eq(run.deck.size(), 6, "시작 덱 6장")
	truthy(run.started, "런 시작 상태")
	eq(run.lord_id, &"lord_liubei", "군주 id 기록")
