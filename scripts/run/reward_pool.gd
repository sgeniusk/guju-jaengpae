# 전리(戰利) 보상 후보를 고르는 순수 로직. 풀 = 모든 유닛 카드, 후보 = 풀에서 현재 owned에 없는 것.
class_name RewardPool
extends RefCounted

# 현재 보유하지 않은 유닛 카드 id를 결정적 순서로 반환(테스트용).
static func eligible(catalog: CardCatalog, owned: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in catalog.cards.keys():
		var card: CardData = catalog.cards[id]
		if not (card is UnitCardData):
			continue
		if not owned.has(id):
			out.append(id)
	out.sort()
	return out

# 후보 중 최대 n장을 무작위로 뽑는다(게임 플레이용).
static func roll(catalog: CardCatalog, owned: Array[StringName], n: int) -> Array[StringName]:
	var pool := eligible(catalog, owned)
	pool.shuffle()
	return pool.slice(0, mini(n, pool.size()))
