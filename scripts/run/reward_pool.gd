# 전리(戰利) 보상 후보를 고르는 순수 로직. 타입별 pool 정책과 유닛 성장 반복 제안을 다룬다.
class_name RewardPool
extends RefCounted

const DEFAULT_REWARD_TYPES := ["general", "troop", "scheme", "treasure"]
const TYPE_ORDER := {
	"general": 0,
	"troop": 1,
	"scheme": 2,
	"treasure": 3,
	"building": 4,
}

# 현재 보유하지 않은 보상 카드 id를 결정적 순서로 반환(테스트용).
static func eligible(catalog: CardCatalog, owned: Array[StringName], allowed_types: Array = []) -> Array[StringName]:
	return _eligible(catalog, owned, allowed_types, {})

static func eligible_for_profile(catalog: CardCatalog, owned: Array[StringName], profile: ProfileState, allowed_types: Array = []) -> Array[StringName]:
	return _eligible(catalog, owned, allowed_types, _profile_unlock_filter(catalog, profile))

static func _eligible(catalog: CardCatalog, owned: Array[StringName], allowed_types: Array = [], unlock_filter: Dictionary = {}) -> Array[StringName]:
	var out: Array[StringName] = []
	if catalog == null:
		return out
	var type_set := _allowed_type_set(allowed_types)
	var owned_counts := _counts(owned)
	for id in _all_card_ids(catalog):
		var card := catalog.get_card(id)
		if card == null:
			continue
		var card_type := String(card.get("card_type"))
		if not type_set.has(card_type):
			continue
		if not unlock_filter.is_empty() and not _is_profile_unlocked(card, unlock_filter):
			continue
		if _can_offer(card, owned_counts):
			out.append(id)
	out.sort_custom(func(a: StringName, b: StringName) -> bool:
		return _compare_cards(catalog, a, b)
	)
	return out

static func by_type(catalog: CardCatalog, owned: Array[StringName], allowed_types: Array = []) -> Dictionary:
	return _by_type_from_ids(catalog, eligible(catalog, owned, allowed_types), allowed_types)

static func by_type_for_profile(catalog: CardCatalog, owned: Array[StringName], profile: ProfileState, allowed_types: Array = []) -> Dictionary:
	return _by_type_from_ids(catalog, eligible_for_profile(catalog, owned, profile, allowed_types), allowed_types)

static func _by_type_from_ids(catalog: CardCatalog, ids: Array[StringName], allowed_types: Array = []) -> Dictionary:
	var out := {}
	var types := _allowed_types(allowed_types)
	for card_type in types:
		out[String(card_type)] = []
	for id in ids:
		var card := catalog.get_card(id)
		if card == null:
			continue
		var card_type := String(card.get("card_type"))
		if not out.has(card_type):
			out[card_type] = []
		var bucket: Array = out[card_type]
		bucket.append(id)
		out[card_type] = bucket
	return out

# 후보 중 최대 n장을 무작위로 뽑는다(게임 플레이용).
static func roll(catalog: CardCatalog, owned: Array[StringName], n: int, allowed_types: Array = []) -> Array[StringName]:
	var pool := eligible(catalog, owned, allowed_types)
	pool.shuffle()
	return pool.slice(0, mini(n, pool.size()))

static func roll_for_profile(catalog: CardCatalog, owned: Array[StringName], profile: ProfileState, n: int, allowed_types: Array = []) -> Array[StringName]:
	var pool := eligible_for_profile(catalog, owned, profile, allowed_types)
	pool.shuffle()
	return pool.slice(0, mini(n, pool.size()))

static func _all_card_ids(catalog: CardCatalog) -> Array[StringName]:
	var seen := {}
	for id in catalog.cards.keys():
		seen[StringName(id)] = true
	for id in catalog.building_cards.keys():
		seen[StringName(id)] = true
	var ids: Array[StringName] = []
	for id in seen.keys():
		ids.append(StringName(id))
	return ids

static func _allowed_types(allowed_types: Array) -> Array:
	if allowed_types.is_empty():
		return DEFAULT_REWARD_TYPES.duplicate()
	return allowed_types.duplicate()

static func _allowed_type_set(allowed_types: Array) -> Dictionary:
	var out := {}
	for card_type in _allowed_types(allowed_types):
		out[String(card_type)] = true
	return out

static func _counts(ids: Array[StringName]) -> Dictionary:
	var out := {}
	for id in ids:
		out[StringName(id)] = int(out.get(StringName(id), 0)) + 1
	return out

static func _can_offer(card: CardData, owned_counts: Dictionary) -> bool:
	var count := int(owned_counts.get(card.id, 0))
	if card is TreasureCardData:
		return count < maxi(1, card.stack_limit)
	if card is UnitCardData:
		return count < RunState.CARD_LEVEL_MAX
	return count == 0

static func _profile_unlock_filter(catalog: CardCatalog, profile: ProfileState) -> Dictionary:
	var nations := {}
	var cards := {}
	if catalog == null or profile == null:
		return {}
	for lord_id in profile.unlocked_lord_ids:
		var lord := catalog.get_lord(StringName(lord_id))
		if lord != null:
			nations[String(lord.nation)] = true
	for card_id in profile.unlocked_card_ids:
		cards[StringName(card_id)] = true
	return {
		"nations": nations,
		"cards": cards,
	}

static func _is_profile_unlocked(card: CardData, unlock_filter: Dictionary) -> bool:
	var unlocked_cards: Dictionary = unlock_filter.get("cards", {})
	if unlocked_cards.has(card.id):
		return true
	var unlocked_nations: Dictionary = unlock_filter.get("nations", {})
	return unlocked_nations.has(String(card.nation))

static func _compare_cards(catalog: CardCatalog, a: StringName, b: StringName) -> bool:
	var card_a := catalog.get_card(a)
	var card_b := catalog.get_card(b)
	var type_a := String(card_a.get("card_type")) if card_a != null else ""
	var type_b := String(card_b.get("card_type")) if card_b != null else ""
	var order_a := int(TYPE_ORDER.get(type_a, 99))
	var order_b := int(TYPE_ORDER.get(type_b, 99))
	if order_a == order_b:
		return String(a) < String(b)
	return order_a < order_b
