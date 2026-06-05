# 핵심 UI 피드백 스모크 — 주요 화면의 tooltip_text와 배치 피드백 문구를 헤드리스 씬으로 검증한다.
# 실행 — godot --headless --path . --script res://tools/ui_feedback_smoke.gd
extends SceneTree

const LORD_ID := &"lord_liubei"
const LORD_SELECT_SCENE_PATH := "res://scenes/screens/lord_select.tscn"
const RUN_MAP_SCENE_PATH := "res://scenes/screens/run_map.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors := 0
	errors += await _lord_select_case()
	errors += await _run_map_first_combat_case()
	errors += await _run_map_shop_case()
	errors += await _run_map_edict_case()
	errors += await _run_map_event_case()
	errors += await _battle_deploy_case()
	errors += await _battle_reward_case()
	if errors == 0:
		print("✅ UI 툴팁/피드백 스모크 통과")
		quit(0)
	else:
		printerr("❌ UI 툴팁/피드백 스모크 실패: %d건" % errors)
		quit(1)

func _lord_select_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.reset_profile()
	var screen = _instantiate_scene(LORD_SELECT_SCENE_PATH)
	if screen == null:
		return _fail("lord_select.tscn 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_any_tooltip(screen, "선택하면 새 런", "군주 선택 버튼 tooltip")
	errors += _assert_any_tooltip(screen, "잠김. 보스 승리", "잠긴 군주 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  군주 선택 tooltip OK")
	return errors

func _run_map_first_combat_case() -> int:
	if _prepare_run_map_stage(1) == null:
		return _fail("RunManager autoload 조회 실패")
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 첫 전투 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_any_text(screen, "첫 전투입니다", "첫 전투 안내 문구")
	errors += _assert_any_text(screen, "빈 타일에 배치", "첫 배치 행동 안내")
	errors += _assert_button_tooltip(screen, "전투 시작", "손패를 배치", "첫 전투 시작 버튼 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 첫 전투 안내 OK")
	return errors

func _run_map_shop_case() -> int:
	var run_manager = _prepare_run_map_stage(4)
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.state.gold = 999
	run_manager.state.hand.append(&"scheme_raid")
	run_manager.state.hand.append(&"building_dunjeon")
	run_manager.state.board["0:0"] = &"troop_infantry"
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 상점 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_button_tooltip(screen, "상점 떠나기", "다음 스테이지", "상점 떠나기 tooltip")
	errors += _assert_any_tooltip(screen, "손패 구매", "상점 카드 구매 경로 tooltip")
	errors += _assert_any_tooltip(screen, "보드 배치", "보드 요약 카드 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 상점 tooltip OK")
	return errors

func _run_map_edict_case() -> int:
	if _prepare_run_map_stage(3) == null:
		return _fail("RunManager autoload 조회 실패")
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 칙령 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_any_tooltip(screen, "선택하면 즉시 적용", "칙령 즉시 적용 tooltip")
	errors += _assert_any_tooltip(screen, "다음 스테이지", "칙령 다음 스테이지 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 칙령 tooltip OK")
	return errors

func _run_map_event_case() -> int:
	if _prepare_run_map_stage(11) == null:
		return _fail("RunManager autoload 조회 실패")
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 사건 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_button_tooltip(screen, "군량 징발", "+20금", "사건 보상 tooltip")
	errors += _assert_button_tooltip(screen, "군량 징발", "다음 스테이지", "사건 이동 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 사건 tooltip OK")
	return errors

func _battle_deploy_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = 1
	run_manager.state.board.clear()
	run_manager.state.hand.clear()
	run_manager.state.hand.append(&"scheme_raid")
	run_manager.state.hand.append(&"troop_infantry")
	run_manager.state.hand.append(&"building_dunjeon")
	var battle = _instantiate_scene(BATTLE_SCENE_PATH)
	if battle == null:
		return _fail("battle.tscn 인스턴스 생성 실패")
	root.add_child(battle)
	await _frames(8)
	var errors := 0
	errors += _assert_button_tooltip(battle, "계략 발동", "손패에서 계략", "계략 버튼 기본 tooltip")
	errors += _assert_button_tooltip(battle, "우물", "+10골드", "우물 버튼 tooltip")
	errors += _assert_button_tooltip(battle, "교전 시작", "성 위치", "교전 시작 비활성 tooltip")
	errors += _assert_button_tooltip(battle, "계략 발동", "계략 발동 버튼", "계략 손패 tooltip")
	errors += _assert_button_tooltip(battle, "10명 분대", "빈 타일", "병종 손패 tooltip")
	if battle.has_method("_select_hand"):
		battle._select_hand(0)
		await _frames(2)
		errors += _assert_button_tooltip(battle, "계략 발동", "선택한 계략", "선택 계략 tooltip")
		battle._select_hand(1)
		await _frames(2)
		errors += _assert_button_tooltip(battle, "우물", "먼저 성", "선택 우물 tooltip")
	battle.queue_free()
	await _frames(2)
	if errors == 0:
		print("  전투 배치 tooltip OK")
	return errors

func _battle_reward_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = 1
	run_manager.state.board = {
		"0:0": &"troop_infantry",
		"1:0": &"troop_archer",
		"2:0": &"troop_cavalry",
	}
	var battle = _instantiate_scene(BATTLE_SCENE_PATH)
	if battle == null:
		return _fail("battle.tscn 보상 인스턴스 생성 실패")
	root.add_child(battle)
	await _frames(8)
	battle._sim.result = BattleSim.Result.PLAYER_WIN
	battle._end_battle()
	await _frames(8)
	var errors := 0
	errors += _assert_any_text(battle, "전리품 — 한 장을 고르세요", "보상 선택 제목")
	errors += _assert_any_text(battle, "카드 버튼을 누르면", "보상 선택 행동 안내")
	errors += _assert_button_text(battle, "선택 —", "보상 선택 버튼")
	errors += _assert_any_tooltip(battle, "이 전리품을 선택합니다", "보상 선택 tooltip")
	battle.queue_free()
	await _frames(2)
	if errors == 0:
		print("  전투 보상 안내 OK")
	return errors

func _prepare_run_map_stage(stage: int):
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return null
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = stage
	run_manager.state.board.clear()
	return run_manager

func _instantiate_scene(path: String):
	var scene := load(path)
	if scene == null:
		return null
	return scene.instantiate()

func _assert_button_tooltip(node: Node, text_needle: String, tooltip_needle: String, msg: String) -> int:
	for button in _buttons(node):
		if _control_text_contains(button, text_needle) and button.tooltip_text.find(tooltip_needle) >= 0:
			return 0
	return _fail("%s 누락: text=%s tooltip~=%s" % [msg, text_needle, tooltip_needle])

func _assert_any_tooltip(node: Node, tooltip_needle: String, msg: String) -> int:
	for control in _controls(node):
		if control.tooltip_text.find(tooltip_needle) >= 0:
			return 0
	return _fail("%s 누락: tooltip~=%s" % [msg, tooltip_needle])

func _assert_any_text(node: Node, text_needle: String, msg: String) -> int:
	for text in _collect_texts(node):
		if text.find(text_needle) >= 0:
			return 0
	return _fail("%s 누락: text~=%s" % [msg, text_needle])

func _assert_button_text(node: Node, text_needle: String, msg: String) -> int:
	for button in _buttons(node):
		if button.text.find(text_needle) >= 0:
			return 0
	return _fail("%s 누락: button text~=%s" % [msg, text_needle])

func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	if node is Button:
		out.append(node as Button)
	for child in node.get_children():
		out.append_array(_buttons(child))
	return out

func _controls(node: Node) -> Array[Control]:
	var out: Array[Control] = []
	if node is Control:
		out.append(node as Control)
	for child in node.get_children():
		out.append_array(_controls(child))
	return out

func _control_text_contains(node: Node, needle: String) -> bool:
	if node is Button and (node as Button).text.find(needle) >= 0:
		return true
	if node is Label and (node as Label).text.find(needle) >= 0:
		return true
	for child in node.get_children():
		if _control_text_contains(child, needle):
			return true
	return false

func _collect_texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Label:
		out.append((node as Label).text)
	elif node is Button:
		out.append((node as Button).text)
	for child in node.get_children():
		out.append_array(_collect_texts(child))
	return out

func _frames(n: int) -> void:
	for _i in n:
		await process_frame

func _fail(msg: String) -> int:
	printerr("  ", msg)
	return 1
