# 전투 화면 스크린샷 하네스 — 런을 세팅하고 battle.tscn을 띄워 배치·교전 장면을 캡처한다. 시각 QA 전용(게임 로직 아님).
# 실행 — LORD=lord_caocao SHOOT_STAGE=5 SHOT_DIR=/tmp/guju-visual-qa godot --path . --scene res://tools/shoot_battle.tscn
extends Node

const _VisualQaConfig := preload("res://tools/visual_qa_config.gd")

func _ready() -> void:
	var target_stage := _VisualQaConfig.env_int("SHOOT_STAGE", _VisualQaConfig.DEFAULT_BATTLE_STAGE)
	var fight_frames := _VisualQaConfig.env_int("SHOOT_FIGHT_FRAMES", 560)
	var forced_result := OS.get_environment("SHOOT_FORCE_RESULT").strip_edges().to_lower()
	var lord := _VisualQaConfig.env_lord()
	var output_dir := _VisualQaConfig.env_output_dir()
	DirAccess.make_dir_recursive_absolute(output_dir)
	RunManager.ensure_started(lord)
	var guard := 0
	while RunManager.stage_index() < target_stage and guard < 50:
		RunManager.advance_stage()
		guard += 1
	# QA 시연용 — 건물 카드(둔전·망루)를 손패에 추가해 기지에 보이게 한다.
	RunManager.hand_add(&"building_dunjeon")
	RunManager.hand_add(&"building_mangru")
	# 손패를 보드에 가득 배치(군세·건물이 보이도록)
	var blocks := ["0:0", "1:0", "2:0", "0:1", "1:1", "2:1", "0:2", "1:2", "2:2"]
	if not RunManager.has_castle():
		RunManager.set_castle_key("1:1")
	for key in blocks:
		if RunManager.get_hand().is_empty():
			break
		if key == RunManager.get_castle_key():
			continue
		RunManager.state.place_from_hand(0, key)
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await _frames(25)
	await _shoot(_VisualQaConfig.shot_path("battle_deploy", lord, target_stage, output_dir))
	if forced_result == "win" or forced_result == "loss":
		battle._sim.result = BattleSim.Result.PLAYER_WIN if forced_result == "win" else BattleSim.Result.PLAYER_LOSE
		battle._end_battle()
		await _frames(10)
		await _shoot(_VisualQaConfig.shot_path("battle_result_%s" % forced_result, lord, target_stage, output_dir))
		get_tree().quit()
		return
	if battle.has_method("_on_start_pressed"):
		battle._on_start_pressed()
	await _frames(fight_frames)
	await _shoot(_VisualQaConfig.shot_path("battle_fight", lord, target_stage, output_dir))
	get_tree().quit()

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

func _shoot(path: String) -> void:
	await _VisualQaConfig.capture_viewport_png(get_viewport(), get_tree(), path)
