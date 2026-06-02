# 전투 화면 스크린샷 하네스 — 런을 세팅하고 battle.tscn을 띄워 배치·교전 장면을 캡처한다. 시각 QA 전용(게임 로직 아님).
# 실행 — godot --path . res://tools/shoot_battle.tscn   (비헤드리스, 렌더 필요). SHOOT_STAGE 환경변수로 스테이지 지정(기본 5=보스).
extends Node

func _ready() -> void:
	var target_stage := 5
	if OS.has_environment("SHOOT_STAGE"):
		target_stage = maxi(1, int(OS.get_environment("SHOOT_STAGE")))
	var lord := "lord_liubei"
	if OS.has_environment("LORD"):
		lord = OS.get_environment("LORD")
	RunManager.ensure_started(lord)
	var guard := 0
	while RunManager.stage_index() < target_stage and guard < 50:
		RunManager.advance_stage()
		guard += 1
	# QA 시연용 — 건물 카드(둔전·망루)를 손패에 추가해 기지에 보이게 한다.
	RunManager.hand_add(&"building_dunjeon")
	RunManager.hand_add(&"building_mangru")
	# 손패를 보드에 가득 배치(군세·건물이 보이도록)
	var blocks := ["0:2", "1:2", "2:2", "0:1", "1:1", "2:1", "0:0", "1:0", "2:0"]
	for key in blocks:
		if RunManager.get_hand().is_empty():
			break
		RunManager.place_from_hand(0, key)
	var battle: Node = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await _frames(25)
	await _shoot("/tmp/shot_deploy.png")
	if battle.has_method("_on_start_pressed"):
		battle._on_start_pressed()
	await _frames(560)
	await _shoot("/tmp/shot_fight.png")
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
