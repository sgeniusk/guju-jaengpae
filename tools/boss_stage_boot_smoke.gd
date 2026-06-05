# 보스 스테이지별 battle.tscn 부팅 스모크 — stage 5/10/15 컨텍스트로 장면을 직접 띄운다.
# 실행 — godot --headless --path . --script res://tools/boss_stage_boot_smoke.gd
extends SceneTree

const LORD_ID := &"lord_liubei"
const BOSS_STAGES := [5, 10, 15]
const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors := 0
	for stage in BOSS_STAGES:
		errors += await _boot_stage(stage)
	if errors == 0:
		print("✅ 보스 스테이지 부팅 스모크 통과")
		quit(0)
	else:
		printerr("❌ 보스 스테이지 부팅 스모크 실패: %d건" % errors)
		quit(1)

func _boot_stage(stage: int) -> int:
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
	run_manager.state.castle_key = "1:1"
	run_manager.state.board = {
		"0:0": &"general_guanyu",
		"1:0": &"general_zhangfei",
		"2:0": &"general_zhaoyun",
		"0:1": &"troop_infantry",
		"1:1": &"troop_archer",
		"2:1": &"troop_cavalry",
		"0:2": &"general_caocao",
		"1:2": &"general_xiahoudun",
		"2:2": &"general_sunquan",
	}
	if not run_manager.is_boss_stage():
		return _fail("stage %d가 보스 stage로 인식되지 않음" % stage)
	var battle = battle_scene.instantiate()
	if battle == null:
		return _fail("battle.tscn 인스턴스 생성 실패 stage %d" % stage)
	root.add_child(battle)
	await _frames(8)
	if battle.has_method("_on_start_pressed"):
		battle._on_start_pressed()
	await _frames(24)
	battle.queue_free()
	await _frames(2)
	print("  stage %d 보스 전투 부팅 OK" % stage)
	return 0

func _frames(n: int) -> void:
	for _i in n:
		await process_frame

func _fail(msg: String) -> int:
	printerr("  ", msg)
	return 1
