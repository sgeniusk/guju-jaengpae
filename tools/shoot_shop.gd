# 상점 화면 스크린샷 하네스 — 런을 상점 스테이지(4)로 보내고 골드를 주입해 run_map을 띄워 캡처한다. 시각 QA 전용.
# 실행 — godot --path . res://tools/shoot_shop.tscn   (비헤드리스). SHOP_STAGE 환경변수로 스테이지 지정(기본 4).
extends Node

func _ready() -> void:
	var target := 4
	if OS.has_environment("SHOP_STAGE"):
		target = maxi(1, int(OS.get_environment("SHOP_STAGE")))
	RunManager.ensure_started("lord_liubei")
	var guard := 0
	while RunManager.stage_index() < target and guard < 50:
		RunManager.advance_stage()
		guard += 1
	RunManager.add_gold(60)  # 구매력 주입
	var screen: Node = load("res://scenes/screens/run_map.tscn").instantiate()
	add_child(screen)
	await _frames(30)
	await _shoot("/tmp/shot_shop.png")
	get_tree().quit()

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
