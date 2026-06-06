# 선형 런 스테이지 화면 — 현재 스테이지 정보를 보여주고 전투로 진입한다.
extends Control

const LORD_ID := &"lord_liubei"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")
const _EdictCatalog := preload("res://scripts/run/edict_catalog.gd")
const _CardChoiceAdvisor := preload("res://scripts/run/card_choice_advisor.gd")
const _CardUiText := preload("res://scripts/ui/card_ui_text.gd")
const _ExportSmoke := preload("res://scripts/run/export_smoke.gd")
const _RunPrepSummary := preload("res://scripts/run/run_prep_summary.gd")
const _ShopHandSummary := preload("res://scripts/run/shop_hand_summary.gd")
const _RunFlowSummary := preload("res://scripts/run/run_flow_summary.gd")
const _ShopPurchaseFeedback := preload("res://scripts/run/shop_purchase_feedback.gd")

var _root: VBoxContainer
var _shop_status_message := ""

func _ready() -> void:
	if not RunManager.is_run_started() and RunManager.has_resumeable_run_save():
		RunManager.load_run()
	RunManager.ensure_started(LORD_ID)
	AudioManager.play_music(&"battle")
	_render()
	if _ExportSmoke.is_first_battle_requested():
		call_deferred("_run_export_first_battle_smoke")

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
	var kind := RunManager.stage_node_kind()
	var stage_label := Label.new()
	stage_label.text = _stage_label(stage)
	stage_label.add_theme_font_size_override("font_size", 44)
	if kind == "boss":
		stage_label.modulate = Color(1.0, 0.55, 0.35)
	elif kind == "edict":
		stage_label.modulate = Color(0.70, 0.90, 1.0)
	elif kind == "shop":
		stage_label.modulate = Color(0.95, 0.78, 0.36)
	elif kind == "elite":
		stage_label.modulate = Color(1.0, 0.68, 0.78)
	elif kind == "event":
		stage_label.modulate = Color(0.74, 1.0, 0.68)
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
	summary.tooltip_text = "현재 보드 배치, 손패 장수, 보유 골드, 이번 스테이지 난이도입니다."
	summary.add_theme_font_size_override("font_size", 26)
	_root.add_child(summary)

	var boss_note := Label.new()
	boss_note.text = _stage_note()
	boss_note.add_theme_font_size_override("font_size", 24)
	boss_note.modulate = Color(1.0, 0.75, 0.45) if _has_accent_note(kind) else Color(0.78, 0.82, 0.78)
	_root.add_child(boss_note)

	_add_run_flow_summary()

	var board_box := VBoxContainer.new()
	board_box.add_theme_constant_override("separation", 8)
	_root.add_child(board_box)
	_add_board_summary(board_box)

	if kind == "boss":
		pass
	elif kind == "edict":
		_build_edict_panel()
		return
	elif kind == "shop":
		_build_shop_panel()
		return
	elif kind == "event":
		_build_event_panel()
		return

	_add_battle_prep_summary()

	var start := Button.new()
	start.text = "전투 시작"
	start.tooltip_text = "전투 화면으로 들어가 성 위치를 고르고 손패 1장을 사용한 뒤 전투를 시작합니다." if RunManager.get_board().is_empty() else "현재 보드 군세에 손패 1장을 더하거나 계략/우물을 쓰고 전투를 시작합니다."
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

	if _shop_status_message != "":
		var feedback := Label.new()
		feedback.text = _shop_status_message
		feedback.add_theme_font_size_override("font_size", 22)
		feedback.modulate = Color(0.72, 1.0, 0.78)
		_root.add_child(feedback)

	_add_shop_hand_summary()

	# 카드 타입 → 프레임 애셋 경로 매핑.
	var frame_paths := {
		"general":  "res://assets/sprites/ui/card_frame_general.png",
		"troop":    "res://assets/sprites/ui/card_frame_troop.png",
		"building": "res://assets/sprites/ui/card_frame_building.png",
	}

	var leave := Button.new()
	leave.text = "상점 떠나기"
	leave.tooltip_text = "구매를 마치고 다음 스테이지로 이동합니다."
	leave.custom_minimum_size = Vector2(360.0, 56.0)
	leave.add_theme_font_size_override("font_size", 26)
	leave.pressed.connect(_on_shop_leave_pressed)
	_root.add_child(leave)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1760.0, 340.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_root.add_child(scroll)

	# 그리드 레이아웃 — HFlowContainer로 카드 자동 줄바꿈.
	var grid := HFlowContainer.new()
	grid.custom_minimum_size = Vector2(1720.0, 0.0)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)

	var gold := RunManager.get_gold()
	var choice_context := _CardChoiceAdvisor.context(
		RunManager.get_board(),
		RunManager.get_board_levels(),
		RunManager.get_hand(),
		gold,
		CardLibrary.catalog
	)

	var shop_ids := _CardChoiceAdvisor.ranked_ids(
		RunManager.shop_card_ids(),
		choice_context,
		CardLibrary.catalog,
		_CardChoiceAdvisor.MODE_SHOP
	)
	for id in shop_ids:
		var card := CardLibrary.get_card(id)
		if card == null:
			continue

		var can_afford: bool = gold >= card.cost
		var card_type: String = card.card_type if card.get("card_type") != null else ""

		# 카드 컨테이너 버튼 — 프레임 이미지 위에 텍스트를 올린다.
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(240.0, 330.0)
		btn.tooltip_text = _shop_card_tooltip(card, can_afford, choice_context)
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

		var route_label := Label.new()
		route_label.text = "%s · %s" % [_CardUiText.type_label(card), _CardUiText.shop_route_label(card)]
		route_label.add_theme_font_size_override("font_size", 15)
		route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		route_label.modulate = Color(0.72, 0.92, 1.0)
		route_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(route_label)

		var effect_label := Label.new()
		effect_label.text = _CardUiText.battle_brief(card)
		effect_label.add_theme_font_size_override("font_size", 16)
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_label.modulate = Color(0.88, 0.94, 0.82)
		effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(effect_label)

		var advice_label := Label.new()
		advice_label.text = _CardChoiceAdvisor.line_for_card(card, choice_context, _CardChoiceAdvisor.MODE_SHOP)
		advice_label.add_theme_font_size_override("font_size", 14)
		advice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		advice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		advice_label.modulate = Color(1.0, 0.86, 0.46) if can_afford else Color(1.0, 0.56, 0.46)
		advice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(advice_label)

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

		var purchase_status := Label.new()
		purchase_status.text = _ShopPurchaseFeedback.availability_line(card, gold)
		purchase_status.add_theme_font_size_override("font_size", 14)
		purchase_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		purchase_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		purchase_status.modulate = Color(0.70, 1.0, 0.70) if can_afford else Color(1.0, 0.62, 0.48)
		purchase_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(purchase_status)

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
		btn.tooltip_text = "%s\n%s\n선택하면 즉시 적용되고 다음 스테이지로 이동합니다." % [
			String(info.get("name", id)),
			String(info.get("desc", "")),
		]
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_edict_pressed.bind(id))
		row.add_child(btn)

