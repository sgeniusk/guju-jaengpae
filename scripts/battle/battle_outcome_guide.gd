# 전투 결과 화면의 복귀/새 런 안내 문구를 순수 계산한다.
class_name BattleOutcomeGuide
extends RefCounted

static func summary_line(outcome: Dictionary) -> String:
	var run_result := String(outcome.get("run_result", "ongoing"))
	match run_result:
		"defeat":
			return "런 종료 — 성이 함락되었습니다"
		"victory":
			return "런 종료 — 구주 정복 완료"
		_:
			return "런 계속 — 전리품을 고르고 런맵으로 복귀"

static func action_line(outcome: Dictionary) -> String:
	var run_result := String(outcome.get("run_result", "ongoing"))
	match run_result:
		"defeat":
			return "기록은 프로필에 남습니다. 군주 선택에서 새 런을 시작하세요."
		"victory":
			return "해금과 최고 기록을 저장했습니다. 군주 선택에서 새 런을 시작하세요."
		_:
			return "보상 선택 후 다음 스테이지 버튼이 열립니다. 현재 런을 유지합니다."

static func banner_title(outcome: Dictionary) -> String:
	var run_result := String(outcome.get("run_result", "ongoing"))
	match run_result:
		"defeat":
			return "결과 — 성 함락"
		"victory":
			return "결과 — 구주 정복"
		_:
			return "결과 — 전투 승리"

static func banner_detail(outcome: Dictionary) -> String:
	var run_result := String(outcome.get("run_result", "ongoing"))
	match run_result:
		"defeat":
			return "이번 런은 종료됩니다. 기록을 확인하고 새 군주를 고르세요."
		"victory":
			return "최종 보스를 격파했습니다. 해금과 최고 기록을 확인하세요."
		_:
			return "전리품 한 장을 고른 뒤 다음 스테이지를 준비합니다."

static func next_action_line(outcome: Dictionary) -> String:
	if bool(outcome.get("run_complete", false)):
		return "다음 행동 — 군주 선택으로 새 런"
	return "다음 행동 — 전리품 선택 후 런맵 복귀"

static func restart_tooltip(outcome: Dictionary) -> String:
	if bool(outcome.get("run_complete", false)):
		return "완료된 런 기록은 프로필에 남습니다.\n군주 선택 화면으로 돌아가 새 런을 시작합니다."
	return "현재 런을 포기하고 자동저장 슬롯을 초기화합니다.\n군주 선택 화면으로 돌아갑니다."

static func next_stage_tooltip(stage_label: String) -> String:
	var label := stage_label.strip_edges()
	if label.is_empty():
		label = "다음 스테이지"
	return "현재 런을 유지한 채 런맵으로 돌아갑니다.\n%s를 준비합니다." % label
