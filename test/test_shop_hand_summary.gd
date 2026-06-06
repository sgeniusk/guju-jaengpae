# 상점 손패 안내 helper가 다음 전투 후보 정리 문구를 안정적으로 만든다.
extends TestCase

const _ShopHandSummary := preload("res://scripts/run/shop_hand_summary.gd")

func test_summary_shows_shop_hand_collapsing_to_next_deploy_candidates() -> void:
	var summary := _ShopHandSummary.for_state(5, 3, true)

	eq(String(summary.get("title", "")), "다음 전투 손패 — 후보 3장 중 1장", "다음 전투 후보 title")
	truthy(String(summary.get("detail", "")).contains("상점 손패 5장 → 전투 후보 3장"), "현재 손패와 후보 수 표시")
	truthy(String(summary.get("detail", "")).contains("구매 카드는 드로우 더미"), "구매 카드 정리 안내")
	truthy(String(summary.get("tooltip", "")).contains("현재 손패 5장"), "tooltip 현재 손패")
	truthy(String(summary.get("tooltip", "")).contains("드로우 더미"), "tooltip 드로우 더미")
	truthy(bool(summary.get("refresh_pending", false)), "refresh pending 보존")

func test_summary_handles_already_prepared_deploy_hand() -> void:
	var summary := _ShopHandSummary.for_state(3, 3, false)

	eq(String(summary.get("title", "")), "다음 전투 손패 — 후보 3장 중 1장", "준비된 후보 title")
	truthy(String(summary.get("detail", "")).contains("현재 전투 후보 3장 중 1장"), "이미 준비된 후보 문구")
	truthy(String(summary.get("tooltip", "")).contains("이미 이번 전투 배치 후보"), "이미 준비된 tooltip")
