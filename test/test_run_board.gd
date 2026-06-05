# RunState의 영속 보드·손패·골드 상태 모델과 RunManager 브리지를 검증한다.
extends TestCase

const _EdictCatalog := preload("res://scripts/run/edict_catalog.gd")
const _BoardEconomy := preload("res://scripts/run/board_economy.gd")
const StrategyDeckCatalog := preload("res://scripts/run/strategy_deck_catalog.gd")

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

func test_start_run_draws_three_card_strategy_hand_and_resets_board_gold() -> void:
	run.edicts.append(&"edict_might")
	run.add_treasure(&"treasure_old")
	run.start_run(lord, cat)
	truthy(_has_property(run, "board"), "RunState.board 존재")
	truthy(_has_property(run, "hand"), "RunState.hand 존재")
	truthy(_has_property(run, "draw_pile"), "RunState.draw_pile 존재")
	truthy(_has_property(run, "gold"), "RunState.gold 존재")
	truthy(_has_property(run, "treasures"), "RunState.treasures 존재")
	truthy(run.has_method("board_card_ids"), "RunState.board_card_ids 존재")
	if not _has_property(run, "board") or not _has_property(run, "hand") or not _has_property(run, "draw_pile") or not _has_property(run, "gold") or not _has_property(run, "treasures") or not run.has_method("board_card_ids"):
		return
	eq(run.board.size(), 0, "시작 보드는 비어 있음")
	var strategy_deck := cat.get_lord_strategy_deck(lord)
	eq(strategy_deck.size(), StrategyDeckCatalog.TARGET_POOL_SIZE, "유비 전략 풀은 12장")
	eq(run.hand.size(), RunState.HAND_DRAW_COUNT, "시작 손패는 3장")
	eq(run.draw_pile.size(), strategy_deck.size() - RunState.HAND_DRAW_COUNT, "남은 전략 카드는 드로우 더미")
	eq(run.hand, [&"general_guanyu", &"troop_infantry", &"troop_archer"], "첫 선택지는 장수와 병종이 섞인 3장")
	eq(run.gold, 0, "시작 골드는 0")
	eq(run.board_card_ids(), [], "시작 보드 카드 없음")
	eq(run.edicts, [], "시작 시 칙령 누적 초기화")
	eq(run.treasures, [], "시작 시 보패 초기화")
	eq(run.castle_key, "", "성 위치는 시작 시 고정하지 않음")
	eq(run.terrain_perk_id, cat.terrain_perk_id_for_lord(lord), "군주별 지형 특전 저장")

func test_edict_catalog_sums_stacked_modifiers() -> void:
	var edicts := [&"edict_might", &"edict_might", &"edict_economy", &"edict_fortify", &"missing"]
	almost(_EdictCatalog.attack_pct(edicts), 0.20, 0.0001, "군세 2회는 공격력 +20%")
	almost(_EdictCatalog.gold_pct(edicts), 0.20, 0.0001, "재정 1회는 골드 +20%")
	almost(_EdictCatalog.castle_hp_pct(edicts), 0.15, 0.0001, "축성 1회는 성 HP +15%")
	eq(_EdictCatalog.all_ids(), [&"edict_might", &"edict_economy", &"edict_fortify"], "칙령 후보 3종 고정")
	eq(_EdictCatalog.info(&"edict_might").get("name", ""), "군세(軍勢)", "칙령 info 조회")

func test_edict_might_applies_after_lord_traits_and_stacks() -> void:
	var might_twice := [&"edict_might", &"edict_might"]
	var infantry := cat.build_player_unit(&"troop_infantry", 0, 0.0, lord, might_twice)
	not_null(infantry, "촉 보병 생성")
	eq(infantry.attack, 19, "군세 2회는 기본 공격력 16을 +20%로 보정")

	var caocao := cat.get_lord(&"lord_caocao")
	var cavalry := cat.build_player_unit(&"troop_cavalry", 0, 0.0, caocao, might_twice)
	not_null(cavalry, "호패 기병 생성")
	eq(cavalry.attack, 46, "호패 25% 적용 뒤 군세 20%를 곱셈 적용")

	var board := {"0:0": &"troop_infantry"}
	var army: Array = cat.build_board_army(board, lord, RunState.BOARD_ROWS_START, might_twice)
	eq(army.size(), 1, "build_board_army가 칙령 배열 전달")
	if army.size() == 1:
		eq(army[0].attack, 19, "보드 군세도 군세 칙령 공격력 반영")

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

