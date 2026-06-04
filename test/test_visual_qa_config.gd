# 시각 QA 촬영 루틴의 군주 목록과 스크린샷 파일명 계약.
extends TestCase

const _VisualQaConfig := preload("res://tools/visual_qa_config.gd")

func test_default_lords_cover_three_mortal_factions() -> void:
	eq(_VisualQaConfig.DEFAULT_LORDS, [&"lord_liubei", &"lord_caocao", &"lord_sunquan"], "위·촉·오 군주 촬영 목록")

func test_default_flow_stages_cover_first_boss_ui_path() -> void:
	eq(_VisualQaConfig.DEFAULT_FLOW_STAGES, [1, 3, 4, 5], "첫 보스 UI 흐름 촬영 스테이지")

func test_normalize_output_dir_removes_trailing_slashes() -> void:
	eq(_VisualQaConfig.normalize_output_dir("/tmp/guju-visual-qa///"), "/tmp/guju-visual-qa", "출력 경로 trailing slash 정리")
	eq(_VisualQaConfig.normalize_output_dir(""), _VisualQaConfig.DEFAULT_OUTPUT_DIR, "빈 출력 경로는 기본값")

func test_shot_path_names_kind_lord_and_stage() -> void:
	var path := _VisualQaConfig.shot_path("battle fight", &"lord_caocao", 5, "/tmp/qa/")
	eq(path, "/tmp/qa/battle_fight_lord_caocao_stage_5.png", "전투 스크린샷 파일명")

func test_shot_path_omits_stage_for_scene_captures() -> void:
	var path := _VisualQaConfig.shot_path("lord_select", &"all", 0, "/tmp/qa")
	eq(path, "/tmp/qa/lord_select_all.png", "씬 스크린샷 파일명")
