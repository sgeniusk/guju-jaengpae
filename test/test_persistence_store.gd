# Phase 3 저장 포맷은 Godot ConfigFile과 user:// 기본 경로로 고정한다.
extends TestCase

const _PersistenceStore := preload("res://scripts/run/persistence_store.gd")
const TEST_PATH := "user://guju_test_persistence_format.cfg"
const TEST_FILE := "guju_test_persistence_format.cfg"

func before_each() -> void:
	_remove_test_file()

func test_default_save_paths_are_user_config_files() -> void:
	eq(_PersistenceStore.default_run_path(), "user://guju_run.cfg", "런 저장 기본 경로")
	eq(_PersistenceStore.default_profile_path(), "user://guju_profile.cfg", "프로필 저장 기본 경로")
	var paths := _PersistenceStore.default_paths()
	eq(paths.get("run"), "user://guju_run.cfg", "기본 경로 딕셔너리 run")
	eq(paths.get("profile"), "user://guju_profile.cfg", "기본 경로 딕셔너리 profile")

func test_new_config_is_godot_configfile_with_format_stamp() -> void:
	var config := _PersistenceStore.new_config()
	truthy(config is ConfigFile, "저장 포맷은 Godot ConfigFile")
	eq(config.get_value("meta", "format", ""), "ConfigFile", "format stamp")
	truthy(_PersistenceStore.is_configfile_format(config), "format 판별")

func test_configfile_format_roundtrips_under_user_path() -> void:
	var config := _PersistenceStore.new_config()
	config.set_value("paths", "run", _PersistenceStore.default_run_path())
	config.set_value("paths", "profile", _PersistenceStore.default_profile_path())
	eq(config.save(TEST_PATH), OK, "ConfigFile 저장")

	var loaded := ConfigFile.new()
	eq(loaded.load(TEST_PATH), OK, "ConfigFile 로드")
	truthy(_PersistenceStore.is_configfile_format(loaded), "로드 후 format 유지")
	eq(loaded.get_value("paths", "run", ""), "user://guju_run.cfg", "run path roundtrip")
	eq(loaded.get_value("paths", "profile", ""), "user://guju_profile.cfg", "profile path roundtrip")
	_remove_test_file()

func test_run_payload_roundtrips_through_configfile_section() -> void:
	var run := RunState.new()
	run.lord_id = &"lord_liubei"
	run.started = true
	run.board = {"0:0": &"general_zhaoyun"}
	run.hand = [&"scheme_raid"]
	run.gold = 31
	run.stage_index = 4
	run.edicts = [&"edict_might"]
	run.treasures = [&"treasure_bingfashu"]

	eq(_PersistenceStore.save_run_state(run, TEST_PATH), OK, "RunState 저장")
	truthy(_PersistenceStore.run_save_exists(TEST_PATH), "런 저장 파일 존재")
	var loaded := _PersistenceStore.load_run_payload(TEST_PATH)
	truthy(loaded.get("ok", false), "런 payload 로드 성공")
	eq((loaded.get("payload", {}) as Dictionary).get("lord_id"), "lord_liubei", "lord id section roundtrip")
	eq(((loaded.get("payload", {}) as Dictionary).get("board", {}) as Dictionary).get("0:0"), "general_zhaoyun", "board section roundtrip")
	eq(((loaded.get("payload", {}) as Dictionary).get("treasures", []) as Array)[0], "treasure_bingfashu", "treasure section roundtrip")
	eq(_PersistenceStore.delete_run_save(TEST_PATH), OK, "런 저장 파일 삭제")
	falsy(_PersistenceStore.run_save_exists(TEST_PATH), "삭제 후 저장 파일 없음")

func test_profile_payload_roundtrips_through_configfile_section() -> void:
	var profile := ProfileState.new_default()
	profile.unlock_lord(&"lord_caocao")
	profile.unlock_card(&"scheme_raid")
	profile.record_result(5, 1030)
	truthy(profile.set_setting("music", true), "primitive 설정 저장")

	eq(_PersistenceStore.save_profile_state(profile, TEST_PATH), OK, "ProfileState 저장")
	truthy(_PersistenceStore.profile_save_exists(TEST_PATH), "프로필 저장 파일 존재")
	var loaded := _PersistenceStore.load_profile_payload(TEST_PATH)
	truthy(loaded.get("ok", false), "프로필 payload 로드 성공")
	var payload := loaded.get("payload", {}) as Dictionary
	eq(payload.get("unlocked_lord_ids"), ["lord_liubei", "lord_caocao"], "군주 해금 section roundtrip")
	eq(payload.get("unlocked_card_ids"), ["scheme_raid"], "카드 해금 section roundtrip")
	eq(payload.get("best_stage"), 5, "best stage section roundtrip")
	eq((payload.get("settings", {}) as Dictionary).get("music"), true, "settings section roundtrip")
	eq(_PersistenceStore.delete_profile_save(TEST_PATH), OK, "프로필 저장 파일 삭제")
	falsy(_PersistenceStore.profile_save_exists(TEST_PATH), "삭제 후 프로필 저장 파일 없음")

func _remove_test_file() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(TEST_FILE):
		dir.remove(TEST_FILE)