func test_duplicate_unit_card_upgrades_existing_board_slot() -> void:
	if not _require_methods(["hand_add", "place_from_hand", "can_upgrade_from_hand", "upgrade_from_hand", "board_level"]):
		return
	run.hand_add(&"troop_archer")
	run.hand_add(&"troop_archer")
	truthy(run.place_from_hand(0, "1:1"), "첫 궁병 배치")
	eq(run.board_level("1:1"), 1, "첫 배치는 Lv.1")
	truthy(run.can_upgrade_from_hand(0), "같은 궁병 카드는 증원 가능")
	var upgraded_key := run.upgrade_from_hand(0)
	eq(upgraded_key, "1:1", "기존 궁병 칸을 증원")
	eq(run.board.size(), 1, "증원은 새 칸을 차지하지 않음")
	eq(run.board_level("1:1"), 2, "증원 후 Lv.2")
	eq(run.hand.size(), 0, "증원 카드는 손패에서 제거")

func test_castle_key_reserves_a_board_block() -> void:
	truthy(run.set_castle_key("1:1"), "성 위치 선택")
	eq(run.castle_key, "1:1", "성 key 저장")
	falsy(run.set_castle_key("0:0"), "성은 한 번만 선택")
	falsy(run.is_block_free("1:1"), "성 칸은 카드 배치 불가")
	run.hand_add(&"general_zhaoyun")
	falsy(run.place_from_hand(0, "1:1"), "성 칸 배치 실패")
	truthy(run.place_from_hand(0, "0:0"), "성 아닌 빈 칸 배치 성공")

func test_prepare_deploy_recycles_unpicked_hand_into_next_three_choices() -> void:
	run.start_run(lord, cat)
	truthy(run.set_castle_key("1:1"), "성 위치 선택")
	truthy(run.place_from_hand(0, "0:0"), "첫 교전 카드 1장 배치")
	run.mark_deploy_card_played()
	eq(run.hand.size(), 2, "배치 후 선택하지 않은 2장 남음")
	run.advance_stage()
	truthy(run.prepare_deploy_hand(), "다음 스테이지 배치 손패 준비")
	eq(run.hand.size(), RunState.HAND_DRAW_COUNT, "다음 배치도 3장 제시")
	eq(run.deploy_cards_played, 0, "다음 교전 배치 수 초기화")

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
	if not _require_methods(["hand_add", "discard_from_hand", "consume_from_hand"]):
		return
	run.hand_add(&"general_zhaoyun")
	run.hand_add(&"troop_crossbow")
	truthy(run.discard_from_hand(1), "우물 버리기 성공")
	eq(run.hand, [&"general_zhaoyun"], "버린 카드 손패 제거")
	eq(run.gold, 10, "우물 골드 +10")
	falsy(run.discard_from_hand(5), "잘못된 index 버리기 실패")
	eq(run.gold, 10, "실패한 버리기는 골드 불변")
	run.hand_add(&"scheme_test")
	eq(run.consume_from_hand(1), &"scheme_test", "소비는 선택한 손패 id 반환")
	eq(run.hand, [&"general_zhaoyun"], "소비한 카드는 손패에서 제거")
	eq(run.consume_from_hand(9), &"", "잘못된 index 소비는 빈 id")

func test_owned_card_ids_and_gold_spend_rules() -> void:
	if not _require_methods(["hand_add", "hand_over_limit", "owned_card_ids", "add_treasure", "treasure_ids", "add_gold", "spend_gold"]):
		return
	run.hand_add(&"general_zhaoyun")
	falsy(run.hand_over_limit(), "손패 1장은 제한 이내")
	run.hand_add(&"general_huangzhong")
	run.hand_add(&"troop_crossbow")
	falsy(run.hand_over_limit(), "손패 3장은 제한 이내")
	run.hand_add(&"troop_marine")
	truthy(run.hand_over_limit(), "손패 4장은 제한 초과")
	run.add_treasure(&"treasure_test")
	var owned: Array = run.owned_card_ids()
	eq(owned.size(), run.board.size() + run.hand.size() + run.treasures.size(), "owned = board + hand + treasures")
	truthy(owned.has(&"general_zhaoyun"), "손패 카드도 owned")
	truthy(owned.has(&"treasure_test"), "보패도 owned")
	eq(run.treasure_ids(), [&"treasure_test"], "treasure_ids는 보패 id 복사")
	var treasure_copy := run.treasure_ids()
	treasure_copy.append(&"mutated")
	eq(run.treasure_ids(), [&"treasure_test"], "treasure_ids 반환 배열 수정은 상태 불변")
	run.add_gold(15)
	eq(run.gold, 15, "골드 추가")
	truthy(run.spend_gold(10), "보유 골드 이내 소비 성공")
	eq(run.gold, 5, "소비 후 차감")
	falsy(run.spend_gold(6), "부족한 골드 소비 실패")
	eq(run.gold, 5, "실패한 소비는 골드 불변")

func test_run_state_persistent_fields_remain_id_or_primitive_values() -> void:
	run.start_run(lord, cat)
	truthy(run.place_from_hand(0, "0:0"), "보드 배치 성공")
	run.hand_add(&"scheme_raid")
	run.add_edict(&"edict_might")
	run.add_treasure(&"treasure_bingfashu")
	run.add_gold(12)
	run.expand_board()
	run.advance_stage()

	eq(typeof(run.lord_id), TYPE_STRING_NAME, "군주는 Resource가 아니라 id")
	_assert_board_id_dictionary(run.board, "board")
	_assert_id_array(run.hand, "hand")
	_assert_id_array(run.edicts, "edicts")
	_assert_id_array(run.treasures, "treasures")
	_assert_id_array(run.owned_card_ids(), "owned_card_ids")
	eq(typeof(run.gold), TYPE_INT, "gold는 primitive int")
	eq(typeof(run.board_rows), TYPE_INT, "board_rows는 primitive int")
	eq(typeof(run.stage_index), TYPE_INT, "stage_index는 primitive int")
	eq(typeof(run.wave_index), TYPE_INT, "wave_index는 primitive int")
	eq(typeof(run.command_points), TYPE_INT, "command_points는 primitive int")
	eq(typeof(run.started), TYPE_BOOL, "started는 primitive bool")

func test_starting_hand_is_capped_to_three_card_choice() -> void:
	if not _require_methods(["hand_over_limit"]):
		return
	run.start_run(lord, cat)
	eq(run.hand.size(), RunState.HAND_DRAW_COUNT, "시작 손패는 3장")
	falsy(run.hand_over_limit(), "시작부터 손패 초과하지 않음")

func test_run_manager_deck_and_add_card_bridge_to_hand() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	for method in ["get_deck", "add_card", "acquire_card", "get_hand", "hand_add", "get_treasures"]:
		truthy(RunManager.has_method(method), "RunManager.%s 존재" % method)
	if not RunManager.has_method("get_deck") or not RunManager.has_method("add_card") or not RunManager.has_method("acquire_card") or not RunManager.has_method("get_hand") or not RunManager.has_method("hand_add") or not RunManager.has_method("get_treasures"):
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
	falsy(RunManager.acquire_card(&"missing_card"), "없는 카드는 획득 실패")
	eq(RunManager.get_treasures(), [], "일반 카드 획득은 보패를 늘리지 않음")

func test_run_manager_delegates_hand_board_and_gold_operations() -> void:
	RunManager.reset_run()
	for method in ["add_card", "get_gold", "add_gold", "spend_gold", "place_from_hand", "can_discard_from_hand", "discard_from_hand", "board_full", "hand_card_type", "can_place_hand_card", "can_cast_scheme_from_hand", "cast_scheme_from_hand"]:
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
	truthy(RunManager.state.set_castle_key("1:1"), "RunManager 배치 전 성 위치 선택")
	truthy(RunManager.place_from_hand(0, block_key), "RunManager.place_from_hand 위임")
	eq(RunManager.get_deck(), [&"general_zhaoyun"], "손패 배치 후 보드 브리지 반영")
	RunManager.state.hand_add(&"general_huangzhong")
	falsy(RunManager.discard_from_hand(0), "한 장 배치 후 같은 교전 우물 실패")
	RunManager.state.deploy_cards_played = 0
	truthy(RunManager.discard_from_hand(0), "RunManager.discard_from_hand 위임")
	eq(RunManager.get_gold(), 15, "우물 버리기 골드 반영")

