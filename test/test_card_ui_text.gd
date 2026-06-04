# 카드 UI 문구는 내부 effect_id 대신 플레이어 행동 경로를 안내한다.
extends TestCase

func before_each() -> void:
	CardLibrary.catalog.load_all()

func test_tooltip_combines_type_route_effect_and_description() -> void:
	var scheme := CardLibrary.get_card(&"scheme_raid")
	var text := CardUiText.tooltip(scheme)
	truthy(text.find("계략") >= 0, "계략 타입 노출")
	truthy(text.find("손패 구매") >= 0, "구매 후 손패 경로 노출")
	truthy(text.find("계략 발동") >= 0, "전투 행동 경로 노출")
	truthy(text.find(scheme.description) >= 0, "카드 설명 포함")

func test_tooltip_distinguishes_treasure_immediate_equipment() -> void:
	var treasure := CardLibrary.get_card(&"treasure_bingfashu")
	var text := CardUiText.tooltip(treasure)
	truthy(text.find("보패") >= 0, "보패 타입 노출")
	truthy(text.find("즉시 장착") >= 0, "보패 즉시 장착 경로 노출")
	truthy(text.find("보패 장착") >= 0, "전투/런 효과 경로 노출")
