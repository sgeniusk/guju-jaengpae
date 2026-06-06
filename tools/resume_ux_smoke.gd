# 저장/이어하기 UX 스모크 — 군주 선택 화면의 저장 런 이어하기 경로를 검증한다.
# 실행 — godot --headless --path . --script res://tools/resume_ux_smoke.gd
extends SceneTree

const LORD_ID := &"lord_liubei"
const LORD_SELECT_SCENE_PATH := "res://scenes/screens/lord_select.tscn"
const RUN_MAP_SCENE_PATH := "res://scenes/screens/run_map.tscn"
const _PersistenceStore := preload("res://scripts/run/persistence_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors := 0
	errors += await _no_save_case()
	errors += await _corrupt_save_case()
	errors += await _saved_run_continue_case()
	_cleanup_default_save()
	if errors == 0:
		print("✅ 저장/이어하기 UX 스모크 통과")
		quit(0)
	else:
		printerr("❌ 저장/이어하기 UX 스모크 실패: %d건" % errors)
		quit(1)

func _no_save_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	var screen = _instantiate_scene(LORD_SELECT_SCENE_PATH)
	if screen == null:
		return _fail("lord_select.tscn no-save 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	if _find_button(screen, "저장된 런 이어하기") != null:
		errors += _fail("저장 파일이 없는데 이어하기 버튼이 노출됨")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  저장 없음 상태 OK")
	return errors

func _corrupt_save_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	var err := _PersistenceStore.save_run_payload({
		"save_version": "2.0.0",
		"started": true,
		"lord_id": "lord_caocao",
	}, _PersistenceStore.RUN_SAVE_PATH)
	if err != OK:
		return _fail("테스트용 손상 저장 생성 실패: %d" % err)

	var screen = _instantiate_scene(LORD_SELECT_SCENE_PATH)
	if screen == null:
		return _fail("lord_select.tscn corrupt-save 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)

	var errors := 0
	if run_manager.has_resumeable_run_save():
		errors += _fail("손상 저장이 resumeable로 판정됨")
	if _find_button(screen, "저장된 런 이어하기") != null:
		errors += _fail("손상 저장인데 이어하기 버튼이 노출됨")
	var notice := _find_button(screen, "저장된 런을 불러올 수 없음")
	if notice == null:
		errors += _fail("손상 저장 안내 누락")
	else:
		if not notice.disabled:
			errors += _fail("손상 저장 안내가 비활성 상태가 아님")
		if notice.tooltip_text.find("새 군주") < 0:
			errors += _fail("손상 저장 안내 tooltip 누락: %s" % notice.tooltip_text)
	screen.queue_free()
	await _frames(2)
	run_manager.clear_run_save()
	if errors == 0:
		print("  손상 저장 안내 OK")
	return errors

func _saved_run_continue_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	var game_manager := root.get_node_or_null("/root/GameManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	if game_manager == null:
		return _fail("GameManager autoload 조회 실패")
	var expected := _create_saved_run(run_manager)
	if expected.is_empty():
		return _fail("테스트용 저장 런 생성 실패")
	run_manager.state = RunState.new()
	run_manager.last_scheme_result.clear()
	run_manager.last_battle_outcome.clear()

	var screen = _instantiate_scene(LORD_SELECT_SCENE_PATH)
	if screen == null:
		return _fail("lord_select.tscn saved-run 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)

	var errors := 0
	var continue_btn := _find_button(screen, "저장된 런 이어하기")
	if continue_btn == null:
		errors += _fail("저장된 런 이어하기 버튼 누락")
	else:
		if continue_btn.tooltip_text.find("현재 스테이지") < 0:
			errors += _fail("이어하기 버튼 tooltip 누락: %s" % continue_btn.tooltip_text)
		var route := {"path": ""}
		var on_scene_changed := func(scene_path: String) -> void:
			route["path"] = scene_path
		game_manager.scene_changed.connect(on_scene_changed)
		screen._on_continue_pressed()
		await _frames(8)
		if route["path"] != RUN_MAP_SCENE_PATH:
			errors += _fail("이어하기 scene route=%s, expected %s" % [String(route["path"]), RUN_MAP_SCENE_PATH])
		errors += _assert_loaded_state(run_manager, expected)
		if game_manager.scene_changed.is_connected(on_scene_changed):
			game_manager.scene_changed.disconnect(on_scene_changed)

	if is_instance_valid(screen):
		screen.queue_free()
	await _frames(2)
	run_manager.reset_run()
	if errors == 0:
		print("  저장 런 이어하기 OK")
	return errors

func _create_saved_run(run_manager: Node) -> Dictionary:
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	if not run_manager.set_castle_key("2:2"):
		return {}
	var hand_before: Array[StringName] = run_manager.get_hand()
	var place_index := _first_placeable_hand_index(run_manager)
	if place_index < 0:
		return {}
	var placed_id := hand_before[place_index]
	if not run_manager.place_from_hand(place_index, "1:1"):
		return {}
	run_manager.add_gold(12)
	run_manager.advance_stage()
	if not run_manager.has_run_save():
		return {}
	return {
		"stage": run_manager.stage_index(),
		"castle_key": run_manager.get_castle_key(),
		"board": run_manager.get_board(),
		"hand": run_manager.get_hand(),
		"gold": run_manager.get_gold(),
		"placed_id": placed_id,
	}

func _first_placeable_hand_index(run_manager: Node) -> int:
	var hand: Array[StringName] = run_manager.get_hand()
	for idx in hand.size():
		if run_manager.can_place_hand_card(idx):
			return idx
	return -1

func _assert_loaded_state(run_manager: Node, expected: Dictionary) -> int:
	var errors := 0
	if not run_manager.is_run_started():
		errors += _fail("이어하기 후 런 started=false")
	if run_manager.stage_index() != int(expected.get("stage", 0)):
		errors += _fail("stage 복원 실패: %d != %d" % [run_manager.stage_index(), int(expected.get("stage", 0))])
	if run_manager.get_castle_key() != String(expected.get("castle_key", "")):
		errors += _fail("성 위치 복원 실패: %s != %s" % [run_manager.get_castle_key(), String(expected.get("castle_key", ""))])
	if run_manager.get_board() != expected.get("board", {}):
		errors += _fail("보드 복원 실패: %s != %s" % [str(run_manager.get_board()), str(expected.get("board", {}))])
	if run_manager.get_hand() != expected.get("hand", []):
		errors += _fail("손패 복원 실패: %s != %s" % [str(run_manager.get_hand()), str(expected.get("hand", []))])
	if run_manager.get_gold() != int(expected.get("gold", -1)):
		errors += _fail("골드 복원 실패: %d != %d" % [run_manager.get_gold(), int(expected.get("gold", -1))])
	if not run_manager.get_board().has("1:1"):
		errors += _fail("배치 타일 1:1 복원 누락")
	return errors

func _instantiate_scene(path: String):
	var packed := load(path)
	if packed == null:
		return null
	return packed.instantiate()

func _find_button(node: Node, needle: String) -> Button:
	if node is Button and (node as Button).text.find(needle) >= 0:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, needle)
		if found != null:
			return found
	return null

func _cleanup_default_save() -> void:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager != null:
		run_manager.reset_run()

func _frames(n: int) -> void:
	for _i in n:
		await process_frame

func _fail(msg: String) -> int:
	printerr("  ", msg)
	return 1
