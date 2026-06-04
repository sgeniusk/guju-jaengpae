# TreasureCatalog의 순수 보패 효과 해석과 채널별 합산을 검증한다.
extends TestCase

func test_all_ids_are_deterministic() -> void:
	eq(TreasureCatalog.all_ids(), [&"treasure_attack_pct", &"treasure_gold_pct", &"treasure_reward_bonus"], "보패 effect id 결정 순서")
	truthy(TreasureCatalog.has_effect(&"treasure_attack_pct"), "공격 보패 effect 등록")
	falsy(TreasureCatalog.has_effect(&"missing_treasure"), "없는 effect 제외")
	eq(TreasureCatalog.info(&"treasure_gold_pct").get("name", ""), "금인", "보패 info 조회")

func test_resolve_keeps_battle_economy_reward_channels_separate() -> void:
	var attack := _make_treasure(&"treasure_attack_test", &"treasure_attack_pct", 15)
	var gold := _make_treasure(&"treasure_gold_test", &"treasure_gold_pct", 20)
	var reward := _make_treasure(&"treasure_reward_test", &"treasure_reward_bonus", 2)

	var attack_result := TreasureCatalog.resolve(attack)
	truthy(attack_result.get("ok", false), "공격 보패 해석 성공")
	almost((attack_result.get("battle", {}) as Dictionary).get("attack_pct", 0.0), 0.15, 0.0001, "공격 보패는 battle 채널")
	eq(attack_result.get("economy", {}), {}, "공격 보패는 economy 비움")

	var gold_result := TreasureCatalog.resolve(gold)
	almost((gold_result.get("economy", {}) as Dictionary).get("gold_pct", 0.0), 0.20, 0.0001, "골드 보패는 economy 채널")
	eq(gold_result.get("battle", {}), {}, "골드 보패는 battle 비움")

	var reward_result := TreasureCatalog.resolve(reward)
	eq((reward_result.get("reward", {}) as Dictionary).get("bonus_choices", 0), 2, "보상 보패는 reward 채널")
	eq(reward_result.get("battle", {}), {}, "보상 보패는 battle 비움")

func test_modifiers_sum_only_valid_owned_treasures() -> void:
	var catalog := CardCatalog.new()
	var attack_a := _make_treasure(&"treasure_attack_a", &"treasure_attack_pct", 10)
	var attack_b := _make_treasure(&"treasure_attack_b", &"treasure_attack_pct", 5)
	var gold := _make_treasure(&"treasure_gold_a", &"treasure_gold_pct", 25)
	var reward := _make_treasure(&"treasure_reward_a", &"treasure_reward_bonus", 1)
	var unknown := _make_treasure(&"treasure_unknown", &"missing_treasure", 99)
	catalog.cards[attack_a.id] = attack_a
	catalog.cards[attack_b.id] = attack_b
	catalog.cards[gold.id] = gold
	catalog.cards[reward.id] = reward
	catalog.cards[unknown.id] = unknown

	var mods := TreasureCatalog.modifiers([attack_a.id, attack_b.id, gold.id, reward.id, unknown.id, &"not_in_catalog"], catalog)
	almost((mods.get("battle", {}) as Dictionary).get("attack_pct", 0.0), 0.15, 0.0001, "공격 보패 합산")
	almost((mods.get("economy", {}) as Dictionary).get("gold_pct", 0.0), 0.25, 0.0001, "골드 보패 합산")
	eq((mods.get("reward", {}) as Dictionary).get("bonus_choices", 0), 1, "보상 보패 합산")

func test_unknown_effect_returns_failure_without_side_effects() -> void:
	var unknown := _make_treasure(&"treasure_unknown", &"missing_treasure", 9)
	var result := TreasureCatalog.resolve(unknown)
	falsy(result.get("ok", true), "없는 보패 effect 실패")
	eq(result.get("reason", ""), "unknown_effect", "실패 사유")
	eq(result.get("battle", {}), {}, "실패 결과 battle 비움")
	eq(TreasureCatalog.modifiers([unknown.id], null), {"battle": {}, "economy": {}, "reward": {}}, "카탈로그 없으면 빈 보정")

func _make_treasure(id: StringName, effect_id: StringName, value: int) -> TreasureCardData:
	var card := TreasureCardData.new()
	card.id = id
	card.display_name = String(id)
	card.effect_id = effect_id
	card.value = value
	return card
