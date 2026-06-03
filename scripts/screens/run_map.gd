# 선형 런 스테이지 화면 — 현재 스테이지 정보를 보여주고 전투로 진입한다.
extends Control

const LORD_ID := &"lord_liubei"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")
const _EdictCatalog := preload("res://scripts/run/edict_catalog.gd")

var _root: VBoxContainer

func _ready() -> void:
	RunManager.ensure_started(LORD_ID)
	_render()

func _render() -> void:
	for child in get_children():
		child.queue_free()
	_build_background()
	_build_root()
	_build_stage_panel()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _build_root() -> void:
	_root = VBoxContainer.new()
	_root.position = Vector2(80.0, 56.0)
	_root.size = Vector2(1760.0, 960.0)
	_root.add_theme_constant_override("separation", 24)
	add_child(_root)

	var title := Label.new()
	title.text = "구주쟁패"
	title.add_theme_font_size_override("font_size", 54)
	_root.add_child(title)

func _build_stage_panel() -> void:
	var stage := RunManager.stage_index()
	var stage_label := Label.new()
	stage_label.text = _stage_label(stage)
	stage_label.add_theme_font_size_override("font_size", 44)
	if RunManager.is_boss_stage():
		stage_label.modulate = Color(1.0, 0.55, 0.35)
	elif RunManager.is_edict_stage():
		stage_label.modulate = Color(0.70, 0.90, 1.0)
	elif RunManager.is_shop_stage():
		stage_label.modulate = Color(0.95, 0.78, 0.36)
	_root.add_child(stage_label)

	var summary := Label.new()
	summary.text = "보드 %d / %d · 손패 %d / %d · 골드 %d · 난이도 x%.2f" % [
		RunManager.get_board().size(),
		RunManager.get_board_capacity(),
		RunManager.get_hand().size(),
		RunState.HAND_MAX,
		RunManager.get_gold(),
		RunManager.difficulty_scale(),
	]
	summary.add_theme_font_size_override("font_size", 26)
	_root.add_child(summary)

	var boss_note := Label.new()
	boss_note.text = _stage_note()
	boss_note.add_theme_font_size_override("font_size", 24)
	boss_note.modulate = Color(1.0, 0.75, 0.45) if (RunManager.is_boss_stage() or RunManager.is_shop_stage() or RunManager.is_edict_stage()) else Color(0.78, 0.82, 0.78)
	_root.add_child(boss_note)

	var board_box := VBoxContainer.new()
	board_box.add_theme_constant_override("separation", 8)
	_root.add_child(board_box)
	_add_board_summary(board_box)

	if RunManager.is_boss_stage():
		pass
	elif RunManager.is_edict_stage():
		_build_edict_panel()
		return
	elif RunManager.is_shop_stage():
		_build_shop_panel()
		return

	var start := Button.new()
	start.text = "전투 시작"
	start.custom_minimum_size = Vector2(360.0, 64.0)
	start.add_theme_font_size_override("font_size", 28)
	start.pressed.connect(_on_battle_pressed)
	_root.add_child(start)

