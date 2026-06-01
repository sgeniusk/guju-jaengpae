# 선형 런 스테이지 화면 — 현재 스테이지 정보를 보여주고 전투로 진입한다.
extends Control

const LORD_ID := &"lord_liubei"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")

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
	stage_label.text = _StageCadence.stage_label(stage)
	stage_label.add_theme_font_size_override("font_size", 44)
	if RunManager.is_boss_stage():
		stage_label.modulate = Color(1.0, 0.55, 0.35)
	_root.add_child(stage_label)

	var summary := Label.new()
	summary.text = "보드 %d / %d · 손패 %d장 · 골드 %d · 난이도 x%.2f" % [
		RunManager.get_board().size(),
		RunState.BOARD_BLOCKS,
		RunManager.get_hand().size(),
		RunManager.get_gold(),
		RunManager.difficulty_scale(),
	]
	summary.add_theme_font_size_override("font_size", 26)
	_root.add_child(summary)

	var boss_note := Label.new()
	boss_note.text = "강적 출현" if RunManager.is_boss_stage() else "적 군세가 성을 향해 진군합니다."
	boss_note.add_theme_font_size_override("font_size", 24)
	boss_note.modulate = Color(1.0, 0.75, 0.45) if RunManager.is_boss_stage() else Color(0.78, 0.82, 0.78)
	_root.add_child(boss_note)

	var board_box := VBoxContainer.new()
	board_box.add_theme_constant_override("separation", 8)
	_root.add_child(board_box)
	_add_board_summary(board_box)

	var start := Button.new()
	start.text = "전투 시작"
	start.custom_minimum_size = Vector2(360.0, 64.0)
	start.add_theme_font_size_override("font_size", 28)
	start.pressed.connect(_on_battle_pressed)
	_root.add_child(start)

func _add_board_summary(parent: VBoxContainer) -> void:
	var board := RunManager.get_board()
	if board.is_empty():
		var empty := Label.new()
		empty.text = "보드 군세 없음 — 전투 화면에서 손패를 배치하세요."
		empty.add_theme_font_size_override("font_size", 22)
		parent.add_child(empty)
		return
	for key in RunState.block_keys():
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

func _block_label(block_key: String) -> String:
	var parts := block_key.split(":")
	if parts.size() != 2:
		return block_key
	return "%d열 %d행" % [int(parts[0]) + 1, int(parts[1]) + 1]
