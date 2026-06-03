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

func test_block_keys_are_nine_unique_3x3_keys_by_default() -> void:
	truthy(run.has_method("block_keys"), "RunState.block_keys 존재")
	if not run.has_method("block_keys"):
		return
	var keys: Array = run.block_keys()
	eq(run.board_rows, 3, "기본 보드 행은 3")
	eq(keys.size(), 9, "기본 3x3 블록 9개")
	var seen := {}
	for key in keys:
		falsy(seen.has(key), "블록 키는 유일")
		seen[key] = true
		var parts: PackedStringArray = String(key).split(":")
		eq(parts.size(), 2, "블록 키는 col:row 형식")
		if parts.size() == 2:
			truthy(int(parts[0]) >= 0 and int(parts[0]) <= 2, "col 범위 0..2")
			truthy(int(parts[1]) >= 0 and int(parts[1]) <= 2, "row 범위 0..2")

func test_expand_board_grows_to_six_rows_and_caps() -> void:
	truthy(run.has_method("expand_board"), "RunState.expand_board 존재")
	if not run.has_method("expand_board"):
		return
	eq(run.board_rows, 3, "시작 보드 3행")
	truthy(run.expand_board(), "3→4행 확장 성공")
	eq(run.board_rows, 4, "4행")
	truthy(run.expand_board(), "4→5행 확장 성공")
	eq(run.board_rows, 5, "5행")
	truthy(run.expand_board(), "5→6행 확장 성공")
	eq(run.board_rows, 6, "6행")
	falsy(run.expand_board(), "6행 상한에서는 확장 실패")
	eq(run.board_rows, 6, "상한 실패 후 행 수 불변")

func test_block_keys_follow_board_rows() -> void:
	var expected_counts := {
		3: 9,
		4: 12,
		5: 15,
		6: 18,
	}
	for rows in [3, 4, 5, 6]:
		run.board_rows = rows
		var keys := run.block_keys()
		eq(keys.size(), expected_counts[rows], "%d행 키 개수" % rows)
		truthy(keys.has("0:0"), "%d행은 첫 키 포함" % rows)
		truthy(keys.has("2:%d" % (rows - 1)), "%d행은 마지막 행 키 포함" % rows)
		falsy(keys.has("0:%d" % rows), "%d행 밖 키 제외" % rows)

func test_start_run_places_lord_deck_in_hand_and_resets_board_gold() -> void:
	run.start_run(lord, cat)
	truthy(_has_property(run, "board"), "RunState.board 존재")
	truthy(_has_property(run, "hand"), "RunState.hand 존재")
	truthy(_has_property(run, "gold"), "RunState.gold 존재")
	truthy(run.has_method("board_card_ids"), "RunState.board_card_ids 존재")
	if not _has_property(run, "board") or not _has_property(run, "hand") or not _has_property(run, "gold") or not run.has_method("board_card_ids"):
		return
	eq(run.board.size(), 0, "시작 보드는 비어 있음")
	eq(run.hand, cat.get_lord_deck(lord), "유비 시작 카드 6장은 손패에 들어감")
	eq(run.gold, 0, "시작 골드는 0")
	eq(run.board_card_ids(), [], "시작 보드 카드 없음")

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

func test_board_full_tracks_expanded_capacity() -> void:
	if not _require_methods(["hand_add", "place_from_hand", "board_full", "first_free_block"]):
		return
	run.expand_board()
	var keys := _block_keys()
	eq(keys.size(), 12, "4행 보드는 12칸")
	for idx in 11:
		run.hand_add(StringName("card_%d" % idx))
		truthy(run.place_from_hand(0, keys[idx]), "확장 보드 11칸 채우기 %d" % idx)
	falsy(run.board_full(), "12칸 중 11칸은 가득 아님")
	eq(run.first_free_block(), keys[11], "마지막 1칸이 빈 블록")
	run.hand_add(&"last")
	truthy(run.place_from_hand(0, keys[11]), "12번째 칸 배치")
	truthy(run.board_full(), "4행 12칸을 채우면 가득 참")

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

func test_starting_hand_can_exceed_soft_limit() -> void:
	if not _require_methods(["hand_over_limit"]):
		return
	run.start_run(lord, cat)
	eq(run.hand.size(), 6, "시작 손패는 시작 카드 수만큼 허용")
	truthy(run.hand_over_limit(), "손패 한도 3은 소프트 경고")

