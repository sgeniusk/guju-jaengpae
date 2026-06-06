# 상점 손패와 다음 전투 배치 후보의 차이를 player-facing 문구로 요약한다.
class_name ShopHandSummary
extends RefCounted

static func for_state(current_hand_size: int, preview_hand_size: int, refresh_pending: bool) -> Dictionary:
	var current := maxi(0, current_hand_size)
	var preview := maxi(0, preview_hand_size)
	var title := "다음 전투 손패 — 후보 %d장 중 1장" % preview
	var detail := ""
	if refresh_pending:
		detail = "상점 손패 %d장 → 전투 후보 %d장" % [current, preview]
		if current > preview:
			detail += " · 구매 카드는 드로우 더미로 정리"
		elif current < preview:
			detail += " · 부족분은 드로우 더미에서 보충"
		else:
			detail += " · 전투 진입 때 후보를 다시 확인"
	else:
		detail = "현재 전투 후보 %d장 중 1장" % preview
	var tooltip := _tooltip(current, preview, refresh_pending)
	return {
		"title": title,
		"detail": detail,
		"tooltip": tooltip,
		"current_hand_size": current,
		"preview_hand_size": preview,
		"refresh_pending": refresh_pending,
	}

static func _tooltip(current: int, preview: int, refresh_pending: bool) -> String:
	if refresh_pending:
		return "상점에서 구매한 카드는 현재 손패에 들어옵니다.\n전투 진입 시 현재 손패 %d장은 드로우 더미로 돌아가고 다음 배치 후보 %d장이 열립니다." % [current, preview]
	return "이미 이번 전투 배치 후보가 준비되어 있습니다. 손패 후보 %d장 중 1장을 사용합니다." % preview
