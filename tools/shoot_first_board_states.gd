# 첫 전투 보드 상태 스크린샷 하네스 — 성 후보/손패 선택/계략 버튼/배치 가능 상태를 차례로 캡처한다.
# 실행 — LORD=lord_liubei SHOOT_STAGE=1 SHOT_DIR=/tmp/guju-first-board godot --path . res://tools/shoot_first_board_states.tscn
extends Node

const _VisualQaConfig := preload("res://tools/visual_qa_config.gd")

func _ready() -> void:
	var target_stage := _VisualQaConfig.env_int("SHOOT_STAGE", 1)
	var lord := _VisualQaConfig.env_lord()
	var output_dir := _VisualQaConfig.env_output_dir()
	DirAccess.make_dir_recursive_absolute(output_dir)
	_prepare_first_run(lord, target_stage)
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await _frames(12)
	await _shoot(_VisualQaConfig.shot_path("battle_first_castle", lord, target_stage, output_dir))
	if battle.has_method("_on_tile_pressed"):
		battle._on_tile_pressed("1:1")
	await _frames(4)
	await _shoot(_VisualQaConfig.shot_path("battle_first_hand", lord, target_stage, output_dir))
	if battle.has_method("_select_hand"):
		battle._select_hand(0)
	await _frames(4)
	await _shoot(_VisualQaConfig.shot_path("battle_first_scheme", lord, target_stage, output_dir))
	if battle.has_method("_select_hand"):
		battle._select_hand(1)
	await _frames(4)
	await _shoot(_VisualQaConfig.shot_path("battle_first_place", lord, target_stage, output_dir))
	get_tree().quit()

func _prepare_first_run(lord: StringName, target_stage: int) -> void:
	RunManager.reset_run()
	RunManager.ensure_started(lord)
	RunManager.state.stage_index = target_stage
	RunManager.state.castle_key = ""
	RunManager.state.board.clear()
	RunManager.state.board_levels.clear()
	RunManager.state.hand.clear()
	RunManager.state.draw_pile.clear()
	RunManager.state.hand.append(&"scheme_raid")
	RunManager.state.hand.append(&"troop_infantry")
	RunManager.state.hand.append(&"building_dunjeon")
	RunManager.state.deploy_cards_played = 0
	RunManager.state.deploy_stage_index = target_stage

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

func _shoot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("SHOT ", path, " ", img.get_size())
	else:
		print("SHOT FAIL ", path)