func test_run_manager_deck_and_add_card_bridge_to_hand() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	for method in ["get_deck", "add_card", "get_hand", "hand_add"]:
		truthy(RunManager.has_method(method), "RunManager.%s 존재" % method)
	if not RunManager.has_method("get_deck") or not RunManager.has_method("add_card") or not RunManager.has_method("get_hand") or not RunManager.has_method("hand_add"):
		return
	if not RunManager.state.has_method("board_card_ids") or not RunManager.state.has_method("first_free_block") or not RunManager.state.has_method("board_full"):
		truthy(false, "RunManager.state 보드 브리지 API 존재")
		return
	eq(RunManager.get_deck(), RunManager.state.board_card_ids(), "get_deck은 보드 카드 브리지")
	eq(RunManager.get_deck(), [], "시작 보드는 비어 있음")
	var hand_before := RunManager.get_hand().size()
	RunManager.add_card(&"general_zhaoyun")
	eq(RunManager.get_hand().size(), hand_before + 1, "add_card 보상 브리지는 손패에 추가")
	truthy(RunManager.get_hand().has(&"general_zhaoyun"), "add_card 획득 카드는 손패에 있음")
	eq(RunManager.get_deck(), [], "add_card는 보드 자동 배치 안 함")
	RunManager.hand_add(&"troop_crossbow")
	truthy(RunManager.get_hand().has(&"troop_crossbow"), "hand_add 직접 위임")

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
	var block_key: String = RunManager.state.block_keys()[0]
	truthy(RunManager.place_from_hand(0, block_key), "RunManager.place_from_hand 위임")
	eq(RunManager.get_deck(), [&"general_zhaoyun"], "손패 배치 후 보드 브리지 반영")
	RunManager.state.hand_add(&"general_huangzhong")
	truthy(RunManager.discard_from_hand(0), "RunManager.discard_from_hand 위임")
	eq(RunManager.get_gold(), 15, "우물 버리기 골드 반영")

func test_run_manager_delegates_board_expansion() -> void:
	RunManager.reset_run()
	for method in ["get_board_rows", "get_board_capacity", "expand_board"]:
		truthy(RunManager.has_method(method), "RunManager.%s 존재" % method)
	if not RunManager.has_method("get_board_rows") or not RunManager.has_method("get_board_capacity") or not RunManager.has_method("expand_board"):
		return
	eq(RunManager.get_board_rows(), 3, "기본 보드 행 위임")
	eq(RunManager.get_board_capacity(), 9, "기본 보드 용량 위임")
	truthy(RunManager.expand_board(), "RunManager 확장 3→4")
	eq(RunManager.get_board_rows(), 4, "확장 후 4행")
	eq(RunManager.get_board_capacity(), 12, "확장 후 12칸")
	truthy(RunManager.expand_board(), "RunManager 확장 4→5")
	truthy(RunManager.expand_board(), "RunManager 확장 5→6")
	falsy(RunManager.expand_board(), "RunManager 6행 상한")
	eq(RunManager.get_board_rows(), 6, "상한 이후 6행 유지")

func test_run_manager_starting_hand_place_and_well_flow() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	for method in ["get_board", "get_hand", "place_from_hand", "discard_from_hand", "get_gold"]:
		truthy(RunManager.has_method(method), "RunManager.%s 존재" % method)
	if not RunManager.has_method("get_board") or not RunManager.has_method("get_hand"):
		return
	var starting_hand := RunManager.get_hand()
	eq(starting_hand.size(), 6, "시작 손패 6장")
	eq(RunManager.get_board().size(), 0, "시작 보드 비어 있음")
	var placed: StringName = starting_hand[0]
	truthy(RunManager.place_from_hand(0, "2:1"), "시작 손패에서 보드 배치")
	eq(RunManager.get_board().get("2:1"), placed, "선택 블록에 배치")
	eq(RunManager.get_hand().size(), 5, "배치 후 손패 -1")
	var discarded: StringName = RunManager.get_hand()[0]
	truthy(RunManager.discard_from_hand(0), "남은 손패 우물 처리")
	falsy(RunManager.get_hand().has(discarded), "우물 처리 카드 제거")
	eq(RunManager.get_gold(), RunState.WELL_GOLD, "우물 골드 반영")

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
	var block_keys := Callable(run, "block_keys")
	truthy(block_keys.is_valid(), "RunState.block_keys 존재")
	if not block_keys.is_valid():
		return []
	return block_keys.call()
