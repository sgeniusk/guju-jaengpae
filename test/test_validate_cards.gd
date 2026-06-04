# tools/validate_cards.gd의 scheme/treasure 전용 검증 규칙을 잠근다.
extends TestCase

const _ValidateCards := preload("res://tools/validate_cards.gd")

func test_existing_cards_have_no_validator_errors() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	for id in cat.cards.keys():
		var errors := _ValidateCards.card_errors(cat.cards[id])
		eq(errors.size(), 0, "%s 기존 카드 validator 통과" % id)
	for id in cat.building_cards.keys():
		var errors := _ValidateCards.card_errors(cat.building_cards[id])
		eq(errors.size(), 0, "%s 기존 건물 카드 validator 통과" % id)

func test_scheme_validator_requires_subclass_effect_registry_and_cost() -> void:
	var valid := SchemeCardData.new()
	_fill_common(valid, &"scheme_valid")
	valid.effect_id = &"scheme_gain_gold"
	valid.value = 3
	eq(_ValidateCards.card_errors(valid).size(), 0, "유효 계략 validator 통과")

	var base := CardData.new()
	_fill_common(base, &"scheme_base")
	base.card_type = "scheme"
	var base_errors := _ValidateCards.card_errors(base)
	truthy(_has_error(base_errors, "SchemeCardData"), "base CardData scheme 거부")
	truthy(_has_error(base_errors, "effect_id 비어 있음"), "scheme effect_id 필수")

	var bad := SchemeCardData.new()
	_fill_common(bad, &"scheme_bad")
	bad.cost = -1
	bad.effect_id = &"missing_scheme"
	var bad_errors := _ValidateCards.card_errors(bad)
	truthy(_has_error(bad_errors, "cost는 음수"), "scheme cost 음수 거부")
	truthy(_has_error(bad_errors, "registry 미등록"), "scheme registry 미등록 거부")

func test_treasure_validator_requires_subclass_effect_registry_cost_and_stack() -> void:
	var valid := TreasureCardData.new()
	_fill_common(valid, &"treasure_valid")
	valid.effect_id = &"treasure_attack_pct"
	valid.value = 10
	valid.stack_limit = 1
	eq(_ValidateCards.card_errors(valid).size(), 0, "유효 보패 validator 통과")

	var base := CardData.new()
	_fill_common(base, &"treasure_base")
	base.card_type = "treasure"
	var base_errors := _ValidateCards.card_errors(base)
	truthy(_has_error(base_errors, "TreasureCardData"), "base CardData treasure 거부")
	truthy(_has_error(base_errors, "effect_id 비어 있음"), "treasure effect_id 필수")
	truthy(_has_error(base_errors, "stack_limit"), "treasure stack_limit 필수")

	var bad := TreasureCardData.new()
	_fill_common(bad, &"treasure_bad")
	bad.cost = -1
	bad.effect_id = &"missing_treasure"
	bad.stack_limit = 0
	var bad_errors := _ValidateCards.card_errors(bad)
	truthy(_has_error(bad_errors, "cost는 음수"), "treasure cost 음수 거부")
	truthy(_has_error(bad_errors, "registry 미등록"), "treasure registry 미등록 거부")
	truthy(_has_error(bad_errors, "stack_limit은 1 이상"), "treasure stack_limit 하한")

func _fill_common(card: CardData, id: StringName) -> void:
	card.id = id
	card.display_name = String(id)
	card.realm = "mortal"
	card.nation = &"shu"
	card.cost = 1
	card.fantasy_tier = "romance"

func _has_error(errors: PackedStringArray, needle: String) -> bool:
	for msg in errors:
		if String(msg).contains(needle):
			return true
	return false
