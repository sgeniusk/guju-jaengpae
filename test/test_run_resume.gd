# RunManager 저장/재개 경계가 런 핵심 필드를 보존하는지 검증한다.
extends TestCase

const TEST_PATH := "user://guju_test_run_resume.cfg"
const _PersistenceStore := preload("res://scripts/run/persistence_store.gd")

func before_each() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	RunManager.clear_run_save(TEST_PATH)

func test_save_load_run_preserves_board_hand_gold_stage_edicts_treasures() -> void:
	RunManager.ensure_started(&"lord_liubei")
	truthy(RunManager.set_castle_key("1:1"), "성 위치 저장")
	var placed: StringName = RunManager.get_hand()[0]
	truthy(RunManager.place_from_hand(0, "0:0"), "보드 배치")
	RunManager.hand_add(&"scheme_raid")
	RunManager.add_gold(41)
	truthy(RunManager.expand_board(), "보드 4행 확장")
	truthy(RunManager.add_edict(&"edict_might"), "칙령 추가")
	truthy(RunManager.add_treasure(&"treasure_bingfashu"), "보패 추가")
	RunManager.advance_stage()

	var expected_hand := RunManager.get_hand()
	truthy(RunManager.save_run(TEST_PATH), "명시 런 저장")
	RunManager.reset_run()
	truthy(RunManager.load_run(TEST_PATH), "명시 런 로드")

	truthy(RunManager.is_run_started(), "로드 후 started")
	eq(RunManager.state.lord_id, &"lord_liubei", "군주 보존")
	eq(RunManager.get_castle_key(), "1:1", "성 위치 보존")
	eq(RunManager.get_board().get("0:0"), placed, "보드 보존")
	eq(RunManager.get_hand(), expected_hand, "손패 보존")
	eq(RunManager.get_gold(), 41, "골드 보존")
	eq(RunManager.stage_index(), 2, "스테이지 보존")
	eq(RunManager.get_board_rows(), 4, "보드 행 보존")
	eq(RunManager.get_edicts(), [&"edict_might"], "칙령 보존")
	eq(RunManager.get_treasures(), [&"treasure_bingfashu"], "보패 보존")
	RunManager.clear_run_save(TEST_PATH)

func test_autosave_default_run_can_resume_after_state_recreation() -> void:
	RunManager.ensure_started(&"lord_liubei")
	truthy(RunManager.set_castle_key("2:2"), "성 위치 autosave")
	truthy(RunManager.place_from_hand(0, "1:1"), "배치 autosave")
	RunManager.add_gold(12)
	RunManager.advance_stage()
	truthy(RunManager.has_run_save(), "기본 런 저장 생성")
	var expected_board := RunManager.get_board()
	var expected_hand := RunManager.get_hand()

	RunManager.state = RunState.new()
	truthy(RunManager.load_run(), "기본 저장에서 재개")
	eq(RunManager.get_board(), expected_board, "autosave 보드 복원")
	eq(RunManager.get_castle_key(), "2:2", "autosave 성 위치 복원")
	eq(RunManager.get_hand(), expected_hand, "autosave 손패 복원")
	eq(RunManager.get_gold(), 12, "autosave 골드 복원")
	eq(RunManager.stage_index(), 2, "autosave 스테이지 복원")

	RunManager.reset_run()
	falsy(RunManager.has_run_save(), "새 런 리셋은 기본 저장 삭제")

func test_load_run_accepts_missing_and_unknown_fields_with_defaults() -> void:
	eq(_PersistenceStore.save_run_payload({
		"save_version": RunState.SAVE_VERSION,
		"started": true,
		"board_rows": 99,
		"stage_index": -3,
		"unknown_future_field": "ignored",
	}, TEST_PATH), OK, "호환 payload 저장")

	truthy(RunManager.load_run(TEST_PATH), "missing/unknown 런 payload 로드")
	truthy(RunManager.is_run_started(), "started 복원")
	eq(RunManager.state.lord_id, &"", "missing lord 기본값")
	eq(RunManager.get_hand(), [], "missing hand 기본값")
	eq(RunManager.get_gold(), 0, "missing gold 기본값")
	eq(RunManager.get_board_rows(), RunState.BOARD_ROWS_MAX, "board_rows 보정")
	eq(RunManager.stage_index(), 1, "stage_index 보정")

func test_load_run_rejects_newer_major_without_mutating_current_run() -> void:
	RunManager.ensure_started(&"lord_liubei")
	RunManager.add_gold(5)
	var original_hand := RunManager.get_hand()
	eq(_PersistenceStore.save_run_payload({
		"save_version": "2.0.0",
		"started": true,
		"lord_id": "lord_caocao",
		"gold": 99,
		"hand": ["scheme_raid"],
	}, TEST_PATH), OK, "newer payload 저장")

	falsy(RunManager.load_run(TEST_PATH), "newer major 런 저장 로드 거부")
	eq(RunManager.state.lord_id, &"lord_liubei", "거부 후 군주 유지")
	eq(RunManager.get_gold(), 5, "거부 후 골드 유지")
	eq(RunManager.get_hand(), original_hand, "거부 후 손패 유지")
