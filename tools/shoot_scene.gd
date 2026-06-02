# 범용 씬 스크린샷 하네스 — SCENE 환경변수의 씬을 띄워 몇 프레임 뒤 /tmp/shot_scene.png로 캡처. 시각 QA 전용.
# 실행 — SCENE=res://scenes/screens/lord_select.tscn godot --path . res://tools/shoot_scene.tscn
extends Node

func _ready() -> void:
	var path := "res://scenes/screens/lord_select.tscn"
	if OS.has_environment("SCENE"):
		path = OS.get_environment("SCENE")
	var scn: Node = load(path).instantiate()
	add_child(scn)
	await _frames(30)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("/tmp/shot_scene.png")
		print("SHOT /tmp/shot_scene.png ", img.get_size())
	get_tree().quit()

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame
