# 전투 결과 안내 helper는 런 계속/종료 경로를 명확히 구분한다.
extends TestCase

const _BattleOutcomeGuide := preload("res://scripts/battle/battle_outcome_guide.gd")

func test_defeat_explains_run_end_and_new_run_path() -> void:
	var outcome := {"run_result": "defeat", "run_complete": true}

	eq(_BattleOutcomeGuide.summary_line(outcome), "런 종료 — 성이 함락되었습니다", "패배 summary")
	eq(_BattleOutcomeGuide.banner_title(outcome), "결과 — 성 함락", "패배 banner title")
	truthy(_BattleOutcomeGuide.banner_detail(outcome).contains("런은 종료"), "패배 banner detail")
	eq(_BattleOutcomeGuide.next_action_line(outcome), "다음 행동 — 군주 선택으로 새 런", "패배 next action")
	truthy(_BattleOutcomeGuide.action_line(outcome).contains("군주 선택에서 새 런"), "패배 action")
	truthy(_BattleOutcomeGuide.restart_tooltip(outcome).contains("프로필에 남습니다"), "패배 새 런 tooltip")

func test_final_victory_explains_saved_clear_record() -> void:
	var outcome := {"run_result": "victory", "run_complete": true}

	eq(_BattleOutcomeGuide.summary_line(outcome), "런 종료 — 구주 정복 완료", "승리 summary")
	eq(_BattleOutcomeGuide.banner_title(outcome), "결과 — 구주 정복", "승리 banner title")
	truthy(_BattleOutcomeGuide.banner_detail(outcome).contains("최종 보스"), "승리 banner detail")
	eq(_BattleOutcomeGuide.next_action_line(outcome), "다음 행동 — 군주 선택으로 새 런", "승리 next action")
	truthy(_BattleOutcomeGuide.action_line(outcome).contains("해금과 최고 기록"), "승리 action")
	truthy(_BattleOutcomeGuide.restart_tooltip(outcome).contains("새 런을 시작"), "승리 새 런 tooltip")

func test_ongoing_victory_distinguishes_continue_from_abandon() -> void:
	var outcome := {"run_result": "ongoing", "run_complete": false}

	eq(_BattleOutcomeGuide.summary_line(outcome), "런 계속 — 전리품을 고르고 런맵으로 복귀", "진행 summary")
	eq(_BattleOutcomeGuide.banner_title(outcome), "결과 — 전투 승리", "진행 banner title")
	truthy(_BattleOutcomeGuide.banner_detail(outcome).contains("전리품 한 장"), "진행 banner detail")
	eq(_BattleOutcomeGuide.next_action_line(outcome), "다음 행동 — 전리품 선택 후 런맵 복귀", "진행 next action")
	truthy(_BattleOutcomeGuide.action_line(outcome).contains("현재 런을 유지"), "진행 action")
	truthy(_BattleOutcomeGuide.restart_tooltip(outcome).contains("현재 런을 포기"), "진행 새 런 tooltip")
	truthy(_BattleOutcomeGuide.next_stage_tooltip("스테이지 2 — 전투").contains("현재 런을 유지한 채"), "다음 stage tooltip")
