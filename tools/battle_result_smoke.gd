# 전투 결과 화면 스모크 — 런 패배와 최종 승리가 보상/다음 stage가 아니라 새 런 경로로 닫히는지 검증한다.
# 실행 — godot --headless --path . --script res://tools/battle_result_smoke.gd
extends SceneTree

const LORD_ID := &"lord_liubei"
const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors := 0
	errors += await _result_case(3, BattleSim.Result.PLAYER_LOSE, "defeat", ["결과 — 성 함락", "다음 행동 — 군주 선택으로 새 런", "런 종료 — 성이 함락되었습니다", "런 결산 — 패배", "스테이지 3", "군세 6/18", "런 실패", "군주 선택으로 새 런"], ["전리품", "다음 스테이지로", "런 승리"])
	errors += await _result_case(15, BattleSim.Result.PLAYER_WIN, "victory", ["결과 — 구주 정복", "다음 행동 — 군주 선택으로 새 런", "런 종료 — 구주 정복 완료", "런 결산 — 승리", "스테이지 15", "군세 6/18", "구주 정복!", "런 승리 — 구주 정복", "군주 선택으로 새 런"], ["전리품", "다음 스테이지로"])
	if errors == 0:
		print("✅ 전투 결과 화면 스모크 통과")
		quit(0)
	else:
		printerr("❌ 전투 결과 화면 스모크 실패: %d건" % errors)
		quit(1)

func _result_case(stage: int, sim_result: int, run_result: String, expected: Array, forbidden: Array) -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	var run_state_script := load(RUN_STATE_SCRIPT_PATH)
	var battle_scene := load(BATTLE_SCENE_PATH)
	if run_state_script == null:
		return _fail("RunState 스크립트 로드 실패")
	if battle_scene == null:
		return _fail("battle.tscn 로드 실패")
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = stage
	run_manager.state.board_rows = run_state_script.BOARD_ROWS_MAX
	run_manager.state.hand.clear()
	run_manager.state.board = _sample_board()
	var battle = battle_scene.instantiate()
	if battle == null:
		return _fail("battle.tscn 인스턴스 생성 실패 stage %d" % stage)
	root.add_child(battle)
	await _frames(8)
	battle._sim.result = sim_result
	battle._end_battle()
	await _frames(8)

	var errors := 0
	var outcome: Dictionary = run_manager.get_last_battle_outcome()
	if String(outcome.get("run_result", "")) != run_result:
		errors += _fail("stage %d run_result=%s, expected %s" % [stage, String(outcome.get("run_result", "")), run_result])
	if not bool(outcome.get("run_complete", false)):
		errors += _fail("stage %d 결과가 run_complete로 닫히지 않음" % stage)
	var texts := _collect_texts(battle)
	var tooltips := _collect_tooltips(battle)
	for text in expected:
		if not _has_text_containing(texts, String(text)):
			errors += _fail("stage %d 결과 화면 누락: %s" % [stage, String(text)])
	for text in forbidden:
		if _has_text_containing(texts, String(text)):
			errors += _fail("stage %d 결과 화면 금지 문구 노출: %s" % [stage, String(text)])
	if not _has_text_containing(tooltips, "프로필에 남습니다"):
		errors += _fail("stage %d 새 런 버튼 tooltip 누락" % stage)
	if not _has_text_containing(tooltips, "칙령 0개"):
		errors += _fail("stage %d 결산 tooltip 칙령 누락" % stage)
	if not _has_text_containing(tooltips, "드로우"):
		errors += _fail("stage %d 결산 tooltip 드로우 누락" % stage)
	battle.queue_free()
	await _frames(2)
	if errors == 0:
		print("  stage %d %s 결과 화면 OK" % [stage, run_result])
	return errors

func _sample_board() -> Dictionary:
	return {
		"0:0": &"general_guanyu",
		"1:0": &"general_zhangfei",
		"2:0": &"general_zhaoyun",
		"0:1": &"troop_infantry",
		"1:1": &"troop_archer",
		"2:1": &"troop_cavalry",
	}

func _collect_texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Label:
		out.append((node as Label).text)
	elif node is Button:
		out.append((node as Button).text)
	for child in node.get_children():
		out.append_array(_collect_texts(child))
	return out

func _collect_tooltips(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Control:
		var tooltip := (node as Control).tooltip_text
		if not tooltip.is_empty():
			out.append(tooltip)
	for child in node.get_children():
		out.append_array(_collect_tooltips(child))
	return out

func _has_text_containing(texts: Array[String], needle: String) -> bool:
	for text in texts:
		if text.find(needle) >= 0:
			return true
	return false

func _frames(n: int) -> void:
	for _i in n:
		await process_frame

func _fail(msg: String) -> int:
	printerr("  ", msg)
	return 1