func _build_event_panel() -> void:
	var status := Label.new()
	status.text = "길목 사건 — 군량을 확보합니다."
	status.add_theme_font_size_override("font_size", 28)
	status.modulate = Color(0.74, 1.0, 0.68)
	_root.add_child(status)

	var take := Button.new()
	take.text = "군량 징발 +20금"
	take.tooltip_text = "+20금을 획득하고 다음 스테이지로 이동합니다."
	take.custom_minimum_size = Vector2(360.0, 64.0)
	take.add_theme_font_size_override("font_size", 28)
	take.pressed.connect(_on_event_gold_pressed.bind(20))
	_root.add_child(take)

func _add_board_summary(parent: VBoxContainer) -> void:
	var board := RunManager.get_board()
	if board.is_empty():
		var empty := Label.new()
		empty.text = "보드 군세 없음 — 전투 화면에서 손패를 배치하세요."
		empty.tooltip_text = "전투 화면의 배치 단계에서 손패를 선택한 뒤 빈 타일을 클릭합니다."
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
		label.tooltip_text = _CardUiText.tooltip(card) if card != null else String(board[key])
		label.add_theme_font_size_override("font_size", 21)
		parent.add_child(label)

func _add_battle_prep_summary() -> void:
	var summary := _RunPrepSummary.for_run(
		RunManager.get_board(),
		RunManager.get_board_levels(),
		RunManager.get_deploy_hand_preview(),
		RunManager.get_castle_key(),
		RunManager.get_board_capacity(),
		CardLibrary.catalog,
		RunManager.get_hand().size()
	)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.tooltip_text = String(summary.get("tooltip", ""))
	_root.add_child(box)

	var title := Label.new()
	title.text = String(summary.get("title", "전투 준비"))
	title.tooltip_text = String(summary.get("tooltip", ""))
	title.add_theme_font_size_override("font_size", 27)
	title.modulate = Color(0.78, 0.94, 1.0)
	box.add_child(title)

	var detail := Label.new()
	detail.text = String(summary.get("detail", ""))
	detail.tooltip_text = String(summary.get("tooltip", ""))
	detail.add_theme_font_size_override("font_size", 22)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.modulate = Color(0.86, 0.88, 0.78)
	box.add_child(detail)

func _add_shop_hand_summary() -> void:
	var summary := _ShopHandSummary.for_state(
		RunManager.get_hand().size(),
		RunManager.get_deploy_hand_preview().size(),
		RunManager.deploy_hand_refresh_pending()
	)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.tooltip_text = String(summary.get("tooltip", ""))
	_root.add_child(box)

	var title := Label.new()
	title.text = String(summary.get("title", "다음 전투 손패"))
	title.tooltip_text = String(summary.get("tooltip", ""))
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(0.82, 0.94, 1.0)
	box.add_child(title)

	var detail := Label.new()
	detail.text = String(summary.get("detail", ""))
	detail.tooltip_text = String(summary.get("tooltip", ""))
	detail.add_theme_font_size_override("font_size", 20)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.modulate = Color(1.0, 0.86, 0.48)
	box.add_child(detail)

