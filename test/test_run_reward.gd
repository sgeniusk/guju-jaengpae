# RunState와 RewardPool의 owned 기준 보상 후보 규칙을 검증한다.
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

func test_hand_add_updates_owned_and_removes_from_eligible() -> void:
	if not _require_methods(["owned_card_ids", "hand_add"]):
		return
	var elig := RewardPool.eligible(cat, run.owned_card_ids())
	var picked: StringName = elig[0]
	var before: int = run.owned_card_ids().size()
	run.hand_add(picked)
	eq(run.owned_card_ids().size(), before + 1, "획득 후 owned 크기 증가")
	truthy(run.has_card(picked), "획득 카드 보유")
	var after := RewardPool.eligible(cat, run.owned_card_ids())
	eq(after.size(), elig.size() - 1, "후보 수 감소")
	falsy(after.has(picked), "획득 카드는 후보에서 제외")

func test_eligible_excludes_owned_and_is_deterministic() -> void:
	if not _require_methods(["owned_card_ids"]):
		return
	var elig := RewardPool.eligible(cat, run.owned_card_ids())
	var elig_again := RewardPool.eligible(cat, run.owned_card_ids())
	eq(elig.size(), 4, "시작 보드 제외 후 후보 4장")
	eq(elig, elig_again, "같은 입력의 후보 순서 결정적")
	for id in elig:
		falsy(run.owned_card_ids().has(id), "owned에 있는 카드는 후보가 아님")

func test_roll_returns_requested_count_when_pool_has_enough() -> void:
	if not _require_methods(["owned_card_ids"]):
		return
	var roll := RewardPool.roll(cat, run.owned_card_ids(), 3)
	eq(roll.size(), 3, "3장 보상 후보")

func test_start_run_sets_initial_hand_and_started() -> void:
	if not _require_methods(["board_card_ids"]):
		return
	eq(run.board_card_ids().size(), 0, "시작 보드 0장")
	eq(run.hand.size(), 6, "시작 손패 6장")
	truthy(run.started, "런 시작 상태")
	eq(run.lord_id, &"lord_liubei", "군주 id 기록")

func _require_methods(methods: Array[String]) -> bool:
	var ok := true
	for method in methods:
		var has_it := run.has_method(method)
		truthy(has_it, "RunState.%s 존재" % method)
		ok = ok and has_it
	return ok
