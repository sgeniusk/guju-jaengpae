# 런맵 진행 리듬 안내 helper를 검증한다.
extends TestCase

const _RunFlowSummary := preload("res://scripts/run/run_flow_summary.gd")

func test_combat_stage_summarizes_current_action_and_next_three_steps() -> void:
	var summary := _RunFlowSummary.for_stage(1)
	truthy(String(summary.get("title", "")).contains("현재 1 전투"), "현재 전투 라벨")
	truthy(String(summary.get("current", "")).contains("손패 3장 중 1장"), "현재 행동 안내")
	truthy(String(summary.get("upcoming", "")).contains("2 전투"), "다음 전투 표시")
	truthy(String(summary.get("upcoming", "")).contains("3 칙령"), "칙령 표시")
	truthy(String(summary.get("upcoming", "")).contains("4 상점"), "상점 표시")
	truthy(String(summary.get("tooltip", "")).contains("전투 시작"), "전투 tooltip")
	eq(String(summary.get("kind", "")), "combat", "kind 기록")

func test_shop_stage_points_toward_first_boss() -> void:
	var summary := _RunFlowSummary.for_stage(4, 3)
	truthy(String(summary.get("title", "")).contains("현재 4 상점"), "상점 현재 라벨")
	truthy(String(summary.get("current", "")).contains("군자금"), "상점 행동 안내")
	truthy(String(summary.get("upcoming", "")).contains("5 보스"), "첫 보스 표시")
	truthy(String(summary.get("upcoming", "")).contains("6 칙령"), "보스 뒤 칙령 표시")
	truthy(String(summary.get("upcoming", "")).contains("7 정예"), "정예 표시")
	truthy(String(summary.get("tooltip", "")).contains("상점 떠나기"), "상점 tooltip")

func test_final_boss_is_named_in_rhythm() -> void:
	var summary := _RunFlowSummary.for_stage(14, 1)
	truthy(String(summary.get("upcoming", "")).contains("15 최종 보스"), "최종 보스 표시")
	eq(int(summary.get("lookahead", -1)), 1, "lookahead 기록")

func test_non_positive_stage_clamps_to_first_stage() -> void:
	var summary := _RunFlowSummary.for_stage(0, -3)
	eq(int(summary.get("stage", 0)), 1, "stage 1로 보정")
	eq(int(summary.get("lookahead", -1)), 0, "lookahead 0으로 보정")
	truthy(String(summary.get("upcoming", "")).contains("표시할 다음 스테이지가 없습니다"), "빈 다음 흐름 안내")
