# 저장 payload는 Resource/StringName을 직접 내보내지 않고 primitive Dictionary만 사용한다.
extends TestCase

func test_run_state_to_dict_uses_only_primitive_values() -> void:
	var run := RunState.new()
	run.lord_id = &"lord_liubei"
	run.board = {"0:0": &"general_zhaoyun", "1:0": &"troop_infantry"}
	run.board_levels = {"0:0": 2, "1:0": 3}
	run.hand = [&"scheme_raid"]
	run.gold = 17
	run.board_rows = 5
	run.stage_index = 4
	run.wave_index = 1
	run.started = true
	run.command_points = 9
	run.edicts = [&"edict_might"]
	run.treasures = [&"treasure_bingfashu"]

	var payload := run.to_dict()
	_assert_primitive_payload(payload, "RunState payload")
	eq(payload.get("save_version"), RunState.SAVE_VERSION, "RunState save_version 기록")
	eq(payload.get("lord_id"), "lord_liubei", "lord id는 String")
	eq((payload.get("board") as Dictionary).get("0:0"), "general_zhaoyun", "board card id는 String")
	eq((payload.get("board_levels") as Dictionary).get("1:0"), 3, "board level은 int")
	eq((payload.get("hand") as Array)[0], "scheme_raid", "hand id는 String")
	eq((payload.get("treasures") as Array)[0], "treasure_bingfashu", "treasure id는 String")

func test_run_state_from_dict_restores_runtime_id_types() -> void:
	var payload := {
		"save_version": RunState.SAVE_VERSION,
		"lord_id": "lord_sunquan",
		"board": {"0:0": "general_zhouyu"},
		"board_levels": {"0:0": 4},
		"hand": ["troop_navy", "scheme_levy"],
		"gold": 21,
		"board_rows": 6,
		"stage_index": 8,
		"wave_index": 2,
		"started": true,
		"command_points": 5,
		"edicts": ["edict_fortify"],
		"treasures": ["treasure_jinyin"],
	}
	var run := RunState.new()
	truthy(run.from_dict(payload), "from_dict 성공")
	eq(run.lord_id, &"lord_sunquan", "lord id 복원")
	eq(run.board.get("0:0"), &"general_zhouyu", "board id StringName 복원")
	eq(run.board_level("0:0"), 4, "board level 복원")
	eq(run.hand, [&"troop_navy", &"scheme_levy"], "hand 복원")
	eq(run.gold, 21, "gold 복원")
	eq(run.board_rows, 6, "board_rows 복원")
	eq(run.stage_index, 8, "stage_index 복원")
	eq(run.edicts, [&"edict_fortify"], "edict 복원")
	eq(run.treasures, [&"treasure_jinyin"], "treasure 복원")

func test_run_state_missing_and_unknown_fields_load_with_defaults() -> void:
	var payload := {
		"unknown_future_field": "ignored",
		"board_rows": 99,
		"stage_index": -4,
		"wave_index": -2,
	}
	var run := RunState.new()
	truthy(run.from_dict(payload), "missing save_version과 unknown field는 로드 가능")
	eq(run.lord_id, &"", "missing lord는 빈 id")
	eq(run.hand, [], "missing hand는 빈 배열")
	eq(run.gold, 0, "missing gold는 0")
	eq(run.board_rows, RunState.BOARD_ROWS_MAX, "board_rows는 최대치로 보정")
	eq(run.stage_index, 1, "stage_index는 최소 1")
	eq(run.wave_index, 0, "wave_index는 최소 0")
	falsy(run.started, "missing started는 false")

func test_run_state_newer_major_version_fails_without_mutation() -> void:
	var run := RunState.new()
	run.lord_id = &"lord_liubei"
	run.gold = 7
	run.started = true
	run.hand = [&"troop_infantry"]

	var payload := {
		"save_version": "2.0.0",
		"lord_id": "lord_caocao",
		"gold": 99,
		"started": false,
		"hand": ["scheme_raid"],
	}
	falsy(run.from_dict(payload), "newer major run save는 안전하게 로드 실패")
	eq(run.lord_id, &"lord_liubei", "실패 시 lord 유지")
	eq(run.gold, 7, "실패 시 gold 유지")
	truthy(run.started, "실패 시 started 유지")
	eq(run.hand, [&"troop_infantry"], "실패 시 hand 유지")

