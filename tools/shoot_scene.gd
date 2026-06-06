# 범용 씬 스크린샷 하네스 — SCENE 환경변수의 씬을 띄워 몇 프레임 뒤 캡처. 시각 QA 전용.
# 실행 — SCENE=res://scenes/screens/lord_select.tscn SHOT_KIND=lord_select SHOT_DIR=/tmp/guju-visual-qa godot --path . --scene res://tools/shoot_scene.tscn
extends Node

const _VisualQaConfig := preload("res://tools/visual_qa_config.gd")

func _ready() -> void:
	var path := "res://scenes/screens/lord_select.tscn"
	if OS.has_environment("SCENE"):
		path = OS.get_environment("SCENE")
	var kind := "scene"
	if OS.has_environment("SHOT_KIND"):
		kind = OS.get_environment("SHOT_KIND")
	var output_dir := _VisualQaConfig.env_output_dir()
	DirAccess.make_dir_recursive_absolute(output_dir)
	var scn: Node = load(path).instantiate()
	add_child(scn)
	await _frames(30)
	var shot_path := _VisualQaConfig.shot_path(kind, &"all", 0, output_dir)
	await _VisualQaConfig.capture_viewport_png(get_viewport(), get_tree(), shot_path)
	get_tree().quit()

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame
