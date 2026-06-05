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

func test_hand_add_updates_owned_and_removes_non_unit_from_eligible() -> void:
	if not _require_methods(["owned_card_ids", "hand_add"]):
		return
	var elig := RewardPool.eligible(cat, run.owned_card_ids())
	var picked: StringName = &"scheme_raid"
	truthy(elig.has(picked), "테스트용 계략 후보 존재")
	var before: int = run.owned_card_ids().size()
	run.hand_add(picked)
	eq(run.owned_card_ids().size(), before + 1, "획득 후 owned 크기 증가")
	truthy(run.has_card(picked), "획득 카드 보유")
	var after := RewardPool.eligible(cat, run.owned_card_ids())
	eq(after.size(), elig.size() - 1, "후보 수 감소")
	falsy(after.has(picked), "계략은 획득 후 후보에서 제외")

func test_eligible_excludes_owned_and_is_deterministic() -> void:
	if not _require_methods(["owned_card_ids"]):
		return
	var elig := RewardPool.eligible(cat, run.owned_card_ids())
	var elig_again := RewardPool.eligible(cat, run.owned_card_ids())
	truthy(elig.size() > 0, "전략 덱 owned 제외 후에도 보상 후보 존재")
	eq(elig, elig_again, "같은 입력의 후보 순서 결정적")
	for id in elig:
		if run.owned_card_ids().has(id):
			var card := cat.get_card(id)
			truthy(card is UnitCardData or card is TreasureCardData, "owned 재등장은 성장/stack 가능 카드만 허용")

func test_unit_cards_remain_eligible_until_level_cap() -> void:
	if not _require_methods(["owned_card_ids", "hand_add"]):
		return
	truthy(RewardPool.eligible(cat, run.owned_card_ids()).has(&"troop_archer"), "초기 궁병은 중복 성장 후보")
	while _owned_count(&"troop_archer") < RunState.CARD_LEVEL_MAX:
		run.hand_add(&"troop_archer")
	falsy(RewardPool.eligible(cat, run.owned_card_ids()).has(&"troop_archer"), "최대 레벨 수량이면 성장 후보 제외")

func test_roll_returns_requested_count_when_pool_has_enough() -> void:
	if not _require_methods(["owned_card_ids"]):
		return
	var roll := RewardPool.roll(cat, run.owned_card_ids(), 3)
	eq(roll.size(), 3, "3장 보상 후보")

func test_reward_pool_uses_card_type_policy_and_owned_treasures() -> void:
	if not _require_methods(["owned_card_ids", "add_treasure"]):
		return
	var scheme := _add_scheme(&"scheme_reward_policy")
	var owned_treasure := _add_treasure(&"treasure_reward_owned", 1)
	var stackable_treasure := _add_treasure(&"treasure_reward_stackable", 2)
	var building := _add_building(&"building_reward_policy")
	run.add_treasure(owned_treasure.id)
	run.add_treasure(stackable_treasure.id)

	var elig := RewardPool.eligible(cat, run.owned_card_ids())
	truthy(elig.has(scheme.id), "기본 보상 풀은 계략 포함")
	falsy(elig.has(owned_treasure.id), "stack_limit 1 보패는 owned면 후보 제외")
	truthy(elig.has(stackable_treasure.id), "stack_limit 여유 보패는 후보 유지")
	falsy(elig.has(building.id), "건물은 기본 전리 보상 풀에서 제외")

	var grouped := RewardPool.by_type(cat, run.owned_card_ids())
	truthy((grouped.get("scheme", []) as Array).has(scheme.id), "타입별 pool에 계략 bucket")
	truthy((grouped.get("treasure", []) as Array).has(stackable_treasure.id), "타입별 pool에 보패 bucket")
	falsy((grouped.get("treasure", []) as Array).has(owned_treasure.id), "타입별 pool도 stack_limit 반영")

