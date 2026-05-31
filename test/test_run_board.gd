# RunState의 영속 보드·손패·골드 상태 모델과 RunManager 브리지를 검증한다.
extends TestCase

var cat: CardCatalog
var lord: LordData
var run: RunState

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	lord = cat.get_lord(&"lord_liubei")
	run = RunState.new()

func test_block_keys_are_nine_unique_3x3_keys() -> void:
	var block_keys := Callable(RunState, "block_keys")
	truthy(block_keys.is_valid(), "RunState.block_keys 존재")
	if not block_keys.is_valid():
		return
	var keys: Array = block_keys.call()
	eq(keys.size(), 9, "3x3 블록 9개")
	var seen := {}
	for key in keys:
		falsy(seen.has(key), "블록 키는 유일")
		seen[key] = true
		var parts: PackedStringArray = String(key).split(":")
		eq(parts.size(), 2, "블록 키는 col:row 형식")
		if parts.size() == 2:
			truthy(int(parts[0]) >= 0 and int(parts[0]) <= 2, "col 범위 0..2")
			truthy(int(parts[1]) >= 0 and int(parts[1]) <= 2, "row 범위 0..2")

func test_start_run_places_lord_deck_on_board_and_resets_hand_gold() -> void:
	run.start_run(lord, cat)
	truthy(_has_property(run, "board"), "RunState.board 존재")
	truthy(_has_property(run, "hand"), "RunState.hand 존재")
	truthy(_has_property(run, "gold"), "RunState.gold 존재")
	truthy(run.has_method("board_card_ids"), "RunState.board_card_ids 존재")
	if not _has_property(run, "board") or not _has_property(run, "hand") or not _has_property(run, "gold") or not run.has_method("board_card_ids"):
		return
	eq(run.board.size(), 6, "유비 시작 카드 6장은 보드에 배치")
	eq(run.hand.size(), 0, "시작 손패는 비어 있음")
	eq(run.gold, 0, "시작 골드는 0")
	eq(run.board_card_ids(), cat.get_lord_deck(lord), "보드 카드 순서는 시작 덱 순서")

func test_place_from_hand_moves_card_to_free_block_only() -> void:
	if not _require_methods(["hand_add", "place_from_hand"]):
		return
	run.hand_add(&"general_zhaoyun")
	run.hand_add(&"general_huangzhong")
	var keys := _block_keys()
	if keys.is_empty():
		return
	var first_key: String = keys[0]
	truthy(run.place_from_hand(0, first_key), "빈 블록 배치 성공")
	eq(run.board.get(first_key), &"general_zhaoyun", "보드에 손패 카드 배치")
	eq(run.hand, [&"general_huangzhong"], "손패에서 배치 카드 제거")
	falsy(run.place_from_hand(0, first_key), "점유 블록 배치 실패")
	falsy(run.place_from_hand(7, keys[1]), "잘못된 손패 index 실패")
	eq(run.hand, [&"general_huangzhong"], "실패한 배치는 상태 불변")

func test_board_full_and_first_free_block_track_capacity() -> void:
	if not _require_methods(["hand_add", "place_from_hand", "board_full", "first_free_block"]):
		return
	var keys := _block_keys()
	if keys.size() != 9:
		return
	for idx in 9:
		run.hand_add(StringName("card_%d" % idx))
		truthy(run.place_from_hand(0, keys[idx]), "블록 채우기 %d" % idx)
	truthy(run.board_full(), "9칸을 채우면 보드 가득 참")
	is_null(run.first_free_block(), "가득 찬 보드는 빈 블록 없음")
	run.hand_add(&"overflow")
	falsy(run.place_from_hand(0, "9:9"), "잘못된 블록 키 배치 실패")

func test_discard_from_hand_removes_card_and_adds_well_gold() -> void:
	if not _require_methods(["hand_add", "discard_from_hand"]):
		return
	run.hand_add(&"general_zhaoyun")
	run.hand_add(&"troop_crossbow")
	truthy(run.discard_from_hand(1), "우물 버리기 성공")
	eq(run.hand, [&"general_zhaoyun"], "버린 카드 손패 제거")
	eq(run.gold, 10, "우물 골드 +10")
	falsy(run.discard_from_hand(5), "잘못된 index 버리기 실패")
	eq(run.gold, 10, "실패한 버리기는 골드 불변")

