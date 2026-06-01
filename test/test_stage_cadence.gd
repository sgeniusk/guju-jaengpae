# 선형 스테이지 캐이던스의 간격과 난이도 배율을 검증한다.
extends TestCase

const _StageCadence := preload("res://scripts/run/stage_cadence.gd")

func test_interval_predictors_ignore_non_positive_stages() -> void:
	for stage in [-5, -1, 0]:
		falsy(_StageCadence.is_boss(stage), "비양수 stage는 보스 아님")
		falsy(_StageCadence.is_shop(stage), "비양수 stage는 상점 아님")
		falsy(_StageCadence.is_expand(stage), "비양수 stage는 확장 아님")

func test_interval_predictors_match_cadence() -> void:
	falsy(_StageCadence.is_shop(3), "3스테이지는 상점 아님")
	truthy(_StageCadence.is_shop(4), "4스테이지는 상점")
	truthy(_StageCadence.is_shop(8), "8스테이지는 상점")
	falsy(_StageCadence.is_boss(4), "4스테이지는 보스 아님")
	truthy(_StageCadence.is_boss(5), "5스테이지는 보스")
	truthy(_StageCadence.is_boss(10), "10스테이지는 보스")
	falsy(_StageCadence.is_expand(4), "4스테이지는 확장 아님")
	truthy(_StageCadence.is_expand(5), "5스테이지는 확장")
	truthy(_StageCadence.is_expand(10), "10스테이지는 확장")

func test_difficulty_scale_is_linear_and_deterministic() -> void:
	almost(_StageCadence.difficulty_scale(-1), 1.0, 0.0001, "음수 stage는 기본 배율")
	almost(_StageCadence.difficulty_scale(0), 1.0, 0.0001, "0 stage는 기본 배율")
	almost(_StageCadence.difficulty_scale(1), 1.0, 0.0001, "1 stage는 기본 배율")
	almost(_StageCadence.difficulty_scale(2), 1.12, 0.0001, "2 stage는 1회 상승")
	almost(_StageCadence.difficulty_scale(5), 1.48, 0.0001, "5 stage는 4회 상승")
	almost(_StageCadence.difficulty_scale(9), _StageCadence.difficulty_scale(9), 0.0001, "같은 입력은 같은 배율")

func test_stage_label_marks_battle_and_boss() -> void:
	truthy(_StageCadence.stage_label(1).contains("스테이지 1"), "stage 번호 포함")
	truthy(_StageCadence.stage_label(1).contains("전투"), "일반 stage는 전투")
	truthy(_StageCadence.stage_label(5).contains("스테이지 5"), "보스 stage 번호 포함")
	truthy(_StageCadence.stage_label(5).contains("보스"), "5의 배수는 보스")