func _add_run_flow_summary() -> void:
	var summary := _RunFlowSummary.for_stage(RunManager.stage_index())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.tooltip_text = String(summary.get("tooltip", ""))
	_root.add_child(box)

	var title := Label.new()
	title.text = String(summary.get("title", "진행 리듬"))
	title.tooltip_text = String(summary.get("tooltip", ""))
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(0.74, 0.92, 1.0)
	box.add_child(title)

	var current := Label.new()
	current.text = String(summary.get("current", ""))
	current.tooltip_text = String(summary.get("tooltip", ""))
	current.add_theme_font_size_override("font_size", 20)
	current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current.modulate = Color(0.88, 0.90, 0.78)
	box.add_child(current)

	var upcoming := Label.new()
	upcoming.text = String(summary.get("upcoming", ""))
	upcoming.tooltip_text = String(summary.get("tooltip", ""))
	upcoming.add_theme_font_size_override("font_size", 20)
	upcoming.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upcoming.modulate = Color(1.0, 0.86, 0.48)
	box.add_child(upcoming)

func _shop_card_tooltip(card: CardData, can_afford: bool, choice_context: Dictionary) -> String:
	var text := _CardUiText.tooltip(card)
	text += "\n%s" % _CardChoiceAdvisor.tooltip_for_card(card, choice_context, _CardChoiceAdvisor.MODE_SHOP)
	text += "\n%s" % _ShopPurchaseFeedback.availability_tooltip(card, RunManager.get_gold())
	if not can_afford:
		text += "\n골드가 부족합니다."
	else:
		text += "\n구매하면 %s" % (_CardUiText.acquisition_hint(card, card.display_name) if card != null else "손패에 추가됩니다.")
	return text

func _on_battle_pressed() -> void:
	AudioManager.play_sfx(&"start")
	GameManager.change_scene(BATTLE_SCENE)

func _run_export_first_battle_smoke() -> void:
	if not _ExportSmoke.is_first_battle_requested():
		return
	var placement := _ExportSmoke.ensure_first_battle_board()
	if not bool(placement.get("ok", false)):
		_ExportSmoke.fail_and_quit(get_tree(), "no_unit_for_first_battle", placement)
		return
	_ExportSmoke.log_marker("run_map_ready", {
		"stage": RunManager.stage_index(),
		"kind": RunManager.stage_node_kind(),
		"placement": placement,
	})
	_on_battle_pressed()

func _on_shop_card_pressed(id: StringName) -> void:
	var card := CardLibrary.get_card(id)
	var before_gold := RunManager.get_gold()
	if RunManager.shop_purchase(id):
		_shop_status_message = _ShopPurchaseFeedback.success_line(card, before_gold, RunManager.get_gold())
		AudioManager.play_sfx(&"gold")
	else:
		_shop_status_message = _ShopPurchaseFeedback.failure_line(card, RunManager.get_gold())
		AudioManager.play_sfx(&"defeat")
	_render()

func _on_shop_leave_pressed() -> void:
	AudioManager.play_sfx(&"ui")
	_shop_status_message = ""
	RunManager.advance_stage()
	_render()

func _on_edict_pressed(id: StringName) -> void:
	AudioManager.play_sfx(&"ui")
	RunManager.add_edict(id)
	RunManager.advance_stage()
	_render()

func _on_event_gold_pressed(amount: int) -> void:
	AudioManager.play_sfx(&"gold")
	RunManager.add_gold(amount)
	RunManager.advance_stage()
	_render()

func _stage_label(stage: int) -> String:
	return _StageCadence.stage_label(stage)

func _stage_note() -> String:
	match RunManager.stage_node_kind():
		"boss":
			return "강적 출현"
		"edict":
			return "왕명이 내려 런 전체 보정을 선택합니다."
		"shop":
			return "전투 전 군자금으로 카드를 구매합니다."
		"elite":
			return "정예 군세가 진군합니다."
		"event":
			return "짧은 사건을 해결하고 다음 길로 나아갑니다."
		_:
			if RunManager.stage_index() == 1:
				return "첫 전투입니다. 전투 화면에서 손패 카드를 고르고 빈 타일에 배치한 뒤 전투 시작을 누르세요."
			return "적 군세가 성을 향해 진군합니다."

func _has_accent_note(kind: String) -> bool:
	return ["boss", "edict", "shop", "elite", "event"].has(kind)

func _block_label(block_key: String) -> String:
	var parts := block_key.split(":")
	if parts.size() != 2:
		return block_key
	return "%d열 %d행" % [int(parts[0]) + 1, int(parts[1]) + 1]