func test_run_manager_separates_scheme_casting_from_board_placement() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	var scheme := SchemeCardData.new()
	scheme.id = &"scheme_test_order"
	scheme.display_name = "군령 시험"
	scheme.effect_id = &"scheme_gain_gold"
	scheme.value = 7
	CardLibrary.catalog.cards[scheme.id] = scheme
	RunManager.state.hand_add(scheme.id)
	RunManager.state.hand_add(&"troop_infantry")
	truthy(RunManager.state.set_castle_key("2:2"), "계략 발동 전 성 위치 선택")

	eq(RunManager.hand_card_type(0), "scheme", "손패 0번은 계략")
	truthy(RunManager.can_cast_scheme_from_hand(0), "계략은 발동 가능")
	eq((RunManager.scheme_result_from_hand(0).get("run", {}) as Dictionary).get("gold_delta", 0), 7, "계략 결과는 run 변경 반환")
	falsy(RunManager.can_place_hand_card(0), "계략은 보드 배치 불가")
	falsy(RunManager.place_from_hand(0, "0:0"), "계략 배치 시도 실패")
	eq(RunManager.get_board(), {}, "계략은 보드에 들어가지 않음")
	truthy(RunManager.cast_scheme_from_hand(0), "계략 발동은 손패 소비")
	eq((RunManager.get_last_scheme_result().get("run", {}) as Dictionary).get("gold_delta", 0), 7, "마지막 계략 결과 기록")
	eq(RunManager.get_gold(), 7, "징발 계략은 런 골드를 즉시 올림")
	eq(RunManager.get_hand(), [&"troop_infantry"], "계략 소비 후 유닛만 남음")
	truthy(RunManager.can_place_hand_card(0), "남은 유닛은 배치 가능")
	falsy(RunManager.place_from_hand(0, "0:0"), "계략도 이번 교전 한 장으로 계산")
	RunManager.state.deploy_cards_played = 0
	truthy(RunManager.place_from_hand(0, "0:0"), "유닛 배치 성공")
	eq(RunManager.get_board().get("0:0"), &"troop_infantry", "유닛만 보드 배치")
	CardLibrary.catalog.cards.erase(scheme.id)

func test_run_manager_acquires_treasure_to_treasures_not_hand() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	var treasure := _register_test_treasure(&"treasure_test_attack_owner", &"treasure_attack_pct", 12, 3, 1)
	var before_hand := RunManager.get_hand()

	truthy(RunManager.acquire_card(treasure.id), "보패 획득 성공")
	eq(RunManager.get_hand(), before_hand, "보패는 손패에 들어가지 않음")
	eq(RunManager.get_treasures(), [treasure.id], "보패는 RunState.treasures에 장착")
	var mods := RunManager.get_treasure_modifiers()
	almost((mods.get("battle", {}) as Dictionary).get("attack_pct", 0.0), 0.12, 0.0001, "보패 공격 보정 집계")
	falsy(RunManager.acquire_card(treasure.id), "stack_limit 1 보패 중복 획득 실패")
	eq(RunManager.get_treasures(), [treasure.id], "중복 실패 후 보패 상태 불변")
	CardLibrary.catalog.cards.erase(treasure.id)

func test_shop_purchase_treasure_spends_gold_and_skips_hand() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	var treasure := _register_test_treasure(&"treasure_test_gold_shop", &"treasure_gold_pct", 25, 4, 1)
	RunManager.add_gold(8)
	var before_hand := RunManager.get_hand()

	truthy(RunManager.shop_purchase(treasure.id), "상점 보패 구매 성공")
	eq(RunManager.get_gold(), 4, "보패 비용만큼 골드 차감")
	eq(RunManager.get_hand(), before_hand, "상점 보패도 손패에 들어가지 않음")
	eq(RunManager.get_treasures(), [treasure.id], "상점 보패 장착")
	almost((RunManager.get_treasure_modifiers().get("economy", {}) as Dictionary).get("gold_pct", 0.0), 0.25, 0.0001, "보패 골드 보정 집계")
	falsy(RunManager.shop_purchase(treasure.id), "stack_limit 중복 보패 구매 실패")
	eq(RunManager.get_gold(), 4, "중복 실패는 골드 불변")
	eq(RunManager.get_treasures(), [treasure.id], "중복 실패는 보패 상태 불변")
	CardLibrary.catalog.cards.erase(treasure.id)