func _build_shop_panel() -> void:
	# 상태 표시줄 — 골드 아이콘 + 자금/손패 정보.
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	_root.add_child(status_row)

	var gold_icon_path := "res://assets/sprites/ui/icon_gold.png"
	if ResourceLoader.exists(gold_icon_path):
		var gold_tex := load(gold_icon_path) as Texture2D
		if gold_tex != null:
			var gold_icon := TextureRect.new()
			gold_icon.texture = gold_tex
			gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			gold_icon.custom_minimum_size = Vector2(32.0, 32.0)
			status_row.add_child(gold_icon)

	var status := Label.new()
	status.text = "상점 자금 %d금  ·  손패 %d / %d" % [
		RunManager.get_gold(),
		RunManager.get_hand().size(),
		RunState.HAND_MAX,
	]
	status.add_theme_font_size_override("font_size", 28)
	status.modulate = Color(0.96, 0.85, 0.50)
	status_row.add_child(status)

	if RunManager.get_hand().size() > RunState.HAND_MAX:
		var hint := Label.new()
		hint.text = "손패 초과분은 다음 전투 배치에서 보드로 정리하세요."
		hint.add_theme_font_size_override("font_size", 22)
		hint.modulate = Color(1.0, 0.82, 0.42)
		_root.add_child(hint)

	# 카드 타입 → 프레임 애셋 경로 매핑.
	var frame_paths := {
		"general":  "res://assets/sprites/ui/card_frame_general.png",
		"troop":    "res://assets/sprites/ui/card_frame_troop.png",
		"building": "res://assets/sprites/ui/card_frame_building.png",
	}

	# 그리드 레이아웃 — HFlowContainer로 카드 자동 줄바꿈.
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	_root.add_child(grid)

	var gold := RunManager.get_gold()

	for id in RunManager.shop_card_ids():
		var card := CardLibrary.get_card(id)
		if card == null:
			continue

		var can_afford: bool = gold >= card.cost
		var card_type: String = card.card_type if card.get("card_type") != null else ""

		# 카드 컨테이너 버튼 — 프레임 이미지 위에 텍스트를 올린다.
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220.0, 300.0)
		btn.disabled = not can_afford
		if not can_afford:
			btn.modulate = Color(0.55, 0.55, 0.55, 0.80)
		btn.pressed.connect(_on_shop_card_pressed.bind(id))

		# 프레임 이미지 배치 — 버튼 안에 TextureRect로 배경 처리.
		var frame_path: String = frame_paths.get(card_type, "")
		if frame_path != "" and ResourceLoader.exists(frame_path):
			var frame_tex := load(frame_path) as Texture2D
			if frame_tex != null:
				var frame_rect := TextureRect.new()
				frame_rect.texture = frame_tex
				frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
				frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
				frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn.add_child(frame_rect)

		# 카드 정보 레이블 컨테이너 — 프레임 위에 올라간다.
		var info_box := VBoxContainer.new()
		info_box.set_anchors_preset(Control.PRESET_FULL_RECT)
		info_box.add_theme_constant_override("separation", 6)
		info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(info_box)

		# 카드명 표시.
		var name_label := Label.new()
		name_label.text = card.display_name
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.modulate = Color(0.96, 0.92, 0.78)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(name_label)

		# 비용 행 — 골드 아이콘 + 숫자.
		var cost_row := HBoxContainer.new()
		cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
		cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(cost_row)

		if ResourceLoader.exists(gold_icon_path):
			var cost_tex := load(gold_icon_path) as Texture2D
			if cost_tex != null:
				var cost_icon := TextureRect.new()
				cost_icon.texture = cost_tex
				cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				cost_icon.custom_minimum_size = Vector2(22.0, 22.0)
				cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				cost_row.add_child(cost_icon)

		var cost_label := Label.new()
		cost_label.text = " %d" % card.cost
		cost_label.add_theme_font_size_override("font_size", 22)
		cost_label.modulate = Color(1.0, 0.85, 0.30) if can_afford else Color(0.70, 0.60, 0.40)
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_row.add_child(cost_label)

		# 설명 텍스트 — 아래쪽에 작게.
		var desc_label := Label.new()
		desc_label.text = card.description
		desc_label.add_theme_font_size_override("font_size", 15)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.modulate = Color(0.80, 0.80, 0.78)
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(desc_label)

		grid.add_child(btn)

	var leave := Button.new()
	leave.text = "상점 떠나기"
	leave.custom_minimum_size = Vector2(360.0, 64.0)
	leave.add_theme_font_size_override("font_size", 28)
	leave.pressed.connect(_on_shop_leave_pressed)
	_root.add_child(leave)

func _build_edict_panel() -> void:
	var status := Label.new()
	status.text = "누적 칙령 %d개 — 하나를 골라 런 전체에 적용합니다." % RunManager.get_edicts().size()
	status.add_theme_font_size_override("font_size", 28)
	status.modulate = Color(0.72, 0.90, 1.0)
	_root.add_child(status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	_root.add_child(row)

	for id in _EdictCatalog.all_ids():
		var info := _EdictCatalog.info(id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(320.0, 160.0)
		btn.text = "%s\n%s" % [String(info.get("name", id)), String(info.get("desc", ""))]
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_edict_pressed.bind(id))
		row.add_child(btn)

func _add_board_summary(parent: VBoxContainer) -> void:
	var board := RunManager.get_board()
	if board.is_empty():
		var empty := Label.new()
		empty.text = "보드 군세 없음 — 전투 화면에서 손패를 배치하세요."
		empty.add_theme_font_size_override("font_size", 22)
		parent.add_child(empty)
		return
	for key in RunState.block_keys_for(RunManager.get_board_rows()):
		if not board.has(key):
			continue
		var card := CardLibrary.get_card(StringName(board[key]))
		var card_name := card.display_name if card != null else String(board[key])
		var label := Label.new()
		label.text = "%s — %s" % [_block_label(key), card_name]
		label.add_theme_font_size_override("font_size", 21)
		parent.add_child(label)

func _on_battle_pressed() -> void:
	GameManager.change_scene(BATTLE_SCENE)

func _on_shop_card_pressed(id: StringName) -> void:
	RunManager.shop_purchase(id)
	_render()

func _on_shop_leave_pressed() -> void:
	RunManager.advance_stage()
	_render()

func _on_edict_pressed(id: StringName) -> void:
	RunManager.add_edict(id)
	RunManager.advance_stage()
	_render()

func _stage_label(stage: int) -> String:
	if RunManager.is_boss_stage():
		return _StageCadence.stage_label(stage)
	if RunManager.is_edict_stage():
		return "스테이지 %d — 왕의 칙령" % stage
	if RunManager.is_shop_stage():
		return "스테이지 %d — 상점" % stage
	return _StageCadence.stage_label(stage)

func _stage_note() -> String:
	if RunManager.is_boss_stage():
		return "강적 출현"
	if RunManager.is_edict_stage():
		return "왕명이 내려 런 전체 보정을 선택합니다."
	if RunManager.is_shop_stage():
		return "전투 전 군자금으로 카드를 구매합니다."
	return "적 군세가 성을 향해 진군합니다."

func _block_label(block_key: String) -> String:
	var parts := block_key.split(":")
	if parts.size() != 2:
		return block_key
	return "%d열 %d행" % [int(parts[0]) + 1, int(parts[1]) + 1]
