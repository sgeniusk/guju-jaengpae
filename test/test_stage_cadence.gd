# 선형 스테이지 캐이던스의 간격과 난이도 배율을 검증한다.
extends TestCase

const _StageCadence := preload("res://scripts/run/stage_cadence.gd")

func test_interval_predictors_ignore_non_positive_stages() -> void:
	for stage in [-5, -1, 0]:
		falsy(_StageCadence.is_boss(stage), "비양수 stage는 보스 아님")
		falsy(_StageCadence.is_shop(stage), "비양수 stage는 상점 아님")
		falsy(_StageCadence.is_expand(stage), "비양수 stage는 확장 아님")
		falsy(_StageCadence.is_edict(stage), "비양수 stage는 칙령 아님")
		falsy(_StageCadence.is_elite(stage), "비양수 stage는 정예 아님")
		falsy(_StageCadence.is_event(stage), "비양수 stage는 사건 아님")

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
	truthy(_StageCadence.is_edict(3), "3스테이지는 칙령")
	truthy(_StageCadence.is_edict(6), "6스테이지는 칙령")
	truthy(_StageCadence.is_edict(9), "9스테이지는 칙령")
	falsy(_StageCadence.is_edict(4), "4스테이지는 칙령 아님")
	falsy(_StageCadence.is_edict(5), "5스테이지는 칙령 아님")
	falsy(_StageCadence.is_elite(6), "6스테이지는 정예 아님")
	truthy(_StageCadence.is_elite(7), "7스테이지는 정예")
	truthy(_StageCadence.is_elite(14), "14스테이지는 정예")
	falsy(_StageCadence.is_event(10), "10스테이지는 사건 아님")
	truthy(_StageCadence.is_event(11), "11스테이지는 사건")
	truthy(_StageCadence.is_event(22), "22스테이지는 사건")

func test_node_kind_prioritizes_boss_edict_shop_elite_event_expand_combat() -> void:
	eq(_StageCadence.node_kind(1), "combat", "일반 stage는 combat")
	eq(_StageCadence.node_kind(3), "edict", "3스테이지는 칙령")
	eq(_StageCadence.node_kind(4), "shop", "4스테이지는 상점")
	eq(_StageCadence.node_kind(5), "boss", "5스테이지는 보스")
	eq(_StageCadence.node_kind(7), "elite", "7스테이지는 정예")
	eq(_StageCadence.node_kind(11), "event", "11스테이지는 사건")
	eq(_StageCadence.node_kind(10), "boss", "보스가 확장보다 우선")
	eq(_StageCadence.node_kind(12), "edict", "칙령이 상점보다 우선")
	eq(_StageCadence.node_kind(15), "boss", "보스가 칙령보다 우선")
	eq(_StageCadence.node_kind(21), "edict", "칙령이 정예보다 우선")
	eq(_StageCadence.node_kind(28), "shop", "상점이 정예보다 우선")
	eq(_StageCadence.node_kind(44), "shop", "상점이 사건보다 우선")
	eq(_StageCadence.node_kind(77), "elite", "정예가 사건보다 우선")

func test_first_fifteen_stage_sequence_is_sanity_baseline() -> void:
	var expected := [
		"combat",
		"combat",
		"edict",
		"shop",
		"boss",
		"edict",
		"elite",
		"shop",
		"edict",
		"boss",
		"event",
		"edict",
		"combat",
		"elite",
		"boss",
	]
	for index in range(expected.size()):
		var stage := index + 1
		eq(_StageCadence.node_kind(stage), expected[index], "stage %d node_kind baseline" % stage)

func test_difficulty_scale_is_linear_and_deterministic() -> void:
	almost(_StageCadence.difficulty_scale(-1), 1.0, 0.0001, "음수 stage는 기본 배율")
	almost(_StageCadence.difficulty_scale(0), 1.0, 0.0001, "0 stage는 기본 배율")
	almost(_StageCadence.difficulty_scale(1), 1.0, 0.0001, "1 stage는 기본 배율")
	almost(_StageCadence.difficulty_scale(2), 1.10, 0.0001, "2 stage는 1회 상승")
	almost(_StageCadence.difficulty_scale(5), 1.40, 0.0001, "5 stage는 4회 상승")
	almost(_StageCadence.difficulty_scale(9), _StageCadence.difficulty_scale(9), 0.0001, "같은 입력은 같은 배율")

func test_stage_label_marks_battle_and_boss() -> void:
	truthy(_StageCadence.stage_label(1).contains("스테이지 1"), "stage 번호 포함")
	truthy(_StageCadence.stage_label(1).contains("전투"), "일반 stage는 전투")
	truthy(_StageCadence.stage_label(5).contains("스테이지 5"), "보스 stage 번호 포함")
	truthy(_StageCadence.stage_label(5).contains("보스"), "5의 배수는 보스")
	truthy(_StageCadence.stage_label(7).contains("정예"), "7스테이지는 정예 라벨")
	truthy(_StageCadence.stage_label(11).contains("사건"), "11스테이지는 사건 라벨")

func test_stage_prep_text_explains_next_action() -> void:
	truthy(_StageCadence.stage_prep_label(2).contains("손패 3장 중 1장"), "전투 준비 문구")
	truthy(_StageCadence.stage_prep_label(3).contains("왕의 칙령"), "칙령 준비 문구")
	truthy(_StageCadence.stage_prep_label(4).contains("군자금"), "상점 준비 문구")
	truthy(_StageCadence.stage_prep_label(5).contains("보스전"), "보스 준비 문구")
	truthy(_StageCadence.stage_prep_tooltip(4).contains("상점"), "상점 준비 tooltip")

func test_final_boss_is_stage_fifteen_only() -> void:
	falsy(_StageCadence.is_final_boss(10), "stage 10은 후속 보스지만 최종 보스 아님")
	truthy(_StageCadence.is_final_boss(15), "stage 15는 최종 보스")
	falsy(_StageCadence.is_final_boss(16), "stage 16은 최종 보스 아님")
	eq(_StageCadence.node_kind(15), "boss", "최종 보스도 boss node_kind")
