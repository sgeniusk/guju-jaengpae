# 계략 효과 레지스트리가 RNG/I/O 없이 결정적 결과 딕셔너리를 반환하는지 검증한다.
extends TestCase

func test_scheme_catalog_lists_known_effects() -> void:
	var ids := SchemeCatalog.all_ids()
	eq(ids, [&"scheme_damage_enemy", &"scheme_fortify_castle", &"scheme_gain_gold"], "effect_id 결정적 정렬")
	truthy(SchemeCatalog.has_effect(&"scheme_gain_gold"), "등록 효과 조회")
	falsy(SchemeCatalog.has_effect(&"missing_scheme"), "없는 효과는 false")
	eq(SchemeCatalog.info(&"scheme_gain_gold").get("run_key", ""), "gold_delta", "info 복사 조회")

func test_damage_scheme_resolves_to_battle_input_without_mutation() -> void:
	var card := SchemeCardData.new()
	card.id = &"scheme_test_damage"
	card.effect_id = &"scheme_damage_enemy"
	card.target_policy = "enemy"
	card.value = 55
	var context := {"stage": 2}

	var result := SchemeCatalog.resolve(card, context)

	truthy(result.get("ok", false), "해석 성공")
	eq(result.get("effect_id", &""), &"scheme_damage_enemy", "effect_id 운반")
	var battle: Dictionary = result.get("battle", {})
	var damage: Dictionary = battle.get("damage_enemy", {})
	eq(damage.get("amount", 0), 55, "피해량은 카드 value")
	eq(damage.get("target_policy", ""), "enemy", "target_policy 운반")
	eq(result.get("run", {}), {}, "전투 계략은 run 변경 없음")
	context["stage"] = 9
	eq((result.get("context", {}) as Dictionary).get("stage", 0), 2, "context는 복사되어 반환")

func test_gain_gold_and_fortify_resolve_to_separate_channels() -> void:
	var gain := SchemeCardData.new()
	gain.effect_id = &"scheme_gain_gold"
	gain.value = 7
	var gain_result := SchemeCatalog.resolve(gain)
	eq((gain_result.get("run", {}) as Dictionary).get("gold_delta", 0), 7, "골드 계략은 run 변경 반환")
	eq(gain_result.get("battle", {}), {}, "골드 계략은 battle 입력 없음")

	var fortify := SchemeCardData.new()
	fortify.effect_id = &"scheme_fortify_castle"
	fortify.value = 120
	var fortify_result := SchemeCatalog.resolve(fortify)
	eq((fortify_result.get("battle", {}) as Dictionary).get("castle_hp_delta", 0), 120, "수축 계략은 성 HP 입력 반환")
	eq(fortify_result.get("run", {}), {}, "수축 계략은 run 변경 없음")

func test_unknown_scheme_returns_failure_without_actions() -> void:
	var card := SchemeCardData.new()
	card.effect_id = &"missing_scheme"

	var result := SchemeCatalog.resolve(card)

	falsy(result.get("ok", true), "없는 effect는 실패")
	eq(result.get("reason", ""), "unknown_effect", "실패 이유")
	eq(result.get("battle", {}), {}, "실패 battle 없음")
	eq(result.get("run", {}), {}, "실패 run 없음")