func test_reward_pool_filters_by_profile_lord_nation_and_card_unlocks() -> void:
	var profile := ProfileState.new_default()
	var shu_only := RewardPool.eligible_for_profile(cat, run.owned_card_ids(), profile)
	truthy(shu_only.has(&"scheme_raid"), "기본 프로필은 시작 풀 밖 촉 계략 보상 유지")
	falsy(shu_only.has(&"general_caocao"), "조조 해금 전 위 장수 제외")
	falsy(shu_only.has(&"general_sunquan"), "손권 해금 전 오 장수 제외")

	truthy(profile.unlock_lord(&"lord_caocao"), "조조 군주 해금")
	var with_wei := RewardPool.eligible_for_profile(cat, run.owned_card_ids(), profile)
	truthy(with_wei.has(&"general_caocao"), "위 군주 해금 후 위 장수 포함")
	truthy(with_wei.has(&"general_xiahoudun"), "위 nation 카드 포함")
	falsy(with_wei.has(&"general_sunquan"), "오 군주 해금 전 오 장수 제외")

	truthy(profile.unlock_card(&"general_sunquan"), "개별 카드 해금")
	var with_card := RewardPool.eligible_for_profile(cat, run.owned_card_ids(), profile)
	truthy(with_card.has(&"general_sunquan"), "개별 카드 해금은 nation 잠금과 별개로 포함")

func test_reward_pool_can_request_building_policy_explicitly() -> void:
	var building := _add_building(&"building_reward_explicit")
	var scheme := _add_scheme(&"scheme_reward_not_building")

	var buildings := RewardPool.eligible(cat, run.owned_card_ids(), ["building"])
	truthy(buildings.has(building.id), "명시적 building pool은 건물 포함")
	falsy(buildings.has(scheme.id), "building pool은 계략 제외")
	for id in buildings:
		var card := cat.get_card(id)
		eq(String(card.get("card_type")), "building", "명시적 pool 결과는 모두 건물")

func test_reward_roll_respects_requested_card_types() -> void:
	var scheme := _add_scheme(&"scheme_reward_roll_only")
	var treasure := _add_treasure(&"treasure_reward_roll_only", 1)

	var schemes := RewardPool.roll(cat, run.owned_card_ids(), 99, ["scheme"])
	truthy(schemes.has(scheme.id), "계략 roll에 synthetic 계략 포함")
	for id in schemes:
		eq(String(cat.get_card(id).get("card_type")), "scheme", "계략만 요청하면 계략 후보만 roll")
	var treasures := RewardPool.roll(cat, run.owned_card_ids(), 99, ["treasure"])
	truthy(treasures.has(treasure.id), "보패 roll에 synthetic 보패 포함")
	for id in treasures:
		eq(String(cat.get_card(id).get("card_type")), "treasure", "보패만 요청하면 보패 후보만 roll")

func test_start_run_sets_initial_hand_and_started() -> void:
	if not _require_methods(["board_card_ids"]):
		return
	eq(run.board_card_ids().size(), 0, "시작 보드 0장")
	eq(run.hand.size(), RunState.HAND_DRAW_COUNT, "시작 손패 3장")
	eq(run.draw_pile.size(), cat.get_lord_strategy_deck(lord).size() - RunState.HAND_DRAW_COUNT, "나머지 전략 카드는 드로우 더미")
	truthy(run.started, "런 시작 상태")
	eq(run.lord_id, &"lord_liubei", "군주 id 기록")

func _owned_count(id: StringName) -> int:
	var count := 0
	for owned_id in run.owned_card_ids():
		if owned_id == id:
			count += 1
	return count

func _require_methods(methods: Array[String]) -> bool:
	var ok := true
	for method in methods:
		var has_it := run.has_method(method)
		truthy(has_it, "RunState.%s 존재" % method)
		ok = ok and has_it
	return ok

func _add_scheme(id: StringName) -> SchemeCardData:
	var card := SchemeCardData.new()
	card.id = id
	card.display_name = String(id)
	card.effect_id = &"scheme_gain_gold"
	card.value = 3
	cat.cards[id] = card
	return card

func _add_treasure(id: StringName, stack_limit: int) -> TreasureCardData:
	var card := TreasureCardData.new()
	card.id = id
	card.display_name = String(id)
	card.effect_id = &"treasure_attack_pct"
	card.value = 10
	card.stack_limit = stack_limit
	cat.cards[id] = card
	return card

func _add_building(id: StringName) -> BuildingCardData:
	var card := BuildingCardData.new()
	card.id = id
	card.display_name = String(id)
	card.cost = 2
	card.gold_per_sec = 1
	cat.building_cards[id] = card
	return card