func test_owned_card_ids_and_gold_spend_rules() -> void:
	if not _require_methods(["hand_add", "hand_over_limit", "owned_card_ids", "add_gold", "spend_gold"]):
		return
	run.start_run(lord, cat)
	run.hand_add(&"general_zhaoyun")
	falsy(run.hand_over_limit(), "손패 1장은 제한 이내")
	run.hand_add(&"general_huangzhong")
	run.hand_add(&"troop_crossbow")
	falsy(run.hand_over_limit(), "손패 3장은 제한 이내")
	run.hand_add(&"troop_marine")
	truthy(run.hand_over_limit(), "손패 4장은 제한 초과")
	var owned: Array = run.owned_card_ids()
	eq(owned.size(), run.board.size() + run.hand.size(), "owned = board + hand")
	truthy(owned.has(&"general_zhaoyun"), "손패 카드도 owned")
	run.add_gold(15)
	eq(run.gold, 15, "골드 추가")
	truthy(run.spend_gold(10), "보유 골드 이내 소비 성공")
	eq(run.gold, 5, "소비 후 차감")
	falsy(run.spend_gold(6), "부족한 골드 소비 실패")
	eq(run.gold, 5, "실패한 소비는 골드 불변")

func test_run_manager_deck_and_add_card_bridge_board_then_hand() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	for method in ["get_deck", "add_card", "get_hand"]:
		truthy(RunManager.has_method(method), "RunManager.%s 존재" % method)
	if not RunManager.has_method("get_deck") or not RunManager.has_method("add_card") or not RunManager.has_method("get_hand"):
		return
	if not RunManager.state.has_method("board_card_ids") or not RunManager.state.has_method("first_free_block") or not RunManager.state.has_method("board_full"):
		truthy(false, "RunManager.state 보드 브리지 API 존재")
		return
	eq(RunManager.get_deck(), RunManager.state.board_card_ids(), "get_deck은 보드 카드 브리지")
	var free_before = RunManager.state.first_free_block()
	truthy(free_before != null, "시작 보드에는 빈 블록 존재")
	RunManager.add_card(&"general_zhaoyun")
	eq(RunManager.state.board.get(free_before), &"general_zhaoyun", "add_card는 빈 블록에 우선 배치")
	eq(RunManager.get_hand().size(), 0, "빈 블록 배치 시 손패 증가 없음")
	while not RunManager.state.board_full():
		RunManager.add_card(StringName("fill_%d" % RunManager.state.board.size()))
	RunManager.add_card(&"overflow_card")
	truthy(RunManager.get_hand().has(&"overflow_card"), "보드가 가득 차면 손패로 이동")
	eq(RunManager.get_deck(), RunManager.state.board_card_ids(), "가득 찬 뒤에도 get_deck은 보드만 반환")

func test_run_manager_delegates_hand_board_and_gold_operations() -> void:
	RunManager.reset_run()
	for method in ["add_card", "get_gold", "add_gold", "spend_gold", "place_from_hand", "discard_from_hand", "board_full"]:
		truthy(RunManager.has_method(method), "RunManager.%s 존재" % method)
	if not RunManager.has_method("get_gold") or not RunManager.has_method("add_gold") or not RunManager.has_method("spend_gold"):
		return
	RunManager.add_gold(20)
	eq(RunManager.get_gold(), 20, "RunManager.add_gold 위임")
	truthy(RunManager.spend_gold(15), "RunManager.spend_gold 성공 위임")
	eq(RunManager.get_gold(), 5, "RunManager.spend_gold 차감")
	falsy(RunManager.spend_gold(6), "RunManager.spend_gold 부족 실패")
	RunManager.state.hand_add(&"general_zhaoyun")
	var block_key: String = RunState.block_keys()[0]
	truthy(RunManager.place_from_hand(0, block_key), "RunManager.place_from_hand 위임")
	eq(RunManager.get_deck(), [&"general_zhaoyun"], "손패 배치 후 보드 브리지 반영")
	RunManager.state.hand_add(&"general_huangzhong")
	truthy(RunManager.discard_from_hand(0), "RunManager.discard_from_hand 위임")
	eq(RunManager.get_gold(), 15, "우물 버리기 골드 반영")

func test_reward_pool_excludes_owned_board_and_hand_cards() -> void:
	if not _require_methods(["hand_add", "owned_card_ids"]):
		return
	run.start_run(lord, cat)
	var before := RewardPool.eligible(cat, run.owned_card_ids())
	var picked: StringName = before[0]
	run.hand_add(picked)
	var after := RewardPool.eligible(cat, run.owned_card_ids())
	falsy(after.has(picked), "손패 owned 카드도 후보 제외")
	eq(after.size(), before.size() - 1, "owned 증가만큼 후보 감소")

func _has_property(obj: Object, property_name: String) -> bool:
	for property in obj.get_property_list():
		if String(property["name"]) == property_name:
			return true
	return false

func _require_methods(methods: Array[String]) -> bool:
	var ok := true
	for method in methods:
		var has_it := run.has_method(method)
		truthy(has_it, "RunState.%s 존재" % method)
		ok = ok and has_it
	return ok

func _block_keys() -> Array:
	var block_keys := Callable(RunState, "block_keys")
	truthy(block_keys.is_valid(), "RunState.block_keys 존재")
	if not block_keys.is_valid():
		return []
	return block_keys.call()