func test_profile_state_to_dict_and_from_dict_use_primitives() -> void:
	var profile := ProfileState.new()
	profile.unlocked_lord_ids = [&"lord_liubei", &"lord_caocao"]
	profile.unlocked_card_ids = [&"general_zhaoyun", &"scheme_raid"]
	profile.best_stage = 9
	profile.best_score = 1234
	profile.settings = {
		"music": true,
		"volume": 0.7,
		"labels": [&"fast", "readable"],
		"ignored_resource": RunState.new(),
	}
	var payload := profile.to_dict()
	_assert_primitive_payload(payload, "ProfileState payload")
	eq(payload.get("save_version"), ProfileState.SAVE_VERSION, "ProfileState save_version 기록")
	eq((payload.get("unlocked_lord_ids") as Array)[0], "lord_liubei", "profile lord id는 String")
	falsy((payload.get("settings") as Dictionary).has("ignored_resource"), "Resource 설정값은 payload에서 제외")

	var restored := ProfileState.new()
	truthy(restored.from_dict(payload), "profile from_dict 성공")
	eq(restored.unlocked_lord_ids, [&"lord_liubei", &"lord_caocao"], "lord unlock 복원")
	eq(restored.unlocked_card_ids, [&"general_zhaoyun", &"scheme_raid"], "card unlock 복원")
	eq(restored.best_stage, 9, "best_stage 복원")
	eq(restored.best_score, 1234, "best_score 복원")
	eq(restored.settings.get("music"), true, "settings bool 복원")
	almost(float(restored.settings.get("volume", 0.0)), 0.7, 0.0001, "settings float 복원")

func test_profile_state_missing_and_unknown_fields_load_with_defaults() -> void:
	var profile := ProfileState.new()
	truthy(profile.from_dict({"unknown_future_field": "ignored"}), "missing profile fields는 기본값으로 로드")
	eq(profile.unlocked_lord_ids, [], "missing lord unlock은 빈 배열")
	eq(profile.unlocked_card_ids, [], "missing card unlock은 빈 배열")
	eq(profile.best_stage, 0, "missing best_stage는 0")
	eq(profile.best_score, 0, "missing best_score는 0")
	eq(profile.settings, {}, "missing settings는 빈 Dictionary")

func test_profile_state_newer_major_version_fails_without_mutation() -> void:
	var profile := ProfileState.new()
	profile.unlocked_lord_ids = [&"lord_liubei"]
	profile.unlocked_card_ids = [&"general_zhaoyun"]
	profile.best_stage = 3
	profile.best_score = 40
	profile.settings = {"music": true}

	var payload := {
		"save_version": "2.0.0",
		"unlocked_lord_ids": ["lord_caocao"],
		"unlocked_card_ids": ["scheme_raid"],
		"best_stage": 99,
		"best_score": 999,
		"settings": {"music": false},
	}
	falsy(profile.from_dict(payload), "newer major profile save는 로드 실패")
	eq(profile.unlocked_lord_ids, [&"lord_liubei"], "실패 시 lord unlock 유지")
	eq(profile.unlocked_card_ids, [&"general_zhaoyun"], "실패 시 card unlock 유지")
	eq(profile.best_stage, 3, "실패 시 best_stage 유지")
	eq(profile.best_score, 40, "실패 시 best_score 유지")
	eq(profile.settings.get("music"), true, "실패 시 settings 유지")

func _assert_primitive_payload(value, label: String) -> void:
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			truthy(true, "%s primitive" % label)
		TYPE_ARRAY:
			for i in (value as Array).size():
				_assert_primitive_payload((value as Array)[i], "%s[%d]" % [label, i])
		TYPE_DICTIONARY:
			for key in (value as Dictionary).keys():
				eq(typeof(key), TYPE_STRING, "%s key는 String" % label)
				_assert_primitive_payload((value as Dictionary)[key], "%s.%s" % [label, key])
		_:
			falsy(true, "%s는 primitive가 아님: %s" % [label, type_string(typeof(value))])
