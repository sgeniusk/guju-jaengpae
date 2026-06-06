# 상점 구매 피드백 helper를 검증한다.
extends TestCase

const _ShopPurchaseFeedback := preload("res://scripts/run/shop_purchase_feedback.gd")

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()

func test_availability_line_shows_purchase_and_remaining_gold() -> void:
	var card := cat.get_card(&"building_dunjeon")
	var line := _ShopPurchaseFeedback.availability_line(card, 10)
	truthy(line.contains("구매 가능"), "구매 가능 표시")
	truthy(line.contains("3금"), "비용 표시")
	truthy(line.contains("구매 후 7금"), "남은 자금 표시")
	truthy(_ShopPurchaseFeedback.availability_tooltip(card, 10).contains("남은 자금은 7금"), "tooltip 남은 자금")

func test_availability_line_shows_shortage() -> void:
	var card := cat.get_card(&"building_mangru")
	var line := _ShopPurchaseFeedback.availability_line(card, 1)
	truthy(line.contains("자금 부족"), "자금 부족 표시")
	truthy(line.contains("현재 1금"), "현재 자금 표시")
	truthy(_ShopPurchaseFeedback.availability_tooltip(card, 1).contains("더 필요"), "tooltip 부족 금액")

func test_success_line_mentions_spent_gold_and_hand_cleanup() -> void:
	var card := cat.get_card(&"troop_infantry")
	var line := _ShopPurchaseFeedback.success_line(card, 12, 11)
	truthy(line.contains("구매 완료"), "구매 완료 표시")
	truthy(line.contains("보병 1금"), "카드명과 비용 표시")
	truthy(line.contains("남은 자금 11금"), "남은 자금 표시")
	truthy(line.contains("3장으로 정리"), "다음 전투 후보 정리 안내")

func test_failure_line_explains_shortage_or_treasure_limit() -> void:
	var mangru := cat.get_card(&"building_mangru")
	var shortage := _ShopPurchaseFeedback.failure_line(mangru, 0)
	truthy(shortage.contains("자금 부족"), "실패 자금 부족")
	truthy(shortage.contains("현재 0금"), "실패 현재 자금")

	var treasure := cat.get_card(&"treasure_bingfashu")
	var limit := _ShopPurchaseFeedback.failure_line(treasure, 99)
	truthy(limit.contains("보패 제한"), "보패 제한 실패")