func test_run_manager_treasure_helpers_drive_runtime_modifiers() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	var attack := _register_test_treasure(&"treasure_test_runtime_attack", &"treasure_attack_pct", 10, 3, 1)
	var gold := _register_test_treasure(&"treasure_test_runtime_gold", &"treasure_gold_pct", 25, 3, 1)
	var reward := _register_test_treasure(&"treasure_test_runtime_reward", &"treasure_reward_bonus", 2, 3, 1)
	truthy(RunManager.acquire_card(attack.id), "공격 보패 획득")
	truthy(RunManager.acquire_card(gold.id), "골드 보패 획득")
	truthy(RunManager.acquire_card(reward.id), "보상 보패 획득")
	almost(RunManager.treasure_attack_pct(), 0.10, 0.0001, "전투 공격 보정 헬퍼")
	almost(RunManager.gold_reward_pct(), 0.25, 0.0001, "전투 골드 보정 헬퍼")
	eq(RunManager.reward_choice_count(3), 5, "보상 선택 수는 보패 보너스를 더함")

	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 100.0, "검병", 100, 20, 1.0, "melee", 0.0)
	var castle := BattleUnit.make_castle(40.0, 300.0, 1200)
	RunManager.apply_treasure_battle_modifiers([unit, castle])
	eq(unit.attack, 22, "공격 보패는 일반 아군 공격력을 보정")
	eq(castle.attack, 0, "성은 공격 보패 보정 대상이 아님")
	CardLibrary.catalog.cards.erase(attack.id)
	CardLibrary.catalog.cards.erase(gold.id)
	CardLibrary.catalog.cards.erase(reward.id)

func test_mixed_card_types_preserve_unit_troop_and_building_flow() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	RunManager.state.hand_add(&"general_zhaoyun")
	RunManager.state.hand_add(&"troop_infantry")
	RunManager.state.hand_add(&"building_dunjeon")
	RunManager.state.hand_add(&"scheme_raid")

	truthy(RunManager.can_place_hand_card(0), "장수는 기존처럼 배치 가능")
	truthy(RunManager.can_place_hand_card(1), "병종은 기존처럼 배치 가능")
	truthy(RunManager.can_place_hand_card(2), "건물은 기존처럼 배치 가능")
	falsy(RunManager.can_place_hand_card(3), "계략은 보드 배치 흐름을 타지 않음")
	truthy(RunManager.can_cast_scheme_from_hand(3), "계략은 발동 흐름을 유지")
	truthy(RunManager.state.place_from_hand(0, "0:0"), "장수 배치")
	truthy(RunManager.state.place_from_hand(0, "1:0"), "병종 배치")
	truthy(RunManager.state.place_from_hand(0, "2:0"), "건물 배치")

	eq(RunManager.get_hand(), [&"scheme_raid"], "배치 후 계략만 손패에 남음")
	var board := RunManager.get_board()
	eq(board.get("0:0"), &"general_zhaoyun", "장수 보드 id 유지")
	eq(board.get("1:0"), &"troop_infantry", "병종 보드 id 유지")
	eq(board.get("2:0"), &"building_dunjeon", "건물 보드 id 유지")
	var army: Array = CardLibrary.catalog.build_board_army(board, CardLibrary.get_lord(&"lord_liubei"), RunManager.get_board_rows(), RunManager.get_edicts())
	eq(army.size(), 2, "군세 변환은 장수·병종만 포함")
	var army_ids: Array[StringName] = []
	for unit in army:
		army_ids.append(unit.card_id)
	truthy(army_ids.has(&"general_zhaoyun"), "장수 군세 유지")
	truthy(army_ids.has(&"troop_infantry"), "병종 군세 유지")
	falsy(army_ids.has(&"building_dunjeon"), "건물은 군세 유닛으로 변환되지 않음")
	eq(_BoardEconomy.gold_per_sec(board, CardLibrary.catalog), 1, "건물 경제 흐름 유지")

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

