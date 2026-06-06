# 상점 구매 가능 여부와 구매 결과를 player-facing 문구로 요약한다.
class_name ShopPurchaseFeedback
extends RefCounted

static func availability_line(card: CardData, gold: int) -> String:
	if card == null:
		return "구매 불가 — 카드 정보 없음"
	var current := maxi(0, gold)
	var cost := maxi(0, int(card.cost))
	if current >= cost:
		return "구매 가능 — %d금, 구매 후 %d금" % [cost, current - cost]
	return "자금 부족 — %d금 필요, 현재 %d금" % [cost, current]

static func availability_tooltip(card: CardData, gold: int) -> String:
	if card == null:
		return "카드 정보를 불러오지 못해 구매할 수 없습니다."
	var current := maxi(0, gold)
	var cost := maxi(0, int(card.cost))
	if current >= cost:
		return "현재 자금 %d금, 비용 %d금입니다. 구매하면 남은 자금은 %d금입니다." % [current, cost, current - cost]
	return "현재 자금 %d금, 비용 %d금입니다. %d금이 더 필요합니다." % [current, cost, cost - current]

static func success_line(card: CardData, before_gold: int, after_gold: int) -> String:
	var name := _card_name(card)
	var spent := maxi(0, before_gold - after_gold)
	return "구매 완료 — %s %d금, 남은 자금 %d금. 다음 전투 후보는 전투 진입 때 3장으로 정리됩니다." % [
		name,
		spent,
		maxi(0, after_gold),
	]

static func failure_line(card: CardData, gold: int) -> String:
	if card == null:
		return "구매 실패 — 카드 정보를 불러오지 못했습니다."
	var current := maxi(0, gold)
	var cost := maxi(0, int(card.cost))
	if current < cost:
		return "구매 실패 — %s. 자금 부족 %d금 (현재 %d금 / 비용 %d금)." % [
			_card_name(card),
			cost - current,
			current,
			cost,
		]
	if String(card.get("card_type")) == "treasure":
		return "구매 실패 — %s. 이미 장착했거나 보패 제한에 걸렸습니다." % _card_name(card)
	return "구매 실패 — %s. 손패나 획득 상태를 확인하세요." % _card_name(card)

static func _card_name(card: CardData) -> String:
	if card == null:
		return "알 수 없음"
	return card.display_name if card.display_name != "" else String(card.id)
