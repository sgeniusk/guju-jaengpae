# 런맵 전투 준비 요약 helper를 검증한다.
extends TestCase

const _RunPrepSummary := preload("res://scripts/run/run_prep_summary.gd")

func test_empty_board_summary_explains_first_hand_choice() -> void:
	var hand := [&"scheme_raid", &"troop_infantry", &"building_dunjeon"]
	var summary := _RunPrepSummary.for_run({}, {}, hand, "", 9, CardLibrary.catalog)
	eq(int(summary.get("hand_size", 0)), 3, "손패 수 기록")
	eq(int(summary.get("place_candidates", 0)), 2, "유닛/건물은 배치 후보")
	eq(int(summary.get("scheme_candidates", 0)), 1, "계략 후보")
	falsy(bool(summary.get("castle_selected", true)), "성 미선택 기록")
	truthy(String(summary.get("title", "")).contains("손패 3장 중 1장"), "제목에 1장 규칙")
	truthy(String(summary.get("detail", "")).contains("성 위치: 미선택"), "성 미선택 표시")
	truthy(String(summary.get("tooltip", "")).contains("성 위치"), "tooltip 성 위치 안내")

func test_existing_unit_in_hand_is_upgrade_candidate() -> void:
	var board := {
		"0:0": &"troop_archer",
		"1:0": &"building_dunjeon",
	}
	var board_levels := {"0:0": 2}
	var hand := [&"troop_archer", &"troop_infantry", &"scheme_raid"]
	var summary := _RunPrepSummary.for_run(board, board_levels, hand, "2:2", 9, CardLibrary.catalog)
	eq(int(summary.get("board_count", 0)), 2, "보드 군세 수")
	truthy(bool(summary.get("castle_selected", false)), "성 선택 기록")
	eq(int(summary.get("upgrade_candidates", 0)), 1, "기존 궁병은 증원 후보")
	eq(int(summary.get("place_candidates", 0)), 1, "새 보병은 배치 후보")
	eq(int(summary.get("scheme_candidates", 0)), 1, "계략 후보 유지")
	truthy(String(summary.get("detail", "")).contains("증원 후보 1장"), "상세 증원 후보")
	truthy(String(summary.get("detail", "")).contains("배치 후보 1장"), "상세 배치 후보")
	truthy(String(summary.get("tooltip", "")).contains("3열 3행"), "성 좌표 사람이 읽는 표기")