func test_run_manager_delegates_edicts() -> void:
	RunManager.reset_run()
	for method in ["is_edict_stage", "add_edict", "get_edicts"]:
		truthy(RunManager.has_method(method), "RunManager.%s 존재" % method)
	if not RunManager.has_method("is_edict_stage") or not RunManager.has_method("add_edict") or not RunManager.has_method("get_edicts"):
		return
	falsy(RunManager.is_edict_stage(), "stage 1은 칙령 아님")
	RunManager.state.stage_index = 3
	truthy(RunManager.is_edict_stage(), "stage 3은 칙령")
	eq(RunManager.get_edicts(), [], "초기 칙령 없음")
	truthy(RunManager.add_edict(&"edict_might"), "유효 칙령 추가 성공")
	truthy(RunManager.add_edict(&"edict_economy"), "두 번째 칙령 누적")
	falsy(RunManager.add_edict(&"missing_edict"), "없는 칙령은 추가 실패")
	eq(RunManager.get_edicts(), [&"edict_might", &"edict_economy"], "칙령 누적 순서 유지")
	var copy := RunManager.get_edicts()
	copy.append(&"edict_fortify")
	eq(RunManager.get_edicts(), [&"edict_might", &"edict_economy"], "반환 배열 수정은 상태 불변")

func test_run_manager_starting_hand_place_and_well_flow() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	for method in ["get_board", "get_hand", "place_from_hand", "discard_from_hand", "get_gold"]:
		truthy(RunManager.has_method(method), "RunManager.%s 존재" % method)
	if not RunManager.has_method("get_board") or not RunManager.has_method("get_hand"):
		return
	var starting_hand := RunManager.get_hand()
	eq(starting_hand.size(), 3, "시작 손패 3장")
	eq(RunManager.get_board().size(), 0, "시작 보드 비어 있음")
	falsy(RunManager.discard_from_hand(0), "성 전 우물 실패")
	truthy(RunManager.set_castle_key("1:1"), "전투 전 성 위치 선택")
	falsy(RunManager.discard_from_hand(0), "보드 군세 전 우물 실패")
	var placed: StringName = starting_hand[0]
	truthy(RunManager.place_from_hand(0, "2:1"), "시작 손패에서 보드 배치")
	eq(RunManager.get_board().get("2:1"), placed, "선택 블록에 배치")
	eq(RunManager.get_hand().size(), 2, "배치 후 손패 -1")
	var discarded: StringName = RunManager.get_hand()[0]
	falsy(RunManager.discard_from_hand(0), "같은 교전 두 번째 우물 실패")
	RunManager.state.deploy_cards_played = 0
	truthy(RunManager.discard_from_hand(0), "남은 손패 우물 처리")
	falsy(RunManager.get_hand().has(discarded), "우물 처리 카드 제거")
	eq(RunManager.get_gold(), RunState.WELL_GOLD, "우물 골드 반영")

func test_reward_pool_excludes_owned_non_unit_hand_cards() -> void:
	if not _require_methods(["hand_add", "owned_card_ids"]):
		return
	run.start_run(lord, cat)
	var before := RewardPool.eligible(cat, run.owned_card_ids())
	var picked: StringName = &"scheme_raid"
	truthy(before.has(picked), "테스트용 계략 후보 존재")
	run.hand_add(picked)
	var after := RewardPool.eligible(cat, run.owned_card_ids())
	falsy(after.has(picked), "손패 owned 계략은 후보 제외")
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

func _assert_id_array(ids: Array, label: String) -> void:
	for id in ids:
		eq(typeof(id), TYPE_STRING_NAME, "%s는 StringName id만 저장" % label)

func _assert_board_id_dictionary(board: Dictionary, label: String) -> void:
	for key in board.keys():
		eq(typeof(key), TYPE_STRING, "%s key는 block string" % label)
		eq(typeof(board[key]), TYPE_STRING_NAME, "%s value는 card id" % label)

func _register_test_treasure(id: StringName, effect_id: StringName, value: int, cost: int, stack_limit: int) -> TreasureCardData:
	var card := TreasureCardData.new()
	card.id = id
	card.display_name = String(id)
	card.effect_id = effect_id
	card.value = value
	card.cost = cost
	card.stack_limit = stack_limit
	CardLibrary.catalog.cards[id] = card
	return card
